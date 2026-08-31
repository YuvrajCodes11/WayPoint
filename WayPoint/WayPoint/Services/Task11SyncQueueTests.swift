//
//  Task11SyncQueueTests.swift
//  WayPoint
//
//  Task 1.1: Sync Queue Hardening & Bounded Capacity Verification Suite
//

import Foundation
import SwiftUI

@MainActor
final class Task11SyncQueueTests {
    static let shared = Task11SyncQueueTests()

    private init() {}

    struct TestResult {
        let name: String
        let passed: Bool
        let details: String
    }

    /// Runs all Task 1.1 test scenarios (A, B, C, D, E) and returns structured results.
    func runAllTask11Tests() async -> [TestResult] {
        var results: [TestResult] = []

        results.append(await testA_Capacity())
        results.append(await testB_Deduplication())
        results.append(await testC_Persistence())
        results.append(await testD_BoundaryBehavior())
        results.append(await testE_Clear())

        for res in results {
            print("[TASK-1.1-TEST] \(res.passed ? "✅ PASS" : "❌ FAIL") - \(res.name): \(res.details)")
        }

        return results
    }

    // MARK: - Test A: Capacity (150 items -> max 100 FIFO)
    private func testA_Capacity() async -> TestResult {
        let store = TripStore.shared
        store.clearPendingQueue()

        let baseTripID = UUID()
        let now = Date()

        for i in 1...150 {
            // Space timestamps by 2.0s to avoid deduplication
            let timestamp = now.addingTimeInterval(Double(i) * 2.0)
            let item = SyncQueueItem(
                tripID: baseTripID,
                mutationReason: "mutation_\(i)",
                timestamp: timestamp,
                tripVersion: i
            )
            store.enqueueSyncItem(item)
        }

        let count = store.pendingQueueCount
        let firstVersion = store.syncQueue.first?.tripVersion ?? 0
        let lastVersion = store.syncQueue.last?.tripVersion ?? 0

        // Oldest 50 (1...50) should be pruned; newest 100 (51...150) remain in FIFO order
        let passed = (count == 100) && (firstVersion == 51) && (lastVersion == 150)

        return TestResult(
            name: "Test A: Bounded Capacity (150 -> 100 FIFO)",
            passed: passed,
            details: "Enqueued 150 items. Final count: \(count) (expected 100). First version: v\(firstVersion) (expected 51), Last version: v\(lastVersion) (expected 150)."
        )
    }

    // MARK: - Test B: Deduplication (Same tripID + reason <= 1s)
    private func testB_Deduplication() async -> TestResult {
        let store = TripStore.shared
        store.clearPendingQueue()

        let tripID = UUID()
        let now = Date()

        let item1 = SyncQueueItem(tripID: tripID, mutationReason: "day selection", timestamp: now, tripVersion: 1)
        store.enqueueSyncItem(item1)
        let countAfter1 = store.pendingQueueCount

        // Duplicate mutation within 0.5s (same tripID & reason)
        let duplicateItem = SyncQueueItem(tripID: tripID, mutationReason: "day selection", timestamp: now.addingTimeInterval(0.5), tripVersion: 2)
        store.enqueueSyncItem(duplicateItem)
        let countAfterDuplicate = store.pendingQueueCount

        // Unrelated mutation: different reason within 0.5s
        let differentReasonItem = SyncQueueItem(tripID: tripID, mutationReason: "panic pivot", timestamp: now.addingTimeInterval(0.6), tripVersion: 3)
        store.enqueueSyncItem(differentReasonItem)
        let countAfterDifferentReason = store.pendingQueueCount

        // Unrelated mutation: same reason but > 1.0s later
        let laterItem = SyncQueueItem(tripID: tripID, mutationReason: "day selection", timestamp: now.addingTimeInterval(2.5), tripVersion: 4)
        store.enqueueSyncItem(laterItem)
        let countAfterLater = store.pendingQueueCount

        let passed = (countAfter1 == 1) &&
                     (countAfterDuplicate == 1) && // Deduplicated!
                     (countAfterDifferentReason == 2) && // Not deduplicated!
                     (countAfterLater == 3) // Not deduplicated!

        return TestResult(
            name: "Test B: Deduplication (1.0s window)",
            passed: passed,
            details: "Count after initial: \(countAfter1), after duplicate <= 1s: \(countAfterDuplicate) (deduplicated), after different reason: \(countAfterDifferentReason), after >1s: \(countAfterLater)."
        )
    }

