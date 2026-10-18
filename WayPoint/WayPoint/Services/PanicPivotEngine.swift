//
//  PanicPivotEngine.swift
//  WayPoint
//
//  Phase 3: Dynamic Panic Pivot Disruption Defense Engine
//

import Foundation

public enum DynamicDisruptionEvent: Equatable, Sendable {
    case severeWeather(condition: String)
    case transitDelay(minutes: Int)
}

public typealias PanicPivotDisruption = DynamicDisruptionEvent

public struct DisruptionDiffReport: Identifiable, Sendable {
    public let id: UUID
    public let replacedStopsCount: Int
    public let preservedReservationsCount: Int
    public let minutesShifted: Int
    public let summary: String
    public let originalStops: [TripStop]
    public let adjustedStops: [TripStop]

    public init(
        id: UUID = UUID(),
        replacedStopsCount: Int,
        preservedReservationsCount: Int,
        minutesShifted: Int,
        summary: String,
        originalStops: [TripStop],
        adjustedStops: [TripStop]
    ) {
        self.id = id
        self.replacedStopsCount = replacedStopsCount
        self.preservedReservationsCount = preservedReservationsCount
        self.minutesShifted = minutesShifted
        self.summary = summary
        self.originalStops = originalStops
        self.adjustedStops = adjustedStops
    }
}

@MainActor
public final class PanicPivotEngine {
    public static let shared = PanicPivotEngine()

    private init() {}

    /// Evaluates a disruption event against a dynamic trip day plan and generates a DisruptionDiffReport.
    /// Hard reservations (isHardReservation == true) are strictly preserved.
    public func evaluateDisruption(
        dayIndex: Int,
        event: DynamicDisruptionEvent,
        trip: DynamicTrip? = nil
    ) -> DisruptionDiffReport {
        guard let activeTrip = trip ?? TripStore.shared.currentTrip,
              activeTrip.days.indices.contains(dayIndex) else {
            return DisruptionDiffReport(
                replacedStopsCount: 0,
                preservedReservationsCount: 0,
                minutesShifted: 0,
                summary: "No active dynamic trip or valid day plan found for index \(dayIndex).",
                originalStops: [],
                adjustedStops: []
            )
        }

        let originalStops = activeTrip.days[dayIndex].stops
        var adjustedStops: [TripStop] = []
        var replacedCount = 0
        var preservedCount = 0
        var minutesShifted = 0
        var summaryNotes: [String] = []

        switch event {
        case .severeWeather(let condition):
            summaryNotes.append("Severe Weather Alert (\(condition)): Swapped outdoor activities for indoor alternatives.")
            
            for stop in originalStops {
                if stop.isHardReservation {
                    preservedCount += 1
                    adjustedStops.append(stop)
                } else if stop.type == .activity || stop.type == .transit {
                    replacedCount += 1
                    let indoorTitle = indoorAlternativeTitle(for: stop.title, condition: condition)
                    var updatedStop = stop
                    updatedStop.title = indoorTitle
                    updatedStop.notes = (stop.notes ?? "") + " [Pivoted from outdoor activity due to \(condition)]"
                    adjustedStops.append(updatedStop)
                } else {
                    adjustedStops.append(stop)
                }
            }

        case .transitDelay(let delayMinutes):
            minutesShifted = delayMinutes
            summaryNotes.append("Transit Delay (\(delayMinutes) mins): Adjusted timeline for non-reserved stops.")

            let currentShiftSeconds = TimeInterval(delayMinutes * 60)
            for stop in originalStops {
                if stop.isHardReservation {
                    preservedCount += 1
                    adjustedStops.append(stop)
                } else {
                    var updatedStop = stop
                    updatedStop.scheduledTime = stop.scheduledTime.addingTimeInterval(currentShiftSeconds)
                    updatedStop.notes = (stop.notes ?? "") + " [Shifted +\(delayMinutes)m due to transit delay]"
                    adjustedStops.append(updatedStop)
                }
            }
        }

        let summary = summaryNotes.joined(separator: " ") + " Preserved \(preservedCount) hard reservation(s)."

        return DisruptionDiffReport(
            replacedStopsCount: replacedCount,
            preservedReservationsCount: preservedCount,
            minutesShifted: minutesShifted,
            summary: summary,
            originalStops: originalStops,
            adjustedStops: adjustedStops
        )
    }

    /// Applies a DisruptionDiffReport directly to the active dynamic trip in TripStore.
    public func applyPivot(dayIndex: Int, report: DisruptionDiffReport) {
        guard var trip = TripStore.shared.currentTrip,
              trip.days.indices.contains(dayIndex) else { return }
        
        trip.days[dayIndex].stops = report.adjustedStops
        TripStore.shared.currentTrip = trip
        
        // Save to disk
        if let data = try? JSONEncoder().encode(trip) {
            UserDefaults.standard.set(data, forKey: "waypoint_active_user_trip_v1")
        }
    }

    private func indoorAlternativeTitle(for originalTitle: String, condition: String) -> String {
        let lower = originalTitle.lowercased()
        if lower.contains("park") || lower.contains("walking") || lower.contains("garden") || lower.contains("tour") {
            return "Mori Art Museum & Indoor Gallery"
        } else if lower.contains("shrine") || lower.contains("temple") {
            return "Edo-Tokyo Museum (Indoor Exhibition)"
        } else if lower.contains("market") || lower.contains("street") {
            return "Depachika Indoor Gourmet Food Hall"
        } else {
            return "Indoor Cultural Center (\(originalTitle))"
        }
    }

    /// Evaluates live weather for destination coordinates via NetworkService and returns a disruption report if severe weather is detected.
    public func evaluateLiveWeatherDisruption(dayIndex: Int, latitude: Double, longitude: Double) async -> DisruptionDiffReport? {
        let weather = await NetworkService.shared.fetchWeather(latitude: latitude, longitude: longitude)
        if weather.isSevereWeather {
            return evaluateDisruption(dayIndex: dayIndex, event: .severeWeather(condition: weather.conditionDescription))
        }
        return nil
    }
}
