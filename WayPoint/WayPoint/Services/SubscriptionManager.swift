//
//  SubscriptionManager.swift
//  WayPoint
//
//  Task 4.1 / WP4: Production RevenueCat & StoreKit 2 Unified Subscription Engine
//

import SwiftUI
import Combine
import StoreKit
import RevenueCat
import RevenueCatUI

public struct ProEntitlementCache: Codable, Equatable {
    public let isPro: Bool
    public let timestamp: Date
    public let productID: String?

    public init(isPro: Bool, timestamp: Date = Date(), productID: String? = nil) {
        self.isPro = isPro
        self.timestamp = timestamp
        self.productID = productID
    }
}

@Observable
@MainActor
public final class SubscriptionManager: NSObject, ObservableObject, PurchasesDelegate {
    public static let shared = SubscriptionManager()

    private let entitlementCacheKey = "waypoint_pro_entitlement_v1"
    private let keychainProKey = "waypoint_is_pro_user_keychain_cache"

    public var isPro: Bool = false {
        didSet {
            if isPro != oldValue {
                saveEntitlementCache(isPro: isPro)
            }
        }
    }
    public var offerings: Offerings? = nil
    public var isLoading: Bool = false
    public var errorMessage: String? = nil
    public private(set) var isConfigured: Bool = false

    /// Backward compatibility aliases for existing codebase & test suites
    public var isProMember: Bool {
        get { isPro }
        set { isPro = newValue }
    }

    public var isProUser: Bool {
        get { isPro }
        set { isPro = newValue }
    }

    public var currentOffering: Offering? {
        get { offerings?.current }
        set { _ = newValue }
    }

    /// Configurable RevenueCat API key with fallback to prompt key
    public var apiKey: String {
        if let envKey = ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        if let infoKey = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String, !infoKey.isEmpty {
            return infoKey
        }
        return "appl_YOUR_REVENUECAT_API_KEY"
    }

    public override init() {
        super.init()
        // 1. Offline Resilience: Read from secure Keychain first, then UserDefaults cache fallback
        if let keychainStatus = KeychainService.shared.readString(forKey: keychainProKey), keychainStatus == "true" {
            self.isPro = true
            print("[SubscriptionManager] Offline entitlement active from Keychain.")
        } else if let cache = loadEntitlementCache(), cache.isPro {
            self.isPro = true
            print("[SubscriptionManager] Offline entitlement active from local cache (timestamp: \(cache.timestamp)).")
        }
        
        // 2. Configure RevenueCat SDK
        configure()
    }

    public func configure() {
        configureRevenueCat()
    }

    public var isPlaceholderKey: Bool {
        let key = apiKey
        return key.isEmpty || key.contains("YOUR_REVENUECAT_API_KEY") || key.contains("placeholder_key") || key == "appl_YOUR_REVENUECAT_API_KEY"
    }

    public func configureRevenueCat() {
        let key = apiKey
        
        if !isPlaceholderKey && key.hasPrefix("appl_") {
            Purchases.logLevel = .debug
            Purchases.configure(withAPIKey: key)
            if Purchases.isConfigured {
                Purchases.shared.delegate = self
                isConfigured = true
            }
        } else {
            print("[SubscriptionManager] RevenueCat API key is placeholder; suppressing remote network fetches and relying on StoreKit 2 local testing (Products.storekit).")
            isConfigured = false
        }

        Task {
            await refreshSubscriptionStatus()
            await fetchOfferings()
        }
    }

    /// Fetch live offerings from RevenueCat
    public func fetchOfferings() async {
        guard isConfigured && !isPlaceholderKey && Purchases.isConfigured else {
            _ = try? await StoreKitManager.shared.loadProducts()
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let fetchedOfferings = try await Purchases.shared.offerings()
            self.offerings = fetchedOfferings
            self.errorMessage = nil
        } catch {
            print("[SubscriptionManager] Fetch Offerings Error: \(error.localizedDescription)")
            self.errorMessage = "Live products currently unavailable."
        }
    }

    /// Purchase a RevenueCat Package
    @discardableResult
    public func purchase(package: Package) async -> Bool {
        guard Purchases.isConfigured else {
            return await purchaseProduct(id: package.storeProduct.productIdentifier)
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await Purchases.shared.purchase(package: package)
            if !result.userCancelled {
                updateProStatus(from: result.customerInfo)
                return self.isPro
            }
        } catch {
            self.errorMessage = error.localizedDescription
            print("[SubscriptionManager] RevenueCat Package Purchase Error: \(error.localizedDescription)")
        }
        return false
    }

