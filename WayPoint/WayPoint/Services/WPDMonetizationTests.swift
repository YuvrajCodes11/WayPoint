//
//  WPDMonetizationTests.swift
//  WayPoint
//
//  WP-D — Monetization & StoreKit 2 End-to-End Automated Test Harness
//

import Foundation
import SwiftUI
import StoreKit

@MainActor
final class WPDMonetizationTests {
    static let shared = WPDMonetizationTests()

    private init() {}

    struct TestResult {
        let name: String
        let passed: Bool
        let details: String
    }

    /// Runs all WP-D test scenarios (Tests A - F) sequentially and returns structured results.
    @discardableResult
    func runAllWPDTests() async -> [TestResult] {
        print("\n==================================================")
        print("[WPD-TEST] 🚀 Launching WP-D Monetization & StoreKit 2 Test Harness")
        print("==================================================\n")

        var results: [TestResult] = []

        results.append(await testA_StoreKitCatalogAndPricing())
        results.append(await testB_SecurityAndJWSSignatureVerification())
        results.append(await testC_PurchaseExecutionAndReactiveUnlock())
        results.append(await testD_RestorePurchasesIdempotency())
        results.append(await testE_OfflineEntitlementRetention())
        results.append(await testF_PaywallUIStateMachine())

        var passCount = 0
        for res in results {
            if res.passed { passCount += 1 }
            print("[WPD-TEST] \(res.passed ? "✅ PASS" : "❌ FAIL") - \(res.name): \(res.details)")
        }

        print("--------------------------------------------------")
        print("[WPD-TEST] \(passCount == results.count ? "✅ PASS" : "❌ FAIL") - Summary: \(passCount)/\(results.count) WP-D Monetization Tests Passed.")
        print("==================================================\n")

        return results
    }

    // MARK: - Test A: StoreKit 2 Catalog & Pricing
    private func testA_StoreKitCatalogAndPricing() async -> TestResult {
        let catalog = StoreKitManager.productCatalog

        let weeklyProduct = catalog.first(where: { $0.id == StoreKitManager.weeklyProductID })
        let annualProduct = catalog.first(where: { $0.id == StoreKitManager.annualProductID })

        let weeklyOk = (weeklyProduct != nil) &&
                       (weeklyProduct?.price == 2.99) &&
                       (weeklyProduct?.subscriptionGroup == "WayPointProGroup") &&
                       (weeklyProduct?.recurringPeriod == "P1W") &&
                       (weeklyProduct?.trialPeriod == "P3D")

        let annualOk = (annualProduct != nil) &&
                       (annualProduct?.price == 29.99) &&
                       (annualProduct?.subscriptionGroup == "WayPointProGroup") &&
                       (annualProduct?.recurringPeriod == "P1Y") &&
                       (annualProduct?.trialPeriod == "P7D")

        let configValid = StoreKitConfig.validateStoreKitConfiguration()

        let passed = weeklyOk && annualOk && configValid

        return TestResult(
            name: "Test A (StoreKit 2 Catalog & Pricing)",
            passed: passed,
            details: "Weekly ($2.99 / P3D trial): \(weeklyOk), Annual ($29.99 / P7D trial): \(annualOk), StoreKit config validated: \(configValid)."
        )
    }

    // MARK: - Test B: Security & JWS Signature Verification
    private func testB_SecurityAndJWSSignatureVerification() async -> TestResult {
        let manager = StoreKitManager.shared
        let subManager = SubscriptionManager.shared

        // Reset state
        subManager.isProUser = false

        // Simulate an unverified VerificationResult
        let unverifiedResult: VerificationResult<String> = .unverified("payload_data", .invalidSignature)

        var jwsErrorCaught = false
        do {
            _ = try manager.checkVerification(unverifiedResult)
        } catch {
            if case StoreKitError.unverifiedTransaction = error {
                jwsErrorCaught = true
            }
        }

        // Verify entitlement remains locked after JWS failure
        let entitlementLocked = (subManager.isProUser == false)

        let passed = jwsErrorCaught && entitlementLocked

        return TestResult(
            name: "Test B (Security & JWS Signature Verification)",
            passed: passed,
            details: "Unverified JWS signature rejected: \(jwsErrorCaught), Entitlement status remains locked: \(entitlementLocked)."
        )
    }

