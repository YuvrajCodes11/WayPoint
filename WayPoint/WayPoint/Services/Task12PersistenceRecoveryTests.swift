//
//  Task12PersistenceRecoveryTests.swift
//  WayPoint
//
//  Task 1.2: Persistence & Recovery Hardening Automated Test Suite
//

import Foundation
import SwiftUI

@MainActor
final class Task12PersistenceRecoveryTests {
    static let shared = Task12PersistenceRecoveryTests()

    private init() {}

    struct TestResult {
        let name: String
        let passed: Bool
        let details: String
    }

    /// Runs all Task 1.2 test scenarios (A, B, C, D) and returns structured results.
    func runAllTask12Tests() async -> [TestResult] {
        var results: [TestResult] = []

        results.append(await testA_ValidSaveAndReload())
        results.append(await testB_CorruptedTripRecovery())
        results.append(await testC_CorruptedBookingsRecovery())
        results.append(await testD_ResetWithFreshSample())

        for res in results {
            print("[TASK-1.2-TEST] \(res.passed ? "✅ PASS" : "❌ FAIL") - \(res.name): \(res.details)")
        }

        return results
    }

    // MARK: - Test A: Valid Trip & Bookings Save -> Reload
    private func testA_ValidSaveAndReload() async -> TestResult {
        let store = TripStore.shared
        store.resetStoreWithFreshSample()

        store.mutate("test_A_mutation") { trip in
            trip.destination = "Tokyo Tech Hub"
        }

        store.savePersistedTrip()
        store.saveBookings()
        let lastPersisted = store.lastPersistedAt

        store.reloadFromDisk()

        let passed = (store.hasRecoveredFromCorruptedTrip == false) &&
                     (store.activeTrip.destination == "Tokyo Tech Hub") &&
                     (lastPersisted != nil)

        return TestResult(
            name: "Test A: Valid Trip & Bookings Save -> Reload",
            passed: passed,
            details: "Destination: '\(store.activeTrip.destination)', hasRecoveredFromCorruptedTrip: \(store.hasRecoveredFromCorruptedTrip), lastPersistedAt: \(String(describing: lastPersisted))."
        )
    }

    // MARK: - Test B: Corrupt Trip Bytes -> Backup & Graceful Recovery
    private func testB_CorruptedTripRecovery() async -> TestResult {
        let store = TripStore.shared
        let corruptedTripBytes = Data("CORRUPTED_NON_JSON_TRIP_PAYLOAD_V2".utf8)

        // Inject raw non-JSON bytes into main trip storage key
        UserDefaults.standard.set(corruptedTripBytes, forKey: "waypoint_persisted_trip_data_v2")

        store.reloadFromDisk()

        let backupData = UserDefaults.standard.data(forKey: "waypoint_persisted_trip_data_v2_corrupted_backup")
        let backupPreserved = (backupData == corruptedTripBytes)
        let recoveredFlag = store.hasRecoveredFromCorruptedTrip
        let validTripSeeded = !store.activeTrip.title.isEmpty

        let passed = backupPreserved && recoveredFlag && validTripSeeded

        return TestResult(
            name: "Test B: Corrupted Trip Backup & Recovery",
            passed: passed,
            details: "Backup key preserved: \(backupPreserved), hasRecoveredFromCorruptedTrip: \(recoveredFlag), active trip seeded title: '\(store.activeTrip.title)'."
        )
    }

    // MARK: - Test C: Corrupt Bookings Bytes -> Backup & Empty Array Fallback
    private func testC_CorruptedBookingsRecovery() async -> TestResult {
        let store = TripStore.shared
        let corruptedBookingBytes = Data("CORRUPTED_NON_JSON_BOOKINGS_PAYLOAD_V1".utf8)

        // Inject raw non-JSON bytes into bookings storage key
        UserDefaults.standard.set(corruptedBookingBytes, forKey: "waypoint_user_bookings_v1")

        store.reloadFromDisk()

        let backupData = UserDefaults.standard.data(forKey: "waypoint_user_bookings_v1_corrupted_backup")
        let backupPreserved = (backupData == corruptedBookingBytes)
        let bookingsEmpty = store.userBookings.isEmpty

        let passed = backupPreserved && bookingsEmpty

        return TestResult(
            name: "Test C: Corrupted Bookings Backup & Empty Array Fallback",
            passed: passed,
            details: "Backup key preserved: \(backupPreserved), userBookings count: \(store.userBookings.count) (expected 0)."
        )
    }

    // MARK: - Test D: Reset Store with Fresh Sample
    private func testD_ResetWithFreshSample() async -> TestResult {
        let store = TripStore.shared

        store.resetStoreWithFreshSample()

        let hasRecovered = store.hasRecoveredFromCorruptedTrip
        let lastPersisted = store.lastPersistedAt
        let daysCount = store.activeTrip.days.count
        let queueCount = store.pendingQueueCount
        let bookingsCount = store.userBookings.count

        let passed = (hasRecovered == false) &&
                     (lastPersisted != nil) &&
                     (daysCount == 3) &&
                     (queueCount == 0) &&
                     (bookingsCount > 0)

        return TestResult(
            name: "Test D: Reset Store with Fresh Sample",
            passed: passed,
            details: "hasRecovered: \(hasRecovered), daysCount: \(daysCount), queueCount: \(queueCount), bookingsCount: \(bookingsCount), lastPersistedAt: \(String(describing: lastPersisted))."
        )
    }
}
