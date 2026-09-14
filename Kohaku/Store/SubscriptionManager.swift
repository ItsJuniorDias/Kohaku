//
//  SubscriptionManager.swift
//  Kohaku
//
//  StoreKit 2 subscription management.
//
//  How to test:
//  1. In Xcode: Product → Scheme → Edit Scheme → Run → Options
//     → StoreKit Configuration: Kohaku.storekit
//  2. Products are defined in Configuration.storekit at project root.
//  3. On device, sandbox testers can be configured in App Store Connect.
//

import Foundation
import StoreKit

@Observable
final class SubscriptionManager {

    // MARK: - Product IDs
    // Must match Configuration.storekit and App Store Connect

    static let monthlyProductID = "com.alexandrejunior.kohaku.subscription.monthly"
    static let yearlyProductID = "com.alexandrejunior.kohaku.subscription.yearly"

    // MARK: - State

    private(set) var products: [Product] = []
    private(set) var purchasedSubscriptions: [Product] = []
    private(set) var subscriptionStatus: SubscriptionStatus = .unknown
    private(set) var isLoading: Bool = false
    private(set) var lastError: String? = nil

    enum SubscriptionStatus {
        case unknown          // Not yet checked
        case notSubscribed
        case active(expiresAt: Date?)
        case expired

        var isActive: Bool {
            if case .active = self { return true }
            return false
        }
    }

    // MARK: - Transaction listener

    private var updateListenerTask: Task<Void, Error>?

    init() {
        updateListenerTask = listenForTransactions()

        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load products

    @MainActor
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let ids = [Self.monthlyProductID, Self.yearlyProductID]
            let loaded = try await Product.products(for: ids)
            // Preserve order: yearly first (recommended plan)
            self.products = loaded.sorted { a, _ in
                a.id == Self.yearlyProductID
            }
        } catch {
            self.lastError = "Failed to load products: \(error.localizedDescription)"
        }
    }

    var monthlyProduct: Product? {
        products.first(where: { $0.id == Self.monthlyProductID })
    }

    var yearlyProduct: Product? {
        products.first(where: { $0.id == Self.yearlyProductID })
    }

    // MARK: - Purchase

    @MainActor
    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateSubscriptionStatus()
                await transaction.finish()
                return true

            case .userCancelled:
                return false

            case .pending:
                self.lastError = "Purchase pending approval."
                return false

            @unknown default:
                return false
            }
        } catch {
            self.lastError = "Purchase failed: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Restore

    @MainActor
    func restore() async {
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            self.lastError = "Restore failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Status check

    @MainActor
    func updateSubscriptionStatus() async {
        var activeSubs: [Product] = []
        var latestExpiration: Date? = nil

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            // Only consider our subscription IDs
            guard transaction.productID == Self.monthlyProductID ||
                    transaction.productID == Self.yearlyProductID else { continue }

            // Skip revoked
            if transaction.revocationDate != nil { continue }

            if let product = products.first(where: { $0.id == transaction.productID }) {
                activeSubs.append(product)
            }

            if let exp = transaction.expirationDate {
                if latestExpiration == nil || exp > latestExpiration! {
                    latestExpiration = exp
                }
            }
        }

        self.purchasedSubscriptions = activeSubs

        if activeSubs.isEmpty {
            self.subscriptionStatus = .notSubscribed
        } else {
            self.subscriptionStatus = .active(expiresAt: latestExpiration)
        }
    }

    // MARK: - Transaction listener (for external purchases, renewals)

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    // Verification failed — ignore, will retry on next launch
                }
            }
        }
    }

    // MARK: - Verification

    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.notEntitled
        case .verified(let value):
            return value
        }
    }
}
