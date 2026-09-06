//
//  BudgetGraphRouter.swift
//  WayPoint
//
//  Created by Yuvraj for RevenueCat #Shipaton 2026
//  Task 2: Cost-Weighted Offline Pareto-Optimal Graph Solver & Panic Pivot Engine
//

import Foundation
import Combine
import SwiftUI

// MARK: - Trip Leg Model
public struct TripLeg: Identifiable, Hashable, Sendable {
    public let id: String
    public let fromStation: Station
    public let toStation: Station
    public let connection: TransitConnection
    
    public init(fromStation: Station, toStation: Station, connection: TransitConnection) {
        self.id = connection.id
        self.fromStation = fromStation
        self.toStation = toStation
        self.connection = connection
    }
}

// MARK: - Strongly Typed Trip Plan
public struct TripPlan: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let legs: [TripLeg]
    public let totalTimeSeconds: Int
    public let totalFareCents: Int
    public let exceedsBudgetBy: Int?
    public let executionTimeMilliseconds: Double
    public let isRerouted: Bool
    public let avoidedStationId: String?
    
    public init(
        id: UUID = UUID(),
        legs: [TripLeg],
        totalTimeSeconds: Int,
        totalFareCents: Int,
        exceedsBudgetBy: Int? = nil,
        executionTimeMilliseconds: Double,
        isRerouted: Bool = false,
        avoidedStationId: String? = nil
    ) {
        self.id = id
        self.legs = legs
        self.totalTimeSeconds = totalTimeSeconds
        self.totalFareCents = totalFareCents
        self.exceedsBudgetBy = exceedsBudgetBy
        self.executionTimeMilliseconds = executionTimeMilliseconds
        self.isRerouted = isRerouted
        self.avoidedStationId = avoidedStationId
    }
    
    public var formattedTotalTime: String {
        let mins = totalTimeSeconds / 60
        let secs = totalTimeSeconds % 60
        return mins > 0 ? "\(mins)m \(secs)s" : "\(secs)s"
    }
    
    public var formattedTotalFare: String {
        let dollars = Double(totalFareCents) / 100.0
        return String(format: "$%.2f", dollars)
    }
    
    public var formattedExceedsBudget: String? {
        guard let excess = exceedsBudgetBy, excess > 0 else { return nil }
        let dollars = Double(excess) / 100.0
        return String(format: "+$%.2f Over Budget", dollars)
    }
}

// MARK: - Pareto Nondominated Frontier State
public struct ParetoState: Hashable, Sendable {
    public let time: Int
    public let fare: Int
    public let predecessorConnection: TransitConnection?
    public let predecessorStationId: String?
    
    public init(time: Int, fare: Int, predecessorConnection: TransitConnection?, predecessorStationId: String?) {
        self.time = time
        self.fare = fare
        self.predecessorConnection = predecessorConnection
        self.predecessorStationId = predecessorStationId
    }
}

// MARK: - Cost-Weighted Offline Graph Solver Engine (Pareto-Optimal)
@Observable
public final class BudgetGraphRouter: ObservableObject, @unchecked Sendable {
    public static let shared = BudgetGraphRouter()
    
    // Published Properties
    public var stations: [Station] = []
    public var connections: [TransitConnection] = []
    public var blockedStations: Set<String> = []
    public var currentPlan: TripPlan?
    public var lastLatencyMs: Double = 0.0
    public var isPanicActive: Bool = false
    public var lastAvoidedStationId: String? = nil
    
    // Fast Lookup Structures
    private var stationDict: [String: Station] = [:]
    private var adjacencyList: [String: [(toId: String, connection: TransitConnection)]] = [:]
    
    public init(stations: [Station] = TransitRegistry.defaultStations, connections: [TransitConnection] = TransitRegistry.defaultConnections) {
        setupGraph(stations: stations, connections: connections)
    }
    
    public func setupGraph(stations: [Station], connections: [TransitConnection]) {
        self.stations = stations
        self.connections = connections
        self.stationDict = Dictionary(uniqueKeysWithValues: stations.map { ($0.id, $0) })
        
        var adj: [String: [(toId: String, connection: TransitConnection)]] = [:]
        for station in stations {
            adj[station.id] = []
        }
        
        for conn in connections {
            adj[conn.fromStationId, default: []].append((toId: conn.toStationId, connection: conn))
            
            let reverseConn = TransitConnection(
                id: "\(conn.id)_rev",
                fromStationId: conn.toStationId,
                toStationId: conn.fromStationId,
                travelTimeSeconds: conn.travelTimeSeconds,
                fareCostCents: conn.fareCostCents,
                transitType: conn.transitType,
                lineName: conn.lineName,
                hexColor: conn.hexColor,
                platformInfo: conn.platformInfo
            )
            adj[conn.toStationId, default: []].append((toId: conn.fromStationId, connection: reverseConn))
        }
        
        self.adjacencyList = adj
    }
    
