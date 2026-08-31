//
//  SubscriptionManager.swift
//  WayPoint
//
//  Task 4.1 / WP4: Unified Subscription Manager & Entitlement Engine
//

import SwiftUI
import StoreKit
import RevenueCat

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

@MainActor
@Observable
final class SubscriptionManager: NSObject, PurchasesDelegate {
    static let shared = SubscriptionManager()

    private let entitlementCacheKey = "waypoint_pro_entitlement_v1"

    var isProMember: Bool = false {
        didSet {
            if isProMember != oldValue {
                saveEntitlementCache(isPro: isProMember)
            }
        }
    }
    var isLoading: Bool = false
    var currentOffering: Offering? = nil
    var errorMessage: String? = nil
    private(set) var isConfigured: Bool = false

    /// Configurable RevenueCat API key reading from process environment or Info.plist
    private var apiKey: String {
        if let envKey = ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        if let infoKey = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String, !infoKey.isEmpty {
            return infoKey
        }
        return ""
    }

    /// Alias for isProMember to support feature gating calls
    var isProUser: Bool {
        get { isProMember }
        set { isProMember = newValue }
    }

    override init() {
        super.init()
        // Load local offline entitlement cache on startup
        if let cache = loadEntitlementCache(), cache.isPro {
            self.isProMember = true
            print("[SubscriptionManager] Loaded active offline entitlement from local cache (timestamp: \(cache.timestamp)).")
        } else {
            self.isProMember = StoreKitManager.shared.isProSubscribed
        }
        configureRevenueCat()
    }

    func configure() {
        configureRevenueCat()
    }

    func configureRevenueCat() {
        let key = apiKey
        let isPlaceholder = key.isEmpty || key.contains("YOUR_API_KEY") || key.contains("production_key") || key == "appl_rCat_YOUR_API_KEY_HERE"
        guard key.hasPrefix("appl_"), !isPlaceholder else {
            print("[SubscriptionManager] Info: RevenueCat API key is unconfigured or placeholder. Skipping Purchases.configure to prevent 401 error loops. Operating in Native StoreKit 2 fallback mode.")
            isConfigured = false
            return
        }

        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: key)
        Purchases.shared.delegate = self
        isConfigured = true
        Task {
            await refreshSubscriptionStatus()
            await fetchOfferings()
        }
    }

    /// Load offerings from both StoreKit 2 and RevenueCat
    func loadOfferings() async {
        isLoading = true
        defer { isLoading = false }
        
        // Load StoreKit 2 Products
        _ = try? await StoreKitManager.shared.loadProducts()
        
        // Fetch RevenueCat offerings if configured
        if isConfigured {
            await fetchOfferings()
        }
    }

    /// Refresh entitlement state for "pro_access" or "pro"
    func refreshSubscriptionStatus() async {
        if isConfigured && Purchases.isConfigured {
            do {
                let customerInfo = try await Purchases.shared.customerInfo()
                updateProStatus(from: customerInfo)
                return
            } catch {
                print("[SubscriptionManager] RevenueCat Status Error: \(error.localizedDescription)")
            }
        }
        await StoreKitManager.shared.checkEntitlements()
        self.isProMember = StoreKitManager.shared.isProSubscribed
    }

    /// Fetch active RevenueCat offerings with graceful fallback handling
    func fetchOfferings() async {
        guard isConfigured, Purchases.isConfigured else { return }
        do {
            let offerings = try await Purchases.shared.offerings()
            self.currentOffering = offerings.current
        } catch {
            print("[SubscriptionManager] Offerings Fetch Error: \(error.localizedDescription)")
            self.errorMessage = "Live products currently unavailable."
        }
    }

    /// Purchase weekly subscription ($2.99/wk)
    @discardableResult
    func purchaseWeekly() async -> Bool {
        return await purchaseProduct(id: StoreKitManager.weeklyProductID)
    }

    /// Purchase annual subscription ($29.99/yr)
    @discardableResult
    func purchaseAnnual() async -> Bool {
        return await purchaseProduct(id: StoreKitManager.annualProductID)
    }

    /// Unified Purchase Entry Point by Product ID
    @discardableResult
    func purchaseProduct(id: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // RevenueCat purchase if configured and offering contains matching package
        if isConfigured, Purchases.isConfigured, let offering = currentOffering {
            let targetPackage = offering.availablePackages.first(where: { $0.storeProduct.productIdentifier == id })
            if let pkg = targetPackage {
                return await purchase(package: pkg)
            }
        }

        // Native StoreKit 2 Purchase Fallback
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
                self.isProMember = true
                saveEntitlementCache(isPro: true, productID: id)
                return true
            case .userCancelled:
                print("[SubscriptionManager] User cancelled purchase for product '\(id)'.")
                return false
            case .pending:
                self.errorMessage = "Purchase is pending approval (Ask to Buy)."
                return false
            case .unverified(let err):
                self.errorMessage = "JWS Verification Failed: \(err.localizedDescription)"
                self.isProMember = false
                saveEntitlementCache(isPro: false, productID: id)
                return false
            }
        } catch {
            self.errorMessage = error.localizedDescription
            print("[SubscriptionManager] Purchase Error: \(error.localizedDescription)")
            return false
        }
    }

    /// Purchase a selected RevenueCat package
    @discardableResult
    func purchase(package: Package) async -> Bool {
        guard isConfigured, Purchases.isConfigured else {
            return await purchaseProduct(id: package.storeProduct.productIdentifier)
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await Purchases.shared.purchase(package: package)
            if !result.userCancelled {
                updateProStatus(from: result.customerInfo)
                return isProMember
            }
        } catch {
            self.errorMessage = error.localizedDescription
            print("[SubscriptionManager] Purchase Error: \(error.localizedDescription)")
        }
        return false
    }

    /// Restore prior purchases via StoreKit 2 and RevenueCat
    @discardableResult
    func restorePurchases() async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if isConfigured, Purchases.isConfigured {
            do {
                let customerInfo = try await Purchases.shared.restorePurchases()
                updateProStatus(from: customerInfo)
                if isProMember { return true }
            } catch {
                print("[SubscriptionManager] RevenueCat Restore Error: \(error.localizedDescription)")
            }
        }

        do {
            let restored = try await StoreKitManager.shared.restorePurchases()
            let newStatus = self.isProMember || restored
            self.isProMember = newStatus
            saveEntitlementCache(isPro: newStatus)
            return newStatus
        } catch {
            self.errorMessage = error.localizedDescription
            print("[SubscriptionManager] StoreKit Restore Error: \(error.localizedDescription)")
            return self.isProMember
        }
    }

    // MARK: - Offline Entitlement Cache Persistence

    func saveEntitlementCache(isPro: Bool, productID: String? = nil) {
        let cache = ProEntitlementCache(isPro: isPro, timestamp: Date(), productID: productID)
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: entitlementCacheKey)
        }
    }

    func loadEntitlementCache() -> ProEntitlementCache? {
        guard let data = UserDefaults.standard.data(forKey: entitlementCacheKey) else { return nil }
        return try? JSONDecoder().decode(ProEntitlementCache.self, from: data)
    }

    private func updateProStatus(from customerInfo: CustomerInfo) {
        let isProAccess = customerInfo.entitlements["pro_access"]?.isActive == true
        let isProFallback = customerInfo.entitlements["pro"]?.isActive == true
        let active = isProAccess || isProFallback
        self.isProMember = active
        saveEntitlementCache(isPro: active)
    }

    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.updateProStatus(from: customerInfo)
        }
    }
}