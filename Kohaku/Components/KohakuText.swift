//
//  KohakuText.swift
//  Kohaku
//
//  Design system — Text component (v0.2) §09
//  NEVER use raw Text(...) in this codebase. Always KohakuText(...).
//

import SwiftUI

struct KohakuText: View {
    let text: String
    let style: KohakuTextStyle
    var color: Color? = nil
    var alignment: TextAlignment = .leading

    init(
        _ text: String,
        style: KohakuTextStyle,
        color: Color? = nil,
        alignment: TextAlignment = .leading
    ) {
        self.text = text
        self.style = style
        self.color = color
        self.alignment = alignment
    }

    var body: some View {
        Text(displayText)
            .font(style.font)
            .fontWeight(style.weight)
            .foregroundStyle(color ?? style.defaultColor)
            .tracking(style.tracking)
            .lineSpacing(style.lineSpacingAdjustment)
            .multilineTextAlignment(alignment)
    }

    private var displayText: String {
        style.uppercased ? text.uppercased() : text
    }
}

#Preview {
    ZStack {
        Color.kohakuVoid.ignoresSafeArea()
        ScrollView {
            VStack(alignment: .leading, spacing: KohakuSpacing.md) {
                KohakuText("The Coil", style: .displayHero)
                KohakuText("Chapter One", style: .displayLarge)
                KohakuText("Kohaku", style: .displayMedium)
                KohakuText("Recently added", style: .displaySmall)
                KohakuText("She noticed the spiral on the seventh morning.", style: .bodyLarge)
                KohakuText("A weekly journal of weird horror short fiction.", style: .bodyMedium)
                KohakuText("This story contains body horror.", style: .bodySmall)
                KohakuText("The amber remembers what the earth forgets.", style: .quote)
                KohakuText("Illustration by the author, 2026.", style: .caption)
                KohakuText("Nº 03 · Body Horror", style: .label)
            }
            .padding(KohakuSpacing.lg)
        }
    }
}
