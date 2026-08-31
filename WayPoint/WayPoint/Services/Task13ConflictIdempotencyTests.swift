//
//  Task13ConflictIdempotencyTests.swift
//  WayPoint
//
//  Task 1.3: Conflict Handling & Revision Idempotency Automated Test Suite
//

import Foundation
import SwiftUI

@MainActor
final class Task13ConflictIdempotencyTests {
    static let shared = Task13ConflictIdempotencyTests()

    private init() {}

    struct TestResult {
        let name: String
        let passed: Bool
        let details: String
    }

    /// Runs all Task 1.3 test scenarios (A, B, C, D, E) and returns structured results.
    func runAllTask13Tests() async -> [TestResult] {
        var results: [TestResult] = []

        results.append(await testA_HigherRemoteVersion())
        results.append(await testB_LowerRemoteVersion())
        results.append(await testC_EqualVersionNewerRemoteTimestamp())
        results.append(await testD_EqualVersionOlderRemoteTimestamp())
        results.append(await testE_DayAndItemIdempotency())

        for res in results {
            print("[TASK-1.3-TEST] \(res.passed ? "✅ PASS" : "❌ FAIL") - \(res.name): \(res.details)")
        }

        return results
    }

    // MARK: - Test A: Higher Remote Version (v2 vs v5 -> Applied & Queue Purged)
    private func testA_HigherRemoteVersion() async -> TestResult {
        let store = TripStore.shared
        store.resetStoreWithFreshSample()

        // Set local trip to version 2
        store.activeTrip.version = 2

        // Enqueue queue items with versions 1, 2, 3
        let item1 = SyncQueueItem(tripID: store.activeTrip.id, mutationReason: "v1_mut", tripVersion: 1)
        let item2 = SyncQueueItem(tripID: store.activeTrip.id, mutationReason: "v2_mut", tripVersion: 2)
        let item3 = SyncQueueItem(tripID: store.activeTrip.id, mutationReason: "v3_mut", tripVersion: 3)
        store.enqueueSyncItem(item1)
        store.enqueueSyncItem(item2)
        store.enqueueSyncItem(item3)

        // Create remote trip at version 5
        let remoteTrip = Trip.createSampleTrip(id: store.activeTrip.id)
        remoteTrip.version = 5
        remoteTrip.destination = "Remote Version 5 Paradise"

        let result = store.reconcileRemoteTrip(remoteTrip)

        let isApplied: Bool
        if case .appliedRemote = result { isApplied = true } else { isApplied = false }

        let versionMatch = (store.activeTrip.version == 5)
        let destinationMatch = (store.activeTrip.destination == "Remote Version 5 Paradise")
        // Items with tripVersion <= 5 (v1, v2, v3) should be purged
        let queuePurged = store.syncQueue.isEmpty

        let passed = isApplied && versionMatch && destinationMatch && queuePurged

        return TestResult(
            name: "Test A: Higher Remote Version (v2 vs v5)",
            passed: passed,
            details: "Result: \(result), active version: v\(store.activeTrip.version), queue count: \(store.pendingQueueCount) (expected 0)."
        )
    }

    // MARK: - Test B: Lower Remote Version (v5 vs v2 -> Retained & Queue Untouched)
    private func testB_LowerRemoteVersion() async -> TestResult {
        let store = TripStore.shared
        store.resetStoreWithFreshSample()

        // Set local trip to version 5
        store.activeTrip.version = 5
        store.activeTrip.destination = "Local Version 5 Sanctuary"

        // Enqueue queue item with version 5
        let queueItem = SyncQueueItem(tripID: store.activeTrip.id, mutationReason: "local_v5_mut", tripVersion: 5)
        store.enqueueSyncItem(queueItem)

        // Create remote trip at version 2
        let remoteTrip = Trip.createSampleTrip(id: store.activeTrip.id)
        remoteTrip.version = 2
        remoteTrip.destination = "Stale Remote v2"

        let result = store.reconcileRemoteTrip(remoteTrip)

        let isRetained: Bool
        if case .retainedLocal = result { isRetained = true } else { isRetained = false }

        let versionMatch = (store.activeTrip.version == 5)
        let destinationMatch = (store.activeTrip.destination == "Local Version 5 Sanctuary")
        let queueIntact = (store.pendingQueueCount == 1)

        let passed = isRetained && versionMatch && destinationMatch && queueIntact

        return TestResult(
            name: "Test B: Lower Remote Version (v5 vs v2)",
            passed: passed,
            details: "Result: \(result), active version: v\(store.activeTrip.version), queue count: \(store.pendingQueueCount) (expected 1)."
        )
    }

