//
//  Task22TimezoneDateLineTests.swift
//  WayPoint
//
//  Task 2.2: Timezones & Date-Line Boundary Engine Automated Test Suite
//

import Foundation
import SwiftUI

@MainActor
final class Task22TimezoneDateLineTests {
    static let shared = Task22TimezoneDateLineTests()

    private init() {}

    struct TestResult {
        let name: String
        let passed: Bool
        let details: String
    }

    /// Runs all Task 2.2 test scenarios (A, B, C, D, E) and returns structured results.
    func runAllTask22Tests() async -> [TestResult] {
        var results: [TestResult] = []

        results.append(await testA_TokyoToLAXDateLineCrossing())
        results.append(await testB_LAXToTokyoDateLineCrossing())
        results.append(await testC_MidnightBoundaryCrossing())
        results.append(await testD_DSTShiftResilience())
        results.append(await testE_LocaleAwareTimeFormatting())

        for res in results {
            print("[TASK-2.2-TEST] \(res.passed ? "✅ PASS" : "❌ FAIL") - \(res.name): \(res.details)")
        }

        return results
    }

    // MARK: - Test A: Tokyo to LAX - West to East Crossing (Oct 15 18:00 JST + 10h -> Oct 15 12:00 PDT -> Offset == 0)
    private func testA_TokyoToLAXDateLineCrossing() async -> TestResult {
        let tokyoTZ = TimeZone(identifier: "Asia/Tokyo")!
        let laxTZ = TimeZone(identifier: "America/Los_Angeles")!

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tokyoTZ
        var components = DateComponents()
        components.year = 2026
        components.month = 10
        components.day = 15
        components.hour = 18
        components.minute = 0
        guard let departureDate = calendar.date(from: components) else {
            return TestResult(name: "Test A", passed: false, details: "Date creation failed")
        }

        // Flight duration: 10 hours
        let arrivalDate = departureDate.addingTimeInterval(10 * 3600)

        // Verify LAX local date/time is Oct 15 12:00 PDT
        var laxCalendar = Calendar(identifier: .gregorian)
        laxCalendar.timeZone = laxTZ
        let laxHour = laxCalendar.component(.hour, from: arrivalDate)
        let laxDay = laxCalendar.component(.day, from: arrivalDate)

        let offset = LocaleManager.calculateDayOffset(
            from: departureDate,
            departureTimeZone: tokyoTZ,
            arrivalDate: arrivalDate,
            arrivalTimeZone: laxTZ
        )

        let passed = (offset == 0) && (laxDay == 15) && (laxHour == 12)

        return TestResult(
            name: "Test A: Tokyo -> LAX West-to-East Date Line Crossing",
            passed: passed,
            details: "Departure: Oct 15 18:00 JST -> Arrival LAX local: Oct \(laxDay) \(laxHour):00 PDT. Calculated day offset: \(offset) (expected 0)."
        )
    }

    // MARK: - Test B: LAX to Tokyo - East to West Crossing (Oct 15 11:00 PDT + 11h -> Oct 16 14:00 JST -> Offset == +1)
    private func testB_LAXToTokyoDateLineCrossing() async -> TestResult {
        let laxTZ = TimeZone(identifier: "America/Los_Angeles")!
        let tokyoTZ = TimeZone(identifier: "Asia/Tokyo")!

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = laxTZ
        var components = DateComponents()
        components.year = 2026
        components.month = 10
        components.day = 15
        components.hour = 11
        components.minute = 0
        guard let departureDate = calendar.date(from: components) else {
            return TestResult(name: "Test B", passed: false, details: "Date creation failed")
        }

        // Flight duration: 11 hours
        let arrivalDate = departureDate.addingTimeInterval(11 * 3600)

        // Verify Tokyo local date/time is Oct 16 14:00 JST
        var tokyoCalendar = Calendar(identifier: .gregorian)
        tokyoCalendar.timeZone = tokyoTZ
        let tokyoHour = tokyoCalendar.component(.hour, from: arrivalDate)
        let tokyoDay = tokyoCalendar.component(.day, from: arrivalDate)

        let offset = LocaleManager.calculateDayOffset(
            from: departureDate,
            departureTimeZone: laxTZ,
            arrivalDate: arrivalDate,
            arrivalTimeZone: tokyoTZ
        )

        let item = ItineraryItem(
            title: "LAX to Haneda Flight",
            subtitle: "ANA 107",
            startTime: departureDate,
            endTime: arrivalDate,
            location: "Tokyo",
            category: .transit,
            estimatedCost: 1450,
            departureTimeZoneIdentifier: "America/Los_Angeles",
            arrivalTimeZoneIdentifier: "Asia/Tokyo"
        )

        let passed = (offset == 1) && (tokyoDay == 16) && (tokyoHour == 14) && (item.dayOffsetString == "+1 Day")

        return TestResult(
            name: "Test B: LAX -> Tokyo East-to-West Date Line Crossing",
            passed: passed,
            details: "Departure: Oct 15 11:00 PDT -> Arrival Tokyo local: Oct \(tokyoDay) \(tokyoHour):00 JST. Calculated day offset: \(offset) (tag: '\(item.dayOffsetString ?? "")')."
        )
    }

