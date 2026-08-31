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
    var userID: UUID?
    var tripID: UUID?
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

    enum CodingKeys: String, CodingKey {
        case id, title, provider, type, date, notes, location, cost
        case userID = "user_id"
        case tripID = "trip_id"
        case confirmationCode = "confirmation_code"
        case seatOrRoom = "seat_or_room"
        case barcodeData = "barcode_data"
    }

    init(
        id: UUID = UUID(),
        userID: UUID? = nil,
        tripID: UUID? = nil,
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
        self.userID = userID
        self.tripID = tripID
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

    func formattedCost(currencyCode: String = "USD") -> String {
        guard let cost = cost else { return "" }
        return LocaleManager.formatCurrency(cost, currencyCode: currencyCode)
    }

    var formattedCost: String {
        formattedCost(currencyCode: "USD")
    }
}

// MARK: - Sample Passes Initializer

extension Booking {
    static var samplePasses: [Booking] {
        let calendar = Calendar.current
        let now = Date()
        let today9am = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
        let today3pm = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: now) ?? now
        let today430pm = calendar.date(bySettingHour: 16, minute: 30, second: 0, of: now) ?? now

        return [
            Booking(
                title: "ANA Airways NH 107",
                provider: "All Nippon Airways",
                confirmationCode: "NH107-JFK",
                type: .flight,
                date: today9am,
                seatOrRoom: "Gate 14B · Seat 2A",
                barcodeData: "NH107-HND-JFK-SEAT-2A",
                notes: "Confirmed status · Boarding 10:45 AM · First Class Cabin",
                location: "HND Tokyo ➔ JFK New York",
                cost: 1450
            ),
            Booking(
                title: "TRUNK (HOTEL) Shibuya",
                provider: "TRUNK Hospitality Group",
                confirmationCode: "#TRK-8821",
                type: .hotel,
                date: today3pm,
                seatOrRoom: "Suite 402 · Check-in 3:00 PM (2 Nights)",
                barcodeData: "TRK-8821-CHECKIN-3PM",
                notes: "Complimentary breakfast & rooftop lounge access included.",
                location: "Shibuya, Tokyo, Japan",
                cost: 620
            ),
            Booking(
                title: "TeamLab Planets Tokyo",
                provider: "teamLab Planets Exhibition",
                confirmationCode: "TLP-VIP-994",
                type: .activity,
                date: today430pm,
                seatOrRoom: "VIP Express Pass · Entry 4:30 PM",
                barcodeData: "TLP-VIP-ENTRY-430PM",
                notes: "Fast-track entrance line & digital art souvenir kit included.",
                location: "Odaiba, Tokyo, Japan",
                cost: 85
            )
        ]
    }
}



