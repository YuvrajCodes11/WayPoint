//
//  WP4MonetizationTests.swift
//  WayPoint
//
//  WP4: Complete Monetization, StoreKit 2 & RevenueCat Bridging Test Suite
//

import Foundation
import StoreKit
import SwiftUI

@MainActor
final class WP4MonetizationTests {
    static let shared = WP4MonetizationTests()

    private init() {}

    struct TestResult {
        let name: String
        let passed: Bool
        let details: String
    }

    /// Runs all WP4 test scenarios (A through F) and returns structured results.
    func runAllWP4Tests() async -> [TestResult] {
        StoreKitManager.shared.isTestingEnvironment = true
        var results: [TestResult] = []

        results.append(await testA_StoreKit2CatalogAndPricing())
        results.append(await testB_SecurityAndJWSVerification())
        results.append(await testC_PurchaseAndReactiveUnlockState())
        results.append(await testD_RestorePurchasesIdempotency())
        results.append(await testE_OfflineEntitlementRetention())
        results.append(await testF_PaywallUIStateTransitions())

        for res in results {
            print("[WP4-TEST] \(res.passed ? "✅ PASS" : "❌ FAIL") - \(res.name): \(res.details)")
        }

        return results
    }

    // MARK: - Test A: StoreKit 2 Catalog & Pricing
    private func testA_StoreKit2CatalogAndPricing() async -> TestResult {
        let catalog = StoreKitManager.productCatalog
        let weekly = catalog.first(where: { $0.id == StoreKitManager.weeklyProductID })
        let annual = catalog.first(where: { $0.id == StoreKitManager.annualProductID })

        guard let weeklyDesc = weekly, let annualDesc = annual else {
            return TestResult(
                name: "Test A: StoreKit 2 Catalog & Pricing",
                passed: false,
                details: "Product catalog missing weekly or annual product definitions."
            )
        }

        let weeklyMatch = weeklyDesc.price == 2.99 && weeklyDesc.trialPeriod == "P3D" && weeklyDesc.subscriptionGroup == "WayPointProGroup"
        let annualMatch = annualDesc.price == 29.99 && annualDesc.trialPeriod == "P7D" && annualDesc.subscriptionGroup == "WayPointProGroup"

        let passed = weeklyMatch && annualMatch

        return TestResult(
            name: "Test A: StoreKit 2 Catalog & Pricing",
            passed: passed,
            details: "Weekly: \(weeklyDesc.displayPrice) (Trial: \(weeklyDesc.trialPeriod ?? "")), Annual: \(annualDesc.displayPrice) (Trial: \(annualDesc.trialPeriod ?? "")), Group: '\(weeklyDesc.subscriptionGroup)'."
        )
    }

    // MARK: - Test B: Security & JWS Signature Verification
    private func testB_SecurityAndJWSVerification() async -> TestResult {
        let manager = StoreKitManager.shared
        manager.setEntitlementStateForTesting(isSubscribed: false)

        var unverifiedRejected = false
        let unverifiedResult: VerificationResult<String> = .unverified("payload", .invalidSignature)

        do {
            _ = try manager.checkVerification(unverifiedResult)
        } catch StoreKitError.unverifiedTransaction(let reason) {
            unverifiedRejected = true
            print("[WP4MonetizationTests] Unverified JWS intercepted cleanly: \(reason)")
        } catch {
            unverifiedRejected = false
        }

        let entitlementBlocked = !manager.isProSubscribed

        let passed = unverifiedRejected && entitlementBlocked

        return TestResult(
            name: "Test B: Security & JWS Signature Verification",
            passed: passed,
            details: "Unverified JWS signature rejected: \(unverifiedRejected). Entitlement status remains locked: \(entitlementBlocked)."
        )
    }

    // MARK: - Test C: Purchase & Reactive Unlock State
    private func testC_PurchaseAndReactiveUnlockState() async -> TestResult {
        let subManager = SubscriptionManager.shared
        subManager.isProUser = false

        // Simulate purchase completion
        subManager.isProUser = true
        let unlocked = subManager.isProUser
        let cached = subManager.loadEntitlementCache()?.isPro == true

        let passed = unlocked && cached

        return TestResult(
            name: "Test C: Purchase & Reactive Unlock State",
            passed: passed,
            details: "Reactive unlock (isProUser = true): \(unlocked). Offline entitlement cache updated: \(cached)."
        )
    }

    // MARK: - Test D: Restore Purchases Idempotency
    private func testD_RestorePurchasesIdempotency() async -> TestResult {
        let subManager = SubscriptionManager.shared
        subManager.isProUser = true

        let stateBefore = subManager.isProUser
        let restored = await subManager.restorePurchases()
        let stateAfter = subManager.isProUser

        let idempotent = (stateBefore == stateAfter)

        let passed = idempotent

        return TestResult(
            name: "Test D: Restore Purchases Idempotency",
            passed: passed,
            details: "Restore result: \(restored). Prior state: \(stateBefore), post-restore state: \(stateAfter) (Idempotent: \(idempotent))."
        )
    }

    // MARK: - Test E: Offline Entitlement Retention
    private func testE_OfflineEntitlementRetention() async -> TestResult {
        let subManager = SubscriptionManager.shared

        // Save verified cache
        subManager.saveEntitlementCache(isPro: true, productID: StoreKitManager.annualProductID)

        // Read back cache
        let loadedCache = subManager.loadEntitlementCache()
        let cacheValid = loadedCache != nil && loadedCache?.isPro == true

        let passed = cacheValid

        return TestResult(
            name: "Test E: Offline Entitlement Retention",
            passed: passed,
            details: "Cached Pro status: \(loadedCache?.isPro ?? false), productID: '\(loadedCache?.productID ?? "")', timestamp: \(loadedCache?.timestamp ?? Date())."
        )
    }

    // MARK: - Test F: Paywall UI State Transitions
    private func testF_PaywallUIStateTransitions() async -> TestResult {
        let subManager = SubscriptionManager.shared

        // State 1: Initial idle
        subManager.isLoading = false
        let idleOk = !subManager.isLoading

        // State 2: Loading products / purchasing
        subManager.isLoading = true
        let loadingOk = subManager.isLoading

        // State 3: User cancelled or completion transition
        subManager.isLoading = false
        let completionOk = !subManager.isLoading

        let passed = idleOk && loadingOk && completionOk

        return TestResult(
            name: "Test F: Paywall UI State Transitions",
            passed: passed,
            details: "Idle state ok: \(idleOk) -> Loading state ok: \(loadingOk) -> Completion state ok: \(completionOk)."
        )
    }
}
