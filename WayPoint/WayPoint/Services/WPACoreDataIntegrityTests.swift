//
//  WPACoreDataIntegrityTests.swift
//  WayPoint
//
//  WP-A — Core Data Integrity End-to-End Automated Test Harness
//

import Foundation
import SwiftUI

@MainActor
final class WPACoreDataIntegrityTests {
    static let shared = WPACoreDataIntegrityTests()

    private init() {}

    struct TestResult {
        let name: String
        let passed: Bool
        let details: String
    }

    /// Runs all WP-A test scenarios (Tests A - E) sequentially and returns structured results.
    @discardableResult
    func runAllWPATests() async -> [TestResult] {
        print("\n==================================================")
        print("[WPA-TEST] 🚀 Launching WP-A Core Data Integrity Test Harness")
        print("==================================================\n")

        var results: [TestResult] = []

        results.append(await testA_BoundedQueueCapacityAndFIFOPruning())
        results.append(await testB_MutationDeduplication())
        results.append(await testC_CorruptDiskDataArchivalAndFallback())
        results.append(await testD_ConflictVersionAndTimestampReconciliation())
        results.append(await testE_DayAndItemEntityIdempotency())

        var passCount = 0
        for res in results {
            if res.passed { passCount += 1 }
            print("[WPA-TEST] \(res.passed ? "✅ PASS" : "❌ FAIL") - \(res.name): \(res.details)")
        }

        print("--------------------------------------------------")
        print("[WPA-TEST] \(passCount == results.count ? "✅ PASS" : "❌ FAIL") - Summary: \(passCount)/\(results.count) WP-A Core Data Integrity Tests Passed.")
        print("==================================================\n")

        return results
    }

