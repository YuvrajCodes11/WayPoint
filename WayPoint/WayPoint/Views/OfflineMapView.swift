//
//  OfflineMapView.swift
//  WayPoint
//
//  Created for RevenueCat #Shipaton 2026
//  100% Offline Vector Transit Map View (Pure SwiftUI Canvas / Path)
//

import SwiftUI

public struct OfflineMapView: View {
    @Bindable var router: GraphRouter = GraphRouter.shared
    
    // Interactive State
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var selectedStation: StationNode? = nil
    @State private var showStationDetail: Bool = false
    
    public init(router: GraphRouter = GraphRouter.shared) {
        self.router = router
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Map Canvas Viewport
            GeometryReader { geometry in
                let size = geometry.size
                
                TimelineView(.animation) { timeline in
                    let now = timeline.date.timeIntervalSince1970
                    
                    ZStack {
                        // Vector Graphics Background Grid
                        VectorGridBackground()
                        
                        // Pure Vector Transit Canvas
                        Canvas { context, canvasSize in
                            let effectiveWidth = canvasSize.width
                            let effectiveHeight = canvasSize.height
                            
                            // 1. Convert Ratios to Screen Points
                            func point(for station: StationNode) -> CGPoint {
                                return CGPoint(
                                    x: effectiveWidth * station.xRatio,
                                    y: effectiveHeight * station.yRatio
                                )
                            }
                            
                            // 2. Draw All Base Transit Lines & Track Edges
                            for edge in router.edges {
                                guard let fromNode = router.station(for: edge.fromStationId),
                                      let toNode = router.station(for: edge.toStationId) else { continue }
                                
                                let p1 = point(for: fromNode)
                                let p2 = point(for: toNode)
                                
                                let isBlockedEdge = router.blockedStations.contains(fromNode.id) || router.blockedStations.contains(toNode.id)
                                
                                var trackPath = Path()
                                trackPath.move(to: p1)
                                
                                // Smooth Bezier Curve for track path
                                let midX = (p1.x + p2.x) / 2
                                let midY = (p1.y + p2.y) / 2
                                let control = CGPoint(x: midX, y: midY + (edge.isTransfer ? -20 : 0))
                                trackPath.addQuadCurve(to: p2, control: control)
                                
                                let baseColor = Color(hex: fromNode.lineColorHex) ?? .gray
                                
                                if isBlockedEdge {
                                    // Render Disrupted / Blocked Track with Strikethrough & Flashing Amber/Red
                                    let pulseFlash = (sin(now * 8.0) + 1.0) / 2.0
                                    let strikeColor = Color.red.opacity(0.4 + 0.5 * pulseFlash)
                                    
                                    context.stroke(
                                        trackPath,
                                        with: .color(strikeColor),
                                        style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [6, 4], dashPhase: CGFloat(now * 20))
                                    )
                                    
                                    // Strike-through cross marker at edge center
                                    var crossPath = Path()
                                    crossPath.move(to: CGPoint(x: midX - 8, y: midY - 8))
                                    crossPath.addLine(to: CGPoint(x: midX + 8, y: midY + 8))
                                    crossPath.move(to: CGPoint(x: midX + 8, y: midY - 8))
                                    crossPath.addLine(to: CGPoint(x: midX - 8, y: midY + 8))
                                    context.stroke(crossPath, with: .color(.red), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                } else {
                                    // Standard Operating Track Line
                                    context.stroke(
                                        trackPath,
                                        with: .color(baseColor.opacity(0.85)),
                                        style: StrokeStyle(lineWidth: edge.isTransfer ? 3 : 5, lineCap: .round)
                                    )
                                }
                            }
                            
                            // 3. Draw Active Rerouted Route Trace (Neon Emerald Glow Overlay)
                            if let route = router.activeRoute, !route.traversedEdges.isEmpty {
                                for edge in route.traversedEdges {
                                    guard let fromNode = router.station(for: edge.fromStationId),
                                          let toNode = router.station(for: edge.toStationId) else { continue }
                                    
                                    let p1 = point(for: fromNode)
                                    let p2 = point(for: toNode)
                                    
                                    var reroutePath = Path()
                                    reroutePath.move(to: p1)
                                    let midX = (p1.x + p2.x) / 2
                                    let midY = (p1.y + p2.y) / 2
                                    let control = CGPoint(x: midX, y: midY + (edge.isTransfer ? -20 : 0))
                                    reroutePath.addQuadCurve(to: p2, control: control)
                                    
                                    // Glowing Neon Emerald Color (#00FF87)
                                    let neonEmerald = Color(red: 0.0, green: 1.0, blue: 0.53)
                                    
                                    // Outer Glow
                                    context.stroke(
                                        reroutePath,
                                        with: .color(neonEmerald.opacity(0.35)),
                                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                    )
                                    
                                    // Pulsing Inner Neon Stroke
                                    context.stroke(
                                        reroutePath,
                                        with: .color(neonEmerald),
                                        style: StrokeStyle(
                                            lineWidth: 5,
                                            lineCap: .round,
                                            dash: [12, 6],
                                            dashPhase: -CGFloat(now * 40.0)
                                        )
                                    )
                                }
                            }
                            
                            // 4. Render Station Nodes
                            for station in router.stations {
                                let p = point(for: station)
                                let isOrigin = station.id == router.originStationId
                                let isDestination = station.id == router.destinationStationId
                                let isBlocked = router.blockedStations.contains(station.id)
                                let isInActiveRoute = router.activeRoute?.path.contains(where: { $0.id == station.id }) ?? false
                                
                                // Active Node Pulse Rings (Origin Station)
                                if isOrigin {
                                    let pulseScale = (sin(now * 4.0) + 1.0) / 2.0
                                    let ringRadius: CGFloat = 16 + (pulseScale * 14)
                                    var pulseCircle = Path()
                                    pulseCircle.addEllipse(in: CGRect(x: p.x - ringRadius, y: p.y - ringRadius, width: ringRadius * 2, height: ringRadius * 2))
                                    context.stroke(pulseCircle, with: .color(Color.cyan.opacity(0.8 - (pulseScale * 0.6))), style: StrokeStyle(lineWidth: 2))
                                }
                                
                                // Disrupted Station Hazard Halo
                                if isBlocked {
                                    let hazardFlash = (sin(now * 10.0) + 1.0) / 2.0
                                    let hazardRadius: CGFloat = 18
                                    var hazardRing = Path()
                                    hazardRing.addEllipse(in: CGRect(x: p.x - hazardRadius, y: p.y - hazardRadius, width: hazardRadius * 2, height: hazardRadius * 2))
                                    context.stroke(hazardRing, with: .color(Color.red.opacity(0.6 + 0.4 * hazardFlash)), style: StrokeStyle(lineWidth: 3, dash: [4, 3]))
                                }
                                
                                // Base Station Outer Node
                                let nodeSize: CGFloat = (isOrigin || isDestination) ? 18 : 12
                                let nodeRect = CGRect(x: p.x - nodeSize/2, y: p.y - nodeSize/2, width: nodeSize, height: nodeSize)
                                var nodePath = Path()
                                nodePath.addEllipse(in: nodeRect)
                                
                                let nodeFillColor: Color = isBlocked ? .red : (isOrigin ? .cyan : (isDestination ? .green : (isInActiveRoute ? Color(red: 0.0, green: 1.0, blue: 0.53) : .white)))
                                
                                context.fill(nodePath, with: .color(nodeFillColor))
                                context.stroke(nodePath, with: .color(Color.black), style: StrokeStyle(lineWidth: 2))
                                
                                // Text Label for Station Name
                                let text = Text(station.name)
                                    .font(.system(size: 10, weight: (isOrigin || isDestination || isBlocked) ? .bold : .medium, design: .rounded))
                                    .foregroundColor(isBlocked ? .red : (isInActiveRoute ? .white : .gray))
                                
                                context.draw(text, at: CGPoint(x: p.x, y: p.y + 14), anchor: .top)
                            }
                        }
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
                                        scale = max(0.6, min(3.0, lastScale * value))
                                    }
                                    .onEnded { _ in
                                        lastScale = scale
                                    }
                            )
                        )
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            
            // Map Legend & Controls Overlay Bar
            MapControlsOverlayBar(
                scale: $scale,
                offset: $offset,
                lastScale: $lastScale,
                lastOffset: $lastOffset
            )
            .padding(.top, 8)
        }
        .padding(8)
        .background(Color(white: 0.05).ignoresSafeArea())
    }
}

