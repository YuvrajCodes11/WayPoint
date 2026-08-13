//
//  TripModel.swift
//  WayPoint
//

import Foundation
import Observation

// MARK: - Location Coordinate

struct LocationCoordinate: Codable, Hashable {
    var latitude: Double
    var longitude: Double
}

// MARK: - Item Category

enum ItemCategory: String, Codable, CaseIterable, Identifiable {
    case dining
    case sightseeing
    case transit
    case transport
    case stay
    case leisure
    case shopping
    case adventure

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .dining: "fork.knife"
        case .sightseeing: "binoculars.fill"
        case .transit, .transport: "car.fill"
        case .stay: "bed.double.fill"
        case .leisure: "sparkles"
        case .shopping: "bag.fill"
        case .adventure: "figure.hiking"
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}

typealias ItineraryCategory = ItemCategory

// MARK: - Trip Model

@Observable
final class Trip: Identifiable, Codable {
    let id: UUID
    var title: String
    var destination: String
    var travelerName: String
    var currencyCode: String
    var days: [DayPlan]
    var selectedDayIndex: Int

    enum CodingKeys: String, CodingKey {
        case id, title, destination
        case travelerName = "traveler_name"
        case currencyCode = "currency_code"
        case days
        case selectedDayIndex = "selected_day_index"
    }

    init(
        id: UUID = UUID(),
        title: String,
        destination: String,
        travelerName: String,
        currencyCode: String = "USD",
        days: [DayPlan],
        selectedDayIndex: Int = 0
    ) {
        self.id = id
        self.title = title
        self.destination = destination
        self.travelerName = travelerName
        self.currencyCode = currencyCode
        self.days = days
        self.selectedDayIndex = selectedDayIndex
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.destination = try container.decodeIfPresent(String.self, forKey: .destination) ?? ""
        self.travelerName = try container.decodeIfPresent(String.self, forKey: .travelerName) ?? ""
        self.currencyCode = try container.decodeIfPresent(String.self, forKey: .currencyCode) ?? "USD"
        self.days = try container.decodeIfPresent([DayPlan].self, forKey: .days) ?? []
        self.selectedDayIndex = try container.decodeIfPresent(Int.self, forKey: .selectedDayIndex) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(destination, forKey: .destination)
        try container.encode(travelerName, forKey: .travelerName)
        try container.encode(currencyCode, forKey: .currencyCode)
        try container.encode(days, forKey: .days)
        try container.encode(selectedDayIndex, forKey: .selectedDayIndex)
    }

    var currentDayPlan: DayPlan {
        get {
            guard days.indices.contains(selectedDayIndex) else {
                return days.first ?? DayPlan(date: Date(), title: "Day Plan", budgetLimit: 0, spentAmount: 0, items: [])
            }
            return days[selectedDayIndex]
        }
        set {
            if days.indices.contains(selectedDayIndex) {
                days[selectedDayIndex] = newValue
            }
        }
    }

    var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.currencySymbol ?? "$"
    }

    var totalTripBudget: Decimal {
        days.reduce(Decimal(0)) { $0 + $1.budgetLimit }
    }

    var totalTripSpent: Decimal {
        days.reduce(Decimal(0)) { $0 + $1.spentAmount }
    }
}

// MARK: - Empty Trip Initializer

extension Trip {
    static var empty: Trip {
        Trip(
            title: "New Trip",
            destination: "",
            travelerName: "",
            currencyCode: "USD",
            days: [DayPlan(date: Date(), title: "Day 1", budgetLimit: 0, spentAmount: 0, items: [])],
            selectedDayIndex: 0
        )
    }
}