    // MARK: - Test C: Midnight Boundary Crossing (23:00 -> 01:30 [+2.5h] -> positive duration)
    private func testC_MidnightBoundaryCrossing() async -> TestResult {
        let baseDate = Date()
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!

        let start = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: baseDate) ?? baseDate
        let end = start.addingTimeInterval(9000) // +2.5 hours -> 01:30 next morning

        let item = ItineraryItem(
            title: "Shinjuku Izakaya Night Crawl",
            subtitle: "Golden Gai",
            startTime: start,
            endTime: end,
            location: "Shinjuku",
            category: .dining,
            estimatedCost: 50
        )

        let durationSeconds = end.timeIntervalSince(start)
        let durationMins = item.durationMinutes
        let passed = (durationSeconds == 9000.0) && (durationMins == 150)

        return TestResult(
            name: "Test C: Midnight Boundary Crossing (23:00 to 01:30)",
            passed: passed,
            details: "Duration: \(durationSeconds)s (\(durationMins) mins). Positive duration maintained across 00:00 midnight boundary."
        )
    }

    // MARK: - Test D: DST Shift Resilience (US Spring Forward Boundary)
    private func testD_DSTShiftResilience() async -> TestResult {
        let nyTZ = TimeZone(identifier: "America/New_York")!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = nyTZ

        // US Spring Forward: March 8, 2026 at 2:00 AM clock jumps to 3:00 AM
        var compA = DateComponents()
        compA.year = 2026; compA.month = 3; compA.day = 8; compA.hour = 1; compA.minute = 30
        let dateA = calendar.date(from: compA)!

        var compB = DateComponents()
        compB.year = 2026; compB.month = 3; compB.day = 8; compB.hour = 3; compB.minute = 30
        let dateB = calendar.date(from: compB)!

        let itemA = ItineraryItem(title: "Pre-DST Event", subtitle: "", startTime: dateA, endTime: dateA.addingTimeInterval(1800), location: "NY", category: .sightseeing, estimatedCost: 0)
        let itemB = ItineraryItem(title: "Post-DST Event", subtitle: "", startTime: dateB, endTime: dateB.addingTimeInterval(1800), location: "NY", category: .sightseeing, estimatedCost: 0)

        let items = [itemB, itemA].sorted(by: { $0.startTime < $1.startTime })
        let passed = (items.first?.title == "Pre-DST Event") && (items.last?.title == "Post-DST Event")

        return TestResult(
            name: "Test D: DST Shift Resilience (Spring Forward Boundary)",
            passed: passed,
            details: "Chronological sorting across 23-hour DST transition day preserved item order: [\(items.map(\.title).joined(separator: ", "))]."
        )
    }

    // MARK: - Test E: Locale-Aware Time Formatting (12-hr vs 24-hr)
    private func testE_LocaleAwareTimeFormatting() async -> TestResult {
        let tokTZ = TimeZone(identifier: "Asia/Tokyo")!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tokTZ
        var comp = DateComponents()
        comp.year = 2026; comp.month = 10; comp.day = 15; comp.hour = 18; comp.minute = 0
        let testDate = calendar.date(from: comp)!

        let usFormat = LocaleManager.formatTime(testDate, timeZone: tokTZ, locale: Locale(identifier: "en_US"))
        let frFormat = LocaleManager.formatTime(testDate, timeZone: tokTZ, locale: Locale(identifier: "fr_FR"))

        let usHasAMPM = usFormat.contains("PM") || usFormat.contains("pm")
        let frIs24Hr = frFormat.contains("18") || frFormat.contains("h")

        let passed = usHasAMPM && frIs24Hr

        return TestResult(
            name: "Test E: Locale-Aware Time Formatting (12-hr vs 24-hr)",
            passed: passed,
            details: "US en_US format: '\(usFormat)', FR fr_FR format: '\(frFormat)'."
        )
    }
}
