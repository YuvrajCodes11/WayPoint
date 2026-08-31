//
//  WPCBackendArchitectureTests.swift
//  WayPoint
//
//  WP-C — Backend Architecture End-to-End Automated Test Harness
//

import Foundation
import SwiftUI

@MainActor
final class WPCBackendArchitectureTests {
    static let shared = WPCBackendArchitectureTests()

    private init() {}

    struct TestResult {
        let name: String
        let passed: Bool
        let details: String
    }

    /// Runs all WP-C test scenarios (Tests A - E) sequentially and returns structured results.
    @discardableResult
    func runAllWPCTests() async -> [TestResult] {
        print("\n==================================================")
        print("[WPC-TEST] 🚀 Launching WP-C Backend Architecture Test Harness")
        print("==================================================\n")

        var results: [TestResult] = []

        results.append(await testA_RLSSQLDDLVerification())
        results.append(await testB_AuthStateMachineAndKeychainIsolation())
        results.append(await testC_OutboundUserIDMismatchSecurityGuard())
        results.append(await testD_Remote409ConflictResolution())
        results.append(await testE_OfflineNetworkLossAnd401AuthErrorHandling())

        var passCount = 0
        for res in results {
            if res.passed { passCount += 1 }
            print("[WPC-TEST] \(res.passed ? "✅ PASS" : "❌ FAIL") - \(res.name): \(res.details)")
        }

        print("--------------------------------------------------")
        print("[WPC-TEST] \(passCount == results.count ? "✅ PASS" : "❌ FAIL") - Summary: \(passCount)/\(results.count) WP-C Backend Architecture Tests Passed.")
        print("==================================================\n")

        return results
    }

    // MARK: - Test A: RLS SQL DDL Verification
    private func testA_RLSSQLDDLVerification() async -> TestResult {
        let sqlPath = Bundle.main.path(forResource: "supabase_schema", ofType: "sql") ?? ""
        var sqlContent = ""
        if let data = try? Data(contentsOf: URL(fileURLWithPath: sqlPath)), let text = String(data: data, encoding: .utf8) {
            sqlContent = text
        } else {
            // Direct path check if bundle path isn't set in test environment
            let altPath = "/Users/yuvraj/Documents/WayPoint IOS APP/WayPoint/WayPoint/supabase_schema.sql"
            sqlContent = (try? String(contentsOfFile: altPath, encoding: .utf8)) ?? ""
        }

        let tables = ["profiles", "trips", "itinerary_items", "bookings", "expenses", "sync_revisions"]
        var rlsEnabledAll = true
        var policiesFoundAll = true

        for table in tables {
            let rlsStmt = "ALTER TABLE public.\(table) ENABLE ROW LEVEL SECURITY;"
            let policyStmt = "auth.uid() ="
            if !sqlContent.contains(rlsStmt) {
                rlsEnabledAll = false
            }
            if !sqlContent.contains("ON public.\(table)") || !sqlContent.contains(policyStmt) {
                policiesFoundAll = false
            }
        }

        let cascadeConfigured = sqlContent.contains("ON DELETE CASCADE")
        let indexesConfigured = sqlContent.contains("idx_trips_user_id_updated_at") && sqlContent.contains("idx_itinerary_items_trip_day")

        let passed = rlsEnabledAll && policiesFoundAll && cascadeConfigured && indexesConfigured

        return TestResult(
            name: "Test A (RLS SQL DDL Verification)",
            passed: passed,
            details: "RLS enabled across 6 tables: \(rlsEnabledAll), RLS auth.uid() policies verified: \(policiesFoundAll), CASCADE constraints: \(cascadeConfigured), Composite indexes: \(indexesConfigured)."
        )
    }

    // MARK: - Test B: Auth State Machine & Keychain Isolation
    private func testB_AuthStateMachineAndKeychainIsolation() async -> TestResult {
        let service = SupabaseService.shared
        let store = TripStore.shared

        // 1. Initial State
        let initialStateOk = (service.authState != .authenticating)

        // 2. Sign In User A
        let emailA = "test_user_a@waypoint.ai"
        let signInRes = await service.signIn(email: emailA, token: "token_user_a_valid")

        let userA_ID: String
        switch signInRes {
        case .success(let uid): userA_ID = uid
        case .failure: userA_ID = ""
        }

        let signedInStateOk = (service.isAuthenticated == true) && (service.currentUserEmail == emailA)
        let loadedSession = service.loadAuthSession()
        let keychainSessionValid = (loadedSession?.userID == userA_ID) && (loadedSession?.isExpired == false)

        // 3. Enqueue trip mutation for User A
        store.mutate("user_a_mutation") { trip in
            trip.destination = "User A Destination"
        }
        let userAQueueCount = store.pendingQueueCount

        // 4. Sign Out User A -> Trigger Keychain Token Purge & Storage Re-isolation
        await service.signOut()

        let postSignOutStateOk = (service.isAuthenticated == false) && (service.currentSession == nil)
        let postSignOutKeychainCleared = (service.loadAuthSession() == nil)
        let guestStoreResetOk = (store.currentUserID == "guest_user") && (store.pendingQueueCount == 0)

        let passed = initialStateOk && signedInStateOk && keychainSessionValid && postSignOutStateOk && postSignOutKeychainCleared && guestStoreResetOk

        return TestResult(
            name: "Test B (Auth State Machine & Keychain Isolation)",
            passed: passed,
            details: "User A signed in: \(userA_ID), Keychain session verified: \(keychainSessionValid), Sign-out token purged: \(postSignOutKeychainCleared), Guest store re-isolated: \(guestStoreResetOk)."
        )
    }

