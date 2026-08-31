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
    
    // Rich Venue Metadata & Panic Pivot Ghost Pre-Caching
    var rating: Double
    var reviewCount: Int
    var priceTier: String
    var photoURL: URL?
    var isIndoor: Bool
    var address: String
    var ghostAlternatives: [ItineraryItem]
    // Timezone metadata fields for Date Line and cross-timezone travel
    var departureTimeZoneIdentifier: String?
    var arrivalTimeZoneIdentifier: String?

    // Panic Pivot & Trust Layer Metadata
    var isPreservedReservation: Bool
    var pivotReason: String?
    var originalTimeSlot: String?

    enum CodingKeys: String, CodingKey {
        case id, title, subtitle
        case startTime = "start_time"
        case endTime = "end_time"
        case location, category
        case estimatedCost = "estimated_cost"
        case isCompleted = "is_completed"
        case coordinate, notes
        case currencyCode = "currency_code"
        case rating
        case reviewCount = "review_count"
        case priceTier = "price_tier"
        case photoURL = "photo_url"
        case isIndoor = "is_indoor"
        case address
        case ghostAlternatives = "ghost_alternatives"
        case departureTimeZoneIdentifier = "departure_time_zone_identifier"
        case arrivalTimeZoneIdentifier = "arrival_time_zone_identifier"
        case isPreservedReservation = "is_preserved_reservation"
        case pivotReason = "pivot_reason"
        case originalTimeSlot = "original_time_slot"
    }

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
        currencyCode: String = "USD",
        rating: Double = 4.8,
        reviewCount: Int = 1200,
        priceTier: String = "$$",
        photoURL: URL? = nil,
        isIndoor: Bool = true,
        address: String = "",
        ghostAlternatives: [ItineraryItem] = [],
        departureTimeZoneIdentifier: String? = nil,
        arrivalTimeZoneIdentifier: String? = nil,
        isPreservedReservation: Bool = false,
        pivotReason: String? = nil,
        originalTimeSlot: String? = nil
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
        self.rating = rating
        self.reviewCount = reviewCount
        self.priceTier = priceTier
        self.photoURL = photoURL
        self.isIndoor = isIndoor
        self.address = address.isEmpty ? location : address
        self.ghostAlternatives = ghostAlternatives
        self.departureTimeZoneIdentifier = departureTimeZoneIdentifier
        self.arrivalTimeZoneIdentifier = arrivalTimeZoneIdentifier
        self.isPreservedReservation = isPreservedReservation
        self.pivotReason = pivotReason
        self.originalTimeSlot = originalTimeSlot
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle) ?? ""
        self.startTime = try container.decodeIfPresent(Date.self, forKey: .startTime) ?? Date()
        self.endTime = try container.decodeIfPresent(Date.self, forKey: .endTime) ?? Date().addingTimeInterval(3600)
        self.location = try container.decodeIfPresent(String.self, forKey: .location) ?? ""
        self.category = try container.decodeIfPresent(ItemCategory.self, forKey: .category) ?? .sightseeing
        self.estimatedCost = try container.decodeIfPresent(Decimal.self, forKey: .estimatedCost) ?? 0
        self.isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        self.coordinate = try container.decodeIfPresent(LocationCoordinate.self, forKey: .coordinate)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
        self.currencyCode = try container.decodeIfPresent(String.self, forKey: .currencyCode) ?? "USD"
        self.rating = try container.decodeIfPresent(Double.self, forKey: .rating) ?? 4.8
        self.reviewCount = try container.decodeIfPresent(Int.self, forKey: .reviewCount) ?? 1200
        self.priceTier = try container.decodeIfPresent(String.self, forKey: .priceTier) ?? "$$"
        self.photoURL = try container.decodeIfPresent(URL.self, forKey: .photoURL)
        self.isIndoor = try container.decodeIfPresent(Bool.self, forKey: .isIndoor) ?? true
        let loc = try container.decodeIfPresent(String.self, forKey: .location) ?? ""
        self.address = try container.decodeIfPresent(String.self, forKey: .address) ?? loc
        self.ghostAlternatives = try container.decodeIfPresent([ItineraryItem].self, forKey: .ghostAlternatives) ?? []
        self.departureTimeZoneIdentifier = try container.decodeIfPresent(String.self, forKey: .departureTimeZoneIdentifier)
        self.arrivalTimeZoneIdentifier = try container.decodeIfPresent(String.self, forKey: .arrivalTimeZoneIdentifier)
        self.isPreservedReservation = try container.decodeIfPresent(Bool.self, forKey: .isPreservedReservation) ?? false
        self.pivotReason = try container.decodeIfPresent(String.self, forKey: .pivotReason)
        self.originalTimeSlot = try container.decodeIfPresent(String.self, forKey: .originalTimeSlot)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(subtitle, forKey: .subtitle)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(location, forKey: .location)
        try container.encode(category, forKey: .category)
        try container.encode(estimatedCost, forKey: .estimatedCost)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encodeIfPresent(coordinate, forKey: .coordinate)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(currencyCode, forKey: .currencyCode)
        try container.encode(rating, forKey: .rating)
        try container.encode(reviewCount, forKey: .reviewCount)
        try container.encode(priceTier, forKey: .priceTier)
        try container.encodeIfPresent(photoURL, forKey: .photoURL)
        try container.encode(isIndoor, forKey: .isIndoor)
        try container.encode(address, forKey: .address)
        try container.encode(ghostAlternatives, forKey: .ghostAlternatives)
        try container.encodeIfPresent(departureTimeZoneIdentifier, forKey: .departureTimeZoneIdentifier)
        try container.encodeIfPresent(arrivalTimeZoneIdentifier, forKey: .arrivalTimeZoneIdentifier)
        try container.encode(isPreservedReservation, forKey: .isPreservedReservation)
        try container.encodeIfPresent(pivotReason, forKey: .pivotReason)
        try container.encodeIfPresent(originalTimeSlot, forKey: .originalTimeSlot)
    }

    var departureTimeZone: TimeZone {
        if let id = departureTimeZoneIdentifier, let tz = TimeZone(identifier: id) {
            return tz
        }
        return .current
    }

    var arrivalTimeZone: TimeZone {
        if let id = arrivalTimeZoneIdentifier, let tz = TimeZone(identifier: id) {
            return tz
        }
        return departureTimeZone
    }

    /// Tuple helper returning arrival date and relative day offset string (e.g. "+1 Day", "-1 Day")
    var arrivalDateWithOffset: (date: Date, dayOffsetString: String?) {
        let offset = LocaleManager.calculateDayOffset(
            from: startTime,
            departureTimeZone: departureTimeZone,
            arrivalDate: endTime,
            arrivalTimeZone: arrivalTimeZone
        )
        let tag: String?
        if offset > 0 {
            tag = "+\(offset) Day\(offset > 1 ? "s" : "")"
        } else if offset < 0 {
            tag = "\(offset) Day\(abs(offset) > 1 ? "s" : "")"
        } else {
            tag = nil
        }
        return (endTime, tag)
    }

    var dayOffsetString: String? {
        arrivalDateWithOffset.dayOffsetString
    }

    var timeRange: String {
        let startStr = LocaleManager.formatTime(startTime, timeZone: departureTimeZone)
        let endStr = LocaleManager.formatTime(endTime, timeZone: arrivalTimeZone)
        if let tag = dayOffsetString {
            return "\(startStr) – \(endStr) (\(tag))"
        } else {
            return "\(startStr) – \(endStr)"
        }
    }

    var durationMinutes: Int {
        max(0, Int(endTime.timeIntervalSince(startTime) / 60))
    }

    var formattedCost: String {
        guard estimatedCost > 0 else { return "Free" }
        return LocaleManager.formatCurrency(estimatedCost, currencyCode: currencyCode)
    }

    var formattedRatingAndReviews: String {
        let reviewStr: String
        if reviewCount >= 1000 {
            reviewStr = String(format: "%.1fk", Double(reviewCount) / 1000.0)
        } else {
            reviewStr = "\(reviewCount)"
        }
        return String(format: "★ %.1f · %@", rating, reviewStr)
    }

    var categoryAndPriceTag: String {
        let costDisplay = estimatedCost == 0 ? "Free" : priceTier
        return "\(category.emoji) \(category.displayName) · \(costDisplay)"
    }
}
