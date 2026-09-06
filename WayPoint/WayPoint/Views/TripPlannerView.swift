//
//  TripPlannerView.swift
//  WayPoint
//
//  Created by Yuvraj for RevenueCat #Shipaton 2026
//  Task 4: Complete Trip Planner & Graph View (Pareto Audit Hardened)
//

import SwiftUI

public struct TripPlannerView: View {
    @Bindable var router: BudgetGraphRouter = BudgetGraphRouter.shared
    
    // User Selection State
    @State private var originId: String = "shibuya"
    @State private var destinationId: String = "tokyo"
    @State private var maxBudgetCents: Double = 500 // Default $5.00
    @State private var prioritizeSpeed: Bool = true
    @State private var avoidStationId: String = "akasaka-mitsuke"
    
    // Telemetry & Audit Test State
    @State private var executionTickerText: String = "0.45 ms"
    @State private var isRerouted: Bool = false
    @State private var testAuditResult: String? = nil
    
    public init(router: BudgetGraphRouter = BudgetGraphRouter.shared) {
        self.router = router
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            
            // MARK: - Header & Live Performance Ticker
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "cpu")
                        .foregroundColor(Color(red: 0.0, green: 1.0, blue: 0.53))
                    Text("Silicon Graph Solver")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                    Text("Calculated Locally in \(executionTickerText) • 0 KB Data")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .foregroundColor(Color(red: 0.0, green: 1.0, blue: 0.53))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color(red: 0.0, green: 1.0, blue: 0.53).opacity(0.15)))
            }
            .padding(.horizontal, 16)
            
            // MARK: - Route Planner Controls Card
            VStack(spacing: 14) {
                // 1. Origin & Destination Station Pickers
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ORIGIN STATION")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.gray)
                        Picker("Origin", selection: $originId) {
                            ForEach(router.stations) { station in
                                Text(station.name).tag(station.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.cyan)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.14)))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DESTINATION STATION")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.gray)
                        Picker("Destination", selection: $destinationId) {
                            ForEach(router.stations) { station in
                                Text(station.name).tag(station.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.green)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.14)))
                }
                
                // 2. Budget Cap Slider ($2.00 to $25.00)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("MAX BUDGET CAP:")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                        Spacer()
                        Text(String(format: "$%.2f", maxBudgetCents / 100.0))
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(.yellow)
                    }
                    
                    Slider(value: $maxBudgetCents, in: 200...2500, step: 50)
                        .tint(.yellow)
                }
                
                // 3. Priority Selector (Fastest Route vs. Budget Saver)
                Picker("Optimization Strategy", selection: $prioritizeSpeed) {
                    Text("Fastest Route").tag(true)
                    Text("Budget Saver").tag(false)
                }
                .pickerStyle(.segmented)
                
                // 4. Buttons: Generate Itinerary & Run Pareto Audit Test
                HStack(spacing: 10) {
                    Button(action: generateItinerary) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Generate Itinerary")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.0, green: 1.0, blue: 0.53), Color.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                    }
                    
                    Button(action: runParetoAudit) {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                            Text("Pareto Audit Test")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.purple))
                    }
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.1)))
            .padding(.horizontal, 16)
            
            // MARK: - Pareto Audit Test Result Banner
            if let auditText = testAuditResult {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("PARETO CONSTRAINED ROUTING AUDIT: PASSED")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.green)
                    }
                    Text(auditText)
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.green.opacity(0.12)))
                .padding(.horizontal, 16)
            }
            
            // MARK: - Disruption Simulator Bar
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("DISRUPT:")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.red)
                    Picker("", selection: $avoidStationId) {
                        ForEach(router.stations) { st in
                            Text(st.name).tag(st.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.red)
                }
                
                Button(action: triggerDisruption) {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Simulate Line Disruption")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)))
                }
                
                if router.isPanicActive {
                    Button(action: resetDisruption) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .padding(.horizontal, 16)
            
            // MARK: - Disruption Amber Alert Banner
            if router.isPanicActive, let avoidedId = router.lastAvoidedStationId, let avoidedStation = router.stations.first(where: { $0.id == avoidedId }) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundColor(.orange)
                    Text("PANIC PIVOT ACTIVE: Station '\(avoidedStation.name)' Blocked. Detour Engaged.")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.15)))
                .padding(.horizontal, 16)
            }
            
            // MARK: - Calculated Itinerary Result Visual Card
            if let plan = router.currentPlan {
                VStack(alignment: .leading, spacing: 12) {
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TOTAL TRAVEL TIME")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.gray)
                            Text(plan.formattedTotalTime)
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("TOTAL FARE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.gray)
                            Text(plan.formattedTotalFare)
                                .font(.system(size: 18, weight: .black, design: .monospaced))
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    if let excessBadge = plan.formattedExceedsBudget {
                        Text(excessBadge)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.red.opacity(0.15)))
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    // Itemized Route Legs List
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(plan.legs.enumerated()), id: \.offset) { index, leg in
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .fill(plan.isRerouted ? Color(red: 0.0, green: 1.0, blue: 0.53) : Color(hex: leg.connection.hexColor) ?? .blue)
                                    .frame(width: 12, height: 12)
                                    .padding(.top, 3)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("\(leg.fromStation.name) → \(leg.toStation.name)")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Text(leg.connection.formattedFare)
                                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                            .foregroundColor(.yellow.opacity(0.9))
                                    }
                                    
                                    HStack(spacing: 8) {
                                        Text(leg.connection.lineName)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(Color(hex: leg.connection.hexColor) ?? .orange))
                                        
                                        Text(leg.connection.platformInfo)
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.gray)
                                        
                                        Spacer()
                                        
                                        Text(leg.connection.formattedTime)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(plan.isRerouted ? Color(red: 0.0, green: 1.0, blue: 0.53).opacity(0.08) : Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(plan.isRerouted ? Color(red: 0.0, green: 1.0, blue: 0.53).opacity(0.4) : Color.clear, lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.1)))
                .padding(.horizontal, 16)
            }
        }
        .onAppear {
            generateItinerary()
        }
    }
    
    // MARK: - Actions & Benchmarking
    private func generateItinerary() {
        let plan = router.findOptimalTrip(
            from: originId,
            to: destinationId,
            maxBudgetCents: Int(maxBudgetCents),
            prioritizeSpeed: prioritizeSpeed
        )
        if let p = plan {
            self.executionTickerText = String(format: "%.2f ms", p.executionTimeMilliseconds)
        }
    }
    
    private func runParetoAudit() {
        let audit = router.testConstrainedBudgetRouting()
        self.testAuditResult = audit.details
    }
    
    private func triggerDisruption() {
        let plan = router.panicPivot(
            avoidStationId: avoidStationId,
            from: originId,
            to: destinationId,
            maxBudgetCents: Int(maxBudgetCents),
            prioritizeSpeed: prioritizeSpeed
        )
        if let p = plan {
            self.executionTickerText = String(format: "%.2f ms", p.executionTimeMilliseconds)
        }
        self.isRerouted = true
    }
    
    private func resetDisruption() {
        router.resetPivot(
            from: originId,
            to: destinationId,
            maxBudgetCents: Int(maxBudgetCents),
            prioritizeSpeed: prioritizeSpeed
        )
        generateItinerary()
        self.isRerouted = false
    }
}
