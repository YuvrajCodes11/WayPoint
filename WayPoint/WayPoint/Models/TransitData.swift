//
//  TransitData.swift
//  WayPoint
//
//  Created by Yuvraj for RevenueCat #Shipaton 2026
//  Task 1: Self-Contained Local Transit Network Dataset
//

import Foundation
import CoreGraphics

// MARK: - Transit Type
public enum TransitType: String, Codable, Hashable, Sendable {
    case metro = "Metro"
    case express = "Express"
    case walking = "Walking Transfer"
    
    public var iconName: String {
        switch self {
        case .metro: return "tram.fill"
        case .express: return "train.side.front.car"
        case .walking: return "figure.walk"
        }
    }
}

// MARK: - Station Model
public struct Station: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let coordinates: CGPoint
    public let lines: [String]
    
    public init(id: String, name: String, coordinates: CGPoint, lines: [String]) {
        self.id = id
        self.name = name
        self.coordinates = coordinates
        self.lines = lines
    }
}

// MARK: - Transit Connection Model
public struct TransitConnection: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let fromStationId: String
    public let toStationId: String
    public let travelTimeSeconds: Int
    public let fareCostCents: Int
    public let transitType: TransitType
    public let lineName: String
    public let hexColor: String
    public let platformInfo: String
    
    public init(
        id: String,
        fromStationId: String,
        toStationId: String,
        travelTimeSeconds: Int,
        fareCostCents: Int,
        transitType: TransitType,
        lineName: String,
        hexColor: String,
        platformInfo: String = "Platform 1"
    ) {
        self.id = id
        self.fromStationId = fromStationId
        self.toStationId = toStationId
        self.travelTimeSeconds = travelTimeSeconds
        self.fareCostCents = fareCostCents
        self.transitType = transitType
        self.lineName = lineName
        self.hexColor = hexColor
        self.platformInfo = platformInfo
    }
    
    public var formattedFare: String {
        let dollars = Double(fareCostCents) / 100.0
        return String(format: "$%.2f", dollars)
    }
    
    public var formattedTime: String {
        let mins = travelTimeSeconds / 60
        let secs = travelTimeSeconds % 60
        return mins > 0 ? "\(mins)m \(secs)s" : "\(secs)s"
    }
}

// MARK: - Pre-Indexed Local Station & Connection Registry
public struct TransitRegistry {
    
    // 10 Tokyo Core Stations with 2D relative projection coordinates
    public static let defaultStations: [Station] = [
        Station(id: "shibuya", name: "Shibuya", coordinates: CGPoint(x: 0.12, y: 0.70), lines: ["Ginza Line", "Yamanote Line"]),
        Station(id: "shinjuku", name: "Shinjuku", coordinates: CGPoint(x: 0.18, y: 0.25), lines: ["Marunouchi Line", "Yamanote Line"]),
        Station(id: "roppongi", name: "Roppongi", coordinates: CGPoint(x: 0.35, y: 0.78), lines: ["Hibiya Line", "Oedo Line"]),
        Station(id: "akasaka-mitsuke", name: "Akasaka-mitsuke", coordinates: CGPoint(x: 0.45, y: 0.46), lines: ["Ginza Line", "Marunouchi Line"]),
        Station(id: "ginza", name: "Ginza", coordinates: CGPoint(x: 0.70, y: 0.55), lines: ["Ginza Line", "Marunouchi Line", "Hibiya Line"]),
        Station(id: "tokyo", name: "Tokyo Station", coordinates: CGPoint(x: 0.78, y: 0.35), lines: ["Marunouchi Line", "Yamanote Line", "Narita Express"]),
        Station(id: "otemachi", name: "Otemachi", coordinates: CGPoint(x: 0.76, y: 0.20), lines: ["Marunouchi Line", "Tozai Line"]),
        Station(id: "akihabara", name: "Akihabara", coordinates: CGPoint(x: 0.85, y: 0.22), lines: ["Hibiya Line", "Yamanote Line"]),
        Station(id: "ueno", name: "Ueno", coordinates: CGPoint(x: 0.88, y: 0.12), lines: ["Ginza Line", "Yamanote Line"]),
        Station(id: "asakusa", name: "Asakusa", coordinates: CGPoint(x: 0.95, y: 0.18), lines: ["Ginza Line", "Asakusa Line"])
    ]
    
