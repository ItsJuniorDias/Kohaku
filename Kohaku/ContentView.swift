//
//  ContentView.swift
//  Kohaku
//
//  Root view — handles the onboarding gate.
//  First launch shows OnboardingView; after that, RootTabView.
//

import SwiftUI

struct ContentView: View {
    /// Persistent flag — set once onboarding is finished.
    @AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false

    var body: some View {
        Group {
            if onboardingCompleted {
                RootTabView()
            } else {
                OnboardingView(onComplete: {
                    withAnimation(KohakuMotion.slow) {
                        onboardingCompleted = true
                    }
                })
            }
        }
    }
}

#Preview("Onboarding") {
    ContentView()
        .environment(StoryRepository())
        .environment(SubscriptionManager())
        .environment(NotificationManager())
        .environment(NotificationTapCoordinator())
        .environment(AudioPlayerService())
}
