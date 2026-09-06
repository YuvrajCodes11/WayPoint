//
//  GraphRouter.swift
//  WayPoint
//
//  Created for RevenueCat #Shipaton 2026
//  100% Air-Gapped Offline Topological Graph & Rerouting Engine
//

import Foundation
import Combine
import SwiftUI

// MARK: - Station Node Model
public struct StationNode: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let japaneseName: String
    public let lineId: String
    public let lineName: String
    public let lineColorHex: String
    public let xRatio: Double
    public let yRatio: Double
    public let latitude: Double
    public let longitude: Double
    
    public init(
        id: String,
        name: String,
        japaneseName: String,
        lineId: String,
        lineName: String,
        lineColorHex: String,
        xRatio: Double,
        yRatio: Double,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.name = name
        self.japaneseName = japaneseName
        self.lineId = lineId
        self.lineName = lineName
        self.lineColorHex = lineColorHex
        self.xRatio = xRatio
        self.yRatio = yRatio
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - Track Edge Model
public struct TrackEdge: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let fromStationId: String
    public let toStationId: String
    public let travelTimeSeconds: Double
    public let lineId: String
    public let isTransfer: Bool
    
    public init(
        id: String,
        fromStationId: String,
        toStationId: String,
        travelTimeSeconds: Double,
        lineId: String,
        isTransfer: Bool
    ) {
        self.id = id
        self.fromStationId = fromStationId
        self.toStationId = toStationId
        self.travelTimeSeconds = travelTimeSeconds
        self.lineId = lineId
        self.isTransfer = isTransfer
    }
}

// MARK: - Transit Network Data Asset Container
public struct TransitNetworkData: Codable, Sendable {
    public let networkName: String
    public let version: String
    public let stations: [StationNode]
    public let edges: [TrackEdge]
}

// MARK: - Pathfinding Route Result
public struct RouteResult: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let path: [StationNode]
    public let traversedEdges: [TrackEdge]
    public let totalTravelTimeSeconds: Double
    public let recalculationLatencyMs: Double
    public let isRerouted: Bool
    public let avoidedStationId: String?
    public let timestamp: Date
    
    public init(
        id: UUID = UUID(),
        path: [StationNode],
        traversedEdges: [TrackEdge],
        totalTravelTimeSeconds: Double,
        recalculationLatencyMs: Double,
        isRerouted: Bool = false,
        avoidedStationId: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.path = path
        self.traversedEdges = traversedEdges
        self.totalTravelTimeSeconds = totalTravelTimeSeconds
        self.recalculationLatencyMs = recalculationLatencyMs
        self.isRerouted = isRerouted
        self.avoidedStationId = avoidedStationId
        self.timestamp = timestamp
    }
    
    public var formattedTravelTime: String {
        let minutes = Int(totalTravelTimeSeconds / 60)
        let seconds = Int(totalTravelTimeSeconds) % 60
        return "\(minutes)m \(seconds)s"
    }
}

// MARK: - Offline Topological Graph Engine
@Observable
public final class GraphRouter: ObservableObject, @unchecked Sendable {
    public static let shared = GraphRouter()
    
    // Published State
    public var stations: [StationNode] = []
    public var edges: [TrackEdge] = []
    public var blockedStations: Set<String> = []
    public var activeRoute: RouteResult?
    public var originStationId: String = "shibuya"
    public var destinationStationId: String = "tokyo"
    public var lastLatencyMs: Double = 0.0
    public var isPanicActive: Bool = false
    public var lastAvoidedStationId: String? = nil
    
    // Internal Indexing Structures
    private var stationLookup: [String: StationNode] = [:]
    private var adjacencyList: [String: [(toId: String, weight: Double, edge: TrackEdge)]] = [:]
    
    public init(bundleAssetFileName: String = "tokyo_metro_graph") {
        loadGraphFromBundle(filename: bundleAssetFileName)
    }
    
