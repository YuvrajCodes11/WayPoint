//
//  OfflineTransitCanvasView.swift
//  WayPoint
//
//  Created by Yuvraj for RevenueCat #Shipaton 2026
//  100% Air-Gapped Offline Schematic Transit Canvas & Local Station Search Engine
//

import SwiftUI

public struct OfflineTransitCanvasView: View {
    @Environment(TripStore.self) private var tripStore
    @Bindable var router: BudgetGraphRouter = BudgetGraphRouter.shared
    
    // Interactive Zoom & Pan State
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    // In-Memory Search & Selection State
    @State private var searchQuery: String = ""
    @State private var isSearchFocused: Bool = false
    @State private var selectedStation: Station? = nil
    @State private var searchSelectionMode: SearchMode = .setOrigin
    
    public enum SearchMode {
        case setOrigin
        case setDestination
    }
    
    public var isEmbedded: Bool = true
    
    public init(router: BudgetGraphRouter = BudgetGraphRouter.shared, isEmbedded: Bool = true) {
        self.router = router
        self.isEmbedded = isEmbedded
    }
    
    private var activeDestination: String {
        tripStore.currentTrip?.destination ?? tripStore.activeTrip.destination
    }

    private var activeStations: [Station] {
        TransitRegistry.stations(for: activeDestination)
    }

    private var activeConnections: [TransitConnection] {
        TransitRegistry.connections(for: activeDestination)
    }

    private var filteredStations: [Station] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty { return [] }
        return activeStations.filter { station in
            station.name.lowercased().contains(query) ||
            station.id.lowercased().contains(query) ||
            station.lines.contains(where: { $0.lowercased().contains(query) })
        }
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            // Layer 1: Vector Canvas Viewport
            GeometryReader { geometry in
                TimelineView(.animation) { timeline in
                    let now = timeline.date.timeIntervalSince1970
                    
                    ZStack {
                        // Background Grid
                        VectorGridBackground()
                        
                        // Vector Schematic Canvas
                        vectorCanvas(now: now)
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                SimultaneousGesture(
                                    DragGesture()
                                        .onChanged { value in
                                            offset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                        }
                                        .onEnded { _ in
                                            lastOffset = offset
                                        },
                                    MagnificationGesture()
                                        .onChanged { value in
                                            scale = max(0.6, min(3.5, lastScale * value))
                                        }
                                        .onEnded { _ in
                                            lastScale = scale
                                        }
                                )
                            )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(WayPointTheme.glassBorder, lineWidth: 1)
            )
            

            
            // Layer 3: Bottom Map Controls & Legend Overlay
            VStack {
                Spacer()
                mapControlsOverlay
                    .padding(.horizontal, 12)
                    .padding(.bottom, 95)
            }
            .allowsHitTesting(true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WayPointTheme.obsidian.ignoresSafeArea())
        .onAppear {
            GraphRouter.shared.switchCity(to: activeDestination)
        }
        .onChange(of: activeDestination) { _, newCity in
            GraphRouter.shared.switchCity(to: newCity)
        }
    }
    
    // MARK: - In-Memory Search Header Bar
    
    private var searchHeaderBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(WayPointTheme.cyanGlow)
                