    // MARK: - Test C: Equal Version, Newer Remote Timestamp -> Applied
    private func testC_EqualVersionNewerRemoteTimestamp() async -> TestResult {
        let store = TripStore.shared
        store.resetStoreWithFreshSample()

        let baseDate = Date()
        store.activeTrip.version = 3
        store.activeTrip.updatedAt = baseDate.addingTimeInterval(-100) // 100s older

        let remoteTrip = Trip.createSampleTrip(id: store.activeTrip.id)
        remoteTrip.version = 3
        remoteTrip.updatedAt = baseDate // Newer timestamp
        remoteTrip.destination = "Tie-Break Remote Winner"

        let result = store.reconcileRemoteTrip(remoteTrip)

        let isApplied: Bool
        if case .appliedRemote = result { isApplied = true } else { isApplied = false }

        let destinationMatch = (store.activeTrip.destination == "Tie-Break Remote Winner")

        let passed = isApplied && destinationMatch

        return TestResult(
            name: "Test C: Equal Version, Newer Remote Timestamp",
            passed: passed,
            details: "Result: \(result), active destination: '\(store.activeTrip.destination)'."
        )
    }

    // MARK: - Test D: Equal Version, Older/Equal Remote Timestamp -> Retained
    private func testD_EqualVersionOlderRemoteTimestamp() async -> TestResult {
        let store = TripStore.shared
        store.resetStoreWithFreshSample()

        let baseDate = Date()
        store.activeTrip.version = 3
        store.activeTrip.updatedAt = baseDate
        store.activeTrip.destination = "Local Timestamp Champion"

        let remoteTrip = Trip.createSampleTrip(id: store.activeTrip.id)
        remoteTrip.version = 3
        remoteTrip.updatedAt = baseDate.addingTimeInterval(-100) // Older timestamp
        remoteTrip.destination = "Stale Timestamp Challenger"

        let result = store.reconcileRemoteTrip(remoteTrip)

        let isRetained: Bool
        if case .retainedLocal = result { isRetained = true } else { isRetained = false }

        let destinationMatch = (store.activeTrip.destination == "Local Timestamp Champion")

        let passed = isRetained && destinationMatch

        return TestResult(
            name: "Test D: Equal Version, Older/Equal Remote Timestamp",
            passed: passed,
            details: "Result: \(result), active destination: '\(store.activeTrip.destination)'."
        )
    }

    // MARK: - Test E: Day & Item Idempotency (No Duplicate IDs)
    private func testE_DayAndItemIdempotency() async -> TestResult {
        let store = TripStore.shared
        store.resetStoreWithFreshSample()

        // Create remote trip with unique day and item IDs
        var remoteTrip = Trip.createSampleTrip()
        remoteTrip.version = 10

        let result = store.reconcileRemoteTrip(remoteTrip)

        let dayIDs = store.activeTrip.days.map(\.id)
        let uniqueDayIDs = Set(dayIDs)
        let noDuplicateDays = (dayIDs.count == uniqueDayIDs.count)

        let allItemIDs = store.activeTrip.days.flatMap { $0.items.map(\.id) }
        let uniqueItemIDs = Set(allItemIDs)
        let noDuplicateItems = (allItemIDs.count == uniqueItemIDs.count)

        let passed = result.isAppliedRemote && noDuplicateDays && noDuplicateItems

        return TestResult(
            name: "Test E: Day & Item Idempotency",
            passed: passed,
            details: "Total days: \(dayIDs.count) (unique: \(uniqueDayIDs.count)), total items: \(allItemIDs.count) (unique: \(uniqueItemIDs.count))."
        )
    }
}

private extension ReconciliationResult {
    var isAppliedRemote: Bool {
        if case .appliedRemote = self { return true }
        return false
    }
}
