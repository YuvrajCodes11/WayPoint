//
//  TravelPassModels.swift
//  WayPoint
//
//  Phase 4: Travel Pass & Booking Models
//

import Foundation

public enum PassType: String, Codable, CaseIterable, Identifiable, Sendable {
    case flight = "Flight"
    case transit = "Transit"
    case hotel = "Hotel"
    case activity = "Activity"
    case key = "Keys"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .flight: "airplane"
        case .transit: "tram.fill"
        case .hotel: "bed.double.fill"
        case .activity: "ticket.fill"
        case .key: "key.fill"
        }
    }

    public var displayName: String {
        switch self {
        case .flight: "Flight"
        case .transit: "Transit"
        case .hotel: "Stay"
        case .activity: "Activity"
        case .key: "Keys"
        }
    }
}

public struct TravelPass: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var tripId: UUID
    public var title: String
    public var providerName: String
    public var passType: PassType
    public var confirmationCode: String
    public var barcodePayload: String
    public var validFrom: Date
    public var validUntil: Date?
    public var seatOrRoom: String?
    public var dayIndex: Int?
    public var colorHex: String?
    public var notes: String?

    public init(
        id: UUID = UUID(),
        tripId: UUID,
        title: String,
        providerName: String,
        passType: PassType,
        confirmationCode: String,
        barcodePayload: String,
        validFrom: Date = Date(),
        validUntil: Date? = nil,
        seatOrRoom: String? = nil,
        dayIndex: Int? = nil,
        colorHex: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.tripId = tripId
        self.title = title
        self.providerName = providerName
        self.passType = passType
        self.confirmationCode = confirmationCode
        self.barcodePayload = barcodePayload
        self.validFrom = validFrom
        self.validUntil = validUntil
        self.seatOrRoom = seatOrRoom
        self.dayIndex = dayIndex
        self.colorHex = colorHex
        self.notes = notes
    }
}
