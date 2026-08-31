//
//  ItineraryModels.swift
//  WayPoint
//

import Foundation
import SwiftUI

// MARK: - Confidence Level

public enum ConfidenceLevel: String, Codable, CaseIterable, Identifiable, Sendable, Comparable {
    case high
    case medium
    case low

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .high: return "High Match"
        case .medium: return "Med Match"
        case .low: return "Needs Review"
        }
    }

    public var emoji: String {
        switch self {
        case .high: return "🟢"
        case .medium: return "🟡"
        case .low: return "🔴"
        }
    }

    public var badgeColor: Color {
        switch self {
        case .high: return WayPointTheme.cyanGlow
        case .medium: return WayPointTheme.budgetWarning
        case .low: return WayPointTheme.budgetOver
        }
    }

    public var badgeBackgroundColor: Color {
        badgeColor.opacity(0.16)
    }

    public static func < (lhs: ConfidenceLevel, rhs: ConfidenceLevel) -> Bool {
        let order: [ConfidenceLevel] = [.low, .medium, .high]
        guard let l = order.firstIndex(of: lhs), let r = order.firstIndex(of: rhs) else { return false }
        return l < r
    }
}

// MARK: - Import Candidate Struct

struct ImportCandidate: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var venueName: String
    var category: String
    var suggestedTime: String
    var estimatedCost: Double
    var confidenceScore: Double
    var extractedAddress: String
    var photoURL: URL?
    var isAccepted: Bool

    init(
        id: UUID = UUID(),
        venueName: String,
        category: String,
        suggestedTime: String,
        estimatedCost: Double,
        confidenceScore: Double,
        extractedAddress: String,
        photoURL: URL? = nil,
        isAccepted: Bool = true
    ) {
        self.id = id
        self.venueName = venueName
        self.category = category
        self.suggestedTime = suggestedTime
        self.estimatedCost = estimatedCost
        self.confidenceScore = min(max(confidenceScore, 0.0), 1.0)
        self.extractedAddress = extractedAddress
        self.photoURL = photoURL
        self.isAccepted = isAccepted
    }

    var confidenceLevel: ConfidenceLevel {
        if confidenceScore > 0.85 {
            return .high
        } else if confidenceScore >= 0.65 {
            return .medium
        } else {
            return .low
        }
    }

    var confidenceBadgeText: String {
        let percent = Int(round(confidenceScore * 100))
        return "\(confidenceLevel.emoji) \(percent)% \(confidenceLevel.title)"
    }

    var mappedCategory: ItemCategory {
        let lower = category.lowercased()
        if lower.contains("dining") || lower.contains("food") || lower.contains("ramen") || lower.contains("cafe") || lower.contains("coffee") || lower.contains("bakery") {
            return .dining
        } else if lower.contains("sightseeing") || lower.contains("museum") || lower.contains("art") || lower.contains("deck") || lower.contains("park") {
            return .sightseeing
        } else if lower.contains("nightlife") || lower.contains("bar") || lower.contains("pub") || lower.contains("club") {
            return .dining
        } else if lower.contains("shopping") || lower.contains("market") || lower.contains("mall") {
            return .shopping
        } else if lower.contains("leisure") || lower.contains("spa") || lower.contains("lounge") {
            return .leisure
        } else {
            return .sightseeing
        }
    }

    func toItineraryItem(baseDate: Date = Date()) -> ItineraryItem {
        let calendar = Calendar.current
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")

        let startTime: Date
        if let parsedTime = timeFormatter.date(from: suggestedTime) {
            let hour = calendar.component(.hour, from: parsedTime)
            let minute = calendar.component(.minute, from: parsedTime)
            startTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: baseDate) ?? baseDate
        } else {
            startTime = baseDate
        }
        let endTime = startTime.addingTimeInterval(5400) // Default 1.5 hours duration

        return ItineraryItem(
            id: UUID(),
            title: venueName,
            subtitle: extractedAddress.isEmpty ? category : extractedAddress,
            startTime: startTime,
            endTime: endTime,
            location: extractedAddress.isEmpty ? venueName : extractedAddress,
            category: mappedCategory,
            estimatedCost: Decimal(estimatedCost),
            isCompleted: false,
            coordinate: nil,
            notes: "Imported via AI Social Importer (\(Int(confidenceScore * 100))% confidence match).",
            currencyCode: "USD",
            rating: Double.random(in: 4.6...4.9),
            reviewCount: Int.random(in: 850...3500),
            priceTier: estimatedCost > 40 ? "$$$" : (estimatedCost > 15 ? "$$" : "$"),
            photoURL: photoURL,
            isIndoor: true,
            address: extractedAddress.isEmpty ? venueName : extractedAddress
        )
    }
}

// MARK: - Pre-populated Demo Candidate Collections

