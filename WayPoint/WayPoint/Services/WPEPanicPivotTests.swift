//
//  WPEPanicPivotTests.swift
//  WayPoint
//
//  WP-E — Panic Pivot & Constraint Solver End-to-End Automated Test Harness
//

import Foundation
import SwiftUI

@MainActor
final class WPEPanicPivotTests {
    static let shared = WPEPanicPivotTests()

    private init() {}

    struct TestResult {
        let name: String
        let passed: Bool
        let details: String
    }

    /// Runs all WP-E test scenarios (Tests A - F) sequentially and returns structured results.
    @discardableResult
    func runAllWPETests() async -> [TestResult] {
        print("\n==================================================")
        print("[WPE-TEST] 🚀 Launching WP-E Panic Pivot Test Harness")
        print("==================================================\n")

        var results: [TestResult] = []

        results.append(await testA_WeatherDisruptionAndIndoorReplacement())
        results.append(await testB_TransitDelayChronologicalShift())
        results.append(await testC_StrictReservationProtection())
        results.append(await testD_ExplainabilityDiffReport())
        results.append(await testE_DayScopedUndoAndPersistenceSurvival())
        results.append(await testF_NoOverlappingStopsAndPositiveDurations())

        var passCount = 0
        for res in results {
            if res.passed { passCount += 1 }
            print("[WPE-TEST] \(res.passed ? "✅ PASS" : "❌ FAIL") - \(res.name): \(res.details)")
        }

        print("--------------------------------------------------")
        print("[WPE-TEST] \(passCount == results.count ? "✅ PASS" : "❌ FAIL") - Summary: \(passCount)/\(results.count) WP-E Panic Pivot Tests Passed.")
        print("==================================================\n")

        return results
    }

    // MARK: - Test A: Weather Disruption & Indoor Replacement
    private func testA_WeatherDisruptionAndIndoorReplacement() async -> TestResult {
        let service = AIRecalculatorService.shared

        let now = Date()
        let outdoor1 = ItineraryItem(title: "Shinjuku Gyoen National Garden", subtitle: "Outdoor botanical garden", startTime: now, endTime: now.addingTimeInterval(3600), location: "Shinjuku", category: .sightseeing, estimatedCost: 15, isIndoor: false)
        let outdoor2 = ItineraryItem(title: "Meiji Jingu Shrine Grounds", subtitle: "Outdoor shrine forest walk", startTime: now.addingTimeInterval(4500), endTime: now.addingTimeInterval(8100), location: "Harajuku", category: .sightseeing, estimatedCost: 0, isIndoor: false)
        let indoor1 = ItineraryItem(title: "Mori Art Museum", subtitle: "Indoor contemporary art gallery", startTime: now.addingTimeInterval(9000), endTime: now.addingTimeInterval(12600), location: "Roppongi", category: .sightseeing, estimatedCost: 20, isIndoor: true)
        let fixedReservation = ItineraryItem(title: "Sukiyabashi Jiro Omakase", subtitle: "Confirmed Michelin sushi booking", startTime: now.addingTimeInterval(14400), endTime: now.addingTimeInterval(18000), location: "Ginza", category: .dining, estimatedCost: 250, isIndoor: true, isPreservedReservation: true)

        let initialPlan = DayPlan(date: now, title: "Weather Test Day", budgetLimit: 500, spentAmount: 0, items: [outdoor1, outdoor2, indoor1, fixedReservation])

        let disruption = DisruptionEvent(type: .weatherRain)
        let result = await service.executePanicPivot(currentPlan: initialPlan, disruption: disruption)

        let newItems = result.rebalancedPlan.items

        let outdoor1Replaced = newItems[0].isIndoor == true && newItems[0].title != outdoor1.title
        let outdoor2Replaced = newItems[1].isIndoor == true && newItems[1].title != outdoor2.title
        let indoor1Untouched = newItems[2].title == indoor1.title && newItems[2].isIndoor == true
        let reservationPreserved = newItems[3].title == fixedReservation.title && newItems[3].isPreservedReservation == true

        let passed = outdoor1Replaced && outdoor2Replaced && indoor1Untouched && reservationPreserved

        return TestResult(
            name: "Test A (Weather Disruption & Indoor Replacement)",
            passed: passed,
            details: "Outdoor 1 replaced: \(outdoor1Replaced) ('\(newItems[0].title)'), Outdoor 2 replaced: \(outdoor2Replaced) ('\(newItems[1].title)'), Indoor untouched: \(indoor1Untouched), Reservation preserved: \(reservationPreserved)."
        )
    }

