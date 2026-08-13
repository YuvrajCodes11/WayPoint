//
//  SubscriptionManager.swift
//  WayPoint
//

import SwiftUI
import RevenueCat

@MainActor
@Observable
final class SubscriptionManager: NSObject, PurchasesDelegate {
    static let shared = SubscriptionManager()

    var isProMember: Bool = false
    var isLoading: Bool = false
    var currentOffering: Offering? = nil
    var errorMessage: String? = nil

    /// Alias for isProMember to support feature gating calls
    var isProUser: Bool {
        get { isProMember }
        set { isProMember = newValue }
    }

    override init() {
        super.init()
        configure()
    }

    func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "appl_rCat_YOUR_API_KEY_HERE")
        Purchases.shared.delegate = self
        Task {
            await refreshSubscriptionStatus()
            await fetchOfferings()
        }
    }

    /// Refresh entitlement state for "pro_access" or "pro"
    func refreshSubscriptionStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateProStatus(from: customerInfo)
        } catch {
            print("RevenueCat Status Error: \(error.localizedDescription)")
        }
    }

    /// Fetch active RevenueCat offerings
    func fetchOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            self.currentOffering = offerings.current
        } catch {
            print("RevenueCat Offerings Error: \(error.localizedDescription)")
        }
    }

    /// Purchase a selected RevenueCat package
    func purchase(package: Package) async -> Bool {
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
            print("Purchase Error: \(error.localizedDescription)")
        }
        return false
    }

    /// Restore prior purchases
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            updateProStatus(from: customerInfo)
        } catch {
            self.errorMessage = error.localizedDescription
            print("Restore Error: \(error.localizedDescription)")
        }
    }

    private func updateProStatus(from customerInfo: CustomerInfo) {
        let isProAccess = customerInfo.entitlements["pro_access"]?.isActive == true
        let isProFallback = customerInfo.entitlements["pro"]?.isActive == true
        self.isProMember = isProAccess || isProFallback
    }

    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.updateProStatus(from: customerInfo)
        }
    }
}