    // MARK: - Load Local JSON Network Asset
    public func loadGraphFromBundle(filename: String) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            print("[GraphRouter] WARNING: \(filename).json not found in Bundle, initializing fallback in-memory graph.")
            setupFallbackGraph()
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let network = try decoder.decode(TransitNetworkData.self, from: data)
            buildGraph(stations: network.stations, edges: network.edges)
            print("[GraphRouter] Successfully loaded local asset \(filename).json (\(network.stations.count) stations, \(network.edges.count) edges).")
        } catch {
            print("[GraphRouter] ERROR decoding graph JSON: \(error). Using fallback.")
            setupFallbackGraph()
        }
    }
    
    public func buildGraph(stations: [StationNode], edges: [TrackEdge]) {
        self.stations = stations
        self.edges = edges
        self.stationLookup = Dictionary(uniqueKeysWithValues: stations.map { ($0.id, $0) })
        
        var adj: [String: [(toId: String, weight: Double, edge: TrackEdge)]] = [:]
        for station in stations {
            adj[station.id] = []
        }
        
        // Build bidirectional adjacency list for metro track network
        for edge in edges {
            adj[edge.fromStationId, default: []].append((toId: edge.toStationId, weight: edge.travelTimeSeconds, edge: edge))
            // Reverse edge with identical travel time & line representation
            let reverseEdge = TrackEdge(
                id: "\(edge.id)_rev",
                fromStationId: edge.toStationId,
                toStationId: edge.fromStationId,
                travelTimeSeconds: edge.travelTimeSeconds,
                lineId: edge.lineId,
                isTransfer: edge.isTransfer
            )
            adj[edge.toStationId, default: []].append((toId: edge.fromStationId, weight: edge.travelTimeSeconds, edge: reverseEdge))
        }
        
        self.adjacencyList = adj
        
        // Calculate initial default route
        recalculateRoute()
    }
    
    // MARK: - On-Device Dijkstra Pathfinding (< 10ms target)
    @discardableResult
    public func findFastestPath(from startId: String, to endId: String) -> RouteResult? {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard let startNode = stationLookup[startId], let _ = stationLookup[endId] else {
            return nil
        }
        
        if startId == endId {
            let endTime = CFAbsoluteTimeGetCurrent()
            let latency = (endTime - startTime) * 1000.0
            return RouteResult(
                path: [startNode],
                traversedEdges: [],
                totalTravelTimeSeconds: 0,
                recalculationLatencyMs: latency,
                isRerouted: !blockedStations.isEmpty,
                avoidedStationId: lastAvoidedStationId
            )
        }
        
        var distances: [String: Double] = [:]
        var predecessors: [String: (fromId: String, edge: TrackEdge)] = [:]
        var openSet = Set<String>()
        
        for station in stations {
            distances[station.id] = Double.infinity
        }
        distances[startId] = 0.0
        openSet.insert(startId)
        
        while !openSet.isEmpty {
            // Extract node with minimum distance in openSet
            guard let currentId = openSet.min(by: { (distances[$0] ?? .infinity) < (distances[$1] ?? .infinity) }) else {
                break
            }
            
            let currentDist = distances[currentId] ?? .infinity
            if currentDist == .infinity { break }
            if currentId == endId { break }
            
            openSet.remove(currentId)
            
            let neighbors = adjacencyList[currentId] ?? []
            for neighbor in neighbors {
                let neighborId = neighbor.toId
                
                // Skip blocked nodes if panic pivot is active
                if blockedStations.contains(neighborId) || blockedStations.contains(currentId) {
                    continue
                }
                
                let altDist = currentDist + neighbor.weight
                if altDist < (distances[neighborId] ?? .infinity) {
                    distances[neighborId] = altDist
                    predecessors[neighborId] = (fromId: currentId, edge: neighbor.edge)
                    openSet.insert(neighborId)
                }
            }
        }
        
        // Verify path reachability
        guard distances[endId] != .infinity else {
            let endTime = CFAbsoluteTimeGetCurrent()
            let latency = (endTime - startTime) * 1000.0
            self.lastLatencyMs = latency
            print("[GraphRouter] Route unreachable from \(startId) to \(endId) due to blockages.")
            return nil
        }
        
        // Reconstruct path backward
        var pathNodes: [StationNode] = []
        var pathEdges: [TrackEdge] = []
        var curr = endId
        
        while let node = stationLookup[curr] {
            pathNodes.append(node)
            if let pred = predecessors[curr] {
                pathEdges.append(pred.edge)
                curr = pred.fromId
            } else {
                break
            }
        }
        
        pathNodes.reverse()
        pathEdges.reverse()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let latency = (endTime - startTime) * 1000.0
        self.lastLatencyMs = latency
        
        let result = RouteResult(
            path: pathNodes,
            traversedEdges: pathEdges,
            totalTravelTimeSeconds: distances[endId] ?? 0,
            recalculationLatencyMs: latency,
            isRerouted: isPanicActive,
            avoidedStationId: lastAvoidedStationId
        )
        
        return result
    }
    
    // MARK: - Panic Pivot Rerouting
    @discardableResult
    public func panicPivot(avoidStationId: String) -> RouteResult? {
        blockedStations.insert(avoidStationId)
        isPanicActive = true
        lastAvoidedStationId = avoidStationId
        
        let rerouted = recalculateRoute()
        return rerouted
    }
    
    public func resetPivot() {
        blockedStations.removeAll()
        isPanicActive = false
        lastAvoidedStationId = nil
        recalculateRoute()
    }
    
    @discardableResult
    public func recalculateRoute() -> RouteResult? {
        let result = findFastestPath(from: originStationId, to: destinationStationId)
        self.activeRoute = result
        return result
    }
    
    public func setRouteEndpoints(originId: String, destinationId: String) {
        self.originStationId = originId
        self.destinationStationId = destinationId
        recalculateRoute()
    }
    
    public func station(for id: String) -> StationNode? {
        return stationLookup[id]
    }
    
    // MARK: - Fallback Local Network Graph
    private func setupFallbackGraph() {
        let defaultStations: [StationNode] = [
            StationNode(id: "shibuya", name: "Shibuya", japaneseName: "渋谷", lineId: "G", lineName: "Ginza Line", lineColorHex: "#FF9500", xRatio: 0.12, yRatio: 0.70, latitude: 35.6580, longitude: 139.7016),
            StationNode(id: "omotesando", name: "Omotesando", japaneseName: "表参道", lineId: "G", lineName: "Ginza Line", lineColorHex: "#FF9500", xRatio: 0.25, yRatio: 0.62, latitude: 35.6652, longitude: 139.7123),
            StationNode(id: "aoyama-itchome", name: "Aoyama-itchome", japaneseName: "青山一丁目", lineId: "G", lineName: "Ginza Line", lineColorHex: "#FF9500", xRatio: 0.38, yRatio: 0.54, latitude: 35.6728, longitude: 139.7239),
            StationNode(id: "akasaka-mitsuke", name: "Akasaka-mitsuke", japaneseName: "赤坂見附", lineId: "G_M", lineName: "Ginza & Marunouchi Hub", lineColorHex: "#FF9500", xRatio: 0.48, yRatio: 0.46, latitude: 35.6766, longitude: 139.7371),
            StationNode(id: "tameike-sanno", name: "Tameike-sanno", japaneseName: "溜池山王", lineId: "G", lineName: "Ginza Line", lineColorHex: "#FF9500", xRatio: 0.58, yRatio: 0.52, latitude: 35.6713, longitude: 139.7417),
            StationNode(id: "toranomon", name: "Toranomon", japaneseName: "虎ノ門", lineId: "G", lineName: "Ginza Line", lineColorHex: "#FF9500", xRatio: 0.68, yRatio: 0.56, latitude: 35.6702, longitude: 139.7497),
            StationNode(id: "shimbashi", name: "Shimbashi", japaneseName: "新橋", lineId: "G", lineName: "Ginza Line", lineColorHex: "#FF9500", xRatio: 0.78, yRatio: 0.58, latitude: 35.6664, longitude: 139.7583),
            StationNode(id: "ginza", name: "Ginza", japaneseName: "銀座", lineId: "G_M", lineName: "Ginza & Marunouchi Hub", lineColorHex: "#FF9500", xRatio: 0.85, yRatio: 0.48, latitude: 35.6719, longitude: 139.7639),
            StationNode(id: "shinjuku", name: "Shinjuku", japaneseName: "新宿", lineId: "M", lineName: "Marunouchi Line", lineColorHex: "#E60012", xRatio: 0.18, yRatio: 0.25, latitude: 35.6909, longitude: 139.7003),
            StationNode(id: "yotsuya", name: "Yotsuya", japaneseName: "四ツ谷", lineId: "M", lineName: "Marunouchi Line", lineColorHex: "#E60012", xRatio: 0.35, yRatio: 0.32, latitude: 35.6860, longitude: 139.7306),
            StationNode(id: "kokkai-gijidomae", name: "Kokkai-gijidomae", japaneseName: "国会議事堂前", lineId: "M", lineName: "Marunouchi Line", lineColorHex: "#E60012", xRatio: 0.52, yRatio: 0.36, latitude: 35.6749, longitude: 139.7452),
            StationNode(id: "kasumigaseki", name: "Kasumigaseki", japaneseName: "霞ケ関", lineId: "M", lineName: "Marunouchi Line", lineColorHex: "#E60012", xRatio: 0.65, yRatio: 0.38, latitude: 35.6751, longitude: 139.7520),
            StationNode(id: "tokyo", name: "Tokyo", japaneseName: "東京", lineId: "M", lineName: "Marunouchi Line", lineColorHex: "#E60012", xRatio: 0.88, yRatio: 0.30, latitude: 35.6812, longitude: 139.7671),
            StationNode(id: "otemachi", name: "Otemachi", japaneseName: "大手町", lineId: "M", lineName: "Marunouchi Line", lineColorHex: "#E60012", xRatio: 0.85, yRatio: 0.18, latitude: 35.6848, longitude: 139.7661)
        ]
        
        let defaultEdges: [TrackEdge] = [
            TrackEdge(id: "e1", fromStationId: "shibuya", toStationId: "omotesando", travelTimeSeconds: 130, lineId: "G", isTransfer: false),
            TrackEdge(id: "e2", fromStationId: "omotesando", toStationId: "aoyama-itchome", travelTimeSeconds: 140, lineId: "G", isTransfer: false),
            TrackEdge(id: "e3", fromStationId: "aoyama-itchome", toStationId: "akasaka-mitsuke", travelTimeSeconds: 150, lineId: "G", isTransfer: false),
            TrackEdge(id: "e4", fromStationId: "akasaka-mitsuke", toStationId: "tameike-sanno", travelTimeSeconds: 110, lineId: "G", isTransfer: false),
            TrackEdge(id: "e5", fromStationId: "tameike-sanno", toStationId: "toranomon", travelTimeSeconds: 120, lineId: "G", isTransfer: false),
            TrackEdge(id: "e6", fromStationId: "toranomon", toStationId: "shimbashi", travelTimeSeconds: 115, lineId: "G", isTransfer: false),
            TrackEdge(id: "e7", fromStationId: "shimbashi", toStationId: "ginza", travelTimeSeconds: 105, lineId: "G", isTransfer: false),
            
            TrackEdge(id: "e8", fromStationId: "shinjuku", toStationId: "yotsuya", travelTimeSeconds: 240, lineId: "M", isTransfer: false),
            TrackEdge(id: "e9", fromStationId: "yotsuya", toStationId: "akasaka-mitsuke", travelTimeSeconds: 130, lineId: "M", isTransfer: false),
            TrackEdge(id: "e10", fromStationId: "akasaka-mitsuke", toStationId: "kokkai-gijidomae", travelTimeSeconds: 110, lineId: "M", isTransfer: false),
            TrackEdge(id: "e11", fromStationId: "kokkai-gijidomae", toStationId: "kasumigaseki", travelTimeSeconds: 95, lineId: "M", isTransfer: false),
            TrackEdge(id: "e12", fromStationId: "kasumigaseki", toStationId: "ginza", travelTimeSeconds: 120, lineId: "M", isTransfer: false),
            TrackEdge(id: "e13", fromStationId: "ginza", toStationId: "tokyo", travelTimeSeconds: 110, lineId: "M", isTransfer: false),
            TrackEdge(id: "e14", fromStationId: "tokyo", toStationId: "otemachi", travelTimeSeconds: 85, lineId: "M", isTransfer: false),
            
            TrackEdge(id: "e15", fromStationId: "tameike-sanno", toStationId: "kokkai-gijidomae", travelTimeSeconds: 60, lineId: "TRANSFER", isTransfer: true),
            TrackEdge(id: "e16", fromStationId: "aoyama-itchome", toStationId: "kokkai-gijidomae", travelTimeSeconds: 190, lineId: "BYPASS_WALK", isTransfer: true),
            TrackEdge(id: "e17", fromStationId: "shimbashi", toStationId: "tokyo", travelTimeSeconds: 180, lineId: "JR_BYPASS", isTransfer: true)
        ]
        
        buildGraph(stations: defaultStations, edges: defaultEdges)
    }
}