    // 16 Pre-indexed Bidirectional Connections with Realistic Fares & Speeds
    public static let defaultConnections: [TransitConnection] = [
        // Ginza Line (Orange #FF9500)
        TransitConnection(id: "c1", fromStationId: "shibuya", toStationId: "akasaka-mitsuke", travelTimeSeconds: 420, fareCostCents: 170, transitType: .metro, lineName: "Ginza Line", hexColor: "#FF9500", platformInfo: "Track 1"),
        TransitConnection(id: "c2", fromStationId: "akasaka-mitsuke", toStationId: "ginza", travelTimeSeconds: 340, fareCostCents: 170, transitType: .metro, lineName: "Ginza Line", hexColor: "#FF9500", platformInfo: "Track 1"),
        TransitConnection(id: "c3", fromStationId: "ginza", toStationId: "ueno", travelTimeSeconds: 510, fareCostCents: 200, transitType: .metro, lineName: "Ginza Line", hexColor: "#FF9500", platformInfo: "Track 2"),
        TransitConnection(id: "c4", fromStationId: "ueno", toStationId: "asakusa", travelTimeSeconds: 290, fareCostCents: 170, transitType: .metro, lineName: "Ginza Line", hexColor: "#FF9500", platformInfo: "Track 2"),
        
        // Marunouchi Line (Red #E60012)
        TransitConnection(id: "c5", fromStationId: "shinjuku", toStationId: "akasaka-mitsuke", travelTimeSeconds: 370, fareCostCents: 170, transitType: .metro, lineName: "Marunouchi Line", hexColor: "#E60012", platformInfo: "Track 1"),
        TransitConnection(id: "c6", fromStationId: "akasaka-mitsuke", toStationId: "ginza", travelTimeSeconds: 330, fareCostCents: 170, transitType: .metro, lineName: "Marunouchi Line", hexColor: "#E60012", platformInfo: "Track 2"),
        TransitConnection(id: "c7", fromStationId: "ginza", toStationId: "tokyo", travelTimeSeconds: 150, fareCostCents: 140, transitType: .metro, lineName: "Marunouchi Line", hexColor: "#E60012", platformInfo: "Track 1"),
        TransitConnection(id: "c8", fromStationId: "tokyo", toStationId: "otemachi", travelTimeSeconds: 90, fareCostCents: 140, transitType: .metro, lineName: "Marunouchi Line", hexColor: "#E60012", platformInfo: "Track 1"),
        
        // Hibiya Line (Silver #999999)
        TransitConnection(id: "c9", fromStationId: "roppongi", toStationId: "ginza", travelTimeSeconds: 410, fareCostCents: 170, transitType: .metro, lineName: "Hibiya Line", hexColor: "#999999", platformInfo: "Track 3"),
        TransitConnection(id: "c10", fromStationId: "ginza", toStationId: "akihabara", travelTimeSeconds: 480, fareCostCents: 200, transitType: .metro, lineName: "Hibiya Line", hexColor: "#999999", platformInfo: "Track 3"),
        TransitConnection(id: "c11", fromStationId: "akihabara", toStationId: "ueno", travelTimeSeconds: 200, fareCostCents: 140, transitType: .metro, lineName: "Hibiya Line", hexColor: "#999999", platformInfo: "Track 4"),
        
        // Express Connections (Green #00B261)
        TransitConnection(id: "c12", fromStationId: "shibuya", toStationId: "shinjuku", travelTimeSeconds: 300, fareCostCents: 160, transitType: .express, lineName: "Yamanote Express", hexColor: "#00B261", platformInfo: "Track 1"),
        TransitConnection(id: "c13", fromStationId: "shinjuku", toStationId: "tokyo", travelTimeSeconds: 780, fareCostCents: 210, transitType: .express, lineName: "Chuo Rapid", hexColor: "#FF6600", platformInfo: "Track 7"),
        TransitConnection(id: "c14", fromStationId: "tokyo", toStationId: "ueno", travelTimeSeconds: 360, fareCostCents: 160, transitType: .express, lineName: "Ueno-Tokyo Line", hexColor: "#00B261", platformInfo: "Track 9"),
        
        // Walking Transfers & Local Detours
        TransitConnection(id: "c15", fromStationId: "tokyo", toStationId: "otemachi", travelTimeSeconds: 300, fareCostCents: 0, transitType: .walking, lineName: "Underground Pass", hexColor: "#777777", platformInfo: "Exit B1"),
        TransitConnection(id: "c16", fromStationId: "shibuya", toStationId: "roppongi", travelTimeSeconds: 600, fareCostCents: 220, transitType: .metro, lineName: "Roppongi Direct", hexColor: "#999999", platformInfo: "Bus Bay 3")
    ]
}
