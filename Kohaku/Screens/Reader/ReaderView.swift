//
//  ReaderView.swift
//  Kohaku
//
//  The reader — now multi-chapter aware.
//  - Progress bar at top (bone) reflects current chapter
//  - Chapter title appears at top of each chapter
//  - Eye ornament between chapters, spiral at story's end
//  - Tap to reveal chrome (close, chapter, aa settings); fade after 3s
//

import SwiftUI

struct ReaderView: View {
    let story: Story

    @Environment(StoryRepository.self) private var repo
    @Environment(AudioPlayerService.self) private var audio
    @Environment(\.dismiss) private var dismiss

    @State private var currentChapterIndex: Int = 0

    @State private var scrollOffset: CGFloat = 0
    @State private var contentHeight: CGFloat = 1
    @State private var viewportHeight: CGFloat = 1

    @State private var controlsVisible: Bool = false
    @State private var controlsFadeTask: Task<Void, Never>? = nil

    @State private var fontSizeDelta: CGFloat = 0
    @State private var settingsPresented: Bool = false
    @State private var chapterSheetPresented: Bool = false

    private var currentChapter: Chapter {
        story.chapters[currentChapterIndex]
    }

    private var progress: Double {
        let range = max(1, contentHeight - viewportHeight)
        return min(1, max(0, Double(scrollOffset / range)))
    }

