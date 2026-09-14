//
//  SubscriptionView.swift
//  Kohaku
//
//  Paywall — StoreKit 2 driven. Monochrome discipline (no amber).
//  Hierarchy through weight and scale, not color.
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(SubscriptionManager.self) private var subs
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProductID: String = SubscriptionManager.yearlyProductID
    @State private var isPurchasing: Bool = false
    @State private var purchaseError: String? = nil

    var body: some View {
        ZStack {
            Color.kohakuVoid.ignoresSafeArea()

            ScrollView {
                VStack(spacing: KohakuSpacing.xl) {
                    // Header
                    VStack(spacing: KohakuSpacing.sm) {
                        KohakuGlyph()
                            .frame(width: 100, height: 100)
                            .padding(.top, KohakuSpacing.lg)

                        KohakuText("Continue with Kohaku", style: .displayLarge, alignment: .center)
                            .padding(.top, KohakuSpacing.md)

                        KohakuText(
                            "A new tale each week. All specimens, preserved.",
                            style: .quote,
                            color: .kohakuPallor,
                            alignment: .center
                        )
                    }
                    .padding(.horizontal, KohakuSpacing.lg)

                    OrnamentDivider(style: .full)
                        .frame(height: 20)
                        .padding(.horizontal, KohakuSpacing.xxl)

                    // Benefits
                    VStack(alignment: .leading, spacing: KohakuSpacing.md) {
                        benefit("Access every tale, past and present.")
                        benefit("A new tale published each week.")
                        benefit("Read offline. Read in the dark.")
                        benefit("Support an independent library.")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, KohakuSpacing.lg)

                    // Product options
                    if subs.isLoading {
                        ProgressView()
                            .tint(.kohakuBone)
                            .padding(.vertical, KohakuSpacing.xl)
                    } else if subs.products.isEmpty {
                        KohakuText(
                            "Subscription options are not available right now. Please try again later.",
                            style: .bodyMedium,
                            color: .kohakuAsh,
                            alignment: .center
                        )
                        .padding(.horizontal, KohakuSpacing.lg)
                    } else {
                        VStack(spacing: KohakuSpacing.sm) {
                            ForEach(subs.products, id: \.id) { product in
                                productOption(product)
                            }
                        }
                        .padding(.horizontal, KohakuSpacing.lg)
                    }

                    // Error
                    if let error = purchaseError {
                        KohakuText(error, style: .caption, color: .kohakuPallor, alignment: .center)
                            .padding(.horizontal, KohakuSpacing.lg)
                    }

                    // CTA
                    VStack(spacing: KohakuSpacing.sm) {
                        KohakuButton(
                            title: isPurchasing ? "…" : "Continue",
                            style: .primary,
                            action: { Task { await purchase() } },
                            isEnabled: !isPurchasing && !subs.products.isEmpty
                        )

                        KohakuButton.ghost("restore purchases") {
                            Task { await subs.restore() }
                        }

                        KohakuText(
                            "Subscription renews automatically. Cancel anytime in Settings.",
                            style: .caption,
                            color: .kohakuAsh,
                            alignment: .center
                        )
                        .padding(.horizontal, KohakuSpacing.lg)
                        .padding(.top, KohakuSpacing.xs)

                        // Legal links — required by Apple Guideline 3.1.2(a)
                        // for any paywall with auto-renewing subscription.
                        HStack(spacing: KohakuSpacing.sm) {
                            Link(destination: AppLinks.termsOfUse) {
                                KohakuText("Terms of Use", style: .caption, color: .kohakuPallor)
                            }
                            KohakuText("·", style: .caption, color: .kohakuAsh)
                            Link(destination: AppLinks.privacyPolicy) {
                                KohakuText("Privacy Policy", style: .caption, color: .kohakuPallor)
                            }
                        }
                        .padding(.top, KohakuSpacing.xs)
                    }
                    .padding(.horizontal, KohakuSpacing.lg)
                    .padding(.bottom, KohakuSpacing.xxl)
                }
            }

            // Close (top-right)
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
        .task {
            if subs.products.isEmpty {
                await subs.loadProducts()
            }
        }
    }

    @ViewBuilder
    private func benefit(_ text: String) -> some View {
        HStack(alignment: .top, spacing: KohakuSpacing.sm) {
            KohakuText("—", style: .bodyLarge, color: .kohakuAsh)
            KohakuText(text, style: .bodyMedium)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func productOption(_ product: Product) -> some View {
        let selected = product.id == selectedProductID
        Button {
            selectedProductID = product.id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    KohakuText(
                        product.id == SubscriptionManager.yearlyProductID ? "Yearly" : "Monthly",
                        style: .displaySmall
                    )
                    if product.id == SubscriptionManager.yearlyProductID {
                        KohakuText("Save 30%", style: .caption, color: .kohakuAsh)
                    } else {
                        KohakuText(product.description, style: .caption, color: .kohakuAsh)
                    }
                }
                Spacer()
                KohakuText(product.displayPrice, style: .displaySmall, color: .kohakuBone)
            }
            .padding(KohakuSpacing.md)
            .overlay(
                RoundedRectangle(cornerRadius: KohakuRadius.md)
                    .stroke(
                        selected ? Color.kohakuBone : Color.kohakuAsh.opacity(0.4),
                        lineWidth: selected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func purchase() async {
        guard let product = subs.products.first(where: { $0.id == selectedProductID }) else {
            return
        }
        purchaseError = nil
        isPurchasing = true
        defer { isPurchasing = false }

        let ok = await subs.purchase(product)
        if ok {
            dismiss()
        } else {
            purchaseError = subs.lastError
        }
    }
}

#Preview {
    SubscriptionView()
        .environment(SubscriptionManager())
}
