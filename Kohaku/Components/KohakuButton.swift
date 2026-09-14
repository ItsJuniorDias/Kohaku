//
//  KohakuButton.swift
//  Kohaku
//
//  Design system — Buttons (v0.2) §10
//  Three variants: primary (bone fill), secondary (bone outline), ghost (text-only).
//  No amber variant in v0.2 — monochrome discipline.
//

import SwiftUI

struct KohakuButton: View {
    enum Style {
        case primary       // Bone fill, void text — the single high-emphasis action per screen
        case secondary     // Bone border, transparent fill — medium emphasis
        case ghost         // Text-only with hairline underline — tertiary
    }

    let title: String
    let style: Style
    let action: () -> Void
    var isEnabled: Bool = true

    // Convenience constructors matching the DS shorthand:
    // KohakuButton.primary("Read", action: ...)
    static func primary(_ title: String, action: @escaping () -> Void) -> KohakuButton {
        KohakuButton(title: title, style: .primary, action: action)
    }
    static func secondary(_ title: String, action: @escaping () -> Void) -> KohakuButton {
        KohakuButton(title: title, style: .secondary, action: action)
    }
    static func ghost(_ title: String, action: @escaping () -> Void) -> KohakuButton {
        KohakuButton(title: title, style: .ghost, action: action)
    }

    var body: some View {
        Button(action: action) {
            content
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.4)
    }

    @ViewBuilder
    private var content: some View {
        switch style {
        case .primary:
            KohakuText(title.uppercased(), style: .displaySmall, color: .kohakuVoid)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KohakuSpacing.md)
                .background(Color.kohakuBone)
                .clipShape(RoundedRectangle(cornerRadius: KohakuRadius.md))

        case .secondary:
            KohakuText(title.uppercased(), style: .displaySmall, color: .kohakuBone)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KohakuSpacing.md)
                .overlay(
                    RoundedRectangle(cornerRadius: KohakuRadius.md)
                        .stroke(Color.kohakuBone, lineWidth: 0.8)
                )

        case .ghost:
            VStack(spacing: 2) {
                KohakuText(title.lowercased(), style: .bodyMedium, color: .kohakuBone)
                Rectangle()
                    .fill(Color.kohakuBone)
                    .frame(height: 0.3)
                    .padding(.horizontal, KohakuSpacing.xxs)
            }
            .fixedSize(horizontal: true, vertical: false)
            .padding(.vertical, KohakuSpacing.xs)
        }
    }
}

#Preview {
    ZStack {
        Color.kohakuVoid.ignoresSafeArea()
        VStack(spacing: KohakuSpacing.lg) {
            KohakuButton.primary("Read the tale", action: {})
            KohakuButton.secondary("Add to library", action: {})
            KohakuButton.ghost("Not now", action: {})
        }
        .padding(KohakuSpacing.lg)
    }
}