    // MARK: - Test C: Persistence (Survives store reload)
    private func testC_Persistence() async -> TestResult {
        let store = TripStore.shared
        store.clearPendingQueue()

        let tripID = UUID()
        let now = Date()

        let item1 = SyncQueueItem(tripID: tripID, mutationReason: "persist_test_1", timestamp: now, tripVersion: 10)
        let item2 = SyncQueueItem(tripID: tripID, mutationReason: "persist_test_2", timestamp: now.addingTimeInterval(2.0), tripVersion: 11)

        store.enqueueSyncItem(item1)
        store.enqueueSyncItem(item2)

        // Verify direct load from UserDefaults persistence
        guard let data = UserDefaults.standard.data(forKey: "waypoint_pending_sync_queue_v1"),
              let reloadedQueue = try? JSONDecoder().decode([SyncQueueItem].self, from: data) else {
            return TestResult(name: "Test C: Persistence", passed: false, details: "Failed to decode queue from UserDefaults.")
        }

        let passed = (reloadedQueue.count == 2) &&
                     (reloadedQueue[0].mutationReason == "persist_test_1") &&
                     (reloadedQueue[1].mutationReason == "persist_test_2")

        return TestResult(
            name: "Test C: Persistence Survival",
            passed: passed,
            details: "Enqueued 2 items. Reloaded from UserDefaults key 'waypoint_pending_sync_queue_v1': \(reloadedQueue.count) items decoded matching original reasons."
        )
    }

    // MARK: - Test D: Boundary Behavior (Exactly 100 -> item 101)
    private func testD_BoundaryBehavior() async -> TestResult {
        let store = TripStore.shared
        store.clearPendingQueue()

        let tripID = UUID()
        let now = Date()

        // Fill exactly 100 items
        for i in 1...100 {
            let item = SyncQueueItem(tripID: tripID, mutationReason: "boundary_\(i)", timestamp: now.addingTimeInterval(Double(i) * 2.0), tripVersion: i)
            store.enqueueSyncItem(item)
        }
        let countAt100 = store.pendingQueueCount
        let firstItemAt100 = store.syncQueue.first?.mutationReason

        // Enqueue item 101
        let item101 = SyncQueueItem(tripID: tripID, mutationReason: "boundary_101", timestamp: now.addingTimeInterval(300.0), tripVersion: 101)
        store.enqueueSyncItem(item101)

        let countAt101 = store.pendingQueueCount
        let newFirstItem = store.syncQueue.first?.mutationReason
        let newLastItem = store.syncQueue.last?.mutationReason

        let passed = (countAt100 == 100) &&
                     (firstItemAt100 == "boundary_1") &&
                     (countAt101 == 100) &&
                     (newFirstItem == "boundary_2") &&
                     (newLastItem == "boundary_101")

        return TestResult(
            name: "Test D: Boundary Behavior (100 -> 101 item boundary)",
            passed: passed,
            details: "Initial 100 count: \(countAt100), first item: '\(firstItemAt100 ?? "")'. After item 101: count \(countAt101), first pruned to '\(newFirstItem ?? "")', last is '\(newLastItem ?? "")'."
        )
    }

    // MARK: - Test E: Clear (clearPendingQueue)
    private func testE_Clear() async -> TestResult {
        let store = TripStore.shared
        let tripID = UUID()
        let now = Date()

        let item = SyncQueueItem(tripID: tripID, mutationReason: "clear_test", timestamp: now, tripVersion: 1)
        store.enqueueSyncItem(item)

        let preClearCount = store.pendingQueueCount
        store.clearPendingQueue()
        let postClearCount = store.pendingQueueCount

        guard let data = UserDefaults.standard.data(forKey: "waypoint_pending_sync_queue_v1"),
              let reloadedQueue = try? JSONDecoder().decode([SyncQueueItem].self, from: data) else {
            return TestResult(name: "Test E: Clear", passed: false, details: "Failed to read UserDefaults after clear.")
        }

        let passed = (preClearCount > 0) && (postClearCount == 0) && (reloadedQueue.isEmpty)

        return TestResult(
            name: "Test E: Queue Clear API",
            passed: passed,
            details: "Pre-clear count: \(preClearCount), post-clear count: \(postClearCount), persisted queue size: \(reloadedQueue.count)."
        )
    }
}
