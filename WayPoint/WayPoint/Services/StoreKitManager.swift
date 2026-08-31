//
//  StoreKitManager.swift
//  WayPoint
//
//  Task 4.1: StoreKit 2 Transaction Engine & Entitlement Manager
//

import Foundation
import StoreKit
import Combine

/// Purchase execution result enum for StoreKit 2 transactions
public enum StoreKitPurchaseResult {
    case success(Transaction)
    case userCancelled
    case pending
    case unverified(Error)
}

/// StoreKit 2 Custom Errors
public enum StoreKitError: Error, LocalizedError, Equatable {
    case productNotFound(String)
    case unverifiedTransaction(String)
    case purchaseFailed(String)
    case systemError(String)

    public var errorDescription: String? {
        switch self {
        case .productNotFound(let id):
            return "Product '\(id)' was not found in App Store catalog."
        case .unverifiedTransaction(let reason):
            return "Transaction JWS Signature Verification failed: \(reason)."
        case .purchaseFailed(let reason):
            return "StoreKit purchase failed: \(reason)."
        case .systemError(let reason):
            return "StoreKit system error: \(reason)."
        }
    }
}

/// Metadata descriptor for StoreKit products for catalog verification
public struct ProductDescriptor: Identifiable, Equatable {
    public let id: String
    public let displayName: String
    public let displayPrice: String
    public let price: Decimal
    public let subscriptionGroup: String
    public let recurringPeriod: String
    public let trialPeriod: String?

    public init(id: String, displayName: String, displayPrice: String, price: Decimal, subscriptionGroup: String, recurringPeriod: String, trialPeriod: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.displayPrice = displayPrice
        self.price = price
        self.subscriptionGroup = subscriptionGroup
        self.recurringPeriod = recurringPeriod
        self.trialPeriod = trialPeriod
    }
}

@MainActor
public final class StoreKitManager: ObservableObject {
    public static let shared = StoreKitManager()

    public static let weeklyProductID = "com.waypoint.weekly"
    public static let annualProductID = "com.waypoint.annual"
    public static let subscriptionGroup = "WayPointProGroup"

    public let productIDs: Set<String> = [weeklyProductID, annualProductID]

    @Published public var isProSubscribed: Bool = false
    @Published public var loadedProducts: [Product] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    public var isTestingEnvironment: Bool = false

    private var transactionListenerTask: Task<Void, Never>? = nil

    /// Static Catalog Descriptors for StoreKit 2 Product Catalog Validation
    public static let productCatalog: [ProductDescriptor] = [
        ProductDescriptor(
            id: weeklyProductID,
            displayName: "WayPoint Weekly Pro",
            displayPrice: "$2.99",
            price: 2.99,
            subscriptionGroup: subscriptionGroup,
            recurringPeriod: "P1W",
            trialPeriod: "P3D"
        ),
        ProductDescriptor(
            id: annualProductID,
            displayName: "WayPoint Annual Pro",
            displayPrice: "$29.99",
            price: 29.99,
            subscriptionGroup: subscriptionGroup,
            recurringPeriod: "P1Y",
            trialPeriod: "P7D"
        )
    ]

    private init() {
        self.transactionListenerTask = listenForTransactions()
        Task {
            await checkEntitlements()
        }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    /// Loads products asynchronously via StoreKit 2 Product.products(for:)
    public func loadProducts() async throws -> [Product] {
        isLoading = true
        defer { isLoading = false }
        do {
            let products = try await Product.products(for: productIDs)
            self.loadedProducts = products
            return products
        } catch {
            print("[StoreKitManager] Failed to load StoreKit products: \(error.localizedDescription)")
            throw StoreKitError.systemError(error.localizedDescription)
        }
    }

    /// Purchase product using StoreKit 2 API
    public func purchase(_ product: Product) async throws -> StoreKitPurchaseResult {
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await updateSubscriptionStatus(from: transaction)
                await transaction.finish()
                return .success(transaction)
            case .unverified(let transaction, let verificationError):
                print("[StoreKitManager] Unverified transaction for \(transaction.productID): \(verificationError)")
                isProSubscribed = false
                SubscriptionManager.shared.isProMember = false
                return .unverified(verificationError)
            }
        case .userCancelled:
            return .userCancelled
        case .pending:
            return .pending
        @unknown default:
            return .userCancelled
        }
    }

    /// Restores prior purchases via StoreKit 2 AppStore.sync()
    @discardableResult
    public func restorePurchases() async throws -> Bool {
        isLoading = true
        defer { isLoading = false }
        if isTestingEnvironment {
            return isProSubscribed
        }
        do {
            try await AppStore.sync()
            await checkEntitlements()
            return isProSubscribed
        } catch {
            print("[StoreKitManager] Restore purchases error: \(error.localizedDescription)")
            throw StoreKitError.systemError(error.localizedDescription)
        }
    }

    /// Listens for background transaction updates via StoreKit 2 Transaction.updates
    public func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { break }
                do {
                    let transaction = try await self.checkVerification(result)
                    await self.updateSubscriptionStatus(from: transaction)
                    await transaction.finish()
                } catch {
                    print("[StoreKitManager] Transaction update JWS verification failed: \(error)")
                    await MainActor.run {
                        self.isProSubscribed = false
                        SubscriptionManager.shared.isProMember = false
                    }
                }
            }
        }
    }

    /// Cryptographic JWS Signature Verification helper
    public func checkVerification<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            print("[StoreKitManager] JWS Verification Failed: \(error.localizedDescription)")
            throw StoreKitError.unverifiedTransaction(error.localizedDescription)
        case .verified(let safe):
            return safe
        }
    }

    /// Checks active entitlements from StoreKit 2 Transaction.currentEntitlements
    public func checkEntitlements() async {
        if isTestingEnvironment {
            return
        }
        var hasActivePro = false
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerification(result)
                if transaction.revocationDate == nil {
                    if let expirationDate = transaction.expirationDate, expirationDate < Date() {
                        continue
                    }
                    if productIDs.contains(transaction.productID) {
                        hasActivePro = true
                    }
                }
            } catch {
                print("[StoreKitManager] Unverified current entitlement skipped: \(error)")
            }
        }

        self.isProSubscribed = hasActivePro
        SubscriptionManager.shared.isProMember = hasActivePro
    }

    /// Updates internal subscription state based on verified transaction
    public func updateSubscriptionStatus(from transaction: Transaction) async {
        let isRevoked = transaction.revocationDate != nil
        let isExpired = (transaction.expirationDate ?? Date.distantFuture) < Date()
        let isValid = !isRevoked && !isExpired && productIDs.contains(transaction.productID)

        self.isProSubscribed = isValid
        SubscriptionManager.shared.isProMember = isValid
        print("[StoreKitManager] Subscription state updated: isProSubscribed = \(isValid) (product: '\(transaction.productID)').")
    }

    /// Direct state mutator for automated unit test scenarios
    public func setEntitlementStateForTesting(isSubscribed: Bool) {
        self.isProSubscribed = isSubscribed
        SubscriptionManager.shared.isProMember = isSubscribed
    }
}