    private var isLastChapter: Bool {
        currentChapterIndex == story.chapters.count - 1
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.kohakuVoid.ignoresSafeArea()

            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: KohakuSpacing.lg) {
                        // Anchor for scroll-to-top when chapter changes.
                        Color.clear
                            .frame(height: 0)
                            .id("chapter-top")

                        // Story title (once, at the very top of chapter 1 only)
                        if currentChapterIndex == 0 {
                            VStack(alignment: .leading, spacing: KohakuSpacing.sm) {
                                KohakuText(
                                    "\(story.formattedNumber) · \(story.category.displayName)",
                                    style: .label,
                                    color: .kohakuAsh
                                )
                                KohakuText(story.title, style: .displayHero)
                            }
                            .padding(.top, KohakuSpacing.xxl)
                        }

                    // Chapter opener
                    VStack(alignment: .center, spacing: KohakuSpacing.md) {
                        if currentChapterIndex > 0 {
                            EyeShape()
                                .frame(width: 100, height: 60)
                                .padding(.top, KohakuSpacing.xl)
                        }
                        KohakuText(
                            "Chapter \(currentChapter.romanNumeral)",
                            style: .label,
                            color: .kohakuAsh,
                            alignment: .center
                        )
                        KohakuText(
                            currentChapter.title,
                            style: .displayLarge,
                            alignment: .center
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, currentChapterIndex == 0 ? KohakuSpacing.lg : 0)

                    OrnamentDivider(style: .minimal)
                        .padding(.vertical, KohakuSpacing.md)

                    // Body prose — split into paragraphs
                    ForEach(paragraphs, id: \.self) { paragraph in
                        Text(paragraph)
                            .font(KohakuFontFamily.body(size: 20 + fontSizeDelta))
                            .foregroundStyle(Color.kohakuBone)
                            .lineSpacing(12)
                            .multilineTextAlignment(.leading)
                            .scrollTransition(.animated(KohakuMotion.medium)) { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1 : 0.15)
                                    .blur(radius: phase.isIdentity ? 0 : 2)
                                    .offset(y: phase == .topLeading ? -8 : (phase == .bottomTrailing ? 20 : 0))
                            }
                    }

                    // End-of-chapter / end-of-story ornaments
                    if isLastChapter {
                        VStack(spacing: KohakuSpacing.lg) {
                            SpiralShape(turns: 6)
                                .stroke(Color.kohakuBone, style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                                .frame(width: 60, height: 60)
                            KohakuText("The tale is complete.", style: .caption, color: .kohakuAsh, alignment: .center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, KohakuSpacing.xxl)
                        .padding(.bottom, KohakuSpacing.xxxl)
                    } else {
                        VStack(spacing: KohakuSpacing.lg) {
                            OrnamentDivider(style: .full)
                                .frame(height: 20)
                                .padding(.horizontal, KohakuSpacing.xl)

                            KohakuButton.secondary("Next chapter") {
                                advanceChapter()
                            }
                            .padding(.horizontal, KohakuSpacing.xl)
                        }
                        .padding(.top, KohakuSpacing.xxl)
                        .padding(.bottom, KohakuSpacing.xxxl)
                    }
                }
                .padding(.horizontal, KohakuSpacing.lg)
                .frame(maxWidth: readerMaxWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: ContentHeightKey.self, value: geo.size.height)
                            .preference(key: ScrollOffsetKey.self, value: -geo.frame(in: .named("reader")).minY)
                    }
                )
            }
            .coordinateSpace(name: "reader")
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: ViewportHeightKey.self, value: geo.size.height)
                }
            )
            .onPreferenceChange(ContentHeightKey.self) { contentHeight = $0 }
            .onPreferenceChange(ScrollOffsetKey.self) { scrollOffset = $0 }
            .onPreferenceChange(ViewportHeightKey.self) { viewportHeight = $0 }
            .scrollIndicators(.hidden)
            .onTapGesture {
                revealControls()
            }
            .onChange(of: currentChapterIndex) { _, _ in
                // When chapter changes, scroll to the top of the new chapter.
                withAnimation(KohakuMotion.dread) {
                    scrollProxy.scrollTo("chapter-top", anchor: .top)
                }
                scrollOffset = 0
            }
            } // end ScrollViewReader

            // Progress bar
            GeometryReader { geo in
                Path { p in
                    p.move(to: .zero)
                    p.addLine(to: CGPoint(x: geo.size.width * CGFloat(progress), y: 0))
                }
                .stroke(Color.kohakuBone, lineWidth: 1.5)
                .animation(KohakuMotion.fast, value: progress)
            }
            .frame(height: 1.5)

            // Chrome
            if controlsVisible {
                VStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            KohakuText("close", style: .bodyMedium, color: .kohakuBone)
                        }
                        Spacer()
                        Button(action: { chapterSheetPresented = true }) {
                            KohakuText(
                                "\(currentChapter.romanNumeral) / \(story.chapters.count)",
                                style: .label,
                                color: .kohakuBone
                            )
                        }
                        Spacer()
                        // Listen button — only shown if audio is bundled for
                        // this story. Tap toggles play/pause on the CURRENT
                        // chapter; if a different chapter/story is playing,
                        // it starts this one from the top.
                        if story.hasAudio {
                            Button(action: toggleListenCurrentChapter) {
                                KohakuText(
                                    listenButtonLabel,
                                    style: .bodyMedium,
                                    color: .kohakuBone
                                )
                            }
                            Spacer()
                        }
                        Button(action: { settingsPresented = true }) {
                            KohakuText("aa", style: .displaySmall, color: .kohakuBone)
                        }
                    }
                    .padding(.horizontal, KohakuSpacing.lg)
                    .padding(.top, KohakuSpacing.lg)
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .statusBarHidden(!controlsVisible)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $settingsPresented) {
            ReaderSettingsView(fontSizeDelta: $fontSizeDelta)
                .presentationDetents([.medium])
                .presentationBackground(Color.kohakuInk)
        }
        .sheet(isPresented: $chapterSheetPresented) {
            ChapterListView(
                story: story,
                currentIndex: $currentChapterIndex
            )
            .presentationDetents([.medium, .large])
            .presentationBackground(Color.kohakuInk)
        }
        .onChange(of: progress) { _, newValue in
            repo.setChapterProgress(newValue, story: story, chapter: currentChapter)
        }
        .onAppear {
            revealControls()
        }
    }

    private var paragraphs: [String] {
        currentChapter.body
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var readerMaxWidth: CGFloat {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad ? KohakuSpacing.iPadMaxWidth : .infinity
        #else
        .infinity
        #endif
    }

    private func advanceChapter() {
        guard currentChapterIndex < story.chapters.count - 1 else { return }
        withAnimation(KohakuMotion.dread) {
            currentChapterIndex += 1
        }
    }

    /// Label shown on the chrome-bar Listen button.
    /// "listen" when nothing/other is playing, "playing" when this exact
    /// chapter is loaded and playing, "paused" when this exact chapter is
    /// loaded but paused.
    private var listenButtonLabel: String {
        if audio.currentStory?.id == story.id
            && audio.currentChapter?.id == currentChapter.id {
            return audio.isPlaying ? "playing" : "paused"
        }
        return "listen"
    }

    /// Tap on the Listen button:
    /// - If this chapter is loaded → toggle play/pause
    /// - Otherwise → start from this chapter's beginning
    private func toggleListenCurrentChapter() {
        if audio.currentStory?.id == story.id
            && audio.currentChapter?.id == currentChapter.id {
            audio.togglePlayPause()
        } else {
            audio.play(story: story, chapter: currentChapter)
        }
    }

    private func revealControls() {
        withAnimation(KohakuMotion.medium) {
            controlsVisible = true
        }
        controlsFadeTask?.cancel()
        controlsFadeTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if !Task.isCancelled {
                await MainActor.run {
                    withAnimation(KohakuMotion.medium) {
                        controlsVisible = false
                    }
                }
            }
        }
    }
}

// MARK: - Chapter list sheet

struct ChapterListView: View {
    let story: Story
    @Binding var currentIndex: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.kohakuInk.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: KohakuSpacing.md) {
                    KohakuText("Chapters", style: .label, color: .kohakuAsh)

                    OrnamentDivider(style: .minimal)
                        .padding(.vertical, KohakuSpacing.xs)

                    ForEach(Array(story.chapters.enumerated()), id: \.offset) { index, chapter in
                        Button {
                            currentIndex = index
                            dismiss()
                        } label: {
                            HStack(alignment: .top, spacing: KohakuSpacing.md) {
                                KohakuText(
                                    chapter.romanNumeral,
                                    style: .displaySmall,
                                    color: index == currentIndex ? .kohakuBone : .kohakuAsh
                                )
                                .frame(width: 30, alignment: .leading)

                                VStack(alignment: .leading, spacing: 2) {
                                    KohakuText(
                                        chapter.title,
                                        style: .displaySmall,
                                        color: index == currentIndex ? .kohakuBone : .kohakuPallor
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
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preference keys

private struct ContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 1
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

private struct ScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

private struct ViewportHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 1
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