    // MARK: - Test B: Transit Delay Chronological Shift
    private func testB_TransitDelayChronologicalShift() async -> TestResult {
        let service = AIRecalculatorService.shared

        let now = Date()
        let item1 = ItineraryItem(title: "Tokyo Tower Deck", subtitle: "Observatory", startTime: now, endTime: now.addingTimeInterval(3600), location: "Minato", category: .sightseeing, estimatedCost: 25, isIndoor: true)
        let item2 = ItineraryItem(title: "Zojo-ji Temple", subtitle: "Historic temple", startTime: now.addingTimeInterval(4500), endTime: now.addingTimeInterval(8100), location: "Minato", category: .sightseeing, estimatedCost: 0, isIndoor: false)

        let initialPlan = DayPlan(date: now, title: "Shift Test", budgetLimit: 200, spentAmount: 0, items: [item1, item2])

        let disruption = DisruptionEvent(type: .transitDelay, estimatedTimeImpactMinutes: 45)
        let result = await service.executePanicPivot(currentPlan: initialPlan, disruption: disruption)

        let newItems = result.rebalancedPlan.items

        let shiftApplied = newItems[1].startTime.timeIntervalSince(item2.startTime) >= 2700 // +45 mins (2700s)
        let zeroNegativeDurations = newItems.allSatisfy { $0.endTime > $0.startTime }

        let passed = shiftApplied && zeroNegativeDurations

        return TestResult(
            name: "Test B (Transit Delay Chronological Shift)",
            passed: passed,
            details: "Chronological shift applied: \(shiftApplied), Zero negative durations: \(zeroNegativeDurations)."
        )
    }

    // MARK: - Test C: Strict Reservation Protection
    private func testC_StrictReservationProtection() async -> TestResult {
        let service = AIRecalculatorService.shared

        let now = Date()
        let reservationFlight = ItineraryItem(title: "NH105 Flight Arrival", subtitle: "Confirmed flight arrival", startTime: now, endTime: now.addingTimeInterval(3600), location: "Haneda", category: .transit, estimatedCost: 0, isPreservedReservation: true)
        let reservationDinner = ItineraryItem(title: "Michelin Dinner", subtitle: "Confirmed dinner reservation", startTime: now.addingTimeInterval(14400), endTime: now.addingTimeInterval(18000), location: "Ginza", category: .dining, estimatedCost: 200, isPreservedReservation: true)

        let initialPlan = DayPlan(date: now, title: "Protection Test", budgetLimit: 500, spentAmount: 0, items: [reservationFlight, reservationDinner])

        let resRain = await service.executePanicPivot(currentPlan: initialPlan, disruptionType: .weatherRain)
        let resFlight = await service.executePanicPivot(currentPlan: initialPlan, disruptionType: .flightDelay)
        let resSchedule = await service.executePanicPivot(currentPlan: initialPlan, disruptionType: .scheduleDisruption)

        let rainPreserved = resRain.rebalancedPlan.items.allSatisfy { $0.isPreservedReservation }
        let flightPreserved = resFlight.rebalancedPlan.items.allSatisfy { $0.isPreservedReservation }
        let schedulePreserved = resSchedule.rebalancedPlan.items.allSatisfy { $0.isPreservedReservation }

        let passed = rainPreserved && flightPreserved && schedulePreserved

        return TestResult(
            name: "Test C (Strict Reservation Protection)",
            passed: passed,
            details: "Rain preserved: \(rainPreserved), Flight delay preserved: \(flightPreserved), Schedule disruption preserved: \(schedulePreserved)."
        )
    }

    // MARK: - Test D: Explainability Diff Report
    private func testD_ExplainabilityDiffReport() async -> TestResult {
        let service = AIRecalculatorService.shared

        let now = Date()
        let outdoor1 = ItineraryItem(title: "Yoyogi Park Walking Tour", subtitle: "Outdoor park walk", startTime: now, endTime: now.addingTimeInterval(3600), location: "Shibuya", category: .sightseeing, estimatedCost: 0, isIndoor: false)
        let outdoor2 = ItineraryItem(title: "Harajuku Takeshita Street", subtitle: "Outdoor shopping street", startTime: now.addingTimeInterval(4500), endTime: now.addingTimeInterval(8100), location: "Harajuku", category: .shopping, estimatedCost: 30, isIndoor: false)
        let reservation = ItineraryItem(title: "Teppanyaki Dinner", subtitle: "Confirmed reservation", startTime: now.addingTimeInterval(9000), endTime: now.addingTimeInterval(12600), location: "Shinjuku", category: .dining, estimatedCost: 150, isPreservedReservation: true)

        let initialPlan = DayPlan(date: now, title: "Diff Test", budgetLimit: 300, spentAmount: 0, items: [outdoor1, outdoor2, reservation])
        let result = await service.executePanicPivot(currentPlan: initialPlan, disruptionType: .weatherRain)

        guard let diff = result.diffReport else {
            return TestResult(name: "Test D", passed: false, details: "PivotDiffReport was nil.")
        }

        let replacedCountOk = diff.replacedItems.count == 2
        let preservedCountOk = diff.preservedReservationsCount == 1
        let summaryValid = !diff.explanationSummary.isEmpty

        let passed = replacedCountOk && preservedCountOk && summaryValid

        return TestResult(
            name: "Test D (Explainability Diff Report)",
            passed: passed,
            details: "Replaced items count: \(diff.replacedItems.count) (expected 2), Preserved reservations count: \(diff.preservedReservationsCount) (expected 1), Summary: '\(diff.explanationSummary)'."
        )
    }

