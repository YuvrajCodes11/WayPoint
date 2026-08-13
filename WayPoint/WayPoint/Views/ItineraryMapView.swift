//
//  ItineraryMapView.swift
//  WayPoint
//

import SwiftUI
import MapKit

struct ItineraryMapView: View {
    @Binding var trip: Trip
    @State private var selectedItem: ItineraryItem? = nil
    @State private var position: MapCameraPosition = .automatic
    @State private var locationService = LocationService.shared

    private var currentDayPlan: DayPlan {
        trip.currentDayPlan
    }

    private var coordinates: [CLLocationCoordinate2D] {
        currentDayPlan.items.compactMap { item in
            if let coord = item.coordinate {
                return CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
            }
            return nil
        }
    }

    var body: some View {
        ZStack {
            // Layer 1: Native Interactive Map View (Full screen touch receiver)
            Map(position: $position, selection: $selectedItem) {
                UserAnnotation()

                if coordinates.count > 1 {
                    MapPolyline(coordinates: coordinates)
                        .stroke(WayPointTheme.cyanGlow, lineWidth: 3)
                }

                ForEach(currentDayPlan.items, id: \.id) { item in
                    if let coord = item.coordinate {
                        Annotation(
                            item.title,
                            coordinate: CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
                        ) {
                            MapMarkerPin(item: item, isSelected: selectedItem?.id == item.id)
                                .onTapGesture {
                                    withAnimation {
                                        selectedItem = item
                                    }
                                }
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapPitchToggle()
                MapUserLocationButton()
            }

            // Layer 2: Top Header Overlay (Non-blocking parent container, active hit-testing on header)
            VStack {
                topHeaderOverlay
                    .padding(.top, 12)
                    .allowsHitTesting(true)
                Spacer()
            }
            .allowsHitTesting(false)

            // Layer 3: Bottom Detail Overlay Card (Non-blocking parent container, active hit-testing on card)
            if let selected = selectedItem {
                VStack {
                    Spacer()
                    bottomDetailCard(item: selected)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 95)
                        .allowsHitTesting(true)
                }
                .allowsHitTesting(false)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if selectedItem == nil {
                selectedItem = currentDayPlan.items.first
            }
            updateCameraPosition()
        }
        .onChange(of: trip.selectedDayIndex) {
            selectedItem = currentDayPlan.items.first
            updateCameraPosition()
        }
    }

    // MARK: - Top Header Overlay

    private var topHeaderOverlay: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("GPS RADAR & MAP")
                        .font(.caption.weight(.bold))
                        .tracking(1.5)
                        .foregroundStyle(WayPointTheme.cyanGlow)

                    Text(currentDayPlan.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(WayPointTheme.textPrimary)
                }

                Spacer()

                Menu {
                    ForEach(Array(trip.days.enumerated()), id: \.element.id) { index, day in
                        Button("Day \(index + 1): \(day.title)") {
                            withAnimation {
                                trip.selectedDayIndex = index
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Day \(trip.selectedDayIndex + 1)")
                            .font(.caption.weight(.bold))
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(WayPointTheme.obsidian)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(WayPointTheme.accentGradient, in: Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }

    // MARK: - Bottom Detail Card Overlay

    private func bottomDetailCard(item: ItineraryItem) -> some View {
        GlassCardView(
            cornerRadius: 22,
            padding: 16,
            glowColor: WayPointTheme.cyanGlow
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: item.category.systemImage)
                                .font(.caption.weight(.bold))
                            Text(item.category.displayName.uppercased())
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(WayPointTheme.cyanGlow)

                        Text(item.title)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(WayPointTheme.textPrimary)

                        Text(item.timeRange)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(WayPointTheme.textSecondary)
                    }

                    Spacer()

                    Button(action: { openInAppleMaps(item: item) }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                .font(.body.weight(.bold))
                            Text("Directions")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(WayPointTheme.accentGradient, in: Capsule())
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "mappin")
                        .font(.caption)
                        .foregroundStyle(WayPointTheme.textTertiary)
                    Text(item.location)
                        .font(.caption)
                        .foregroundStyle(WayPointTheme.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func updateCameraPosition() {
        if let userLoc = locationService.currentLocation?.coordinate {
            let region = MKCoordinateRegion(
                center: userLoc,
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
            position = .region(region)
        } else if let firstCoord = coordinates.first {
            let region = MKCoordinateRegion(
                center: firstCoord,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
            position = .region(region)
        }
    }

    private func openInAppleMaps(item: ItineraryItem) {
        guard let coord = item.coordinate else { return }
        let clCoord = CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: clCoord))
        mapItem.name = item.title
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - Map Marker Pin

private struct MapMarkerPin: View {
    let item: ItineraryItem
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? WayPointTheme.cyanGlow : WayPointTheme.obsidianElevated)
                .frame(width: 38, height: 38)
                .shadow(color: WayPointTheme.cyanGlow.opacity(isSelected ? 0.6 : 0.2), radius: 8)

            Image(systemName: item.category.systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(isSelected ? .black : WayPointTheme.cyanGlow)
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    ItineraryMapView(trip: .constant(.empty))
}