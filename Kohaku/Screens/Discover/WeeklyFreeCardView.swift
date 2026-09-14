//
//  WeeklyFreeCardView.swift
//  Kohaku
//
//  Featured card on Discover — the story that is free by weekly rotation.
//  Tapping navigates to the story detail. If no rotation is active (empty
//  pool, dev-only edge case), this view is not rendered by the parent.
//
//  Layout: horizontal — square cover on the left, title / meta / countdown
//  on the right. Larger and more prominent than a normal StoryCardView so
//  it clearly reads as a featured slot, not just another item in the grid.
//

import SwiftUI
import Combine

struct WeeklyFreeCardView: View {
    let story: Story
    let nextRotationDate: Date

    // Timer publisher — every 60s is enough for a "Xd Yh" countdown; we
    // don't need per-second resolution unless the user is watching in the
    // last minute, which is fine to be off by a bit.
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    @State private var now: Date = Date()

    var body: some View {
        KohakuCard {
            VStack(alignment: .leading, spacing: 0) {
                // Top banner — "Free this week"
                HStack {
                    KohakuText("Free this week", style: .label, color: .kohakuBone)
                    Spacer(minLength: KohakuSpacing.xs)
                    KohakuText(countdown, style: .label, color: .kohakuAsh)
                }
                .padding(.horizontal, KohakuSpacing.md)
                .padding(.vertical, KohakuSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.kohakuVoid.opacity(0.6))

                // Body — cover + text
                HStack(alignment: .top, spacing: KohakuSpacing.md) {
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
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: KohakuRadius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: KohakuRadius.sm)
                            .stroke(Color.kohakuAsh.opacity(0.4), lineWidth: 0.3)
                    )

                    VStack(alignment: .leading, spacing: KohakuSpacing.xs) {
                        KohakuText(
                            "\(story.formattedNumber) · \(story.category.displayName)",
                            style: .label,
                            color: .kohakuAsh
                        )
                        .lineLimit(1)

                        KohakuText(story.title, style: .displaySmall)
                            .lineLimit(2)

                        KohakuText(story.readingTimeLabel, style: .caption, color: .kohakuAsh)
                            .padding(.top, KohakuSpacing.xxs)

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(KohakuSpacing.md)
            }
        }
        .onReceive(timer) { newValue in
            now = newValue
            // If the deadline just passed, the parent's rotation refresh
            // will kick in on next scene activation. In-view, we just stop
            // the countdown at 0.
        }
    }

    private var countdown: String {
        // "New tale in Xd Yh"
        let remaining = WeeklyRotation.timeRemainingLabel(until: nextRotationDate, now: now)
        return "New tale in \(remaining)"
    }
}

#Preview {
    ZStack {
        Color.kohakuVoid.ignoresSafeArea()
        WeeklyFreeCardView(
            story: MockStories.all[0],
            nextRotationDate: Date().addingTimeInterval(3 * 86400 + 4 * 3600)
        )
        .padding(KohakuSpacing.md)
    }
}
