//
//  MiniPlayerView.swift
//  Kohaku
//
//  Persistent audio bar that appears above the tab bar whenever
//  something is loaded in the AudioPlayerService — regardless of
//  which screen the user is on.
//
//  Tap → opens FullPlayerView as a sheet.
//  Play/pause button on the right for one-tap control.
//  A hair-thin progress line at the bottom shows how far into the
//  chapter the user is.
//

import SwiftUI

struct MiniPlayerView: View {
    @Environment(AudioPlayerService.self) private var audio
    @State private var fullPlayerPresented: Bool = false

    var body: some View {
        // Only render when audio is loaded. When the audio session ends
        // (stop()), currentStory becomes nil and this collapses cleanly.
        if let story = audio.currentStory, let chapter = audio.currentChapter {
            Button {
                fullPlayerPresented = true
            } label: {
                VStack(spacing: 0) {
                    HStack(spacing: KohakuSpacing.md) {
                        // Cover thumbnail
                        Image(story.coverAssetName)
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: KohakuRadius.sm))

                        // Title + chapter
                        VStack(alignment: .leading, spacing: 2) {
                            KohakuText(story.title, style: .bodyMedium)
                                .lineLimit(1)
                            KohakuText(
                                "Ch. \(chapter.number). \(chapter.title)",
                                style: .caption,
                                color: .kohakuAsh
                            )
                            .lineLimit(1)
                        }

                        Spacer(minLength: KohakuSpacing.sm)

                        // Play / pause
                        Button {
                            audio.togglePlayPause()
                        } label: {
                            KohakuText(
                                audio.isPlaying ? "pause" : "play",
                                style: .bodyMedium,
                                color: .kohakuBone
                            )
                            .padding(.horizontal, KohakuSpacing.sm)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, KohakuSpacing.md)
                    .padding(.vertical, KohakuSpacing.sm)

                    // Hair-thin progress line
                    GeometryReader { geo in
                        Path { p in
                            p.move(to: .zero)
                            let x = geo.size.width * CGFloat(progress)
                            p.addLine(to: CGPoint(x: x, y: 0))
                        }
                        .stroke(Color.kohakuBone.opacity(0.6), lineWidth: 1)
                        .animation(KohakuMotion.fast, value: progress)
                    }
                    .frame(height: 1)
                }
                .background(Color.kohakuInk)
                .overlay(
                    Rectangle()
                        .fill(Color.kohakuAsh.opacity(0.3))
                        .frame(height: 0.3),
                    alignment: .top
                )
            }
            .buttonStyle(.plain)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .sheet(isPresented: $fullPlayerPresented) {
                FullPlayerView()
                    .presentationDetents([.large])
                    .presentationBackground(Color.kohakuVoid)
            }
        }
    }

    private var progress: Double {
        guard audio.duration > 0 else { return 0 }
        return min(1, max(0, audio.currentTime / audio.duration))
    }
}