    // MARK: - Test E: Day-Scoped Undo & Persistence Survival
    private func testE_DayScopedUndoAndPersistenceSurvival() async -> TestResult {
        let store = TripStore.shared
        let undoMgr = UndoPivotManager.shared

        store.resetStoreWithFreshSample()

        let day1ID = store.activeTrip.days[0].id
        let day2ID = store.activeTrip.days[1].id

        let origDay1Title = store.activeTrip.days[0].items.first?.title ?? ""
        let origDay2Title = store.activeTrip.days[1].items.first?.title ?? ""

        // Perform pivot on Day 1
        let service = AIRecalculatorService.shared
        let pivotRes = await service.executePanicPivot(currentPlan: store.activeTrip.days[0], disruptionType: .weatherRain)

        store.commitPivot(pivotRes, dayID: day1ID)

        let day1CanUndo = undoMgr.canUndo(dayID: day1ID)
        let day2CanUndo = undoMgr.canUndo(dayID: day2ID)

        // Undo Day 1 pivot
        _ = store.undoLastPivot(for: day1ID)

        let day1Restored = store.activeTrip.days[0].items.first?.title == origDay1Title
        let day2Unaffected = store.activeTrip.days[1].items.first?.title == origDay2Title

        let passed = day1CanUndo && !day2CanUndo && day1Restored && day2Unaffected

        return TestResult(
            name: "Test E (Day-Scoped Undo & Persistence Survival)",
            passed: passed,
            details: "Day 1 canUndo: \(day1CanUndo), Day 2 canUndo: \(day2CanUndo) (isolated), Day 1 restored: \(day1Restored), Day 2 unaffected: \(day2Unaffected)."
        )
    }

    // MARK: - Test F: No Overlapping Stops & Positive Durations
    private func testF_NoOverlappingStopsAndPositiveDurations() async -> TestResult {
        let service = AIRecalculatorService.shared

        let now = Date()
        let item1 = ItineraryItem(title: "Stop A", subtitle: "", startTime: now, endTime: now.addingTimeInterval(3600), location: "Tokyo", category: .sightseeing, estimatedCost: 10)
        let item2 = ItineraryItem(title: "Stop B", subtitle: "", startTime: now.addingTimeInterval(1800), endTime: now.addingTimeInterval(5400), location: "Tokyo", category: .sightseeing, estimatedCost: 15)
        let item3 = ItineraryItem(title: "Stop C", subtitle: "", startTime: now.addingTimeInterval(3600), endTime: now.addingTimeInterval(7200), location: "Tokyo", category: .sightseeing, estimatedCost: 20)

        let initialPlan = DayPlan(date: now, title: "Collision Test", budgetLimit: 150, spentAmount: 0, items: [item1, item2, item3])

        let result = await service.executePanicPivot(currentPlan: initialPlan, disruptionType: .scheduleDisruption)
        let newItems = result.rebalancedPlan.items

        var noOverlaps = true
        var allPositiveDurations = true

        for i in 0..<newItems.count {
            let duration = newItems[i].endTime.timeIntervalSince(newItems[i].startTime)
            if duration < 900 { // minimum 15 minutes
                allPositiveDurations = false
            }
            if i + 1 < newItems.count {
                if newItems[i].endTime > newItems[i + 1].startTime {
                    noOverlaps = false
                }
            }
        }

        let passed = noOverlaps && allPositiveDurations

        return TestResult(
            name: "Test F (No Overlapping Stops & Positive Durations)",
            passed: passed,
            details: "No overlapping stops: \(noOverlaps), All durations positive (min 15m): \(allPositiveDurations)."
        )
    }
}