extension ImportCandidate {
    static let demoTikTokReel: [ImportCandidate] = [
        ImportCandidate(
            venueName: "Ichiran Ramen Shibuya",
            category: "Dining",
            suggestedTime: "11:30 AM",
            estimatedCost: 18.0,
            confidenceScore: 0.98,
            extractedAddress: "1-22-7 Jinnan, Shibuya City, Tokyo",
            photoURL: URL(string: "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600&auto=format&fit=crop&q=80"),
            isAccepted: true
        ),
        ImportCandidate(
            venueName: "teamLab Planets Tokyo",
            category: "Sightseeing",
            suggestedTime: "02:00 PM",
            estimatedCost: 32.0,
            confidenceScore: 0.94,
            extractedAddress: "6-1-16 Toyosu, Koto City, Tokyo",
            photoURL: URL(string: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop&q=80"),
            isAccepted: true
        ),
        ImportCandidate(
            venueName: "Shibuya Sky Sunset Deck",
            category: "Sightseeing",
            suggestedTime: "05:30 PM",
            estimatedCost: 22.0,
            confidenceScore: 0.91,
            extractedAddress: "2-24-12 Shibuya, Shibuya City, Tokyo",
            photoURL: URL(string: "https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=600&auto=format&fit=crop&q=80"),
            isAccepted: true
        ),
        ImportCandidate(
            venueName: "Golden Gai Omoide Yokocho Bar",
            category: "Nightlife",
            suggestedTime: "08:30 PM",
            estimatedCost: 45.0,
            confidenceScore: 0.88,
            extractedAddress: "1-1-6 Kabukicho, Shinjuku City, Tokyo",
            photoURL: URL(string: "https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=600&auto=format&fit=crop&q=80"),
            isAccepted: true
        )
    ]

    static let demoInstagramCafes: [ImportCandidate] = [
        ImportCandidate(
            venueName: "Koffee Mameya Omotesando",
            category: "Dining",
            suggestedTime: "09:00 AM",
            estimatedCost: 14.0,
            confidenceScore: 0.84,
            extractedAddress: "4-15-3 Jingumae, Shibuya City, Tokyo",
            photoURL: URL(string: "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=600&auto=format&fit=crop&q=80"),
            isAccepted: true
        ),
        ImportCandidate(
            venueName: "Cafe Reissue 3D Latte Art",
            category: "Leisure",
            suggestedTime: "11:30 AM",
            estimatedCost: 16.0,
            confidenceScore: 0.78,
            extractedAddress: "3-25-7 Jingumae, Shibuya City, Tokyo",
            photoURL: URL(string: "https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=600&auto=format&fit=crop&q=80"),
            isAccepted: true
        ),
        ImportCandidate(
            venueName: "Bear Pond Espresso Shimokitazawa",
            category: "Dining",
            suggestedTime: "02:30 PM",
            estimatedCost: 10.0,
            confidenceScore: 0.72,
            extractedAddress: "2-21-3 Kitazawa, Setagaya City, Tokyo",
            photoURL: URL(string: "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=600&auto=format&fit=crop&q=80"),
            isAccepted: true
        ),
        ImportCandidate(
            venueName: "Fuglen Tokyo Yoyogi Lounge",
            category: "Leisure",
            suggestedTime: "04:30 PM",
            estimatedCost: 12.0,
            confidenceScore: 0.81,
            extractedAddress: "1-16-11 Tomigaya, Shibuya City, Tokyo",
            photoURL: URL(string: "https://images.unsplash.com/photo-1442512595331-e89e73853f31?w=600&auto=format&fit=crop&q=80"),
            isAccepted: true
        )
    ]

    static let demoRawNotes: [ImportCandidate] = [
        ImportCandidate(
            venueName: "Roppongi Hills Sunset Terrace",
            category: "Sightseeing",
            suggestedTime: "06:00 PM",
            estimatedCost: 25.0,
            confidenceScore: 0.92,
            extractedAddress: "6-10-1 Roppongi, Minato City, Tokyo",
            photoURL: URL(string: "https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=600&auto=format&fit=crop&q=80"),
            isAccepted: true
        ),
        ImportCandidate(
            venueName: "Memory Lane Yakitori Alley",
            category: "Dining",
            suggestedTime: "07:45 PM",
            estimatedCost: 30.0,
            confidenceScore: 0.74,
            extractedAddress: "1-2 Nishi-Shinjuku, Shinjuku City, Tokyo",
            photoURL: URL(string: "https://images.unsplash.com/photo-1554797589-7241ab691973?w=600&auto=format&fit=crop&q=80"),
            isAccepted: true
        ),
        ImportCandidate(
            venueName: "Underground Jazz Lounge Speakeasy",
            category: "Nightlife",
            suggestedTime: "10:15 PM",
            estimatedCost: 50.0,
            confidenceScore: 0.58,
            extractedAddress: "Basement B2, 2-14-1 Ginza, Chuo City, Tokyo",
            photoURL: URL(string: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&auto=format&fit=crop&q=80"),
            isAccepted: false
        )
    ]
}
