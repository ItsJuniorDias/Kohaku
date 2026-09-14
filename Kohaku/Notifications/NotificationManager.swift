//
//  NotificationManager.swift
//  Kohaku
//
//  Local notifications for the weekly rotation drop. No remote push,
//  no APNs, no server. Everything is scheduled ahead of time from the
//  same rotation math the discovery card uses.
//
//  How it works:
//
//  • On startup and on foreground, if the user has opted in AND has
//    granted permission, we schedule the NEXT 8 rotations as one-shot
//    local notifications at Monday 00:00 UTC.
//  • iOS caps pending notifications at 64 per app; 8 is a safe number
//    that lasts almost 2 months without the app ever being opened, and
//    each foreground re-scheduling replaces them cleanly.
//  • We use identifiers of the form "kohaku.weekly.<weekIndex>" so
//    reschedules idempotently replace the same slot instead of piling up.
//  • Tapping the notification is handled by NotificationTapCoordinator
//    (elsewhere) — this manager is only about scheduling and permission.
//

import Foundation
import UserNotifications

@Observable
final class NotificationManager {

    // MARK: - Constants

    static let weeklyIdentifierPrefix = "kohaku.weekly."
    static let categoryIdentifier = "weekly-rotation"
    static let userInfoTypeKey = "kohaku.notification.type"
    static let weeklyRotationType = "weekly-rotation"

    /// How many upcoming rotations to schedule at once. 8 = about 2 months
    /// of coverage even if the user never opens the app. Well under iOS's
    /// 64-notification cap.
    static let rotationsToSchedule = 8

    // MARK: - Persisted user preference

    private static let enabledDefaultsKey = "weeklyNotificationsEnabled"

    /// User preference: has the user opted in to weekly notifications?
    /// Persisted in UserDefaults. Changing this via `setEnabled(_:)` also
    /// triggers re-scheduling / cancellation.
    private(set) var weeklyNotificationsEnabled: Bool

    /// Update the user preference. Views should call this from a Toggle
    /// binding. Persistence and downstream effects happen here.
    ///
    /// If enabling and permission has never been requested, this returns
    /// without side-effects — the caller (Settings) is expected to prompt
    /// via `requestAuthorization()` first, then call this again.
    func setEnabled(_ newValue: Bool) {
        weeklyNotificationsEnabled = newValue
        UserDefaults.standard.set(newValue, forKey: Self.enabledDefaultsKey)
        if !newValue {
            cancelAll()
        }
    }

    // MARK: - Runtime authorization state

    /// Last-known system authorization status. Refreshed on init and on
    /// every scheduleUpcomingRotations() call.
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional
    }

    /// True when we CANNOT re-prompt — user denied and only iOS Settings
    /// can turn it back on.
    var isPermanentlyDenied: Bool {
        authorizationStatus == .denied
    }

    // MARK: - Init

    init() {
        self.weeklyNotificationsEnabled = UserDefaults.standard.bool(
            forKey: Self.enabledDefaultsKey
        )
        Task { await refreshAuthorizationStatus() }
    }

    // MARK: - Authorization

    /// Query the current system status without prompting the user.
    @MainActor
    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        self.authorizationStatus = settings.authorizationStatus
    }

    /// Ask the user for permission. Returns true iff the user granted it
    /// (either now or previously). Silently returns false if already denied.
    @MainActor
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            #if DEBUG
            print("⚠️ Kohaku: notification permission request failed — \(error)")
            #endif
            await refreshAuthorizationStatus()
            return false
        }
    }

    // MARK: - Scheduling

    /// Schedule the next N weekly rotation notifications. Safe to call
    /// often — the identifier scheme makes reschedules idempotent.
    ///
    /// No-op if:
    /// • User hasn't opted in (`weeklyNotificationsEnabled == false`), or
    /// • System permission is not granted
    @MainActor
    func scheduleUpcomingRotations(
        premiumIDs: [String],
        stories: [Story],
        now: Date = Date()
    ) async {
        await refreshAuthorizationStatus()

        guard weeklyNotificationsEnabled, isAuthorized else {
            // If the user opted out (or system revoked), clear everything
            // to avoid stale drops.
            cancelAll()
            return
        }
        guard !premiumIDs.isEmpty else { return }

        let order = WeeklyRotation.shuffledOrder(premiumIDs)
        let currentWeek = WeeklyRotation.weekIndex(from: now)
        let center = UNUserNotificationCenter.current()

        // Register the category (idempotent).
        registerCategory(on: center)

        // Compute the identifiers we're about to schedule so we can safely
        // cancel any stale ones outside this window in one call.
        let targetWeeks = (0..<Self.rotationsToSchedule).map { currentWeek + 1 + $0 }
        let targetIDs = Set(targetWeeks.map(Self.identifier(forWeek:)))

        // Cancel any previously-scheduled weekly drops that are NOT in the
        // new window (they'd be duplicates or now-past rotations).
        let pending = await center.pendingNotificationRequests()
        let stale = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.weeklyIdentifierPrefix) && !targetIDs.contains($0) }
        if !stale.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: stale)
        }

        // Schedule (or re-schedule) each upcoming week.
        for weekIndex in targetWeeks {
            let idx = ((weekIndex % order.count) + order.count) % order.count
            let storyID = order[idx]

            guard let story = stories.first(where: { $0.id == storyID }) else {
                #if DEBUG
                print("⚠️ Kohaku: notification skipped — no story for id \(storyID)")
                #endif
                continue
            }

            let fireDate = WeeklyRotation.anchor.addingTimeInterval(
                TimeInterval(weekIndex) * (7 * 24 * 60 * 60)
            )

            // Skip past dates (guards against clock skew or edge weeks).
            guard fireDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = "A new tale is free this week"
            content.body = story.title
            content.sound = .default
            content.categoryIdentifier = Self.categoryIdentifier
            content.userInfo = [
                Self.userInfoTypeKey: Self.weeklyRotationType
            ]

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponentsUTC(from: fireDate),
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: Self.identifier(forWeek: weekIndex),
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
            } catch {
                #if DEBUG
                print("⚠️ Kohaku: failed to schedule notification for week \(weekIndex) — \(error)")
                #endif
            }
        }
    }

    /// Remove all Kohaku-scheduled notifications.
    func cancelAll() {
        let center = UNUserNotificationCenter.current()
        Task {
            let pending = await center.pendingNotificationRequests()
            let ids = pending
                .map(\.identifier)
                .filter { $0.hasPrefix(Self.weeklyIdentifierPrefix) }
            if !ids.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: ids)
            }
        }
    }

    // MARK: - Helpers

    private static func identifier(forWeek weekIndex: Int) -> String {
        "\(weeklyIdentifierPrefix)\(weekIndex)"
    }

    private func registerCategory(on center: UNUserNotificationCenter) {
        let category = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    /// Build DateComponents pinned to UTC so the calendar trigger fires
    /// at exactly Monday 00:00 UTC everywhere, matching WeeklyRotation.
    private func dateComponentsUTC(from date: Date) -> DateComponents {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        var comps = cal.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        comps.timeZone = TimeZone(identifier: "UTC")
        return comps
    }
}
