//
//  PanicPivotEngineTests.swift
//  WayPoint
//
//  Phase 3: Automated Tests for Dynamic Panic Pivot Engine
//

import Foundation

@MainActor
public struct PanicPivotEngineTests {
    public static func runAllTests() {
        print("=== Running PanicPivotEngine Suite (Phase 3) ===")
        testSevereWeatherDisruption()
        testTransitDelayDisruption()
        testApplyPivotToStore()
        print("✅ PanicPivotEngine Suite Passed!")
    }

    private static func testSevereWeatherDisruption() {
        let engine = PanicPivotEngine.shared
        
        let stop1 = TripStop(
            title: "Yoyogi Outdoor Park Walk",
            type: .activity,
            scheduledTime: Date(),
            durationMinutes: 60,
            estimatedCost: 0.0,
            isHardReservation: false
        )
        
        let stop2 = TripStop(
            title: "Hotel Check-in Reservation",
            type: .hotel,
            scheduledTime: Date().addingTimeInterval(3600),
            durationMinutes: 30,
            estimatedCost: 200.0,
            isHardReservation: true,
            bookingReference: "HT-8812"
        )
        
        let budget = BudgetAllocation(total: 1000.0)
        let dayPlan = DynamicDayPlan(dayNumber: 1, date: Date(), stops: [stop1, stop2])
        let trip = DynamicTrip(
            origin: "SFO",
            destination: "Tokyo",
            type: .roundTrip,
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 3),
            budget: budget,
            days: [dayPlan]
        )
        
        let report = engine.evaluateDisruption(dayIndex: 0, event: DynamicDisruptionEvent.severeWeather(condition: "Heavy Rain"), trip: trip)
        
        assert(report.replacedStopsCount == 1, "Expected 1 replaced outdoor stop, got \(report.replacedStopsCount)")
        assert(report.preservedReservationsCount == 1, "Expected 1 preserved hard reservation, got \(report.preservedReservationsCount)")
        assert(report.adjustedStops.count == 2, "Adjusted stops count mismatch")
        assert(report.adjustedStops[0].title.contains("Museum") || report.adjustedStops[0].title.contains("Indoor"), "Outdoor activity was not swapped to indoor")
        assert(report.adjustedStops[1].bookingReference == "HT-8812", "Hard reservation booking ref lost")
        
        print("  - testSevereWeatherDisruption passed")
    }

    private static func testTransitDelayDisruption() {
        let engine = PanicPivotEngine.shared
        
        let now = Date()
        let stop1 = TripStop(
            title: "Shibuya Crossing Photography",
            type: .activity,
            scheduledTime: now,
            durationMinutes: 45,
            estimatedCost: 0.0,
            isHardReservation: false
        )
        
        let budget = BudgetAllocation(total: 800.0)
        let dayPlan = DynamicDayPlan(dayNumber: 1, date: now, stops: [stop1])
        let trip = DynamicTrip(
            origin: "SFO",
            destination: "Tokyo",
            type: .roundTrip,
            startDate: now,
            endDate: now.addingTimeInterval(86400 * 2),
            budget: budget,
            days: [dayPlan]
        )
        
        let report = engine.evaluateDisruption(dayIndex: 0, event: DynamicDisruptionEvent.transitDelay(minutes: 25), trip: trip)
        
        assert(report.minutesShifted == 25, "Minutes shifted mismatch")
        assert(report.adjustedStops.count == 1, "Adjusted stops count mismatch")
        let shiftedTime = report.adjustedStops[0].scheduledTime
        let diffMinutes = Int(shiftedTime.timeIntervalSince(now) / 60)
        assert(diffMinutes == 25, "Scheduled time was not shifted by +25m")
        
        print("  - testTransitDelayDisruption passed")
    }

    private static func testApplyPivotToStore() {
        let engine = PanicPivotEngine.shared
        let store = TripStore.shared
        
        store.clearCurrentTrip()
        store.createTrip(
            origin: "NYC",
            destination: "London",
            type: .roundTrip,
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 3),
            budget: BudgetAllocation(total: 1200.0)
        )
        
        let stop = TripStop(title: "Hyde Park Picnic", type: .activity, scheduledTime: Date())
        store.addStop(to: 0, stop: stop)
        
        let report = engine.evaluateDisruption(dayIndex: 0, event: DynamicDisruptionEvent.severeWeather(condition: "Storm Alert"))
        engine.applyPivot(dayIndex: 0, report: report)
        
        guard let updatedTrip = store.currentTrip else {
            fatalError("Failed: currentTrip is nil after applyPivot")
        }
        
        assert(updatedTrip.days[0].stops.count == 1, "Applied stops count mismatch")
        assert(updatedTrip.days[0].stops[0].title.contains("Indoor") || updatedTrip.days[0].stops[0].title.contains("Museum"), "Pivot report was not committed to store")
        
        print("  - testApplyPivotToStore passed")
    }
}