// MARK: - Subviews & Helpers

struct VectorGridBackground: View {
    var body: some View {
        Canvas { context, size in
            let gridSpacing: CGFloat = 30
            var gridPath = Path()
            
            var x: CGFloat = 0
            while x < size.width {
                gridPath.move(to: CGPoint(x: x, y: 0))
                gridPath.addLine(to: CGPoint(x: x, y: size.height))
                x += gridSpacing
            }
            
            var y: CGFloat = 0
            while y < size.height {
                gridPath.move(to: CGPoint(x: 0, y: y))
                gridPath.addLine(to: CGPoint(x: size.width, y: y))
                y += gridSpacing
            }
            
            context.stroke(gridPath, with: .color(Color.white.opacity(0.04)), style: StrokeStyle(lineWidth: 1))
        }
        .background(Color(red: 0.03, green: 0.04, blue: 0.07))
    }
}

struct MapControlsOverlayBar: View {
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    @Binding var lastScale: CGFloat
    @Binding var lastOffset: CGSize
    
    var body: some View {
        HStack(spacing: 16) {
            // Legend
            HStack(spacing: 12) {
                LegendItem(color: Color(hex: "#FF9500") ?? .orange, label: "Ginza")
                LegendItem(color: Color(hex: "#E60012") ?? .red, label: "Marunouchi")
                LegendItem(color: Color(red: 0.0, green: 1.0, blue: 0.53), label: "Bypass Route")
            }
            
            Spacer()
            
            // Zoom Reset Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    scale = 1.0
                    lastScale = 1.0
                    offset = .zero
                    lastOffset = .zero
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .bold))
                    Text("Reset View")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.12)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.08)))
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - Color Hex Extension
extension Color {
    init?(hex: String) {
        let r, g, b: Double
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexSanitized.hasPrefix("#") {
            hexSanitized.remove(at: hexSanitized.startIndex)
        }
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        if hexSanitized.count == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            self.init(red: r, green: g, blue: b)
        } else {
            return nil
        }
    }
}
