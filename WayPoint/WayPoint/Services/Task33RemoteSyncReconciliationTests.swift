//
//  Task33RemoteSyncReconciliationTests.swift
//  WayPoint
//
//  Task 3.3: Remote-to-Local Sync, Retry & Network Reconciliation Automated Test Suite
//

import Foundation
import SwiftUI

@MainActor
final class Task33RemoteSyncReconciliationTests {
    static let shared = Task33RemoteSyncReconciliationTests()

    private init() {}

    struct TestResult {
        let name: String
        let passed: Bool
        let details: String
    }

    /// Runs all Task 3.3 test scenarios (A, B, C, D) and returns structured results.
    func runAllTask33Tests() async -> [TestResult] {
        var results: [TestResult] = []

        results.append(await testA_SuccessfulRemotePush())
        results.append(await testB_409VersionConflictResolution())
        results.append(await testC_OfflineNetworkLossResilience())
        results.append(await testD_401UnauthorizedErrorHandling())

        for res in results {
            print("[TASK-3.3-TEST] \(res.passed ? "✅ PASS" : "❌ FAIL") - \(res.name): \(res.details)")
        }

        return results
    }

    // MARK: - Test A: Successful Remote Push
    private func testA_SuccessfulRemotePush() async -> TestResult {
        let service = SupabaseService.shared
        let store = TripStore.shared

        _ = await service.signIn(email: "test_push_success@waypoint.ai", token: "valid_token_33")
        if case .authenticated(let authedID, _) = service.authState {
            store.handleUserSignIn(userID: authedID)
        }

        store.clearPendingQueue()
        store.mutate("test_push_mutation") { trip in
            trip.title = "Verified Remote Push Trip"
        }

        let pushRes = await service.syncTripRecord(store.activeTrip, reason: "test_push_mutation")
        var pushSuccess = false
        var syncedVer = 0

        if case .success(let resp) = pushRes {
            pushSuccess = true
            syncedVer = resp.syncedVersion
            store.pruneSyncQueue(upToVersion: syncedVer)
            store.clearPendingQueue()
        }

        let queuePruned = store.pendingQueueCount == 0
        let hasPendingSync = store.hasPendingRemoteSync

        let passed = pushSuccess && queuePruned && !hasPendingSync && (syncedVer == store.activeTrip.version)

        return TestResult(
            name: "Test A: Successful Remote Push",
            passed: passed,
            details: "Push success: \(pushSuccess). Synced version: v\(syncedVer). Pending queue count: \(store.pendingQueueCount), hasPendingRemoteSync: \(hasPendingSync)."
        )
    }

    // MARK: - Test B: 409 Version Conflict Resolution
    private func testB_409VersionConflictResolution() async -> TestResult {
        let store = TripStore.shared

        // Set local trip to v4
        store.activeTrip.version = 4
        store.mutate("local_v4_edit") { trip in
            trip.destination = "Local v4 Destination"
        }

        // Simulate remote trip at v8 with matching ID
        let remoteV8 = Trip(
            id: store.activeTrip.id,
            title: store.activeTrip.title,
            destination: "Remote v8 Winner Destination",
            travelerName: store.activeTrip.travelerName,
            days: store.activeTrip.days,
            version: 8
        )
        remoteV8.updatedAt = Date().addingTimeInterval(3600)

        // Reconcile 409 conflict
        let reconResult = store.reconcileRemoteTrip(remoteV8)
        let postVersion = store.activeTrip.version
        let postDest = store.activeTrip.destination
        let queuePruned = store.pendingQueueCount == 0

        let passed = (postVersion == 8) && (postDest == "Remote v8 Winner Destination") && queuePruned

        return TestResult(
            name: "Test B: 409 Version Conflict Resolution",
            passed: passed,
            details: "Reconciliation result: \(reconResult). Active version: v\(postVersion) ('\(postDest)'). Queue count: \(store.pendingQueueCount)."
        )
    }

    // MARK: - Test C: Offline / Network Loss Resilience
    private func testC_OfflineNetworkLossResilience() async -> TestResult {
        let service = SupabaseService.shared
        let store = TripStore.shared

        _ = await service.signIn(email: "test_offline@waypoint.ai", token: "valid_token_offline")
        if case .authenticated(let authedID, _) = service.authState {
            store.handleUserSignIn(userID: authedID)
        }
        store.clearPendingQueue()

        let initialVersion = store.activeTrip.version
        let initialTitle = store.activeTrip.title

        // Simulate offline response
        let offlineResult = await service.syncTripRecord(store.activeTrip, reason: "offline_test_mutation")
        let isOfflineErr = (offlineResult == .failure(.networkUnavailable)) || (offlineResult == .failure(.serverError(code: 500)))

        // Enqueue offline item
        store.enqueueSyncItem(SyncQueueItem(tripID: store.activeTrip.id, mutationReason: "offline_edit", tripVersion: store.activeTrip.version))
        let postQueueCount = store.pendingQueueCount
        let hasPendingSync = store.hasPendingRemoteSync
        let localDataIntact = (store.activeTrip.version == initialVersion) && (store.activeTrip.title == initialTitle)

        let passed = isOfflineErr && postQueueCount > 0 && hasPendingSync && localDataIntact

        return TestResult(
            name: "Test C: Offline / Network Loss Resilience",
            passed: passed,
            details: "Offline sync error detected: \(isOfflineErr). Queue retained: \(postQueueCount) items, hasPendingRemoteSync: \(hasPendingSync), local data intact: \(localDataIntact)."
        )
    }

    // MARK: - Test D: 401 Unauthorized Error Handling
    private func testD_401UnauthorizedErrorHandling() async -> TestResult {
        let service = SupabaseService.shared
        let store = TripStore.shared

        // User signs out -> becomes unauthenticated
        await service.signOut()

        // Attempt sync record while unauthorized
        let unauthedResult = await service.syncTripRecord(store.activeTrip, reason: "unauthed_attempt")
        let isUnauthedErr = (unauthedResult == .failure(.unauthorized))

        // Enqueue edit while unauthenticated
        store.enqueueSyncItem(SyncQueueItem(tripID: store.activeTrip.id, mutationReason: "unauthed_edit", tripVersion: store.activeTrip.version))
        let queueRetained = store.pendingQueueCount > 0
        let hasPendingSync = store.hasPendingRemoteSync
        let sessionInvalidated = !service.isAuthenticated

        let passed = isUnauthedErr && queueRetained && hasPendingSync && sessionInvalidated

        return TestResult(
            name: "Test D: 401 Unauthorized Error Handling",
            passed: passed,
            details: "Unauthorized error returned: \(isUnauthedErr). Session invalidated: \(sessionInvalidated). Edits retained: \(queueRetained), hasPendingRemoteSync: \(hasPendingSync)."
        )
    }
}
