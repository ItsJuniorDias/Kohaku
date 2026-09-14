//
//  NotificationTapCoordinator.swift
//  Kohaku
//
//  Bridge between the UNUserNotificationCenter delegate (which runs on
//  its own delivery queue) and SwiftUI views. When the user taps the
//  weekly rotation notification, we set `pendingDeepLink` and views
//  observe it.
//
//  RootTabView switches to Discover; DiscoverView scrolls to the
//  featured section; DiscoverView then calls `clearPending()` so the
//  same tap isn't re-consumed on a later navigation.
//

import Foundation
import UserNotifications

@Observable
final class NotificationTapCoordinator: NSObject, UNUserNotificationCenterDelegate {

    /// A deep link that some view still needs to act on. Nil after the
    /// consumer clears it. Only one is buffered — if a tap arrives while
    /// another is pending it replaces the previous (fine for our case,
    /// there's only one destination).
    private(set) var pendingDeepLink: DeepLink?

    enum DeepLink: Equatable {
        /// Show Discover, scrolled to the featured weekly-free section.
        case weeklyRotation
    }

    /// Consume the pending link. Call this after acting on it.
    func clearPending() {
        pendingDeepLink = nil
    }

    // MARK: - Delegate methods

    /// Called when the app is in the FOREGROUND and a notification arrives.
    /// We choose to still show the banner + play the sound — otherwise the
    /// user wouldn't know a new tale dropped while they were mid-app.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    /// Called when the user TAPS a notification (foreground or background).
    /// We only handle our weekly-rotation type; others are ignored gracefully.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }

        let userInfo = response.notification.request.content.userInfo
        guard
            let type = userInfo[NotificationManager.userInfoTypeKey] as? String,
            type == NotificationManager.weeklyRotationType
        else {
            return
        }

        Task { @MainActor in
            self.pendingDeepLink = .weeklyRotation
        }
    }
}
