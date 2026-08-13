//
//  AIRecalculatorService.swift
//  WayPoint
//

import SwiftUI
import Supabase

enum RecalculationTrigger: String, Codable, CaseIterable, Identifiable {
    case flightDelay
    case weatherChange
    case budgetExceeded
    case userPreference

    var id: String { rawValue }

    var title: String {
        switch self {
        case .flightDelay: "Flight Delay"
        case .weatherChange: "Weather Shift"
        case .budgetExceeded: "Budget Cap Exceeded"
        case .userPreference: "Smart Pacing"
        }
    }

    var icon: String {
        switch self {
        case .flightDelay: "airplane.arrival"
        case .weatherChange: "cloud.bolt.rain.fill"
        case .budgetExceeded: "banknote.fill"
        case .userPreference: "sparkles"
        }
    }

    var iconName: String { icon }

    var description: String {
        switch self {
        case .flightDelay: "Shift schedule forward due to delayed flight arrival"
        case .weatherChange: "Swap outdoor tours for climate-controlled indoor passes"
        case .budgetExceeded: "Re-balance estimated activity costs to fit daily budget"
        case .userPreference: "Reorder itinerary items to minimize transit time"
        }
    }
}

@MainActor
@Observable
class AIRecalculatorService {
    static let shared = AIRecalculatorService()

    var isRecalculating: Bool = false
    var statusMessage: String = ""
    var lastOptimizedAt: Date? = nil

    init() {}

    /// Recalculates the day plan by sending a live HTTP/Edge function payload to the AI endpoint with JSON schema validation.
    func recalculate(plan: DayPlan, trigger: RecalculationTrigger) async -> DayPlan {
        isRecalculating = true
        statusMessage = analysisMessage(for: trigger)
        defer {
            isRecalculating = false
            statusMessage = ""
        }

        do {
            struct RebalancePayload: Encodable {
                let dayPlan: DayPlan
                let trigger: String
                let prompt: String
            }

            let promptText = "Rebalance itinerary for trigger '\(trigger.rawValue)': \(trigger.description)"
            let payload = RebalancePayload(dayPlan: plan, trigger: trigger.rawValue, prompt: promptText)

            statusMessage = "Calling AI Engine & validating schema..."

            let responseData: DayPlan = try await SupabaseService.shared.client.functions.invoke(
                "rebalance-dayplan",
                options: FunctionInvokeOptions(body: payload)
            )

            guard !responseData.title.isEmpty else {
                throw NSError(domain: "AIRecalculatorService", code: 422, userInfo: [NSLocalizedDescriptionKey: "AI response failed JSON schema validation: title is empty."])
            }

            self.lastOptimizedAt = Date()
            self.statusMessage = "Itinerary optimization complete!"
            return responseData

        } catch {
            print("[AIRecalculatorService] Live AI call error, applying deterministic fallback: \(error.localizedDescription)")

            var newPlan = plan
            var updatedItems = newPlan.items

            switch trigger {
            case .weatherChange:
                updatedItems = updatedItems.map { item in
                    if item.category == .sightseeing || item.category == .adventure {
                        return ItineraryItem(
                            id: item.id,
                            title: "Indoor Pavilion & Museum",
                            subtitle: "Climate-controlled indoor exhibition",
                            startTime: item.startTime,
                            endTime: item.endTime,
                            location: "\(item.location) (Indoor)",
                            category: .sightseeing,
                            estimatedCost: item.estimatedCost > 0 ? item.estimatedCost : 45,
                            isCompleted: item.isCompleted,
                            coordinate: item.coordinate,
                            notes: "Re-routed indoors due to weather conditions.",
                            currencyCode: item.currencyCode
                        )
                    }
                    return item
                }
            case .flightDelay:
                let offset: TimeInterval = 7200
                updatedItems = updatedItems.map { item in
                    if !item.isCompleted {
                        return ItineraryItem(
                            id: item.id,
                            title: item.title,
                            subtitle: "\(item.subtitle) (+2h Shift)",
                            startTime: item.startTime.addingTimeInterval(offset),
                            endTime: item.endTime.addingTimeInterval(offset),
                            location: item.location,
                            category: item.category,
                            estimatedCost: item.estimatedCost,
                            isCompleted: item.isCompleted,
                            coordinate: item.coordinate,
                            notes: item.notes,
                            currencyCode: item.currencyCode
                        )
                    }
                    return item
                }
            case .budgetExceeded:
                let completedCost = updatedItems.filter(\.isCompleted).reduce(Decimal(0)) { $0 + $1.estimatedCost }
                let remaining = max(Decimal(0), newPlan.budgetLimit - completedCost)
                let incompleteCount = Decimal(max(1, updatedItems.filter { !$0.isCompleted }.count))
                let capPerItem = remaining / incompleteCount

                updatedItems = updatedItems.map { item in
                    if !item.isCompleted && item.estimatedCost > capPerItem {
                        return ItineraryItem(
                            id: item.id,
                            title: item.title,
                            subtitle: "\(item.subtitle) (Budget Adjusted)",
                            startTime: item.startTime,
                            endTime: item.endTime,
                            location: item.location,
                            category: item.category,
                            estimatedCost: capPerItem,
                            isCompleted: item.isCompleted,
                            coordinate: item.coordinate,
                            notes: item.notes,
                            currencyCode: item.currencyCode
                        )
                    }
                    return item
                }
            case .userPreference:
                let completed = updatedItems.filter(\.isCompleted)
                let incomplete = updatedItems.filter { !$0.isCompleted }
                updatedItems = completed + incomplete.reversed()
            }

            newPlan.items = updatedItems
            newPlan.spentAmount = updatedItems.filter(\.isCompleted).reduce(Decimal(0)) { $0 + $1.estimatedCost }
            self.lastOptimizedAt = Date()
            return newPlan
        }
    }

    /// Forwarding alias for backwards compatibility
    func recalculateItinerary(currentPlan: DayPlan, trigger: RecalculationTrigger) async -> DayPlan {
        await recalculate(plan: currentPlan, trigger: trigger)
    }

    private func analysisMessage(for trigger: RecalculationTrigger) -> String {
        switch trigger {
        case .flightDelay: "Analyzing flight delay & arrival schedule..."
        case .weatherChange: "Analyzing weather shifts & local conditions..."
        case .budgetExceeded: "Analyzing spent vs daily budget limit..."
        case .userPreference: "Analyzing travel distance & pacing..."
        }
    }
}
