//
//  UndoPivotManager.swift
//  WayPoint
//
//  WP5: Day-Scoped Undo & Persistent History Stack Engine
//

import SwiftUI

struct PivotHistoryEntry: Codable, Identifiable {
    let id: UUID
    let tripID: UUID
    let dayID: UUID
    let originalDay: DayPlan
    let result: PivotResult
    let timestamp: Date

    init(
        id: UUID = UUID(),
        tripID: UUID,
        dayID: UUID,
        originalDay: DayPlan,
        result: PivotResult,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.tripID = tripID
        self.dayID = dayID
        self.originalDay = originalDay
        self.result = result
        self.timestamp = timestamp
    }
}

@MainActor
@Observable
final class UndoPivotManager {
    static let shared = UndoPivotManager()
    private let storageKey = "waypoint_pivot_history_v1"
    private let legacyStorageKey = "waypoint_pivot_undo_history_v1"

    var historyStack: [PivotHistoryEntry]

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let entries = try? JSONDecoder().decode([PivotHistoryEntry].self, from: data) {
            self.historyStack = entries
        } else if let legacyData = UserDefaults.standard.data(forKey: legacyStorageKey),
                  let entries = try? JSONDecoder().decode([PivotHistoryEntry].self, from: legacyData) {
            self.historyStack = entries
        } else {
            self.historyStack = []
        }
    }

    var canUndo: Bool { !historyStack.isEmpty }
    var lastResult: PivotResult? { historyStack.last?.result }

    /// Checks if an undo entry exists for a specific dayID
    func canUndo(dayID: UUID) -> Bool {
        historyStack.contains(where: { $0.dayID == dayID })
    }

    /// Convenience forwarder for backwards compatibility
    func canUndo(for dayID: UUID) -> Bool {
        canUndo(dayID: dayID)
    }

    func lastResult(for dayID: UUID) -> PivotResult? {
        historyStack.last(where: { $0.dayID == dayID })?.result
    }

    /// Pushes the current pre-pivot state onto the day-isolated history stack.
    func pushState(dayID: UUID, tripID: UUID, originalDay: DayPlan, result: PivotResult? = nil) {
        let entryResult = result ?? PivotResult(
            previousPlan: originalDay,
            rebalancedPlan: originalDay,
            disruptionEvent: DisruptionEvent(type: .weatherRain),
            minutesRecovered: 0,
            explanations: []
        )
        let entry = PivotHistoryEntry(tripID: tripID, dayID: dayID, originalDay: originalDay, result: entryResult)
        historyStack.append(entry)
        persist()
    }

    /// Record pivot result with original plan
    func recordPivot(_ result: PivotResult, tripID: UUID, dayID: UUID) {
        let entry = PivotHistoryEntry(tripID: tripID, dayID: dayID, originalDay: result.previousPlan, result: result)
        historyStack.append(entry)
        persist()
    }

    /// Undoes the last pivot for the specific dayID, restoring originalDay in the trip
    @discardableResult
    func undoLastPivot(dayID: UUID, in trip: inout Trip) -> DayPlan? {
        guard let index = historyStack.lastIndex(where: { $0.dayID == dayID }) else { return nil }
        let entry = historyStack.remove(at: index)
        persist()

        if let dayIndex = trip.days.firstIndex(where: { $0.id == dayID }) {
            trip.days[dayIndex] = entry.originalDay
        }
        return entry.originalDay
    }

    /// Backwards compatibility overload
    @discardableResult
    func undoLastPivot(for tripID: UUID, dayID: UUID? = nil) -> PivotHistoryEntry? {
        let targetIndex: Int?
        if let dayID = dayID {
            targetIndex = historyStack.lastIndex(where: { $0.tripID == tripID && $0.dayID == dayID })
        } else {
            targetIndex = historyStack.lastIndex(where: { $0.tripID == tripID })
        }
        guard let index = targetIndex else { return nil }
        let entry = historyStack.remove(at: index)
        persist()
        return entry
    }

    func clear() {
        historyStack.removeAll()
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(historyStack) {
            UserDefaults.standard.set(data, forKey: storageKey)
            UserDefaults.standard.set(data, forKey: legacyStorageKey)
        }
    }
}