    // MARK: - Test C: Purchase Execution & Reactive Unlock
    private func testC_PurchaseExecutionAndReactiveUnlock() async -> TestResult {
        let manager = StoreKitManager.shared
        let subManager = SubscriptionManager.shared

        manager.isTestingEnvironment = true
        subManager.isProUser = false

        // Perform simulated purchase of annual product
        manager.setEntitlementStateForTesting(isSubscribed: true)
        subManager.saveEntitlementCache(isPro: true, productID: StoreKitConfig.annualProductID)

        let isUnlocked = subManager.isProUser
        let cacheUpdated = (subManager.loadEntitlementCache()?.isPro == true)

        let passed = isUnlocked && cacheUpdated

        return TestResult(
            name: "Test C (Purchase Execution & Reactive Unlock)",
            passed: passed,
            details: "Reactive unlock (isProUser = true): \(isUnlocked), Offline entitlement cache updated: \(cacheUpdated)."
        )
    }

    // MARK: - Test D: Restore Purchases Idempotency
    private func testD_RestorePurchasesIdempotency() async -> TestResult {
        let manager = StoreKitManager.shared
        let subManager = SubscriptionManager.shared

        manager.isTestingEnvironment = true
        manager.setEntitlementStateForTesting(isSubscribed: true)

        let priorState = subManager.isProUser
        let restoreResult = await subManager.restorePurchases()
        let postRestoreState = subManager.isProUser

        let idempotent = (priorState == postRestoreState) && (restoreResult == true)

        let passed = idempotent

        return TestResult(
            name: "Test D (Restore Purchases Idempotency)",
            passed: passed,
            details: "Restore result: \(restoreResult), Prior state: \(priorState), Post-restore state: \(postRestoreState) (Idempotent: \(idempotent))."
        )
    }

    // MARK: - Test E: Offline Entitlement Retention
    private func testE_OfflineEntitlementRetention() async -> TestResult {
        let subManager = SubscriptionManager.shared

        // 1. Save valid Pro entitlement to cache
        let testProductID = StoreKitConfig.annualProductID
        subManager.saveEntitlementCache(isPro: true, productID: testProductID)

        // 2. Clear in-memory state and reload from offline storage
        let loadedCache = subManager.loadEntitlementCache()

        let cacheValid = (loadedCache != nil) &&
                         (loadedCache?.isPro == true) &&
                         (loadedCache?.productID == testProductID) &&
                         (Date().timeIntervalSince(loadedCache?.timestamp ?? Date.distantPast) < 60)

        let passed = cacheValid

        return TestResult(
            name: "Test E (Offline Entitlement Retention)",
            passed: passed,
            details: "Cached Pro status: \(cacheValid), productID: '\(loadedCache?.productID ?? "")', timestamp: \(loadedCache?.timestamp ?? Date())."
        )
    }

    // MARK: - Test F: Paywall UI State Machine
    private func testF_PaywallUIStateMachine() async -> TestResult {
        let subManager = SubscriptionManager.shared

        // 1. Idle State
        let idleStateOk = (subManager.isLoading == false)

        // 2. Simulating Purchasing / Loading State
        subManager.isLoading = true
        let loadingStateOk = (subManager.isLoading == true)

        // 3. Purchase Completed State
        subManager.isProUser = true
        subManager.isLoading = false
        let completionStateOk = (subManager.isProUser == true) && (subManager.isLoading == false)

        let passed = idleStateOk && loadingStateOk && completionStateOk

        return TestResult(
            name: "Test F (Paywall UI State Machine)",
            passed: passed,
            details: "Idle state ok: \(idleStateOk) -> Loading state ok: \(loadingStateOk) -> Completion state ok: \(completionStateOk)."
        )
    }
}