    // MARK: - Multi-Objective Pathfinding Solver (< 10ms execution)
    public func findOptimalTrip(
        from startId: String,
        to destinationId: String,
        maxBudgetCents: Int,
        prioritizeSpeed: Bool
    ) -> TripPlan? {
        let clock = ContinuousClock()
        var plan: TripPlan? = nil
        
        let elapsed = clock.measure {
            plan = runParetoDijkstraSolver(
                startId: startId,
                destinationId: destinationId,
                maxBudgetCents: maxBudgetCents,
                prioritizeSpeed: prioritizeSpeed
            )
        }
        
        let ms = Double(elapsed.components.attoseconds) / 1_000_000_000_000.0
        self.lastLatencyMs = ms
        
        if let p = plan {
            let finalPlan = TripPlan(
                id: p.id,
                legs: p.legs,
                totalTimeSeconds: p.totalTimeSeconds,
                totalFareCents: p.totalFareCents,
                exceedsBudgetBy: p.exceedsBudgetBy,
                executionTimeMilliseconds: ms,
                isRerouted: isPanicActive,
                avoidedStationId: lastAvoidedStationId
            )
            self.currentPlan = finalPlan
            return finalPlan
        }
        
        self.currentPlan = nil
        return nil
    }
    
    // MARK: - Pareto-Optimal Multi-Objective Dijkstra Implementation
    private func runParetoDijkstraSolver(
        startId: String,
        destinationId: String,
        maxBudgetCents: Int,
        prioritizeSpeed: Bool
    ) -> TripPlan? {
        // Pass 1: Strict Budget Pass
        if let strictPlan = executeParetoPass(
            startId: startId,
            destinationId: destinationId,
            strictBudget: maxBudgetCents,
            prioritizeSpeed: prioritizeSpeed
        ) {
            return strictPlan
        }
        
        // Pass 2: Fallback Pass ignoring strict budget cap to find closest viable local route
        if let fallbackPlan = executeParetoPass(
            startId: startId,
            destinationId: destinationId,
            strictBudget: nil,
            prioritizeSpeed: prioritizeSpeed
        ) {
            let excess = max(0, fallbackPlan.totalFareCents - maxBudgetCents)
            return TripPlan(
                legs: fallbackPlan.legs,
                totalTimeSeconds: fallbackPlan.totalTimeSeconds,
                totalFareCents: fallbackPlan.totalFareCents,
                exceedsBudgetBy: excess > 0 ? excess : nil,
                executionTimeMilliseconds: 0.0,
                isRerouted: isPanicActive,
                avoidedStationId: lastAvoidedStationId
            )
        }
        
        return nil
    }
    
