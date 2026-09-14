//
//  SettingsView.swift
//  Kohaku
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(SubscriptionManager.self) private var subs
    @Environment(StoryRepository.self) private var repo
    @Environment(NotificationManager.self) private var notifications

    @State private var subscriptionPresented: Bool = false
    @State private var aboutPresented: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.kohakuVoid.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: KohakuSpacing.lg) {
                        // Header
                        VStack(alignment: .leading, spacing: KohakuSpacing.xs) {
                            KohakuText("Settings", style: .displayLarge)
                        }
                        .padding(.top, KohakuSpacing.md)
                        .padding(.bottom, KohakuSpacing.sm)

                        // Subscription status
                        VStack(alignment: .leading, spacing: KohakuSpacing.sm) {
                            KohakuText("Subscription", style: .label, color: .kohakuAsh)

                            KohakuCard {
                                VStack(alignment: .leading, spacing: KohakuSpacing.xs) {
                                    HStack {
                                        subscriptionStatusView
                                        Spacer()
                                    }

                                    if !subs.subscriptionStatus.isActive {
                                        KohakuText(
                                            "Access every tale, updated weekly.",
                                            style: .caption,
                                            color: .kohakuPallor
                                        )
                                        .padding(.top, KohakuSpacing.xxs)

                                        KohakuButton.secondary("Subscribe") {
                                            subscriptionPresented = true
                                        }
                                        .padding(.top, KohakuSpacing.sm)
                                    }
                                }
                                .padding(KohakuSpacing.md)
                            }
                        }

                        // Notifications section
                        notificationsSection

                        // About section
                        VStack(alignment: .leading, spacing: KohakuSpacing.sm) {
                            KohakuText("About", style: .label, color: .kohakuAsh)

                            KohakuCard {
                                VStack(alignment: .leading, spacing: 0) {
                                    settingsRow("About Kohaku") { aboutPresented = true }
                                    Divider().background(Color.kohakuAsh.opacity(0.3))
                                    settingsRow("Restore purchases") {
                                        Task { await subs.restore() }
                                    }
                                }
                            }
                        }

                        Spacer(minLength: KohakuSpacing.xxl)
                    }
                    .padding(KohakuSpacing.md)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $subscriptionPresented) {
                SubscriptionView()
            }
            .sheet(isPresented: $aboutPresented) {
                AboutView()
            }
        }
    }

    // MARK: - Notifications section

    @ViewBuilder
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: KohakuSpacing.sm) {
            KohakuText("Notifications", style: .label, color: .kohakuAsh)

            KohakuCard {
                VStack(alignment: .leading, spacing: KohakuSpacing.sm) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: KohakuSpacing.xxs) {
                            KohakuText("Weekly free tale", style: .displaySmall)
                            KohakuText(
                                "A quiet note on Monday morning when a new tale is granted.",
                                style: .caption,
                                color: .kohakuAsh
                            )
                        }
                        Spacer()

                        // The toggle itself. Bindings go through a computed
                        // proxy so we can gate on permission before flipping.
                        Toggle("", isOn: toggleBinding)
                            .labelsHidden()
                            .tint(.kohakuBone)
                            .disabled(notifications.isPermanentlyDenied)
                    }

                    // Permanent-denial hint + link to system Settings.
                    if notifications.isPermanentlyDenied {
                        KohakuText(
                            "Notifications are turned off in iOS Settings. Open the app's settings there to turn them on.",
                            style: .caption,
                            color: .kohakuPallor
                        )

                        KohakuButton.secondary("Open Settings") {
                            openSystemSettings()
                        }
                    }
                }
                .padding(KohakuSpacing.md)
            }
        }
    }

    /// Binding that gates ON-flips on the OS permission and re-schedules
    /// after a change. The getter reflects the USER PREFERENCE, not the
    /// combined permission-and-preference state — the visual "off despite
    /// preference on because system permission was revoked" case is
    /// handled by the permanently-denied hint below the toggle.
    private var toggleBinding: Binding<Bool> {
        Binding(
            get: { notifications.weeklyNotificationsEnabled },
            set: { newValue in
                Task {
                    if newValue {
                        // Ask for permission if we haven't yet.
                        if notifications.authorizationStatus == .notDetermined {
                            _ = await notifications.requestAuthorization()
                        }
                        // If still not authorized (user denied), do not
                        // flip the preference — the toggle bounces back.
                        guard notifications.isAuthorized else {
                            notifications.setEnabled(false)
                            return
                        }
                        notifications.setEnabled(true)
                        let premiumIDs = repo.allStories.filter { $0.isPremium }.map(\.id)
                        await notifications.scheduleUpcomingRotations(
                            premiumIDs: premiumIDs,
                            stories: repo.allStories
                        )
                    } else {
                        notifications.setEnabled(false)
                    }
                }
            }
        )
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Subscription status view

    @ViewBuilder
    private var subscriptionStatusView: some View {
        switch subs.subscriptionStatus {
        case .active(let expiresAt):
            VStack(alignment: .leading, spacing: 2) {
                KohakuText("Active", style: .displaySmall)
                if let expiresAt {
                    KohakuText(
                        "Renews \(expiresAt.formatted(date: .abbreviated, time: .omitted))",
                        style: .caption,
                        color: .kohakuAsh
                    )
                }
            }
        case .notSubscribed:
            KohakuText("Not subscribed", style: .displaySmall, color: .kohakuBone)
        case .expired:
            KohakuText("Expired", style: .displaySmall, color: .kohakuAsh)
        case .unknown:
            KohakuText("…", style: .displaySmall, color: .kohakuAsh)
        }
    }

    @ViewBuilder
    private func settingsRow(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                KohakuText(title, style: .bodyMedium)
                Spacer()
                KohakuText("→", style: .bodyMedium, color: .kohakuAsh)
            }
            .padding(KohakuSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
        .environment(SubscriptionManager())
        .environment(StoryRepository())
        .environment(NotificationManager())
}
