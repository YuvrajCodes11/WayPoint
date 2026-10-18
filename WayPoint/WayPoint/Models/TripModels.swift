//
//  TripModels.swift
//  WayPoint
//

import Foundation

public enum TripType: String, Codable, CaseIterable {
    case oneWay = "One Way"
    case roundTrip = "Round Trip"
    case multiDay = "Multi-Day Stay"
    case sameDay = "Same-Day Return"
}

public struct BudgetAllocation: Codable {
    public var total: Double
    public var currencyCode: String
    public var transitLimit: Double
    public var stayLimit: Double
    public var dailyFoodLimit: Double
    
    public init(total: Double, currencyCode: String = "USD") {
        self.total = total
        self.currencyCode = currencyCode
        self.transitLimit = total * 0.25
        self.stayLimit = total * 0.45
        self.dailyFoodLimit = total * 0.20
    }
}

public enum StopType: String, Codable {
    case transit
    case hotel
    case dining
    case activity
    case flight
}

public struct TripStop: Identifiable, Codable {
    public var id: UUID
    public var title: String
    public var type: StopType
    public var scheduledTime: Date
    public var durationMinutes: Int
    public var estimatedCost: Double
    public var isHardReservation: Bool
    public var bookingReference: String?
    public var notes: String?
    
    public init(id: UUID = UUID(), title: String, type: StopType, scheduledTime: Date, durationMinutes: Int = 60, estimatedCost: Double = 0.0, isHardReservation: Bool = false, bookingReference: String? = nil, notes: String? = nil) {
        self.id = id
        self.title = title
        self.type = type
        self.scheduledTime = scheduledTime
        self.durationMinutes = durationMinutes
        self.estimatedCost = estimatedCost
        self.isHardReservation = isHardReservation
        self.bookingReference = bookingReference
        self.notes = notes
    }
}

public struct DynamicDayPlan: Identifiable, Codable {
    public var id: UUID
    public var dayNumber: Int
    public var date: Date
    public var stops: [TripStop]
    
    public init(id: UUID = UUID(), dayNumber: Int, date: Date, stops: [TripStop] = []) {
        self.id = id
        self.dayNumber = dayNumber
        self.date = date
        self.stops = stops
    }
}

public struct DynamicTrip: Identifiable, Codable {
    public var id: UUID
    public var origin: String
    public var destination: String
    public var type: TripType
    public var startDate: Date
    public var endDate: Date
    public var budget: BudgetAllocation
    public var days: [DynamicDayPlan]
    public var createdAt: Date
    
    public init(id: UUID = UUID(), origin: String, destination: String, type: TripType, startDate: Date, endDate: Date, budget: BudgetAllocation, days: [DynamicDayPlan] = []) {
        self.id = id
        self.origin = origin
        self.destination = destination
        self.type = type
        self.startDate = startDate
        self.endDate = endDate
        self.budget = budget
        self.days = days
        self.createdAt = Date()
    }
}

public enum TripModels {
    public typealias DayPlan = DynamicDayPlan
    public typealias Trip = DynamicTrip
}
