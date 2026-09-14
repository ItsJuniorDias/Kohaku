//
//  AboutView.swift
//  Kohaku
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.kohakuVoid.ignoresSafeArea()

            ScrollView {
                VStack(spacing: KohakuSpacing.lg) {
                    KohakuGlyph()
                        .frame(width: 120, height: 120)
                        .padding(.top, KohakuSpacing.xxl)

                    KohakuText("Kohaku", style: .displayHero, alignment: .center)

                    KohakuText("琥珀", style: .displayLarge, color: .kohakuBone, alignment: .center)

                    OrnamentDivider(style: .full)
                        .frame(height: 20)
                        .padding(.horizontal, KohakuSpacing.xxl)

                    VStack(alignment: .leading, spacing: KohakuSpacing.md) {
                        KohakuText(
                            "Kohaku is the Japanese word for amber — fossilized resin that preserved living things millions of years ago. An insect caught in amber is neither alive nor decayed; it exists in a suspended state, perfectly visible and eternally still.",
                            style: .bodyMedium,
                            color: .kohakuPallor
                        )

                        KohakuText(
                            "This is what the app does. Each short tale is captured, preserved, and offered to you unchanged — a specimen of horror held in transparent stillness.",
                            style: .bodyMedium,
                            color: .kohakuPallor
                        )

                        KohakuText(
                            "Written and designed by Alexandre Dias in Sumaré, Brazil.",
                            style: .quote,
                            color: .kohakuAsh
                        )
                        .padding(.top, KohakuSpacing.md)
                    }
                    .padding(.horizontal, KohakuSpacing.lg)

                    Spacer(minLength: KohakuSpacing.xxl)

                    KohakuText("Version 1.0", style: .caption, color: .kohakuAsh, alignment: .center)
                        .padding(.bottom, KohakuSpacing.lg)
                }
            }

            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        KohakuText("close", style: .bodyMedium, color: .kohakuAsh)
                    }
                    .padding(KohakuSpacing.md)
                }
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    AboutView()
}
