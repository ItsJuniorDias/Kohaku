//
//  StoryDetailView.swift
//  Kohaku
//
//  Story detail — cover, metadata, excerpt, chapter list, Read CTA.
//

import SwiftUI

struct StoryDetailView: View {
    let story: Story

    @Environment(StoryRepository.self) private var repo
    @Environment(SubscriptionManager.self) private var subs
    @Environment(\.dismiss) private var dismiss

    @State private var readerPresented: Bool = false
    @State private var subscriptionPresented: Bool = false

    private var canRead: Bool {
        // Free if: not premium at all, OR featured this week, OR user has
        // an active subscription. The weekly-rotation check lives in the
        // repository — do NOT duplicate the rotation math here.
        repo.isFreeToRead(story) || subs.subscriptionStatus.isActive
    }

    var body: some View {
        ZStack {
            Color.kohakuVoid.ignoresSafeArea()

            ScrollView {
                VStack(spacing: KohakuSpacing.lg) {
                    // Hero cover — animated video if available, else the
                    // static PNG. The video cross-fades in over the PNG
                    // once its first frame is ready.
                    Group {
                        if let videoURL = story.coverVideoURL {
                            LoopingVideoView(
                                videoURL: videoURL,
                                placeholderImageName: story.coverAssetName
                            )
                        } else {
                            Image(story.coverAssetName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: KohakuRadius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: KohakuRadius.lg)
                            .stroke(Color.kohakuAsh.opacity(0.4), lineWidth: 0.3)
                    )
                    .padding(.horizontal, KohakuSpacing.lg)
                    .padding(.top, KohakuSpacing.md)

                    // Metadata
                    VStack(spacing: KohakuSpacing.sm) {
                        KohakuText(
                            "\(story.formattedNumber) · \(story.category.displayName)",
                            style: .label,
                            color: .kohakuAsh,
                            alignment: .center
                        )
                        KohakuText(story.title, style: .displayHero, alignment: .center)
                        KohakuText(
                            "\(story.chapters.count) chapters · \(story.readingTimeLabel.replacingOccurrences(of: "—", with: "").trimmingCharacters(in: .whitespaces))",
                            style: .caption,
                            color: .kohakuAsh,
                            alignment: .center
                        )
                        .padding(.top, KohakuSpacing.xs)
                    }
                    .padding(.horizontal, KohakuSpacing.lg)

                    OrnamentDivider(style: .full)
                        .frame(height: 20)
                        .padding(.horizontal, KohakuSpacing.xxl)

                    // Excerpt
                    KohakuText(story.excerpt, style: .quote, color: .kohakuBone, alignment: .leading)
                        .padding(.horizontal, KohakuSpacing.lg)

                    // Chapter list preview
                    VStack(alignment: .leading, spacing: KohakuSpacing.sm) {
                        KohakuText("Chapters", style: .label, color: .kohakuAsh)

                        ForEach(story.chapters) { chapter in
                            HStack(alignment: .center, spacing: KohakuSpacing.md) {
                                KohakuText(chapter.romanNumeral, style: .displaySmall, color: .kohakuAsh)
                                    .frame(width: 30, alignment: .leading)
                                VStack(alignment: .leading, spacing: 2) {
                                    KohakuText(chapter.title, style: .displaySmall)
                                    KohakuText("\(chapter.readingTimeMinutes) min", style: .caption, color: .kohakuAsh)
                                }
                                Spacer()
                            }
                            .padding(.vertical, KohakuSpacing.xs)

                            if chapter.number < story.chapters.count {
                                Rectangle()
                                    .fill(Color.kohakuAsh.opacity(0.25))
                                    .frame(height: 0.3)
                            }
                        }
                    }
                    .padding(KohakuSpacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Content warnings
                    if !story.contentWarnings.isEmpty {
                        VStack(alignment: .leading, spacing: KohakuSpacing.xs) {
                            KohakuText("Contains", style: .label, color: .kohakuAsh)
                            ForEach(story.contentWarnings, id: \.self) { warning in
                                KohakuText("— \(warning)", style: .bodySmall, color: .kohakuPallor)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, KohakuSpacing.lg)
                    }

                    // Actions
                    VStack(spacing: KohakuSpacing.md) {
                        if canRead {
                            KohakuButton.primary("Read the tale") {
                                withAnimation(KohakuMotion.dread) {
                                    readerPresented = true
                                }
                            }
                        } else {
                            KohakuButton.primary("Continue with Kohaku") {
                                subscriptionPresented = true
                            }
                            KohakuText(
                                "This tale is part of the premium library.",
                                style: .caption, color: .kohakuAsh, alignment: .center
                            )
                        }

                        if repo.isInLibrary(story) {
                            KohakuButton.secondary("Remove from library") {
                                repo.removeFromLibrary(story)
                            }
                        } else {
                            KohakuButton.secondary("Add to library") {
                                repo.addToLibrary(story)
                            }
                        }
                    }
                    .padding(.horizontal, KohakuSpacing.lg)
                    .padding(.top, KohakuSpacing.md)

                    Spacer(minLength: KohakuSpacing.xxl)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.kohakuVoid, for: .navigationBar)
        .fullScreenCover(isPresented: $readerPresented) {
            ReaderView(story: story)
        }
        .sheet(isPresented: $subscriptionPresented) {
            SubscriptionView()
        }
    }
}

#Preview {
    NavigationStack {
        StoryDetailView(story: MockStories.all[0])
    }
    .environment(StoryRepository())
    .environment(SubscriptionManager())
}
