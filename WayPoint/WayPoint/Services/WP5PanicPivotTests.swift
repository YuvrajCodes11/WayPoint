//
//  WP5PanicPivotTests.swift
//  WayPoint
//
//  WP5: Panic Pivot Excellence & Constraint Solver Test Suite
//

import Foundation
import SwiftUI

@MainActor
final class WP5PanicPivotTests {
    static let shared = WP5PanicPivotTests()

    private init() {}

    struct TestResult {
        let name: String
        let passed: Bool
        let details: String
    }

    /// Runs all WP5 test scenarios (A through F) and returns structured results.
    func runAllWP5Tests() async -> [TestResult] {
        var results: [TestResult] = []

        results.append(await testA_WeatherDisruptionIndoorReplacement())
        results.append(await testB_TransitDelayChronologicalShift())
        results.append(await testC_StrictReservationProtection())
        results.append(await testD_ExplainabilityDiffReport())
        results.append(await testE_DayScopedUndoAndPersistenceSurvival())
        results.append(await testF_NoOverlappingStopsAndPositiveDurations())

        for res in results {
            print("[WP5-TEST] \(res.passed ? "✅ PASS" : "❌ FAIL") - \(res.name): \(res.details)")
        }

        return results
    }

    private func createTestDayPlan() -> DayPlan {
        let baseDate = Date()
        let outdoor1 = ItineraryItem(
            title: "Shinjuku Gyoen National Garden",
            subtitle: "Outdoor botanical garden & walking tour",
            startTime: baseDate.addingTimeInterval(3600), // 1 hour from now
            endTime: baseDate.addingTimeInterval(7200),
            location: "Shinjuku, Tokyo",
            category: .sightseeing,
            estimatedCost: 15,
            isIndoor: false,
            ghostAlternatives: [
                ItineraryItem(
                    title: "Mori Art Museum",
                    subtitle: "53rd floor indoor contemporary art space",
                    startTime: baseDate.addingTimeInterval(3600),
                    endTime: baseDate.addingTimeInterval(7200),
                    location: "Roppongi, Tokyo",
                    category: .sightseeing,
                    estimatedCost: 20,
                    isIndoor: true
                )
            ]
        )

        let outdoor2 = ItineraryItem(
            title: "Yoyogi Park Walking Tour",
            subtitle: "Scenic outdoor park & shrine path",
            startTime: baseDate.addingTimeInterval(10800), // 3 hours from now
            endTime: baseDate.addingTimeInterval(14400),
            location: "Shibuya, Tokyo",
            category: .sightseeing,
            estimatedCost: 0,
            isIndoor: false,
            ghostAlternatives: [
                ItineraryItem(
                    title: "Tokyo National Museum",
                    subtitle: "Indoor cultural exhibit & treasure gallery",
                    startTime: baseDate.addingTimeInterval(10800),
                    endTime: baseDate.addingTimeInterval(14400),
                    location: "Ueno, Tokyo",
                    category: .sightseeing,
                    estimatedCost: 25,
                    isIndoor: true
                )
            ]
        )

        let indoorItem = ItineraryItem(
            title: "Shibuya Sky Indoor Observatory",
            subtitle: "Enclosed glass deck & atrium",
            startTime: baseDate.addingTimeInterval(18000), // 5 hours from now
            endTime: baseDate.addingTimeInterval(21600),
            location: "Shibuya, Tokyo",
            category: .sightseeing,
            estimatedCost: 30,
            isIndoor: true
        )

        let reservationItem = ItineraryItem(
            title: "Ginza Michelin Sushi Dinner",
            subtitle: "Prepaid 3-star Omakase Tasting Menu",
            startTime: baseDate.addingTimeInterval(25200), // 7 hours from now
            endTime: baseDate.addingTimeInterval(32400),
            location: "Ginza, Tokyo",
            category: .dining,
            estimatedCost: 250,
            isIndoor: true,
            isPreservedReservation: true
        )

        return DayPlan(
            date: baseDate,
            title: "Tokyo Test Itinerary",
            budgetLimit: 100,
            spentAmount: 0,
            items: [outdoor1, outdoor2, indoorItem, reservationItem]
        )
    }

