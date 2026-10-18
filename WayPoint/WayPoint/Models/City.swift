//
//  City.swift
//  WayPoint
//

import Foundation

public enum City: String, Codable, CaseIterable, Identifiable {
    case london = "London"
    case tokyo = "Tokyo"
    
    public var id: String { rawValue }
    
    public var flag: String {
        switch self {
        case .london: return "🇬🇧"
        case .tokyo: return "🇯🇵"
        }
    }
    
    public var graphFileName: String {
        switch self {
        case .london: return "london_underground_graph"
        case .tokyo: return "tokyo_metro_graph"
        }
    }
}