    private func executeParetoPass(
        startId: String,
        destinationId: String,
        strictBudget: Int?,
        prioritizeSpeed: Bool
    ) -> TripPlan? {
        guard stationDict[startId] != nil, stationDict[destinationId] != nil else { return nil }
        
        var frontiers: [String: [ParetoState]] = [:]
        for station in stations {
            frontiers[station.id] = []
        }
        
        let initialState = ParetoState(time: 0, fare: 0, predecessorConnection: nil, predecessorStationId: nil)
        frontiers[startId] = [initialState]
        
        var openQueue: [(stationId: String, state: ParetoState)] = [(startId, initialState)]
        
        while !openQueue.isEmpty {
            let bestIndex: Int
            if prioritizeSpeed {
                bestIndex = openQueue.indices.min(by: { openQueue[$0].state.time < openQueue[$1].state.time })!
            } else {
                bestIndex = openQueue.indices.min(by: {
                    openQueue[$0].state.fare != openQueue[$1].state.fare
                        ? openQueue[$0].state.fare < openQueue[$1].state.fare
                        : openQueue[$0].state.time < openQueue[$1].state.time
                })!
            }
            
            let currentItem = openQueue.remove(at: bestIndex)
            let currId = currentItem.stationId
            let currState = currentItem.state
            
            let neighbors = adjacencyList[currId] ?? []
            for neighbor in neighbors {
                let nextId = neighbor.toId
                
                if blockedStations.contains(currId) || blockedStations.contains(nextId) {
                    continue
                }
                
                let newTime = currState.time + neighbor.connection.travelTimeSeconds
                let newFare = currState.fare + neighbor.connection.fareCostCents
                
                if let maxFare = strictBudget, newFare > maxFare {
                    continue
                }
                
                let candidateState = ParetoState(
                    time: newTime,
                    fare: newFare,
                    predecessorConnection: neighbor.connection,
                    predecessorStationId: currId
                )
                
                let existingFrontier = frontiers[nextId] ?? []
                let isDominated = existingFrontier.contains(where: { existing in
                    existing.time <= candidateState.time && existing.fare <= candidateState.fare
                })
                
                if !isDominated {
                    var updatedFrontier = existingFrontier.filter { existing in
                        !(candidateState.time <= existing.time && candidateState.fare <= existing.fare)
                    }
                    updatedFrontier.append(candidateState)
                    frontiers[nextId] = updatedFrontier
                    
                    openQueue.append((stationId: nextId, state: candidateState))
                }
            }
        }
        
        guard let destFrontier = frontiers[destinationId], !destFrontier.isEmpty else {
            return nil
        }
        
        let bestDestState: ParetoState
        if prioritizeSpeed {
            bestDestState = destFrontier.min(by: { $0.time < $1.time })!
        } else {
            bestDestState = destFrontier.min(by: {
                $0.fare != $1.fare ? $0.fare < $1.fare : $0.time < $1.time
            })!
        }
        
        var legs: [TripLeg] = []
        var currentStationId = destinationId
        var currentState: ParetoState? = bestDestState
        
        while let state = currentState, let predId = state.predecessorStationId, let conn = state.predecessorConnection {
            guard let fromSt = stationDict[predId], let toSt = stationDict[currentStationId] else { break }
            legs.append(TripLeg(fromStation: fromSt, toStation: toSt, connection: conn))
            
            currentStationId = predId
            let targetTime = state.time - conn.travelTimeSeconds
            let targetFare = state.fare - conn.fareCostCents
            currentState = frontiers[predId]?.first(where: { $0.time == targetTime && $0.fare == targetFare })
        }
        
        legs.reverse()
        
        return TripPlan(
            legs: legs,
            totalTimeSeconds: bestDestState.time,
            totalFareCents: bestDestState.fare,
            exceedsBudgetBy: nil,
            executionTimeMilliseconds: 0.0,
            isRerouted: isPanicActive,
            avoidedStationId: lastAvoidedStationId
        )
    }
    
    // MARK: - Panic Pivot Rerouting
    @discardableResult
    public func panicPivot(
        avoidStationId: String,
        from startId: String = "shibuya",
        to destinationId: String = "tokyo",
        maxBudgetCents: Int = 1000,
        prioritizeSpeed: Bool = true
    ) -> TripPlan? {
        blockedStations.insert(avoidStationId)
        isPanicActive = true
        lastAvoidedStationId = avoidStationId
        
        return findOptimalTrip(
            from: startId,
            to: destinationId,
            maxBudgetCents: maxBudgetCents,
            prioritizeSpeed: prioritizeSpeed
        )
    }
    
    public func resetPivot(
        from startId: String = "shibuya",
        to destinationId: String = "tokyo",
        maxBudgetCents: Int = 1000,
        prioritizeSpeed: Bool = true
    ) {
        blockedStations.removeAll()
        isPanicActive = false
        lastAvoidedStationId = nil
        
        _ = findOptimalTrip(
            from: startId,
            to: destinationId,
            maxBudgetCents: maxBudgetCents,
            prioritizeSpeed: prioritizeSpeed
        )
    }
    
    // MARK: - Unit Test Audit Function
    @discardableResult
    public func testConstrainedBudgetRouting() -> (unlimitedPass: Bool, constrainedPass: Bool, details: String) {
        let router = BudgetGraphRouter.shared
        
        // Test 1: Unlimited Budget ($25.00) Shibuya -> Tokyo (Picks Yamanote Express / Chuo Rapid)
        let unlimitedPlan = router.findOptimalTrip(
            from: "shibuya",
            to: "tokyo",
            maxBudgetCents: 2500,
            prioritizeSpeed: true
        )
        
        // Test 2: Constrained Budget ($3.00) Shibuya -> Tokyo (Detours via metro/walking)
        let constrainedPlan = router.findOptimalTrip(
            from: "shibuya",
            to: "tokyo",
            maxBudgetCents: 300,
            prioritizeSpeed: false
        )
        
        let pass1 = unlimitedPlan != nil && (unlimitedPlan?.legs.contains(where: { $0.connection.transitType == .express }) ?? false)
        let pass2 = constrainedPlan != nil && constrainedPlan!.totalFareCents <= 300
        
        let details = "Unlimited Route: \(unlimitedPlan?.formattedTotalFare ?? "N/A"), \(unlimitedPlan?.formattedTotalTime ?? "N/A") | Constrained Route: \(constrainedPlan?.formattedTotalFare ?? "N/A"), \(constrainedPlan?.formattedTotalTime ?? "N/A")"
        
        return (unlimitedPass: pass1, constrainedPass: pass2, details: details)
    }
}