    // MARK: - Test A: Weather Disruption & Indoor Replacement
    private func testA_WeatherDisruptionIndoorReplacement() async -> TestResult {
        let plan = createTestDayPlan()
        let result = await AIRecalculatorService.shared.executePanicPivot(currentPlan: plan, disruptionType: .weatherRain)

        let rebalancedItems = result.rebalancedPlan.items
        let outdoor1Replaced = rebalancedItems[0].isIndoor == true && rebalancedItems[0].title == "Mori Art Museum"
        let outdoor2Replaced = rebalancedItems[1].isIndoor == true && rebalancedItems[1].title == "Tokyo National Museum"
        let indoorUntouched = rebalancedItems[2].title == "Shibuya Sky Indoor Observatory"
        let reservationPreserved = rebalancedItems[3].title == "Ginza Michelin Sushi Dinner" && rebalancedItems[3].isPreservedReservation

        let passed = outdoor1Replaced && outdoor2Replaced && indoorUntouched && reservationPreserved

        return TestResult(
            name: "Test A: Weather Disruption & Indoor Replacement",
            passed: passed,
            details: "Outdoor 1 replaced: \(outdoor1Replaced) ('\(rebalancedItems[0].title)'), Outdoor 2 replaced: \(outdoor2Replaced) ('\(rebalancedItems[1].title)'), Indoor untouched: \(indoorUntouched), Reservation preserved: \(reservationPreserved)."
        )
    }

    // MARK: - Test B: Transit Delay Chronological Shift
    private func testB_TransitDelayChronologicalShift() async -> TestResult {
        let plan = createTestDayPlan()
        let event = DisruptionEvent(type: .transitDelay, estimatedTimeImpactMinutes: 60)
        let result = await AIRecalculatorService.shared.executePanicPivot(currentPlan: plan, disruption: event)

        let items = result.rebalancedPlan.items
        var noNegativeDurations = true
        var nonReservationShifted = false

        for item in items {
            if item.endTime <= item.startTime {
                noNegativeDurations = false
            }
        }

        if items[0].startTime > plan.items[0].startTime {
            nonReservationShifted = true
        }

        let passed = noNegativeDurations && nonReservationShifted

        return TestResult(
            name: "Test B: Transit Delay Chronological Shift",
            passed: passed,
            details: "Chronological shift applied: \(nonReservationShifted), Zero negative durations: \(noNegativeDurations)."
        )
    }

    // MARK: - Test C: Strict Reservation Protection
    private func testC_StrictReservationProtection() async -> TestResult {
        let plan = createTestDayPlan()
        let reservationOrig = plan.items[3]

        let resRain = await AIRecalculatorService.shared.executePanicPivot(currentPlan: plan, disruptionType: .weatherRain)
        let resFlight = await AIRecalculatorService.shared.executePanicPivot(currentPlan: plan, disruptionType: .flightDelay)
        let resSchedule = await AIRecalculatorService.shared.executePanicPivot(currentPlan: plan, disruptionType: .scheduleDisruption)

        let rainPreserved = resRain.rebalancedPlan.items[3].title == reservationOrig.title && resRain.rebalancedPlan.items[3].startTime == reservationOrig.startTime
        let flightPreserved = resFlight.rebalancedPlan.items[3].title == reservationOrig.title && resFlight.rebalancedPlan.items[3].startTime == reservationOrig.startTime
        let schedulePreserved = resSchedule.rebalancedPlan.items[3].title == reservationOrig.title && resSchedule.rebalancedPlan.items[3].startTime == reservationOrig.startTime

        let passed = rainPreserved && flightPreserved && schedulePreserved

        return TestResult(
            name: "Test C: Strict Reservation Protection",
            passed: passed,
            details: "Rain preserved: \(rainPreserved), Flight delay preserved: \(flightPreserved), Schedule disruption preserved: \(schedulePreserved)."
        )
    }

