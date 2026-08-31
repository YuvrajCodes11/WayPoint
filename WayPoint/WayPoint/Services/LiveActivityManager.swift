//
//  LiveActivityManager.swift
//  WayPoint
//
//  Task 4.1 / WP6: ActivityKit Lifecycle, 8-Hour Auto Expiration & Safe Distance Calculator
//

import Foundation
import ActivityKit
import SwiftUI
import CoreLocation

@MainActor
@Observable
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<WayPointActivityAttributes>? = nil
    var isActivityActive: Bool = false
    var activeVenueName: String = ""
    var activeVenueDistance: Int = 450

    private init() {
        checkActiveActivities()
    }

    /// Check if there is an ongoing Activity running
    func checkActiveActivities() {
        if #available(iOS 16.1, *) {
            self.currentActivity = Activity<WayPointActivityAttributes>.activities.first
            self.isActivityActive = self.currentActivity != nil
            if let first = self.currentActivity {
                self.activeVenueName = first.content.state.currentVenueName
                self.activeVenueDistance = first.content.state.distanceMeters
            }
        }
    }

    /// Request & start a Live Activity for the active itinerary stop
    func startTripActivity(trip: Trip, currentItem: ItineraryItem, nextItem: ItineraryItem? = nil) {
        let computedDistance = dynamicDistanceMeters(to: currentItem)

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("[LiveActivityManager] Live Activities are not enabled on this device/simulator. Activating in-app radar mode.")
            self.isActivityActive = true
            self.activeVenueName = currentItem.title
            self.activeVenueDistance = computedDistance
            return
        }

        let attributes = WayPointActivityAttributes(
            tripName: trip.title,
            dayTitle: "Day \(trip.selectedDayIndex + 1): \(trip.currentDayPlan.title)"
        )

        let initialContentState = WayPointActivityAttributes.ContentState(
            currentVenueName: currentItem.title,
            nextVenueName: nextItem?.title ?? "",
            nextVenueTime: nextItem?.timeRange.components(separatedBy: "–").first?.trimmingCharacters(in: .whitespaces) ?? "",
            distanceMeters: computedDistance,
            budgetUsedPercent: trip.currentDayPlan.budgetProgress,
            spentAmount: trip.currentDayPlan.formatCurrency(trip.currentDayPlan.spentAmount),
            remainingAmount: trip.currentDayPlan.formattedRemaining
        )

        let staleDate = Calendar.current.date(byAdding: .hour, value: 8, to: Date())
        let content = ActivityContent(state: initialContentState, staleDate: staleDate)

        do {
            let activity = try Activity<WayPointActivityAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            self.currentActivity = activity
            self.isActivityActive = true
            self.activeVenueName = currentItem.title
            self.activeVenueDistance = computedDistance
            print("[LiveActivityManager] Successfully started Live Activity \(activity.id)")
        } catch {
            print("[LiveActivityManager] Error starting Live Activity: \(error.localizedDescription). Falling back to in-app radar.")
            self.isActivityActive = true
            self.activeVenueName = currentItem.title
            self.activeVenueDistance = computedDistance
        }
    }

    /// Update active Live Activity state
    func updateCurrentStop(
        currentItem: ItineraryItem,
        nextItem: ItineraryItem? = nil,
        distanceMeters: Int? = nil,
        budgetProgress: Double = 0.35,
        spentAmount: String = "$150",
        remainingAmount: String = "$300"
    ) {
        let dist = distanceMeters ?? dynamicDistanceMeters(to: currentItem)
        self.activeVenueName = currentItem.title
        self.activeVenueDistance = dist

        guard let activity = currentActivity else { return }

        let updatedContentState = WayPointActivityAttributes.ContentState(
            currentVenueName: currentItem.title,
            nextVenueName: nextItem?.title ?? "",
            nextVenueTime: nextItem?.timeRange.components(separatedBy: "–").first?.trimmingCharacters(in: .whitespaces) ?? "",
            distanceMeters: dist,
            budgetUsedPercent: budgetProgress,
            spentAmount: spentAmount,
            remainingAmount: remainingAmount
        )

        let staleDate = Calendar.current.date(byAdding: .hour, value: 8, to: Date())
        let content = ActivityContent(state: updatedContentState, staleDate: staleDate)

        Task { @MainActor in
            await activity.update(content)
        }
    }

    /// Safely calculates distance in meters to venue item with zero fallback on invalid inputs
    func dynamicDistanceMeters(to item: ItineraryItem) -> Int {
        guard let userLoc = LocationService.shared.currentLocation,
              let itemCoord = item.coordinate,
              LocationService.isValidCoordinate(latitude: itemCoord.latitude, longitude: itemCoord.longitude) else {
            return 0
        }
        let venueLoc = CLLocation(latitude: itemCoord.latitude, longitude: itemCoord.longitude)
        let meters = userLoc.distance(from: venueLoc)
        return max(50, Int(meters))
    }

    /// Dismiss and end active Live Activity immediately
    func endTripActivity() {
        self.isActivityActive = false
        self.activeVenueName = ""

        guard let activity = currentActivity else { return }

        let content = ActivityContent(state: activity.content.state, staleDate: nil)

        Task { @MainActor in
            await activity.end(content, dismissalPolicy: .immediate)
            self.currentActivity = nil
            print("[LiveActivityManager] Live Activity ended.")
        }
    }
}
