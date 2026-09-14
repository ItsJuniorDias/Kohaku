//
//  KohakuApp.swift
//  Kohaku
//

import SwiftUI
import UserNotifications

@main
struct KohakuApp: App {
    // App-wide state
    @State private var repository = StoryRepository()
    @State private var subscriptions = SubscriptionManager()
    @State private var notifications = NotificationManager()
    @State private var notificationTaps = NotificationTapCoordinator()
    @State private var audioPlayer = AudioPlayerService()

    // Watch scene phase so we can refresh the weekly rotation when the user
    // returns from background after a Monday-00:00-UTC rollover.
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Register bundled fonts programmatically + verify (debug builds).
        // Programmatic registration is more robust than relying on Info.plist
        // UIAppFonts alone.
        FontDebug.registerAndVerifyFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(repository)
                .environment(subscriptions)
                .environment(notifications)
                .environment(notificationTaps)
                .environment(audioPlayer)
                .preferredColorScheme(.dark)
                .tint(.kohakuBone)
                .task {
                    // Install the tap coordinator as the notification-center
                    // delegate exactly once, at first appearance.
                    UNUserNotificationCenter.current().delegate = notificationTaps
                    await refreshRotationAndNotifications()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        Task { await refreshRotationAndNotifications() }
                    }
                }
        }
    }

    /// Refresh the weekly rotation and, if enabled, re-schedule the upcoming
    /// notifications. Called on app start and on every foreground.
    private func refreshRotationAndNotifications() async {
        repository.refreshWeeklyRotation()
        let premiumIDs = repository.allStories.filter { $0.isPremium }.map(\.id)
        await notifications.scheduleUpcomingRotations(
            premiumIDs: premiumIDs,
            stories: repository.allStories
        )
    }
}