    /// Restore Purchases via RevenueCat & StoreKit 2 fallback
    @discardableResult
    public func restorePurchases() async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if Purchases.isConfigured {
            do {
                let customerInfo = try await Purchases.shared.restorePurchases()
                updateProStatus(from: customerInfo)
                if self.isPro { return true }
            } catch {
                print("[SubscriptionManager] RevenueCat Restore Error: \(error.localizedDescription)")
            }
        }

        do {
            let restored = try await StoreKitManager.shared.restorePurchases()
            let newStatus = self.isPro || restored
            self.isPro = newStatus
            saveEntitlementCache(isPro: newStatus)
            return newStatus
        } catch {
            self.errorMessage = error.localizedDescription
            print("[SubscriptionManager] StoreKit Restore Error: \(error.localizedDescription)")
            return self.isPro
        }
    }

    /// Load offerings from both StoreKit 2 and RevenueCat
    public func loadOfferings() async {
        isLoading = true
        defer { isLoading = false }
        _ = try? await StoreKitManager.shared.loadProducts()
        await fetchOfferings()
    }

    /// Refresh subscription entitlement status
    public func refreshSubscriptionStatus() async {
        if isConfigured && !isPlaceholderKey && Purchases.isConfigured {
            do {
                let customerInfo = try await Purchases.shared.customerInfo()
                updateProStatus(from: customerInfo)
                return
            } catch {
                print("[SubscriptionManager] RevenueCat CustomerInfo Status Error: \(error.localizedDescription)")
            }
        }
        await StoreKitManager.shared.checkEntitlements()
        self.isPro = StoreKitManager.shared.isProSubscribed
    }

    /// Unified Purchase Entry Point by Product ID
    @discardableResult
    public func purchaseProduct(id: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if Purchases.isConfigured, let currentOffering = offerings?.current {
            let targetPackage = currentOffering.availablePackages.first(where: { $0.storeProduct.productIdentifier == id })
            if let pkg = targetPackage {
                return await purchase(package: pkg)
            }
        }

        do {
            let products = try await StoreKitManager.shared.loadProducts()
            guard let product = products.first(where: { $0.id == id }) else {
                let err = StoreKitError.productNotFound(id)
                self.errorMessage = err.localizedDescription
                return false
            }
            let res = try await StoreKitManager.shared.purchase(product)
            switch res {
            case .success:
                self.isPro = true
                saveEntitlementCache(isPro: true, productID: id)
                return true
            case .userCancelled:
                return false
            case .pending:
                self.errorMessage = "Purchase is pending approval."
                return false
            case .unverified(let err):
                self.errorMessage = "JWS Verification Failed: \(err.localizedDescription)"
                self.isPro = false
                saveEntitlementCache(isPro: false, productID: id)
                return false
            }
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }

    @discardableResult
    public func purchaseWeekly() async -> Bool {
        return await purchaseProduct(id: StoreKitManager.weeklyProductID)
    }

    @discardableResult
    public func purchaseAnnual() async -> Bool {
        return await purchaseProduct(id: StoreKitManager.annualProductID)
    }

    // MARK: - Offline Entitlement Persistence

    public func saveEntitlementCache(isPro: Bool, productID: String? = nil) {
        let cache = ProEntitlementCache(isPro: isPro, timestamp: Date(), productID: productID)
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: entitlementCacheKey)
        }
        KeychainService.shared.saveString(isPro ? "true" : "false", forKey: keychainProKey)
    }

    public func loadEntitlementCache() -> ProEntitlementCache? {
        guard let data = UserDefaults.standard.data(forKey: entitlementCacheKey) else { return nil }
        return try? JSONDecoder().decode(ProEntitlementCache.self, from: data)
    }

    private func updateProStatus(from customerInfo: CustomerInfo) {
        let isProAccess = customerInfo.entitlements["pro_access"]?.isActive == true
        let isProFallback = customerInfo.entitlements["pro"]?.isActive == true
        let active = isProAccess || isProFallback
        self.isPro = active
        saveEntitlementCache(isPro: active)
    }

    public nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.updateProStatus(from: customerInfo)
        }
    }
}