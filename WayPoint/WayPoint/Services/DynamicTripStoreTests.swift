//
//  DynamicTripStoreTests.swift
//  WayPoint
//

import Foundation

@MainActor
public struct DynamicTripStoreTests {
    public static func runAllTests() {
        print("=== Running Dynamic TripStore Suite (Phase 1) ===")
        testCreateDynamicTrip()
        testAddStopToDynamicTrip()
        testClearDynamicTrip()
        print("✅ Dynamic TripStore Suite Passed!")
    }

    private static func testCreateDynamicTrip() {
        let store = TripStore.shared
        store.clearCurrentTrip()
        assert(store.currentTrip == nil, "Current trip should be nil after clear")

        let startDate = Date()
        let endDate = startDate.addingTimeInterval(86400 * 3) // 3 days
        let budget = BudgetAllocation(total: 1000.0, currencyCode: "USD")

        store.createTrip(
            origin: "SFO",
            destination: "NRT",
            type: .roundTrip,
            startDate: startDate,
            endDate: endDate,
            budget: budget
        )

        guard let trip = store.currentTrip else {
            fatalError("Failed: currentTrip is nil after createTrip")
        }

        assert(trip.origin == "SFO", "Origin mismatch")
        assert(trip.destination == "NRT", "Destination mismatch")
        assert(trip.type == .roundTrip, "Type mismatch")
        assert(trip.budget.total == 1000.0, "Budget total mismatch")
        assert(trip.budget.transitLimit == 250.0, "Transit limit mismatch")
        assert(trip.budget.stayLimit == 450.0, "Stay limit mismatch")
        assert(trip.budget.dailyFoodLimit == 200.0, "Daily food limit mismatch")
        assert(trip.days.count >= 3, "Day plan count mismatch: expected at least 3, got \(trip.days.count)")

        print("  - testCreateDynamicTrip passed")
    }

    private static func testAddStopToDynamicTrip() {
        let store = TripStore.shared
        guard store.currentTrip != nil else {
            fatalError("Failed: expected active dynamic trip")
        }

        let stop = TripStop(
            title: "Tokyo Skytree",
            type: .activity,
            scheduledTime: Date(),
            durationMinutes: 90,
            estimatedCost: 35.0,
            isHardReservation: true,
            bookingReference: "TK-9921",
            notes: "Sunset view tickets"
        )

        store.addStop(to: 0, stop: stop)

        guard let trip = store.currentTrip, !trip.days.isEmpty else {
            fatalError("Failed: currentTrip days empty")
        }

        assert(trip.days[0].stops.count == 1, "Stop was not added to day 0")
        let addedStop = trip.days[0].stops[0]
        assert(addedStop.title == "Tokyo Skytree", "Stop title mismatch")
        assert(addedStop.type == .activity, "Stop type mismatch")
        assert(addedStop.isHardReservation == true, "Reservation flag mismatch")
        assert(addedStop.bookingReference == "TK-9921", "Booking ref mismatch")

        print("  - testAddStopToDynamicTrip passed")
    }

    private static func testClearDynamicTrip() {
        let store = TripStore.shared
        store.clearCurrentTrip()
        assert(store.currentTrip == nil, "Clear current trip failed")
        print("  - testClearDynamicTrip passed")
    }
}