                TextField("Search Tokyo Stations or Lines (Offline)...", text: $searchQuery)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(WayPointTheme.textPrimary)
                    .disableAutocorrection(true)
                
                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(WayPointTheme.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(WayPointTheme.obsidianElevated, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(WayPointTheme.glassBorder, lineWidth: 1)
            )
            
            // Search Selection Mode Toggle Button
            Menu {
                Button("Set as Origin Station") {
                    searchSelectionMode = .setOrigin
                }
                Button("Set as Destination Station") {
                    searchSelectionMode = .setDestination
                }
            } label: {
                HStack(spacing: 4) {
                    Text(searchSelectionMode == .setOrigin ? "Target: Origin" : "Target: Dest")
                        .font(.caption.weight(.bold))
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(searchSelectionMode == .setOrigin ? Color.cyan : Color(red: 0.0, green: 1.0, blue: 0.53))
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background(WayPointTheme.obsidianElevated, in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(WayPointTheme.glassBorder, lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Search Results Dropdown List
    
    private var searchResultsDropdown: some View {
        VStack(spacing: 4) {
            ForEach(filteredStations.prefix(5)) { station in
                Button(action: {
                    selectStationFromSearch(station)
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "tram.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(WayPointTheme.cyanGlow)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(station.name)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(WayPointTheme.textPrimary)
                            
                            Text(station.lines.joined(separator: " • "))
                                .font(.caption2)
                                .foregroundStyle(WayPointTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Text("Select")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(WayPointTheme.cyanGlow)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(WayPointTheme.cyanGlow.opacity(0.15), in: Capsule())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                
                if station.id != filteredStations.prefix(5).last?.id {
                    Divider().background(WayPointTheme.glassBorder)
                }
            }
        }
        .padding(.vertical, 6)
        .background(WayPointTheme.obsidianElevated, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(WayPointTheme.cyanGlow.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.6), radius: 12, x: 0, y: 6)
    }
    
    // MARK: - Bottom Controls & Legend Overlay
    
    private var mapControlsOverlay: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                LegendDot(color: Color(hex: "#FF9500") ?? .orange, label: "Ginza")
                LegendDot(color: Color(hex: "#E60012") ?? .red, label: "Marunouchi")
                LegendDot(color: Color(red: 0.0, green: 0.94, blue: 1.0), label: "Cyan Route")
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    scale = 1.0
                    lastScale = 1.0
                    offset = .zero
                    lastOffset = .zero
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption.weight(.bold))
                    Text("Reset")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(WayPointTheme.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(WayPointTheme.obsidianSurface, in: Capsule())
                .overlay(Capsule().strokeBorder(WayPointTheme.glassBorder, lineWidth: 1))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(WayPointTheme.obsidianElevated.opacity(0.9), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(WayPointTheme.glassBorder, lineWidth: 1))
    }
    
    // MARK: - Search Selection Action
    
    private func selectStationFromSearch(_ station: Station) {
        Haptics.impact(.medium)
        Haptics.selection()
        selectedStation = station
        searchQuery = ""
        
        if searchSelectionMode == .setOrigin {
            router.selectedOriginId = station.id
        } else {
            router.selectedDestinationId = station.id
        }
        
        _ = router.findOptimalTrip(
            from: router.selectedOriginId,
            to: router.selectedDestinationId,
            maxBudgetCents: Int(router.maxBudgetCents),
            prioritizeSpeed: router.prioritizeSpeed
        )
    }
    
    // MARK: - Vector Schematic Canvas Renderer
    
    @ViewBuilder
    private func vectorCanvas(now: Double) -> some View {
        Canvas { context, size in
            let effectiveWidth = size.width
            let effectiveHeight = size.height

            let marginX: CGFloat = 85
            let marginTop: CGFloat = 140
            let marginBottom: CGFloat = 175
            let usableW = max(80, effectiveWidth - (marginX * 2))
            let usableH = max(80, effectiveHeight - marginTop - marginBottom)

            func point(for stationId: String) -> CGPoint? {
                guard let station = activeStations.first(where: { $0.id == stationId }) else { return nil }
                return CGPoint(
                    x: marginX + (usableW * station.coordinates.x),
                    y: marginTop + (usableH * station.coordinates.y)
                )
            }
            
            // 1. Draw Network Connections (Track Edges)
            for connection in activeConnections {
                guard let p1 = point(for: connection.fromStationId),
                      let p2 = point(for: connection.toStationId) else { continue }
                
                let isAvoided = router.isPanicActive && (connection.fromStationId == router.lastAvoidedStationId || connection.toStationId == router.lastAvoidedStationId)
                
                var trackPath = Path()
                trackPath.move(to: p1)
                
                let midX = (p1.x + p2.x) / 2
                let midY = (p1.y + p2.y) / 2
                let control = CGPoint(x: midX, y: midY + (connection.transitType == .walking ? -15 : 0))
                trackPath.addQuadCurve(to: p2, control: control)
                
                let lineColor = Color(hex: connection.hexColor) ?? .gray
                
                if isAvoided {
                    let pulse = (sin(now * 8.0) + 1.0) / 2.0
                    let strikeColor = Color.red.opacity(0.4 + 0.5 * pulse)
                    context.stroke(
                        trackPath,
                        with: .color(strikeColor),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [6, 4])
                    )
                } else {
                    let lineWidth: CGFloat = connection.transitType == .express ? 6 : (connection.transitType == .walking ? 2 : 4)
                    context.stroke(
                        trackPath,
                        with: .color(lineColor.opacity(0.85)),
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round,
                            dash: connection.transitType == .walking ? [4, 4] : []
                        )
                    )
                }
            }
            
            // 2. Draw Solved Active Route Overlay (Neon Cyan #00F0FF)
            if let plan = router.currentPlan, !plan.legs.isEmpty {
                for leg in plan.legs {
                    guard let p1 = point(for: leg.fromStation.id),
                          let p2 = point(for: leg.toStation.id) else { continue }
                    
                    var routePath = Path()
                    routePath.move(to: p1)
                    let midX = (p1.x + p2.x) / 2
                    let midY = (p1.y + p2.y) / 2
                    let control = CGPoint(x: midX, y: midY + (leg.connection.transitType == .walking ? -15 : 0))
                    routePath.addQuadCurve(to: p2, control: control)
                    
                    let neonCyan = Color(red: 0.0, green: 0.94, blue: 1.0) // #00F0FF
                    
                    context.stroke(
                        routePath,
                        with: .color(neonCyan.opacity(0.4)),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    
                    context.stroke(
                        routePath,
                        with: .color(neonCyan),
                        style: StrokeStyle(
                            lineWidth: 6,
                            lineCap: .round,
                            dash: [12, 6],
                            dashPhase: -CGFloat(now * 35.0)
                        )
                    )
                }
            }
            
            // 3. Render Station Nodes & Labels
            for station in activeStations {
                guard let p = point(for: station.id) else { continue }
                
                let isOrigin = station.id == router.selectedOriginId
                let isDestination = station.id == router.selectedDestinationId
                let isSelected = station.id == selectedStation?.id
                let isAvoided = router.isPanicActive && station.id == router.lastAvoidedStationId
                let isInSolvedRoute = router.currentPlan?.legs.contains(where: { $0.fromStation.id == station.id || $0.toStation.id == station.id }) ?? false
                
                if isOrigin {
                    let pulse = (sin(now * 5.0) + 1.0) / 2.0
                    let ringR: CGFloat = 16 + (pulse * 12)
                    var ring = Path()
                    ring.addEllipse(in: CGRect(x: p.x - ringR, y: p.y - ringR, width: ringR * 2, height: ringR * 2))
                    context.stroke(ring, with: .color(Color.cyan.opacity(0.8 - pulse * 0.6)), style: StrokeStyle(lineWidth: 2))
                }
                
                if isAvoided {
                    let hazardFlash = (sin(now * 10.0) + 1.0) / 2.0
                    let hazardR: CGFloat = 18
                    var hazardRing = Path()
                    hazardRing.addEllipse(in: CGRect(x: p.x - hazardR, y: p.y - hazardR, width: hazardR * 2, height: hazardR * 2))
                    context.stroke(hazardRing, with: .color(Color.red.opacity(0.6 + 0.4 * hazardFlash)), style: StrokeStyle(lineWidth: 3, dash: [4, 3]))
                }
                
                let nodeSize: CGFloat = (isOrigin || isDestination || isSelected) ? 20 : 13
                let nodeRect = CGRect(x: p.x - nodeSize/2, y: p.y - nodeSize/2, width: nodeSize, height: nodeSize)
                var nodePath = Path()
                nodePath.addEllipse(in: nodeRect)
                
                let nodeColor: Color = isAvoided ? .red : (isOrigin ? .cyan : (isDestination ? Color(red: 0.0, green: 1.0, blue: 0.53) : (isInSolvedRoute ? Color.cyan : .white)))
                
                context.fill(nodePath, with: .color(nodeColor))
                context.stroke(nodePath, with: .color(Color.black), style: StrokeStyle(lineWidth: 2))
                
                let text = Text(station.name)
                    .font(.system(size: (isOrigin || isDestination || isSelected) ? 11 : 9.5, weight: (isOrigin || isDestination || isSelected) ? .bold : .medium, design: .rounded))
                    .foregroundColor(isAvoided ? .red : (isInSolvedRoute ? .white : Color.white.opacity(0.85)))
                
                let textAnchor: UnitPoint
                let textPos: CGPoint
                if p.x < 110 {
                    // Left-edge stations (e.g. Heathrow Airport): anchor text to leading so it renders to the right of the node
                    textAnchor = .leading
                    textPos = CGPoint(x: p.x + (nodeSize / 2) + 6, y: p.y)
                } else if p.x > (effectiveWidth - 110) {
                    // Right-edge stations: anchor to trailing
                    textAnchor = .trailing
                    textPos = CGPoint(x: p.x - (nodeSize / 2) - 6, y: p.y)
                } else {
                    // Center stations: draw below node
                    textAnchor = .top
                    textPos = CGPoint(x: p.x, y: p.y + (nodeSize / 2) + 4)
                }
                context.draw(text, at: textPos, anchor: textAnchor)
            }
        }
    }
}

public struct VectorGridBackground: View {
    public init() {}
    
    public var body: some View {
        Canvas { context, size in
            let step: CGFloat = 35
            var path = Path()
            for x in stride(from: 0, to: size.width, by: step) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            for y in stride(from: 0, to: size.height, by: step) {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(path, with: .color(WayPointTheme.obsidianElevated.opacity(0.4)), lineWidth: 0.5)
        }
        .background(WayPointTheme.obsidian)
    }
}

private struct LegendDot: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(WayPointTheme.textSecondary)
        }
    }
}

#Preview {
    OfflineTransitCanvasView()
}

