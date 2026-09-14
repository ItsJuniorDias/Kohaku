//
//  LibraryView.swift
//  Kohaku
//
//  Personal library — stories the user has added.
//  Grid of story cards. Empty state if library is empty.
//

import SwiftUI

struct LibraryView: View {
    @Environment(StoryRepository.self) private var repo

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 220), spacing: KohakuSpacing.md, alignment: .top)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.kohakuVoid.ignoresSafeArea()

                if repo.library.isEmpty {
                    VStack(spacing: KohakuSpacing.xl) {
                        header
                        Spacer()
                        EmptyStateView(message: "Nothing here yet.\n\nAdd tales from Discover to keep them near.")
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: KohakuSpacing.lg) {
                            header

                            LazyVGrid(columns: columns, spacing: KohakuSpacing.md) {
                                ForEach(repo.library) { story in
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

                            Spacer(minLength: KohakuSpacing.xl)
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

    private var header: some View {
        VStack(alignment: .leading, spacing: KohakuSpacing.xs) {
            KohakuText("Library", style: .displayLarge)
            KohakuText("Tales you've chosen to keep near.", style: .quote, color: .kohakuAsh)
        }
        .padding(.horizontal, KohakuSpacing.md)
        .padding(.top, KohakuSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    LibraryView()
        .environment(StoryRepository())
}
