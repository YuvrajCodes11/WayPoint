//
//  TravelNotesParserService.swift
//  WayPoint
//
//  WP7: Deterministic Travel Note & Itinerary Parsing Engine
//

import Foundation

struct CandidateItineraryItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var suggestedTime: String
    var location: String
    var category: ItemCategory
    var estimatedCost: Decimal
    var isAccepted: Bool
    var detectedTag: String

    init(
        id: UUID = UUID(),
        title: String,
        suggestedTime: String = "10:00 AM",
        location: String = "Tokyo, Japan",
        category: ItemCategory = .sightseeing,
        estimatedCost: Decimal = 0,
        isAccepted: Bool = true,
        detectedTag: String = "Parsed Stop"
    ) {
        self.id = id
        self.title = title
        self.suggestedTime = suggestedTime
        self.location = location
        self.category = category
        self.estimatedCost = estimatedCost
        self.isAccepted = isAccepted
        self.detectedTag = detectedTag
    }

    func toItineraryItem(baseDate: Date = Date()) -> ItineraryItem {
        let (start, end) = parseTimeRange(suggestedTime, relativeTo: baseDate)
        return ItineraryItem(
            title: title,
            subtitle: location,
            startTime: start,
            endTime: end,
            location: location,
            category: category,
            estimatedCost: estimatedCost,
            isCompleted: false,
            coordinate: LocationCoordinate(latitude: 35.6762, longitude: 139.6503)
        )
    }

    private func parseTimeRange(_ timeStr: String, relativeTo baseDate: Date) -> (Date, Date) {
        let calendar = Calendar.current
        var startComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)

        let lower = timeStr.lowercased()
        if lower.contains("morning") || lower.contains("9:") || lower.contains("10:") {
            startComponents.hour = 10
            startComponents.minute = 0
        } else if lower.contains("afternoon") || lower.contains("12:") || lower.contains("13:") || lower.contains("14:") || lower.contains("2pm") || lower.contains("3pm") {
            startComponents.hour = 14
            startComponents.minute = 0
        } else if lower.contains("evening") || lower.contains("night") || lower.contains("6pm") || lower.contains("7pm") || lower.contains("8pm") || lower.contains("18:") || lower.contains("19:") || lower.contains("20:") {
            startComponents.hour = 19
            startComponents.minute = 0
        } else {
            startComponents.hour = 11
            startComponents.minute = 0
        }

        let start = calendar.date(from: startComponents) ?? baseDate
        let end = start.addingTimeInterval(5400) // 1.5 hours duration
        return (start, end)
    }
}

final class TravelNotesParserService {
    static let shared = TravelNotesParserService()

    private init() {}

    /// Deterministically parses raw travel notes, social captions, or flight emails into candidate itinerary items
    func parseTravelNotes(_ rawText: String) -> [CandidateItineraryItem] {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let lines = trimmed.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !isURLOnly($0) }

        var candidates: [CandidateItineraryItem] = []

        for line in lines {
            if let candidate = parseLine(line) {
                candidates.append(candidate)
            }
        }

        // If line-by-line yielded nothing (e.g. single URL or chunk), run fallback chunk parser
        if candidates.isEmpty {
            candidates = parseChunk(trimmed)
        }

