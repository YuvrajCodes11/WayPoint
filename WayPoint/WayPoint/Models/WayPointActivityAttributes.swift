//
//  WayPointActivityAttributes.swift
//  WayPoint
//

import Foundation
import ActivityKit

struct WayPointActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var currentVenueName: String
        public var nextVenueName: String
        public var nextVenueTime: String
        public var distanceMeters: Int
        public var budgetUsedPercent: Double
        public var spentAmount: String
        public var remainingAmount: String

        public init(
            currentVenueName: String,
            nextVenueName: String = "",
            nextVenueTime: String = "",
            distanceMeters: Int = 450,
            budgetUsedPercent: Double = 0.34,
            spentAmount: String = "$155",
            remainingAmount: String = "$295"
        ) {
            self.currentVenueName = currentVenueName
            self.nextVenueName = nextVenueName
            self.nextVenueTime = nextVenueTime
            self.distanceMeters = distanceMeters
            self.budgetUsedPercent = budgetUsedPercent
            self.spentAmount = spentAmount
            self.remainingAmount = remainingAmount
        }
    }

    public var tripName: String
    public var dayTitle: String

    public init(tripName: String, dayTitle: String) {
        self.tripName = tripName
        self.dayTitle = dayTitle
    }
}
