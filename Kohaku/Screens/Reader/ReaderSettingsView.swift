//
//  ReaderSettingsView.swift
//  Kohaku
//
//  Minimal reader controls sheet. Font size ±4pt, brightness.
//  Per DS: no sharing, no bookmarking here. The reader is for reading.
//

import SwiftUI

struct ReaderSettingsView: View {
    @Binding var fontSizeDelta: CGFloat

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.kohakuInk.ignoresSafeArea()

            VStack(alignment: .leading, spacing: KohakuSpacing.lg) {
                KohakuText("Reader", style: .displayMedium)

                OrnamentDivider(style: .full)
                    .frame(height: 20)

                // Font size adjustment
                VStack(alignment: .leading, spacing: KohakuSpacing.sm) {
                    KohakuText("Text size", style: .label, color: .kohakuAsh)

                    HStack(spacing: KohakuSpacing.md) {
                        Button {
                            withAnimation(KohakuMotion.fast) {
                                fontSizeDelta = max(-4, fontSizeDelta - 1)
                            }
                        } label: {
                            KohakuText("a", style: .bodyLarge, color: .kohakuBone)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    RoundedRectangle(cornerRadius: KohakuRadius.sm)
                                        .stroke(Color.kohakuAsh, lineWidth: 0.5)
                                )
                        }

                        Rectangle()
                            .fill(Color.kohakuAsh)
                            .frame(height: 0.5)

                        Button {
                            withAnimation(KohakuMotion.fast) {
                                fontSizeDelta = min(4, fontSizeDelta + 1)
                            }
                        } label: {
                            KohakuText("A", style: .displayMedium, color: .kohakuBone)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    RoundedRectangle(cornerRadius: KohakuRadius.sm)
                                        .stroke(Color.kohakuAsh, lineWidth: 0.5)
                                )
                        }
                    }
                }

                Spacer()

                KohakuButton.ghost("done", action: { dismiss() })
                    .frame(maxWidth: .infinity)
            }
            .padding(KohakuSpacing.lg)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ReaderSettingsView(fontSizeDelta: .constant(0))
}
