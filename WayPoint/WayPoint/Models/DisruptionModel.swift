//
//  DisruptionModel.swift
//  WayPoint
//

import SwiftUI

// MARK: - Disruption Type Enum

enum DisruptionType: String, Codable, CaseIterable, Identifiable {
    case weatherRain = "weather_rain"
    case flightDelay = "flight_delay"
    case transitDelay = "transit_delay"
    case attractionClosure = "attraction_closure"
    case scheduleDisruption = "schedule_disruption"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .weatherRain: "🌧️"
        case .flightDelay: "✈️"
        case .transitDelay: "🚇"
        case .attractionClosure: "🏛️"
        case .scheduleDisruption: "⏰"
        }
    }

    var title: String {
        switch self {
        case .weatherRain: "Heavy Rain Expected"
        case .flightDelay: "Flight Arrival Delay (+2h)"
        case .transitDelay: "Subway Line Disruption"
        case .attractionClosure: "Current Venue Unexpectedly Closed"
        case .scheduleDisruption: "Schedule Running 45m Late"
        }
    }

    var badgeText: String {
        switch self {
        case .weatherRain: "WEATHER DEFENSE"
        case .flightDelay: "FLIGHT RESCUE"
        case .transitDelay: "TRANSIT RE-ROUTE"
        case .attractionClosure: "CLOSURE PIVOT"
        case .scheduleDisruption: "PACING OPTIMIZER"
        }
    }

    var badgeColor: Color {
        switch self {
        case .weatherRain: WayPointTheme.cyanGlow
        case .flightDelay: WayPointTheme.budgetWarning
        case .transitDelay: WayPointTheme.violetGlow
        case .attractionClosure: Color.pink
        case .scheduleDisruption: Color.orange
        }
    }

    var causeDescription: String {
        switch self {
        case .weatherRain: "Heavy rain forecasted from 14:00 to 17:00. Outdoor activities face severe impact."
        case .flightDelay: "Flight NH105 delayed by 120 mins. Afternoon arrival schedule shifted."
        case .transitDelay: "Yamanote Line signal maintenance outage. 45-minute travel delay expected."
        case .attractionClosure: "Venue undergoing unexpected safety inspection. Closed until tomorrow."
        case .scheduleDisruption: "Previous activity ran long. Subsequent schedule compressed."
        }
    }

    var defaultImpactText: String {
        switch self {
        case .weatherRain: "2 Outdoor Activities Affected"
        case .flightDelay: "3 Afternoon Activities Shifted"
        case .transitDelay: "Transit Route & Buffer Affected"
        case .attractionClosure: "1 Active Stop Affected"
        case .scheduleDisruption: "2 Evening Stops Shifted"
        }
    }

    var estimatedTimeImpactMinutes: Int {
        switch self {
        case .weatherRain: 180
        case .flightDelay: 120
        case .transitDelay: 45
        case .attractionClosure: 90
        case .scheduleDisruption: 60
        }
    }
}

// MARK: - Disruption Event

struct DisruptionEvent: Identifiable, Codable, Hashable {
    let id: UUID
    let type: DisruptionType
    let title: String
    let description: String
    let timestamp: Date
    let affectedItemIDs: [UUID]
    let estimatedTimeImpactMinutes: Int

    init(
        id: UUID = UUID(),
        type: DisruptionType,
        title: String? = nil,
        description: String? = nil,
        timestamp: Date = Date(),
        affectedItemIDs: [UUID] = [],
        estimatedTimeImpactMinutes: Int? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title ?? type.title
        self.description = description ?? type.causeDescription
        self.timestamp = timestamp
        self.affectedItemIDs = affectedItemIDs
        self.estimatedTimeImpactMinutes = estimatedTimeImpactMinutes ?? type.estimatedTimeImpactMinutes
    }
}

// MARK: - Pivot Explanation (Trust Layer)

struct PivotExplanation: Identifiable, Codable, Hashable {
    let id: UUID
    let itemID: UUID
    let itemTitle: String
    let reasonEmoji: String
    let reasonText: String
    let isPreservedReservation: Bool

    init(
        id: UUID = UUID(),
        itemID: UUID,
        itemTitle: String,
        reasonEmoji: String,
        reasonText: String,
        isPreservedReservation: Bool = false
    ) {
        self.id = id
        self.itemID = itemID
        self.itemTitle = itemTitle
        self.reasonEmoji = reasonEmoji
        self.reasonText = reasonText
        self.isPreservedReservation = isPreservedReservation
    }
}

// MARK: - Pivot Item Replacement

struct PivotItemReplacement: Codable, Equatable, Identifiable {
    var id: UUID { original.id }
    let original: ItineraryItem
    let replacement: ItineraryItem

    init(original: ItineraryItem, replacement: ItineraryItem) {
        self.original = original
        self.replacement = replacement
    }
}

// MARK: - Pivot Diff Report

struct PivotDiffReport: Codable, Equatable {
    let replacedItems: [PivotItemReplacement]
    let preservedReservationsCount: Int
    let timeImpactMinutes: Int
    let distanceImpactMeters: Double
    let budgetImpact: Double
    let explanationSummary: String

    init(
        replacedItems: [PivotItemReplacement] = [],
        preservedReservationsCount: Int = 0,
        timeImpactMinutes: Int = 0,
        distanceImpactMeters: Double = 0.0,
        budgetImpact: Double = 0.0,
        explanationSummary: String = ""
    ) {
        self.replacedItems = replacedItems
        self.preservedReservationsCount = preservedReservationsCount
        self.timeImpactMinutes = timeImpactMinutes
        self.distanceImpactMeters = distanceImpactMeters
        self.budgetImpact = budgetImpact
        self.explanationSummary = explanationSummary
    }
}

// MARK: - Pivot Result Snapshot

struct PivotResult: Identifiable, Codable {
    let id: UUID
    let previousPlan: DayPlan
    let rebalancedPlan: DayPlan
    let disruptionEvent: DisruptionEvent
    let minutesRecovered: Int
    let explanations: [PivotExplanation]
    let diffReport: PivotDiffReport?
    let appliedAt: Date

    init(
        id: UUID = UUID(),
        previousPlan: DayPlan,
        rebalancedPlan: DayPlan,
        disruptionEvent: DisruptionEvent,
        minutesRecovered: Int,
        explanations: [PivotExplanation],
        diffReport: PivotDiffReport? = nil,
        appliedAt: Date = Date()
    ) {
        self.id = id
        self.previousPlan = previousPlan
        self.rebalancedPlan = rebalancedPlan
        self.disruptionEvent = disruptionEvent
        self.minutesRecovered = minutesRecovered
        self.explanations = explanations
        self.diffReport = diffReport
        self.appliedAt = appliedAt
    }

    var formattedTimeRecovered: String {
        let hours = minutesRecovered / 60
        let mins = minutesRecovered % 60
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m recovered"
        } else if hours > 0 {
            return "\(hours)h recovered"
        } else {
            return "\(mins)m recovered"
        }
    }
}
