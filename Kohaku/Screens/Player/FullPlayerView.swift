//
//  FullPlayerView.swift
//  Kohaku
//
//  Full audio player screen — presented as a sheet from the mini
//  player. Everything the user might want: scrubber, +15/-15,
//  chapter navigation, speed selector, chapter list.
//
//  Design notes:
//  • The scrubber uses SwiftUI's `Slider` bound to a local State that
//    only writes back to the player on release (via onEditingChanged).
//    This avoids re-seeking on every drag frame — heavy and jittery.
//  • Speed cycles through the discrete AudioPlayerService.availableRates.
//  • No auto-dismiss on chapter end; the user stays in the full player
//    while auto-advance loads the next chapter's audio.
//

import SwiftUI

struct FullPlayerView: View {
    @Environment(AudioPlayerService.self) private var audio
    @Environment(\.dismiss) private var dismiss

    /// Scrubber's local state. Kept in sync with `audio.currentTime`
    /// unless the user is actively dragging.
    @State private var scrubValue: Double = 0
    @State private var isScrubbing: Bool = false
    @State private var chapterListPresented: Bool = false

    var body: some View {
        ZStack {
            Color.kohakuVoid.ignoresSafeArea()

            if let story = audio.currentStory, let chapter = audio.currentChapter {
                VStack(spacing: 0) {
                    // Header — close bar
                    HStack {
                        Button(action: { dismiss() }) {
                            KohakuText("close", style: .bodyMedium, color: .kohakuBone)
                        }
                        Spacer()
                        Button(action: { chapterListPresented = true }) {
                            KohakuText(
                                "\(chapter.romanNumeral) / \(story.chapters.count)",
                                style: .label,
                                color: .kohakuBone
                            )
                        }
                        Spacer()
                        Button(action: audio.stop) {
                            KohakuText("stop", style: .bodyMedium, color: .kohakuAsh)
                        }
                    }
                    .padding(.horizontal, KohakuSpacing.lg)
                    .padding(.top, KohakuSpacing.lg)

                    Spacer(minLength: KohakuSpacing.xl)

                    // Cover
                    Image(story.coverAssetName)
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: 280)
                        .clipShape(RoundedRectangle(cornerRadius: KohakuRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: KohakuRadius.md)
                                .stroke(Color.kohakuAsh.opacity(0.4), lineWidth: 0.3)
                        )
                        .padding(.horizontal, KohakuSpacing.xl)

                    Spacer(minLength: KohakuSpacing.xl)

                    // Titles
                    VStack(spacing: KohakuSpacing.xs) {
                        KohakuText(story.title, style: .displayMedium, alignment: .center)
                            .lineLimit(2)
                        KohakuText(
                            "Chapter \(chapter.romanNumeral). \(chapter.title)",
                            style: .bodyMedium,
                            color: .kohakuAsh,
                            alignment: .center
                        )
                        .lineLimit(2)
                    }
                    .padding(.horizontal, KohakuSpacing.lg)

                    Spacer(minLength: KohakuSpacing.lg)

                    // Scrubber + timestamps
                    VStack(spacing: KohakuSpacing.xs) {
                        Slider(
                            value: $scrubValue,
                            in: 0...max(audio.duration, 0.01),
                            onEditingChanged: { editing in
                                isScrubbing = editing
                                if !editing {
                                    audio.seek(to: scrubValue)
                                }
                            }
                        )
                        .tint(.kohakuBone)

                        HStack {
                            KohakuText(
                                formatTime(scrubValue),
                                style: .caption,
                                color: .kohakuAsh
                            )
                            Spacer()
                            KohakuText(
                                "-\(formatTime(audio.duration - scrubValue))",
                                style: .caption,
                                color: .kohakuAsh
                            )
                        }
                    }
                    .padding(.horizontal, KohakuSpacing.lg)

                    Spacer(minLength: KohakuSpacing.lg)

                    // Transport controls
                    HStack(spacing: KohakuSpacing.xl) {
                        Button(action: { audio.playPreviousChapter() }) {
                            KohakuText("prev", style: .bodyMedium, color: prevColor)
                        }
                        .disabled(!hasPrevious)

                        Button(action: { audio.togglePlayPause() }) {
                            KohakuText(
                                audio.isPlaying ? "pause" : "play",
                                style: .displayMedium,
                                color: .kohakuBone
                            )
                            .padding(.horizontal, KohakuSpacing.md)
                        }

                        Button(action: { audio.playNextChapter() }) {
                            KohakuText("next", style: .bodyMedium, color: nextColor)
                        }
                        .disabled(!hasNext)
                    }

                    Spacer(minLength: KohakuSpacing.xl)
                }
                .buttonStyle(.plain)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            scrubValue = audio.currentTime
        }
        .onChange(of: audio.currentTime) { _, newValue in
            // Follow the player unless the user is dragging.
            if !isScrubbing {
                scrubValue = newValue
            }
        }
        .sheet(isPresented: $chapterListPresented) {
            AudioChapterListView()
                .presentationDetents([.medium, .large])
                .presentationBackground(Color.kohakuInk)
        }
    }

    // MARK: - Helpers

    private var hasPrevious: Bool {
        guard let story = audio.currentStory, let ch = audio.currentChapter,
              let idx = story.chapters.firstIndex(where: { $0.id == ch.id })
        else { return false }
        return idx > 0
    }

    private var hasNext: Bool {
        guard let story = audio.currentStory, let ch = audio.currentChapter,
              let idx = story.chapters.firstIndex(where: { $0.id == ch.id })
        else { return false }
        return idx < story.chapters.count - 1
    }

    private var prevColor: Color { hasPrevious ? .kohakuBone : .kohakuAsh.opacity(0.4) }
    private var nextColor: Color { hasNext ? .kohakuBone : .kohakuAsh.opacity(0.4) }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Chapter list for the audio player

/// Same shape as the reader's ChapterListView but wired to the audio player.
struct AudioChapterListView: View {
    @Environment(AudioPlayerService.self) private var audio
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.kohakuInk.ignoresSafeArea()

            if let story = audio.currentStory {
                ScrollView {
                    VStack(alignment: .leading, spacing: KohakuSpacing.md) {
                        KohakuText("Chapters", style: .label, color: .kohakuAsh)

                        OrnamentDivider(style: .minimal)
                            .padding(.vertical, KohakuSpacing.xs)

                        ForEach(Array(story.chapters.enumerated()), id: \.offset) { index, chapter in
                            Button {
                                audio.play(story: story, chapter: chapter)
                                dismiss()
                            } label: {
                                HStack(alignment: .top, spacing: KohakuSpacing.md) {
                                    KohakuText(
                                        chapter.romanNumeral,
                                        style: .displaySmall,
                                        color: audio.currentChapter?.id == chapter.id ? .kohakuBone : .kohakuAsh
                                    )
                                    .frame(width: 30, alignment: .leading)

                                    VStack(alignment: .leading, spacing: 2) {
                                        KohakuText(
                                            chapter.title,
                                            style: .displaySmall,
                                            color: audio.currentChapter?.id == chapter.id ? .kohakuBone : .kohakuPallor
                                        )
                                        KohakuText(
                                            "\(chapter.readingTimeMinutes) min",
                                            style: .caption,
                                            color: .kohakuAsh
                                        )
                                    }

                                    Spacer()
                                }
                                .padding(.vertical, KohakuSpacing.sm)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if index < story.chapters.count - 1 {
                                Rectangle()
                                    .fill(Color.kohakuAsh.opacity(0.3))
                                    .frame(height: 0.3)
                            }
                        }
                    }
                    .padding(KohakuSpacing.lg)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
