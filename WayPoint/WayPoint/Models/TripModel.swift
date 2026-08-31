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

    var emoji: String {
        switch self {
        case .dining: "🍽️"
        case .sightseeing: "🏛️"
        case .transit, .transport: "🚘"
        case .stay: "🏨"
        case .leisure: "✨"
        case .shopping: "🛍️"
        case .adventure: "🥾"
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
    var userID: UUID?
    var title: String
    var destination: String
    var travelerName: String
    var currencyCode: String
    var days: [DayPlan]
    var selectedDayIndex: Int
    var version: Int
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, destination, days, version
        case userID = "user_id"
        case travelerName = "traveler_name"
        case currencyCode = "currency_code"
        case selectedDayIndex = "selected_day_index"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        userID: UUID? = nil,
        title: String,
        destination: String,
        travelerName: String,
        currencyCode: String = "USD",
        days: [DayPlan],
        selectedDayIndex: Int = 0,
        version: Int = 1,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userID = userID
        self.title = title
        self.destination = destination
        self.travelerName = travelerName
        self.currencyCode = currencyCode
        self.days = days
        self.selectedDayIndex = selectedDayIndex
        self.version = version
        self.updatedAt = updatedAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.userID = try container.decodeIfPresent(UUID.self, forKey: .userID)
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.destination = try container.decodeIfPresent(String.self, forKey: .destination) ?? ""
        self.travelerName = try container.decodeIfPresent(String.self, forKey: .travelerName) ?? ""
        self.currencyCode = try container.decodeIfPresent(String.self, forKey: .currencyCode) ?? "USD"
        self.days = try container.decodeIfPresent([DayPlan].self, forKey: .days) ?? []
        self.selectedDayIndex = try container.decodeIfPresent(Int.self, forKey: .selectedDayIndex) ?? 0
        self.version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(userID, forKey: .userID)
        try container.encode(title, forKey: .title)
        try container.encode(destination, forKey: .destination)
        try container.encode(travelerName, forKey: .travelerName)
        try container.encode(currencyCode, forKey: .currencyCode)
        try container.encode(days, forKey: .days)
        try container.encode(selectedDayIndex, forKey: .selectedDayIndex)
        try container.encode(version, forKey: .version)
        try container.encode(updatedAt, forKey: .updatedAt)
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

    var hasUniqueEntityIDs: Bool {
        let dayIDs = days.map(\.id)
        if dayIDs.count != Set(dayIDs).count { return false }
        let itemIDs = days.flatMap { $0.items.map(\.id) }
        return itemIDs.count == Set(itemIDs).count
    }

    func sanitizeUniqueIdentifiers() {
        var seenDayIDs = Set<UUID>()
        var seenItemIDs = Set<UUID>()
        var sanitizedDays: [DayPlan] = []

        for var day in days {
            var dayID = day.id
            while seenDayIDs.contains(dayID) {
                dayID = UUID()
            }
            seenDayIDs.insert(dayID)

            var sanitizedItems: [ItineraryItem] = []
            for var item in day.items {
                var itemID = item.id
                while seenItemIDs.contains(itemID) {
                    itemID = UUID()
                }
                seenItemIDs.insert(itemID)

                if itemID != item.id {
                    item = ItineraryItem(
                        id: itemID,
                        title: item.title,
                        subtitle: item.subtitle,
                        startTime: item.startTime,
                        endTime: item.endTime,
                        location: item.location,
                        category: item.category,
                        estimatedCost: item.estimatedCost,
                        isCompleted: item.isCompleted,
                        coordinate: item.coordinate,
                        notes: item.notes,
                        currencyCode: item.currencyCode,
                        rating: item.rating,
                        reviewCount: item.reviewCount,
                        priceTier: item.priceTier,
                        photoURL: item.photoURL,
                        isIndoor: item.isIndoor,
                        address: item.address,
                        ghostAlternatives: item.ghostAlternatives,
                        departureTimeZoneIdentifier: item.departureTimeZoneIdentifier,
                        arrivalTimeZoneIdentifier: item.arrivalTimeZoneIdentifier,
                        isPreservedReservation: item.isPreservedReservation,
                        pivotReason: item.pivotReason,
                        originalTimeSlot: item.originalTimeSlot
                    )
                }
                sanitizedItems.append(item)
            }

            if dayID != day.id || sanitizedItems != day.items {
                day = DayPlan(
                    id: dayID,
                    date: day.date,
                    title: day.title,
                    budgetLimit: day.budgetLimit,
                    spentAmount: day.spentAmount,
                    items: sanitizedItems,
                    currencyCode: day.currencyCode
                )
            }
            sanitizedDays.append(day)
        }
        self.days = sanitizedDays
    }
}

// MARK: - Empty & Sample Initializers

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

    static func createSampleTrip(id: UUID = UUID()) -> Trip {
        let base = sample
        return Trip(
            id: id,
            userID: base.userID,
            title: base.title,
            destination: base.destination,
            travelerName: base.travelerName,
            currencyCode: base.currencyCode,
            days: base.days,
            selectedDayIndex: base.selectedDayIndex,
            version: base.version,
            updatedAt: base.updatedAt
        )
    }

    static var sample: Trip {
        let calendar = Calendar.current
        let now = Date()
        let today9am = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
        let today11am = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: now) ?? now
        let today1pm = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: now) ?? now
        let today3pm = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: now) ?? now
        let today5pm = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: now) ?? now
        let today6pm = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now
        let today7pm = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: now) ?? now
        let today8pm = calendar.date(bySettingHour: 20, minute: 30, second: 0, of: now) ?? now

        // Pre-cached Ghost Alternatives
        let MoriDigitalArtMuseum = ItineraryItem(
            title: "Mori Digital Art Museum",
            subtitle: "Interactive teamLab digital light installation & indoor mirrors",
            startTime: today11am,
            endTime: today1pm,
            location: "Odaiba, Tokyo",
            category: .sightseeing,
            estimatedCost: 85,
            isCompleted: false,
            coordinate: LocationCoordinate(latitude: 35.6277, longitude: 139.7749),
            notes: "Indoor alternative with climate control.",
            rating: 4.9,
            reviewCount: 4200,
            priceTier: "$$$",
            photoURL: URL(string: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop&q=80"),
            isIndoor: true,
            address: "1-3-15 Aomi, Koto City, Tokyo"
        )

        let TokyoNationalMuseum = ItineraryItem(
            title: "Tokyo National Museum",
            subtitle: "Ancient Japanese art, samurai armor, & imperial gallery",
            startTime: today11am,
            endTime: today1pm,
            location: "Ueno Park, Taito City, Tokyo",
            category: .sightseeing,
            estimatedCost: 85,
            isCompleted: false,
            coordinate: LocationCoordinate(latitude: 35.7188, longitude: 139.7765),
            notes: "National treasure indoor climate-controlled exhibit.",
            rating: 4.8,
            reviewCount: 2900,
            priceTier: "$$",
            photoURL: URL(string: "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600&auto=format&fit=crop&q=80"),
            isIndoor: true,
            address: "13-9 Uenokoen, Taito City, Tokyo"
        )

        let GinzaSixGallery = ItineraryItem(
            title: "Ginza Six Covered Gallery",
            subtitle: "Luxury atrium art installations & roof garden pavilion",
            startTime: today3pm,
            endTime: today6pm,
            location: "Ginza Six, Chuo City, Tokyo",
            category: .shopping,
            estimatedCost: 50,
            isCompleted: false,
            coordinate: LocationCoordinate(latitude: 35.6713, longitude: 139.7650),
            notes: "Fully covered indoor shopping gallery & architectural atrium.",
            rating: 4.8,
            reviewCount: 2100,
            priceTier: "$$$",
            photoURL: URL(string: "https://images.unsplash.com/photo-1567449303078-57ad995bd301?w=600&auto=format&fit=crop&q=80"),
            isIndoor: true,
            address: "6-10-1 Ginza, Chuo City, Tokyo"
        )

        let NezuMuseumTeaSalon = ItineraryItem(
            title: "Nezu Museum & Tea Salon",
            subtitle: "Pre-modern art gallery & glass-enclosed indoor garden lounge",
            startTime: today3pm,
            endTime: today6pm,
            location: "Minato City, Tokyo",
            category: .leisure,
            estimatedCost: 50,
            isCompleted: false,
            coordinate: LocationCoordinate(latitude: 35.6625, longitude: 139.7171),
            notes: "Covered glass pavilion & serene indoor lounge.",
            rating: 4.9,
            reviewCount: 1450,
            priceTier: "$$",
            photoURL: URL(string: "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=600&auto=format&fit=crop&q=80"),
            isIndoor: true,
            address: "6-5-1 Minamiaoyama, Minato City, Tokyo"
        )

        let EdoTokyoMuseum = ItineraryItem(
            title: "Edo-Tokyo Museum Pavilion",
            subtitle: "Life-sized Edo architectural scale models & indoor theater",
            startTime: today9am,
            endTime: today11am,
            location: "Ryogoku, Sumida City, Tokyo",
            category: .sightseeing,
            estimatedCost: 35,
            isCompleted: false,
            coordinate: LocationCoordinate(latitude: 35.6963, longitude: 139.7958),
            notes: "Immersive historic indoor experience.",
            rating: 4.8,
            reviewCount: 1890,
            priceTier: "$$",
            photoURL: URL(string: "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600&auto=format&fit=crop&q=80"),
            isIndoor: true,
            address: "1-4-1 Yokoami, Sumida City, Tokyo"
        )

        let TokyoMetropolitanTheatre = ItineraryItem(
            title: "Tokyo Metropolitan Theatre",
            subtitle: "Symphonic concert hall & indoor art exhibit spaces",
            startTime: today9am,
            endTime: today11am,
            location: "Ikebukuro, Toshima City, Tokyo",
            category: .sightseeing,
            estimatedCost: 20,
            isCompleted: false,
            coordinate: LocationCoordinate(latitude: 35.7289, longitude: 139.7094),
            notes: "Architectural indoor arts complex.",
            rating: 4.7,
            reviewCount: 1250,
            priceTier: "$$",
            photoURL: URL(string: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&auto=format&fit=crop&q=80"),
            isIndoor: true,
            address: "1-8-1 Nishi-Ikebukuro, Toshima City, Tokyo"
        )

        // Day 1 Items
        let day1Items = [
            ItineraryItem(
                title: "Boutique Hotel Breakfast",
                subtitle: "Artisanal matcha espresso & fluffy Japanese soufflé pancakes",
                startTime: today9am,
                endTime: today11am,
                location: "TRUNK (HOTEL), Shibuya, Tokyo",
                category: .dining,
                estimatedCost: 45,
                isCompleted: true,
                coordinate: LocationCoordinate(latitude: 35.6653, longitude: 139.7025),
                rating: 4.8,
                reviewCount: 1420,
                priceTier: "$$$",
                photoURL: URL(string: "https://images.unsplash.com/photo-1533089860892-a7c6f0a88666?w=600&auto=format&fit=crop&q=80"),
                isIndoor: true,
                address: "5-31 Jingumae, Shibuya City, Tokyo"
            ),
            ItineraryItem(
                title: "Shinjuku Gyoen National Garden",
                subtitle: "Historic emperor's garden walk & serene landscape photography",
                startTime: today11am,
                endTime: today1pm,
                location: "Shinjuku City, Tokyo",
                category: .sightseeing,
                estimatedCost: 85,
                isCompleted: false,
                coordinate: LocationCoordinate(latitude: 35.6852, longitude: 139.7101),
                rating: 4.9,
                reviewCount: 3850,
                priceTier: "$$",
                photoURL: URL(string: "https://images.unsplash.com/photo-1583847268964-b28dc8f51f92?w=600&auto=format&fit=crop&q=80"),
                isIndoor: false,
                address: "11 Naitomachi, Shinjuku City, Tokyo",
                ghostAlternatives: [MoriDigitalArtMuseum, TokyoNationalMuseum]
            ),
            ItineraryItem(
                title: "Ginza Designer Shopping Alley",
                subtitle: "Explore high-fashion flagship boutiques & traditional stationery crafts",
                startTime: today1pm,
                endTime: today3pm,
                location: "Ginza Six, Chuo City, Tokyo",
                category: .shopping,
                estimatedCost: 120,
                isCompleted: false,
                coordinate: LocationCoordinate(latitude: 35.6713, longitude: 139.7650),
                rating: 4.7,
                reviewCount: 1950,
                priceTier: "$$$",
                photoURL: URL(string: "https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=600&auto=format&fit=crop&q=80"),
                isIndoor: true,
                address: "6-10-1 Ginza, Chuo City, Tokyo"
            ),
            ItineraryItem(
                title: "Omotesando Architecture Walk",
                subtitle: "Stroll along tree-lined avenues featuring avant-garde glass facades",
                startTime: today3pm,
                endTime: today6pm,
                location: "Omotesando Hills, Harajuku, Tokyo",
                category: .leisure,
                estimatedCost: 50,
                isCompleted: false,
                coordinate: LocationCoordinate(latitude: 35.6672, longitude: 139.7060),
                rating: 4.8,
                reviewCount: 1620,
                priceTier: "$$",
                photoURL: URL(string: "https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=600&auto=format&fit=crop&q=80"),
                isIndoor: false,
                address: "4-12-10 Jingumae, Shibuya City, Tokyo",
                ghostAlternatives: [GinzaSixGallery, NezuMuseumTeaSalon]
            ),
            ItineraryItem(
                title: "Omakase Sushi & Sake Tasting",
                subtitle: "Michelin-recommended multi-course chef's seasonal dining experience",
                startTime: today6pm,
                endTime: today8pm,
                location: "Sushi Yoshitake, Ginza, Tokyo",
                category: .dining,
                estimatedCost: 150,
                isCompleted: false,
                coordinate: LocationCoordinate(latitude: 35.6698, longitude: 139.7632),
                rating: 4.9,
                reviewCount: 2400,
                priceTier: "$$$$",
                photoURL: URL(string: "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=600&auto=format&fit=crop&q=80"),
                isIndoor: true,
                address: "7-8-13 Ginza, Chuo City, Tokyo",
                isPreservedReservation: true
            )
        ]

        // Day 2 Items
        let day2Items = [
            ItineraryItem(
                title: "Senso-ji Historic Temple Grounds",
                subtitle: "Traditional incense rituals & Nakamise street food tasting",
                startTime: today9am,
                endTime: today11am,
                location: "Asakusa, Taito City, Tokyo",
                category: .sightseeing,
                estimatedCost: 35,
                isCompleted: true,
                coordinate: LocationCoordinate(latitude: 35.7148, longitude: 139.7967),
                rating: 4.9,
                reviewCount: 5200,
                priceTier: "Free",
                photoURL: URL(string: "https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=600&auto=format&fit=crop&q=80"),
                isIndoor: false,
                address: "2-3-1 Asakusa, Taito City, Tokyo",
                ghostAlternatives: [EdoTokyoMuseum]
            ),
            ItineraryItem(
                title: "Sumida River Scenic Cruise",
                subtitle: "Water bus transit to Odaiba futuristic waterfront park",
                startTime: today11am,
                endTime: today1pm,
                location: "Asakusa Pier to Odaiba, Tokyo",
                category: .transit,
                estimatedCost: 40,
                isCompleted: false,
                coordinate: LocationCoordinate(latitude: 35.6277, longitude: 139.7749),
                rating: 4.7,
                reviewCount: 1100,
                priceTier: "$$",
                photoURL: URL(string: "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=600&auto=format&fit=crop&q=80"),
                isIndoor: false,
                address: "1-1-1 Hanakawado, Taito City, Tokyo"
            ),
            ItineraryItem(
                title: "Wagyu Teppanyaki Dinner",
                subtitle: "A5 Kobe beef grilled live over charcoal embers",
                startTime: today6pm,
                endTime: today8pm,
                location: "Shinjuku City, Tokyo",
                category: .dining,
                estimatedCost: 180,
                isCompleted: false,
                coordinate: LocationCoordinate(latitude: 35.6938, longitude: 139.7034),
                rating: 4.9,
                reviewCount: 3100,
                priceTier: "$$$$",
                photoURL: URL(string: "https://images.unsplash.com/photo-1544025162-d76694265947?w=600&auto=format&fit=crop&q=80"),
                isIndoor: true,
                address: "3-14-1 Kabukicho, Shinjuku City, Tokyo"
            )
        ]

        // Day 3 Items
        let day3Items = [
            ItineraryItem(
                title: "Meiji Jingu Forest Trail Walk",
                subtitle: "Serene morning walk through sacred evergreen forest trails",
                startTime: today9am,
                endTime: today11am,
                location: "Yoyogi Park, Shibuya, Tokyo",
                category: .adventure,
                estimatedCost: 20,
                isCompleted: true,
                coordinate: LocationCoordinate(latitude: 35.6764, longitude: 139.6993),
                rating: 4.8,
                reviewCount: 4100,
                priceTier: "Free",
                photoURL: URL(string: "https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=600&auto=format&fit=crop&q=80"),
                isIndoor: false,
                address: "1-1 Yoyogikamizonocho, Shibuya City, Tokyo",
                ghostAlternatives: [TokyoMetropolitanTheatre]
            ),
            ItineraryItem(
                title: "Roppongi Hills Sunset Deck",
                subtitle: "360-degree panoramic skyline views of Tokyo Tower and Mount Fuji",
                startTime: today5pm,
                endTime: today7pm,
                location: "Tokyo City View Observatory, Roppongi",
                category: .sightseeing,
                estimatedCost: 60,
                isCompleted: false,
                coordinate: LocationCoordinate(latitude: 35.6605, longitude: 139.7292),
                rating: 4.8,
                reviewCount: 2800,
                priceTier: "$$$",
                photoURL: URL(string: "https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=600&auto=format&fit=crop&q=80"),
                isIndoor: false,
                address: "6-10-1 Roppongi, Minato City, Tokyo"
            )
        ]

        let day1 = DayPlan(
            date: now,
            title: "City Skyline & District Walk",
            budgetLimit: 450,
            spentAmount: 45,
            items: day1Items
        )

        let day2 = DayPlan(
            date: calendar.date(byAdding: .day, value: 1, to: now) ?? now,
            title: "Historic Temples & Waterfront",
            budgetLimit: 400,
            spentAmount: 0,
            items: day2Items
        )

        let day3 = DayPlan(
            date: calendar.date(byAdding: .day, value: 2, to: now) ?? now,
            title: "Forest Trails & Panoramic Sunset",
            budgetLimit: 350,
            spentAmount: 20,
            items: day3Items
        )

        return Trip(
            title: "Tokyo 3-Day Design & Culinary Tour",
            destination: "Tokyo, Japan",
            travelerName: "Yuvraj",
            currencyCode: "USD",
            days: [day1, day2, day3],
            selectedDayIndex: 0
        )
    }
}