    // MARK: - Test C: Outbound User ID Mismatch Security Guard
    private func testC_OutboundUserIDMismatchSecurityGuard() async -> TestResult {
        let service = SupabaseService.shared

        // 1. Authenticate as User A
        _ = await service.signIn(email: "legitimate_user_a@waypoint.ai", token: "valid_token_a")
        guard case .authenticated(let authedID, _) = service.authState else {
            return TestResult(name: "Test C", passed: false, details: "Failed to authenticate User A.")
        }

        // 2. Attempt outbound request payload with User B ID ("user_b_malicious")
        let maliciousUserBID = "user_b_malicious"
        var securityViolationCaught = false

        do {
            try service.validateOutboundPayload(userID: maliciousUserBID)
        } catch {
            securityViolationCaught = true
        }

        // 3. Verify legitimate payload with User A ID passes validation
        var legitimatePayloadPassed = false
        do {
            try service.validateOutboundPayload(userID: authedID)
            legitimatePayloadPassed = true
        } catch {
            legitimatePayloadPassed = false
        }

        let passed = securityViolationCaught && legitimatePayloadPassed

        // Reset auth state
        await service.signOut()

        return TestResult(
            name: "Test C (Outbound User ID Mismatch Security Guard)",
            passed: passed,
            details: "Attempted User B payload intercepted: \(securityViolationCaught), Legitimate User A payload approved: \(legitimatePayloadPassed)."
        )
    }

    // MARK: - Test D: 409 Remote Conflict Resolution
    private func testD_Remote409ConflictResolution() async -> TestResult {
        let service = SupabaseService.shared
        let store = TripStore.shared

        _ = await service.signIn(email: "conflict_tester@waypoint.ai", token: "valid_token")
        store.resetStoreWithFreshSample()

        // Set local trip to version 2
        store.activeTrip.version = 2
        store.activeTrip.destination = "Local v2 Stale"

        // Enqueue queue item for v2
        let queueItem = SyncQueueItem(tripID: store.activeTrip.id, mutationReason: "v2_mutation", tripVersion: 2)
        store.enqueueSyncItem(queueItem)
        let preSyncQueueCount = store.pendingQueueCount

        // Dispatch sync with "conflict" reason -> returns 409 with remote version 8
        let result = await service.syncTripRecord(store.activeTrip, reason: "simulate_conflict_409")

        let isConflictError: Bool
        let remoteVersion: Int
        switch result {
        case .failure(.conflict(let v, let remoteTrip)):
            isConflictError = true
            remoteVersion = v
            // Trigger store reconciliation upon 409
            _ = store.reconcileRemoteTrip(remoteTrip)
        default:
            isConflictError = false
            remoteVersion = 0
        }

        let localUpdatedToVersion8 = (store.activeTrip.version == 8)
        let queuePurgedAfterAdoption = store.syncQueue.isEmpty

        let passed = isConflictError && (remoteVersion == 8) && localUpdatedToVersion8 && queuePurgedAfterAdoption

        await service.signOut()

        return TestResult(
            name: "Test D (409 Remote Conflict Resolution)",
            passed: passed,
            details: "409 Conflict error classified: \(isConflictError) (remote v\(remoteVersion)), Local activeTrip updated to v\(store.activeTrip.version), Pre-sync queue: \(preSyncQueueCount), Post-reconciliation queue: \(store.pendingQueueCount)."
        )
    }

    // MARK: - Test E: Offline Network Loss & 401 Auth Error Handling
    private func testE_OfflineNetworkLossAnd401AuthErrorHandling() async -> TestResult {
        let service = SupabaseService.shared
        let store = TripStore.shared

        _ = await service.signIn(email: "offline_tester@waypoint.ai", token: "valid_token")
        store.clearPendingQueue()

        // 1. Offline Simulation: Enqueue item under "offline" reason
        let offlineItem = SyncQueueItem(tripID: store.activeTrip.id, mutationReason: "offline_edit", tripVersion: 5)
        store.enqueueSyncItem(offlineItem)

        let syncOfflineRes = await service.syncTripRecord(store.activeTrip, reason: "simulate_offline")

        let isNetworkUnavailable: Bool
        if case .failure(.networkUnavailable) = syncOfflineRes { isNetworkUnavailable = true } else { isNetworkUnavailable = false }

        let offlineQueueRetained = (store.pendingQueueCount == 1)

        // 2. 401 Unauthorized Simulation
        let syncUnauthRes = await service.syncTripRecord(store.activeTrip, reason: "simulate_unauthorized_401")

        let isUnauthorizedError: Bool
        if case .failure(.unauthorized) = syncUnauthRes { isUnauthorizedError = true } else { isUnauthorizedError = false }

        let authStateResetToUnauthenticated = (service.authState == .unauthenticated)
        // Verify 401 pauses queue dispatch without purging un-synced user edits from queue
        let unSyncedEditsPreservedInQueue = (store.pendingQueueCount == 1)

        let passed = isNetworkUnavailable && offlineQueueRetained && isUnauthorizedError && authStateResetToUnauthenticated && unSyncedEditsPreservedInQueue

        await service.signOut()

        return TestResult(
            name: "Test E (Offline Network Loss & 401 Auth Error Handling)",
            passed: passed,
            details: "Offline error classified: \(isNetworkUnavailable), Queue retained offline: \(offlineQueueRetained), 401 Unauthorized classified: \(isUnauthorizedError), Auth state reset: \(authStateResetToUnauthenticated), Un-synced queue edits preserved: \(unSyncedEditsPreservedInQueue)."
        )
    }
}
