//
//  OnboardingView.swift
//  Kohaku
//
//  3-page onboarding flow using the "Between the panels" imagery.
//  Each image was generated with safe zone in the bottom half —
//  UI (title, description, buttons) is overlaid there.
//

import SwiftUI

struct OnboardingView: View {
    /// Called when the user finishes (or skips) onboarding.
    let onComplete: () -> Void

    @State private var currentPage: Int = 0

    private struct Page {
        let imageAsset: String
        let title: String
        let description: String
    }

    private let pages: [Page] = [
        Page(
            imageAsset: "onboarding-1-closed-eye",
            title: "Something watches.",
            description: "Kohaku is a reader for weird horror short fiction. Each tale is a specimen — preserved, unchanged, waiting."
        ),
        Page(
            imageAsset: "onboarding-2-staircase",
            title: "Every tale is a descent.",
            description: "Read at your own pace. Take the steps slowly. The dark below is patient."
        ),
        Page(
            imageAsset: "onboarding-3-empty-chair",
            title: "Sit and read.",
            description: "A new tale each week. Nothing to distract you. Only the story and the silence."
        )
    ]

    var body: some View {
        ZStack {
            Color.kohakuVoid.ignoresSafeArea()

            // Page image (fills safe area)
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    Image(page.imageAsset)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .ignoresSafeArea()
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(KohakuMotion.slow, value: currentPage)

            // Bottom overlay — title + description + controls
            VStack {
                Spacer()

                VStack(alignment: .leading, spacing: KohakuSpacing.md) {
                    KohakuText(pages[currentPage].title, style: .displayLarge)
                        .transition(.opacity)
                        .id("title-\(currentPage)")

                    KohakuText(pages[currentPage].description, style: .bodyMedium, color: .kohakuPallor)
                        .transition(.opacity)
                        .id("desc-\(currentPage)")

                    // Page indicator (dots — ash)
                    HStack(spacing: KohakuSpacing.xs) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.kohakuBone : Color.kohakuAsh.opacity(0.4))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.vertical, KohakuSpacing.sm)

                    // Controls
                    HStack {
                        if currentPage < pages.count - 1 {
                            KohakuButton.ghost("skip", action: onComplete)
                            Spacer()
                            KohakuButton.primary("Continue", action: advance)
                                .frame(maxWidth: 200)
                        } else {
                            KohakuButton.primary("Enter the library", action: onComplete)
                        }
                    }
                    .padding(.top, KohakuSpacing.xs)
                }
                .padding(.horizontal, KohakuSpacing.lg)
                .padding(.bottom, KohakuSpacing.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    // Gradient fade to void, ensuring text is legible over image
                    LinearGradient(
                        colors: [Color.kohakuVoid.opacity(0), .kohakuVoid.opacity(0.9), .kohakuVoid],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .allowsHitTesting(false)
                )
            }
            .animation(KohakuMotion.medium, value: currentPage)
        }
        .preferredColorScheme(.dark)
    }

    private func advance() {
        withAnimation(KohakuMotion.slow) {
            currentPage = min(currentPage + 1, pages.count - 1)
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
