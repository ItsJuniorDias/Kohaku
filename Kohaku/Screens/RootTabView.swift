//
//  RootTabView.swift
//  Kohaku
//
//  iOS 26 native TabView with Liquid Glass tab bar.
//  Minimizes on scroll down, restores on scroll up.
//
//  MiniPlayerView is pinned above the tab bar via safeAreaInset —
//  it renders only when audio is loaded, animating in from the
//  bottom edge.
//

import SwiftUI

struct RootTabView: View {
    @Environment(NotificationTapCoordinator.self) private var taps
    @Environment(AudioPlayerService.self) private var audio

    @State private var selection: Tab = .discover

    enum Tab: Hashable {
        case library, discover, settings
    }

    var body: some View {
        TabView(selection: $selection) {
            SwiftUI.Tab("Library", systemImage: "books.vertical", value: Tab.library) {
                LibraryView()
            }

            SwiftUI.Tab("Discover", systemImage: "sparkles", value: Tab.discover) {
                DiscoverView()
            }

            SwiftUI.Tab("Settings", systemImage: "gearshape", value: Tab.settings) {
                SettingsView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(.kohakuBone)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // Mini-player pinned above the tab bar. Only renders when
            // audio is loaded (MiniPlayerView returns EmptyView otherwise).
            MiniPlayerView()
                .animation(KohakuMotion.medium, value: audio.currentStory?.id)
        }
        .onChange(of: taps.pendingDeepLink) { _, newValue in
            if newValue == .weeklyRotation {
                selection = .discover
            }
        }
    }
}

#Preview {
    RootTabView()
        .environment(StoryRepository())
        .environment(SubscriptionManager())
        .environment(NotificationManager())
        .environment(NotificationTapCoordinator())
        .environment(AudioPlayerService())
}