    // MARK: - Test A: Bounded Queue Capacity & FIFO Pruning
    private func testA_BoundedQueueCapacityAndFIFOPruning() async -> TestResult {
        let store = TripStore.shared
        store.clearPendingQueue()

        let baseTripID = UUID()
        let now = Date()

        for i in 1...150 {
            // Space timestamps by 2.0s to avoid 1.0s deduplication
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

        // Oldest 50 items (v1...v50) dropped; newest 100 (v51...v150) preserved in strict FIFO order
        let countMatch = (count == 100)
        let fifoStartMatch = (firstVersion == 51)
        let fifoEndMatch = (lastVersion == 150)
        let passed = countMatch && fifoStartMatch && fifoEndMatch

        return TestResult(
            name: "Test A (Bounded Queue Capacity & FIFO Pruning)",
            passed: passed,
            details: "Enqueued 150 items. Queue count: \(count) (expected 100). First version: v\(firstVersion) (expected 51), Last version: v\(lastVersion) (expected 150)."
        )
    }

    // MARK: - Test B: Mutation Deduplication
    private func testB_MutationDeduplication() async -> TestResult {
        let store = TripStore.shared
        store.clearPendingQueue()

        let tripID = UUID()
        let now = Date()

        // 1. Initial item
        let item1 = SyncQueueItem(tripID: tripID, mutationReason: "day_selection", timestamp: now, tripVersion: 1)
        store.enqueueSyncItem(item1)
        let count1 = store.pendingQueueCount

        // 2. Rapid duplicate mutation (same tripID + mutationReason within 0.5s <= 1.0s) -> SUPPRESSED
        let duplicateItem = SyncQueueItem(tripID: tripID, mutationReason: "day_selection", timestamp: now.addingTimeInterval(0.5), tripVersion: 2)
        store.enqueueSyncItem(duplicateItem)
        let countAfterDup = store.pendingQueueCount

        // 3. Distinct mutation reason within 0.5s -> ENQUEUED
        let distinctReasonItem = SyncQueueItem(tripID: tripID, mutationReason: "panic_pivot", timestamp: now.addingTimeInterval(0.6), tripVersion: 3)
        store.enqueueSyncItem(distinctReasonItem)
        let countAfterDistinct = store.pendingQueueCount

        // 4. Same mutation reason after >1.0s (2.5s) -> ENQUEUED
        let delayedItem = SyncQueueItem(tripID: tripID, mutationReason: "day_selection", timestamp: now.addingTimeInterval(2.5), tripVersion: 4)
        store.enqueueSyncItem(delayedItem)
        let countAfterDelay = store.pendingQueueCount

        let passed = (count1 == 1) &&
                     (countAfterDup == 1) &&       // Deduplicated!
                     (countAfterDistinct == 2) &&  // Distinct reason enqueued!
                     (countAfterDelay == 3)        // Delayed enqueued!

        return TestResult(
            name: "Test B (Mutation Deduplication)",
            passed: passed,
            details: "Count initial: \(count1), post-duplicate (<=1s): \(countAfterDup) (suppressed), post-distinct reason: \(countAfterDistinct), post->1s delay: \(countAfterDelay)."
        )
    }

    // MARK: - Test C: Corrupt Disk Data Archival & Fallback
    private func testC_CorruptDiskDataArchivalAndFallback() async -> TestResult {
        let store = TripStore.shared
        let corruptTripBytes = Data("MALFORMED_CORRUPTED_TRIP_BYTES_WP_A".utf8)
        let corruptBookingBytes = Data("MALFORMED_CORRUPTED_BOOKING_BYTES_WP_A".utf8)

        // Inject raw corrupted non-JSON bytes into disk keys
        UserDefaults.standard.set(corruptTripBytes, forKey: "waypoint_persisted_trip_data_v2")
        UserDefaults.standard.set(corruptBookingBytes, forKey: "waypoint_user_bookings_v1")

        // Reload store from disk
        store.reloadFromDisk()

        // Verify corrupted data archived to backup keys
        let tripBackup = UserDefaults.standard.data(forKey: "waypoint_persisted_trip_data_v2_corrupted_backup")
        let bookingBackup = UserDefaults.standard.data(forKey: "waypoint_user_bookings_v1_corrupted_backup")

        let tripArchived = (tripBackup == corruptTripBytes)
        let bookingArchived = (bookingBackup == corruptBookingBytes)
        let hasRecovered = store.hasRecoveredFromCorruptedTrip
        let activeTripSeeded = !store.activeTrip.title.isEmpty

        let passed = tripArchived && bookingArchived && hasRecovered && activeTripSeeded

        // Clean up store state
        store.resetStoreWithFreshSample()

        return TestResult(
            name: "Test C (Corrupt Disk Data Archival & Fallback)",
            passed: passed,
            details: "Trip backup archived: \(tripArchived), Booking backup archived: \(bookingArchived), hasRecoveredFromCorruptedTrip: \(hasRecovered), active trip title: '\(store.activeTrip.title)'."
        )
    }

    // MARK: - Test D: Conflict Version & Timestamp Reconciliation
    private func testD_ConflictVersionAndTimestampReconciliation() async -> TestResult {
        let store = TripStore.shared
        store.resetStoreWithFreshSample()

        // Scenario D1: Higher Remote Version adoption
        store.activeTrip.version = 2
        let remoteHigher = Trip.createSampleTrip(id: store.activeTrip.id)
        remoteHigher.version = 5
        remoteHigher.destination = "Remote v5 Adopted"

        let resHigher = store.reconcileRemoteTrip(remoteHigher)
        let isHigherAdopted: Bool
        if case .appliedRemote = resHigher { isHigherAdopted = true } else { isHigherAdopted = false }

        // Scenario D2: Lower Remote Version retention
        store.activeTrip.version = 5
        store.activeTrip.destination = "Local v5 Retained"
        let remoteLower = Trip.createSampleTrip(id: store.activeTrip.id)
        remoteLower.version = 2
        remoteLower.destination = "Remote v2 Stale"

        let resLower = store.reconcileRemoteTrip(remoteLower)
        let isLowerRetained: Bool
        if case .retainedLocal = resLower { isLowerRetained = true } else { isLowerRetained = false }

        // Scenario D3: Equal Version, Newer Remote Timestamp tie-breaking
        let baseDate = Date()
        store.activeTrip.version = 4
        store.activeTrip.updatedAt = baseDate.addingTimeInterval(-60)
        let remoteNewerTime = Trip.createSampleTrip(id: store.activeTrip.id)
        remoteNewerTime.version = 4
        remoteNewerTime.updatedAt = baseDate
        remoteNewerTime.destination = "TieBreak Remote Newer"

        let resTime = store.reconcileRemoteTrip(remoteNewerTime)
        let isNewerTimestampAdopted: Bool
        if case .appliedRemote = resTime { isNewerTimestampAdopted = true } else { isNewerTimestampAdopted = false }

        let passed = isHigherAdopted && isLowerRetained && isNewerTimestampAdopted

        return TestResult(
            name: "Test D (Conflict Version & Timestamp Reconciliation)",
            passed: passed,
            details: "Higher remote adoption (v5>v2): \(isHigherAdopted), Lower remote retention (v2<v5): \(isLowerRetained), Equal version newer timestamp adoption: \(isNewerTimestampAdopted)."
        )
    }

    // MARK: - Test E: Day & Item Idempotency
    private func testE_DayAndItemEntityIdempotency() async -> TestResult {
        let store = TripStore.shared
        store.resetStoreWithFreshSample()

        let remoteTrip = Trip.createSampleTrip()
        remoteTrip.version = 10

        let res = store.reconcileRemoteTrip(remoteTrip)

        let isApplied: Bool
        if case .appliedRemote = res { isApplied = true } else { isApplied = false }

        let uniqueEntities = store.activeTrip.hasUniqueEntityIDs
        let dayCount = store.activeTrip.days.count
        let itemCount = store.activeTrip.days.flatMap(\.items).count

        let passed = isApplied && uniqueEntities

        return TestResult(
            name: "Test E (Day & Item Idempotency)",
            passed: passed,
            details: "Reconciliation applied: \(isApplied), unique entity IDs across \(dayCount) day(s) and \(itemCount) item(s): \(uniqueEntities)."
        )
    }
}
