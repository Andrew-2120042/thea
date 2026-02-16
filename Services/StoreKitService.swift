import StoreKit
import SwiftUI

@MainActor
class StoreKitService: ObservableObject {
    @Published var products: [Product] = []
    @Published var isPremium = false
    @Published var isLoading = false

    private var updateTask: Task<Void, Never>?

    init() {
        updateTask = Task {
            await loadProducts()
            await checkPurchaseStatus()
            await listenForTransactions()
        }
    }

    deinit {
        updateTask?.cancel()
    }

    // MARK: - Load Products
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: [
                Constants.monthlySubscriptionID,
                Constants.yearlySubscriptionID
            ])
            // Sort: monthly first
            products.sort { $0.price < $1.price }
        } catch {
            print("StoreKitService: Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                await checkPurchaseStatus()
                return true
            case .unverified:
                return false
            }
        case .pending:
            return false
        case .userCancelled:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Restore Purchases
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkPurchaseStatus()
        } catch {
            print("StoreKitService: Restore failed: \(error)")
        }
    }

    // MARK: - Check Purchase Status
    func checkPurchaseStatus() async {
        var hasPremium = false

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == Constants.monthlySubscriptionID ||
                   transaction.productID == Constants.yearlySubscriptionID {
                    if transaction.revocationDate == nil {
                        hasPremium = true
                    }
                }
            }
        }

        isPremium = hasPremium
    }

    // MARK: - Listen for Transaction Updates
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await transaction.finish()
                await checkPurchaseStatus()
            }
        }
    }

    // MARK: - Helpers
    var monthlyProduct: Product? {
        products.first { $0.id == Constants.monthlySubscriptionID }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == Constants.yearlySubscriptionID }
    }
}