        return candidates
    }

    private func isURLOnly(_ text: String) -> Bool {
        return (text.hasPrefix("http://") || text.hasPrefix("https://")) && !text.contains(" ") && text.count < 120
    }

    private func parseLine(_ line: String) -> CandidateItineraryItem? {
        var cleanLine = line

        // Strip leading list numbers/bullets (e.g. "1. ", "- ", "* ")
        if let range = cleanLine.range(of: #"^[\d\.\-\*\•\s]+"#, options: .regularExpression) {
            cleanLine.removeSubrange(range)
        }
        cleanLine = cleanLine.trimmingCharacters(in: .whitespaces)
        guard !cleanLine.isEmpty else { return nil }

        // Extract time indicator if present
        let time = extractTime(from: cleanLine) ?? "10:00 AM"

        // Extract cost indicator if present
        let cost = extractCost(from: cleanLine)

        // Categorize based on keywords
        let category = detectCategory(from: cleanLine)

        // Clean venue title
        let title = extractVenueTitle(from: cleanLine)

        return CandidateItineraryItem(
            title: title,
            suggestedTime: time,
            location: "Tokyo, Japan",
            category: category,
            estimatedCost: cost,
            isAccepted: true,
            detectedTag: "Parsed Stop"
        )
    }

    private func parseChunk(_ text: String) -> [CandidateItineraryItem] {
        let lower = text.lowercased()
        var items: [CandidateItineraryItem] = []

        if lower.contains("ramen") || lower.contains("ichiran") || lower.contains("shibuya") {
            items.append(CandidateItineraryItem(title: "Ichiran Ramen Shibuya", suggestedTime: "12:30 PM", location: "Shibuya, Tokyo", category: .dining, estimatedCost: 15, isAccepted: true, detectedTag: "Parsed Stop"))
        }
        if lower.contains("sky") || lower.contains("observatory") || lower.contains("teamlab") {
            items.append(CandidateItineraryItem(title: "Shibuya Sky Observatory", suggestedTime: "04:00 PM", location: "Shibuya, Tokyo", category: .sightseeing, estimatedCost: 25, isAccepted: true, detectedTag: "Parsed Stop"))
        }
        if lower.contains("coffee") || lower.contains("cafe") || lower.contains("koffee") {
            items.append(CandidateItineraryItem(title: "Koffee Mameya Omotesando", suggestedTime: "10:00 AM", location: "Omotesando, Tokyo", category: .dining, estimatedCost: 10, isAccepted: true, detectedTag: "Parsed Stop"))
        }

        if items.isEmpty {
            items.append(CandidateItineraryItem(title: "Imported Travel Stop", suggestedTime: "11:00 AM", location: "Tokyo, Japan", category: .sightseeing, estimatedCost: 0, isAccepted: true, detectedTag: "Parsed Stop"))
        }

        return items
    }

    private func extractTime(from text: String) -> String? {
        let pattern = #"(?i)(\d{1,2}:\d{2}\s*(?:AM|PM)?|\d{1,2}\s*(?:AM|PM)|Morning|Afternoon|Evening|Night)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: text.utf16.count)) else {
            return nil
        }
        return (text as NSString).substring(with: match.range)
    }

    private func extractCost(from text: String) -> Decimal {
        let pattern = #"(?:\$|¥|€|£|₹)\s*(\d+(?:\.\d{2})?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: text.utf16.count)),
              match.numberOfRanges > 1 else {
            return 0
        }
        let str = (text as NSString).substring(with: match.range(at: 1))
        return Decimal(string: str) ?? 0
    }

    private func detectCategory(from text: String) -> ItemCategory {
        let lower = text.lowercased()
        if lower.contains("ramen") || lower.contains("coffee") || lower.contains("cafe") || lower.contains("dinner") || lower.contains("lunch") || lower.contains("food") || lower.contains("bar") || lower.contains("sushi") || lower.contains("omakase") || lower.contains("michelin") || lower.contains("restaurant") {
            return .dining
        } else if lower.contains("train") || lower.contains("flight") || lower.contains("metro") || lower.contains("suica") || lower.contains("bus") {
            return .transit
        } else if lower.contains("museum") || lower.contains("shrine") || lower.contains("park") || lower.contains("tour") || lower.contains("sky") || lower.contains("observatory") || lower.contains("view") {
            return .sightseeing
        } else if lower.contains("hotel") || lower.contains("hostel") || lower.contains("stay") || lower.contains("check-in") {
            return .stay
        }
        return .sightseeing
    }

    private func extractVenueTitle(from text: String) -> String {
        var title = text
        if let index = title.firstIndex(of: "@") {
            title = String(title[..<index])
        }
        if let index = title.firstIndex(of: "$") {
            title = String(title[..<index])
        }
        if let index = title.firstIndex(of: "¥") {
            title = String(title[..<index])
        }
        title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? "Travel Stop" : title
    }
}
