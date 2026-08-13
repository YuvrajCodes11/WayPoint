//
//  ItineraryItem.swift
//  WayPoint
//

import Foundation

struct ItineraryItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var subtitle: String
    var startTime: Date
    var endTime: Date
    var location: String
    var category: ItemCategory
    var estimatedCost: Decimal
    var isCompleted: Bool
    var coordinate: LocationCoordinate?
    var notes: String?
    var currencyCode: String

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        startTime: Date,
        endTime: Date,
        location: String,
        category: ItemCategory,
        estimatedCost: Decimal,
        isCompleted: Bool = false,
        coordinate: LocationCoordinate? = nil,
        notes: String? = nil,
        currencyCode: String = "USD"
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.category = category
        self.estimatedCost = estimatedCost
        self.isCompleted = isCompleted
        self.coordinate = coordinate
        self.notes = notes
        self.currencyCode = currencyCode
    }

    var timeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: startTime)) – \(formatter.string(from: endTime))"
    }

    var durationMinutes: Int {
        max(0, Int(endTime.timeIntervalSince(startTime) / 60))
    }

    var formattedCost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 0
        return formatter.string(from: estimatedCost as NSDecimalNumber) ?? "\(currencyCode) \(estimatedCost)"
    }
}
