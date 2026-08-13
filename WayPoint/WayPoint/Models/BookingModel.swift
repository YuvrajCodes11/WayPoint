//
//  BookingModel.swift
//  WayPoint
//

import Foundation

// MARK: - Booking Type

enum BookingType: String, Codable, CaseIterable, Identifiable {
    case flight
    case hotel
    case activity
    case transit
    case dining

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .flight: "airplane"
        case .hotel: "bed.double.fill"
        case .activity: "ticket.fill"
        case .transit: "car.fill"
        case .dining: "fork.knife"
        }
    }

    var systemImage: String { icon }

    var displayName: String {
        switch self {
        case .flight: "Flight"
        case .hotel: "Hotel"
        case .activity: "Activity"
        case .transit: "Transit"
        case .dining: "Dining"
        }
    }
}

// MARK: - Booking Struct

struct Booking: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var provider: String
    var confirmationCode: String
    var type: BookingType
    var date: Date
    var seatOrRoom: String?
    var barcodeData: String?
    var notes: String?
    var location: String?
    var cost: Decimal?

    init(
        id: UUID = UUID(),
        title: String,
        provider: String = "WayPoint Travel",
        confirmationCode: String = "CONF-0000",
        confirmationNumber: String? = nil,
        type: BookingType,
        date: Date = Date(),
        startDate: Date? = nil,
        endDate: Date? = nil,
        seatOrRoom: String? = nil,
        barcodeData: String? = nil,
        status: BookingStatus? = nil,
        currencyCode: String? = nil,
        notes: String? = nil,
        location: String? = nil,
        cost: Decimal? = nil
    ) {
        self.id = id
        self.title = title
        self.provider = provider
        let code = confirmationNumber ?? confirmationCode
        self.confirmationCode = code
        self.type = type
        self.date = startDate ?? date
        self.seatOrRoom = seatOrRoom
        self.barcodeData = barcodeData ?? "\(code)-PASS"
        self.notes = notes
        self.location = location
        self.cost = cost
    }

    var confirmationNumber: String {
        get { confirmationCode }
        set { confirmationCode = newValue }
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var formattedCost: String {
        guard let cost = cost else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "AED"
        return formatter.string(from: cost as NSDecimalNumber) ?? "AED \(cost)"
    }
}


