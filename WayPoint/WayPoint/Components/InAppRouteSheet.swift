//
//  InAppRouteSheet.swift
//  WayPoint
//

import SwiftUI
import MapKit

struct InAppRouteSheet: View {
    let item: ItineraryItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var route: MKRoute? = nil
    @State private var travelTimeMinutes: Int = 0
    @State private var travelDistanceMeters: Int = 0
    @State private var isCalculating: Bool = true
    @State private var selectedTransportType: MKDirectionsTransportType = .walking
    @State private var cameraPosition: MapCameraPosition = .automatic

    private var userLocation: CLLocationCoordinate2D {
        LocationService.shared.currentLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
    }

    private var destinationLocation: CLLocationCoordinate2D {
        if let coord = item.coordinate {
            return CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
        }
        // Fallback Tokyo Shibuya Coordinate
        return CLLocationCoordinate2D(latitude: 35.6586, longitude: 139.7454)
    }

    init(item: ItineraryItem) {
        self.item = item
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Native SwiftUI Map View
            Map(position: $cameraPosition) {
                // User Location Annotation
                Annotation("My Location", coordinate: userLocation) {
                    ZStack {
                        Circle()
                            .fill(WayPointTheme.sapphireAccent.opacity(0.25))
                            .frame(width: 36, height: 36)
                        Circle()
                            .fill(WayPointTheme.sapphireAccent)
                            .frame(width: 14, height: 14)
                        Image(systemName: "location.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                // Destination Stop Annotation
                Annotation(item.title, coordinate: destinationLocation) {
                    ZStack {
                        Circle()
                            .fill(WayPointTheme.emeraldRecovery.opacity(0.25))
                            .frame(width: 44, height: 44)
                        Circle()
                            .fill(WayPointTheme.emeraldRecovery)
                            .frame(width: 24, height: 24)
                        Image(systemName: item.category.systemImage)
                            .font(.system(size: 11, weight: .bold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white)
                    }
                }

                // Polyline Route Overlay
                if let route {
                    MapPolyline(route.polyline)
                        .stroke(
                            LinearGradient(
                                colors: [WayPointTheme.sapphireAccent, WayPointTheme.emeraldRecovery],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 5
                        )
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()

            // Header Dismiss Bar & Floating Overlay
            VStack {
                // Header Bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("IN-APP NAVIGATION")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .tracking(1.2)
                            .foregroundStyle(WayPointTheme.sapphireAccent)

                        Text(item.title)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(WayPointTheme.textPrimary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(WayPointTheme.textSecondary)
                    }
                    .buttonStyle(.scalePress)
                    .accessibilityLabel("Close Navigation")
                }
                .padding(14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(WayPointTheme.hairlineStroke, lineWidth: 1))
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer()

                // Route Info & Turn-by-Turn Card
                routeSummaryCard
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await calculateRoute()
        }
    }

    private var routeSummaryCard: some View {
        GlassCardView(cornerRadius: 20, padding: 18, glowColor: WayPointTheme.sapphireAccent) {
            VStack(alignment: .leading, spacing: 14) {
                // Transport Mode Segment Picker & ETA Row
                HStack {
                    HStack(spacing: 6) {
                        Button(action: {
                            selectedTransportType = .walking
                            Task { await calculateRoute() }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "figure.walk")
                                    .font(.caption.weight(.bold))
                                Text("Walk")
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundStyle(selectedTransportType == .walking ? WayPointTheme.sapphireAccent : WayPointTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedTransportType == .walking ? WayPointTheme.sapphireAccent.opacity(0.18) : WayPointTheme.cardSurface, in: Capsule())
                            .overlay(Capsule().strokeBorder(selectedTransportType == .walking ? WayPointTheme.sapphireAccent : WayPointTheme.hairlineStroke, lineWidth: 1))
                        }
                        .buttonStyle(.scalePress)

                        Button(action: {
                            selectedTransportType = .transit
                            Task { await calculateRoute() }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "tram.fill")
                                    .font(.caption.weight(.bold))
                                Text("Transit")
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundStyle(selectedTransportType == .transit ? WayPointTheme.sapphireAccent : WayPointTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedTransportType == .transit ? WayPointTheme.sapphireAccent.opacity(0.18) : WayPointTheme.cardSurface, in: Capsule())
                            .overlay(Capsule().strokeBorder(selectedTransportType == .transit ? WayPointTheme.sapphireAccent : WayPointTheme.hairlineStroke, lineWidth: 1))
                        }
                        .buttonStyle(.scalePress)
                    }

                    Spacer()

                    if isCalculating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("\(travelTimeMinutes) min")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(WayPointTheme.emeraldRecovery)

                            Text("\(travelDistanceMeters)m away")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(WayPointTheme.textSecondary)
                        }
                    }
                }

                Divider().overlay(WayPointTheme.hairlineStroke)

                // Step-by-Step Instructions Preview
                if let steps = route?.steps, steps.count > 1 {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NAVIGATION STEPS")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(WayPointTheme.textTertiary)

                        ForEach(Array(steps.prefix(3).enumerated()), id: \.offset) { index, step in
                            if !step.instructions.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                        .font(.caption2.weight(.bold))
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundStyle(WayPointTheme.sapphireAccent)

                                    Text(step.instructions)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(WayPointTheme.textPrimary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundStyle(WayPointTheme.sapphireAccent)

                        Text(item.location)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(WayPointTheme.textSecondary)
                    }
                }

                // Done Button
                Button(action: { dismiss() }) {
                    Text("Done")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(WayPointTheme.emeraldRecovery, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.scalePress)
            }
        }
    }

    private func calculateRoute() async {
        isCalculating = true
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationLocation))
        request.transportType = selectedTransportType

        let directions = MKDirections(request: request)
        do {
            let response = try await directions.calculate()
            if let firstRoute = response.routes.first {
                self.route = firstRoute
                self.travelTimeMinutes = max(1, Int(firstRoute.expectedTravelTime / 60))
                self.travelDistanceMeters = Int(firstRoute.distance)
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.5)) {
                    self.cameraPosition = .rect(firstRoute.polyline.boundingMapRect)
                }
            }
        } catch {
            print("[InAppRouteSheet] Directions calculation fallback: \(error.localizedDescription)")
            self.travelDistanceMeters = LocationService.shared.distanceMeters(to: destinationLocation.latitude, to: destinationLocation.longitude)
            self.travelTimeMinutes = max(2, travelDistanceMeters / 80)
        }
        isCalculating = false
    }
}
