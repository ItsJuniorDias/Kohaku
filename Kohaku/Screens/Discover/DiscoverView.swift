//
//  DiscoverView.swift
//  Kohaku
//
//  Discover — browse all available tales in the catalog.
//

import SwiftUI

struct DiscoverView: View {
    @Environment(StoryRepository.self) private var repo
    @Environment(NotificationTapCoordinator.self) private var taps

    /// Anchor id for scroll-to when the user opens the app via the
    /// weekly-rotation notification.
    private let featuredAnchor = "featured-weekly"

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 220), spacing: KohakuSpacing.md, alignment: .top)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.kohakuVoid.ignoresSafeArea()

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: KohakuSpacing.lg) {
                            // Featured header
                            VStack(alignment: .leading, spacing: KohakuSpacing.xs) {
                                KohakuText("A specimen of horror,", style: .displayLarge)
                                KohakuText("preserved in ink.", style: .displayLarge, color: .kohakuAsh)
                            }
                            .padding(.horizontal, KohakuSpacing.md)
                            .padding(.top, KohakuSpacing.md)
                            .scrollTransition(.animated(KohakuMotion.slow)) { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1 : 0)
                                    .offset(y: phase.isIdentity ? 0 : -30)
                            }

                            OrnamentDivider(style: .full)
                                .frame(height: 20)
                                .padding(.horizontal, KohakuSpacing.lg)

                            // Section: Free this week
                            if let free = repo.weeklyFreeStory {
                                VStack(alignment: .leading, spacing: KohakuSpacing.sm) {
                                    KohakuText("This week's grant", style: .displaySmall)
                                        .padding(.horizontal, KohakuSpacing.md)

                                    NavigationLink(value: free) {
                                        WeeklyFreeCardView(
                                            story: free,
                                            nextRotationDate: repo.nextRotationDate
                                        )
                                        .scrollTransition(.animated(KohakuMotion.medium)) { content, phase in
                                            content
                                                .opacity(phase.isIdentity ? 1 : 0.3)
                                                .scaleEffect(phase.isIdentity ? 1 : 0.94)
                                        }
                                        .padding(.horizontal, KohakuSpacing.md)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .id(featuredAnchor)
                            }

                            // Section: Recently added
                            VStack(alignment: .leading, spacing: KohakuSpacing.sm) {
                                KohakuText("Recently added", style: .displaySmall)
                                    .padding(.horizontal, KohakuSpacing.md)

                                LazyVGrid(columns: columns, spacing: KohakuSpacing.md) {
                                    ForEach(repo.allStories) { story in
                                        NavigationLink(value: story) {
                                            StoryCardView(story: story)
                                                .scrollTransition(.animated(KohakuMotion.medium)) { content, phase in
                                                    content
                                                        .opacity(phase.isIdentity ? 1 : 0.3)
                                                        .scaleEffect(phase.isIdentity ? 1 : 0.92)
                                                        .blur(radius: phase.isIdentity ? 0 : 3)
                                                }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, KohakuSpacing.md)
                            }

                            Spacer(minLength: KohakuSpacing.xl)
                        }
                    }
                    // Consume the deep link — scroll to featured section
                    // and clear the pending flag so a later Discover open
                    // doesn't re-trigger it.
                    .onChange(of: taps.pendingDeepLink) { _, newValue in
                        guard newValue == .weeklyRotation else { return }
                        withAnimation(KohakuMotion.slow) {
                            proxy.scrollTo(featuredAnchor, anchor: .top)
                        }
                        taps.clearPending()
                    }
                    .onAppear {
                        // If the deep link was set BEFORE this view appeared
                        // (e.g. tap arrived while Discover wasn't the active
                        // tab yet), consume it now.
                        if taps.pendingDeepLink == .weeklyRotation {
                            withAnimation(KohakuMotion.slow) {
                                proxy.scrollTo(featuredAnchor, anchor: .top)
                            }
                            taps.clearPending()
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .navigationDestination(for: Story.self) { story in
                StoryDetailView(story: story)
            }
        }
    }
}

#Preview {
    DiscoverView()
        .environment(StoryRepository())
        .environment(SubscriptionManager())
        .environment(NotificationTapCoordinator())
}
