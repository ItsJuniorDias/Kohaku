//
//  StoryCardView.swift
//  Kohaku
//
//  The primary discovery unit (DS §11).
//  Cover illustration + title + metadata + author + reading time.
//

import SwiftUI

struct StoryCardView: View {
    let story: Story

    var body: some View {
        KohakuCard {
            VStack(alignment: .center, spacing: KohakuSpacing.xs) {
                // Cover illustration
                Image(story.coverAssetName)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: KohakuRadius.sm))
                    .padding(KohakuSpacing.sm)

                // Title — always reserves 2 lines of height for consistent card alignment
                KohakuText(story.title.uppercased(), style: .displaySmall, alignment: .center)
                    .lineLimit(2, reservesSpace: true)
                    .padding(.horizontal, KohakuSpacing.sm)

                // Metadata line — Nº XX · CATEGORY
                // Reserves 2 lines so cards with short & long categories align in the grid
                KohakuText(
                    "\(story.formattedNumber) · \(story.category.displayName)",
                    style: .label,
                    color: .kohakuAsh,
                    alignment: .center
                )
                .lineLimit(2, reservesSpace: true)
                .padding(.top, 2)

                // Reading time
                KohakuText(story.readingTimeLabel, style: .caption, color: .kohakuAsh, alignment: .center)
                    .padding(.top, 2)
                    .padding(.bottom, KohakuSpacing.md)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.kohakuVoid.ignoresSafeArea()
        StoryCardView(story: MockStories.all[0])
            .frame(width: 220)
            .padding()
    }
}