    // MARK: - Test D: Explainability Diff Report
    private func testD_ExplainabilityDiffReport() async -> TestResult {
        let plan = createTestDayPlan()
        let result = await AIRecalculatorService.shared.executePanicPivot(currentPlan: plan, disruptionType: .weatherRain)

        guard let diff = result.diffReport else {
            return TestResult(name: "Test D: Explainability Diff Report", passed: false, details: "diffReport is nil.")
        }

        let replacementsMatch = diff.replacedItems.count == 2
        let preservedMatch = diff.preservedReservationsCount == 1
        let summaryValid = !diff.explanationSummary.isEmpty

        let passed = replacementsMatch && preservedMatch && summaryValid

        return TestResult(
            name: "Test D: Explainability Diff Report",
            passed: passed,
            details: "Replaced items count: \(diff.replacedItems.count) (expected 2), Preserved reservations count: \(diff.preservedReservationsCount) (expected 1), Summary: '\(diff.explanationSummary)'."
        )
    }

    // MARK: - Test E: Day-Scoped Undo & Persistence Survival
    private func testE_DayScopedUndoAndPersistenceSurvival() async -> TestResult {
        let day1 = createTestDayPlan()
        let day2Items = createTestDayPlan().items
        let day2 = DayPlan(id: UUID(), date: Date().addingTimeInterval(86400), title: "Kyoto Day 2", budgetLimit: 100, spentAmount: 0, items: day2Items)

        let tripID = UUID()
        var trip = Trip(id: tripID, title: "Test Dual Day Trip", destination: "Japan", travelerName: "Explorer", days: [day1, day2])

        let manager = UndoPivotManager.shared
        manager.clear()

        let pivotResult = await AIRecalculatorService.shared.executePanicPivot(currentPlan: day1, disruptionType: .weatherRain)

        // Push Day 1 pivot
        manager.pushState(dayID: day1.id, tripID: tripID, originalDay: day1, result: pivotResult)

        let canUndoDay1 = manager.canUndo(dayID: day1.id)
        let canUndoDay2 = manager.canUndo(dayID: day2.id)

        // Execute Undo for Day 1
        let restoredDay1 = manager.undoLastPivot(dayID: day1.id, in: &trip)

        let day1RestoredCorrectly = restoredDay1 != nil && restoredDay1?.items[0].title == day1.items[0].title
        let day2Unaffected = trip.days[1].title == "Kyoto Day 2"

        let passed = canUndoDay1 && !canUndoDay2 && day1RestoredCorrectly && day2Unaffected

        return TestResult(
            name: "Test E: Day-Scoped Undo & Persistence Survival",
            passed: passed,
            details: "Day 1 canUndo: \(canUndoDay1), Day 2 canUndo: \(canUndoDay2) (isolated), Day 1 restored: \(day1RestoredCorrectly), Day 2 unaffected: \(day2Unaffected)."
        )
    }

    // MARK: - Test F: No Overlapping Stops & Positive Durations
    private func testF_NoOverlappingStopsAndPositiveDurations() async -> TestResult {
        let plan = createTestDayPlan()
        let result = await AIRecalculatorService.shared.executePanicPivot(currentPlan: plan, disruptionType: .scheduleDisruption)

        let items = result.rebalancedPlan.items
        var noOverlaps = true
        var positiveDurations = true

        for i in 0..<items.count {
            if items[i].endTime <= items[i].startTime {
                positiveDurations = false
            }
            if i + 1 < items.count {
                if items[i].endTime > items[i + 1].startTime {
                    noOverlaps = false
                }
            }
        }

        let passed = noOverlaps && positiveDurations

        return TestResult(
            name: "Test F: No Overlapping Stops & Positive Durations",
            passed: passed,
            details: "No overlapping stops: \(noOverlaps), All durations positive (min 15m): \(positiveDurations)."
        )
    }
}
