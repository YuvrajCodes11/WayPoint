//
//  ItineraryMapView.swift
//  WayPoint
//
//  Task 4.1 / WP6: MapKit Navigation, Null Island Guard & Route Safety
//

import SwiftUI
import MapKit

struct ItineraryMapView: View {
    @Environment(TripStore.self) private var tripStore
    @State private var selectedItem: ItineraryItem? = nil
    @State private var position: MapCameraPosition = .automatic
    @State private var locationService = LocationService.shared
    @State private var directionError: String? = nil
    @State private var routeSheetItem: ItineraryItem? = nil

    private var currentDayPlan: DayPlan {
        tripStore.currentDayPlan
    }

    private var coordinates: [CLLocationCoordinate2D] {
        currentDayPlan.items.compactMap { item in
            if let coord = item.coordinate, LocationService.isValidCoordinate(latitude: coord.latitude, longitude: coord.longitude) {
                return CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
            }
            return nil
        }
    }

    @State private var openMapsToast: String? = nil

    var body: some View {
        ZStack {
            // Layer 1: Native Interactive Map View
            Map(position: $position, selection: $selectedItem) {
                UserAnnotation()

                if coordinates.count > 1 {
                    MapPolyline(coordinates: coordinates)
                        .stroke(WayPointTheme.cyanGlow, lineWidth: 3)
                }

                ForEach(currentDayPlan.items, id: \.id) { item in
                    if let coord = item.coordinate, LocationService.isValidCoordinate(latitude: coord.latitude, longitude: coord.longitude) {
                        Annotation(
                            item.title,
                            coordinate: CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
                        ) {
                            MapMarkerPin(item: item, isSelected: selectedItem?.id == item.id)
                                .onTapGesture {
                                    #if canImport(UIKit)
                                    UISelectionFeedbackGenerator().selectionChanged()
                                    #endif
                                    withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                                        selectedItem = item
                                        updateCameraPosition(for: item)
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

            // Layer 2: Top Header Overlay
            VStack {
                topHeaderOverlay
                    .allowsHitTesting(true)
                
                if let mapsToast = openMapsToast {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.black)
                        Text(mapsToast)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.black)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(WayPointTheme.cyanGlow, in: Capsule())
                    .shadow(color: WayPointTheme.cyanGlow.opacity(0.4), radius: 10, x: 0, y: 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
                }

                Spacer()
            }
            .allowsHitTesting(false)

            // Layer 3: Synchronized Horizontal Card Deck Overlay
            VStack {
                Spacer()
                horizontalCardDeck
                    .padding(.bottom, 95)
                    .allowsHitTesting(true)
            }
            .allowsHitTesting(false)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if selectedItem == nil {
                selectedItem = currentDayPlan.items.first
            }
            updateCameraPosition(for: selectedItem)
        }
        .onChange(of: tripStore.activeTrip.selectedDayIndex) {
            selectedItem = currentDayPlan.items.first
            updateCameraPosition(for: selectedItem)
        }
        .alert("Directions unavailable", isPresented: Binding(
            get: { directionError != nil },
            set: { if !$0 { directionError = nil } }
        )) {
            Button("OK", role: .cancel) { directionError = nil }
        } message: {
            Text(directionError ?? "")
        }
        .sheet(item: $routeSheetItem) { item in
            InAppRouteSheet(item: item)
        }
    }

    // MARK: - Top Header Overlay

    private var topHeaderOverlay: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("GPS RADAR & MAP")
                        .font(.caption.weight(.bold))
                        .tracking(1.5)
                        .foregroundStyle(WayPointTheme.cyanGlow)

                    Text(currentDayPlan.title)
                        .font(.title3.weight(.bold))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundStyle(WayPointTheme.textPrimary)
                }

                Spacer()

                Menu {
                    ForEach(Array(tripStore.activeTrip.days.enumerated()), id: \.element.id) { index, day in
                        Button("Day \(index + 1): \(day.title)") {
                            #if canImport(UIKit)
                            UISelectionFeedbackGenerator().selectionChanged()
                            #endif
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                                tripStore.selectDay(index)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Day \(tripStore.activeTrip.selectedDayIndex + 1)")
                            .font(.caption.weight(.bold))
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(WayPointTheme.obsidian)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(WayPointTheme.accentGradient, in: Capsule())
                    .shadow(color: WayPointTheme.cyanGlow.opacity(0.3), radius: 8, x: 0, y: 3)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)
        }
    }

    // MARK: - Synchronized Horizontal Card Deck Overlay

    private var horizontalCardDeck: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(currentDayPlan.items, id: \.id) { item in
                        venueCard(item: item)
                            .id(item.id)
                            .onTapGesture {
                                #if canImport(UIKit)
                                UISelectionFeedbackGenerator().selectionChanged()
                                #endif
                                withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                                    selectedItem = item
                                    updateCameraPosition(for: item)
                                }
                            }
                    }
                }
                .padding(.horizontal, 20)
            }
            .onChange(of: selectedItem?.id) { _, newID in
                if let targetID = newID {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                        proxy.scrollTo(targetID, anchor: .center)
                    }
                }
            }
        }
    }

    private func venueCard(item: ItineraryItem) -> some View {
        let isSelected = selectedItem?.id == item.id
        let hasValidCoord = item.coordinate != nil && LocationService.isValidCoordinate(latitude: item.coordinate!.latitude, longitude: item.coordinate!.longitude)

        return GlassCardView(
            cornerRadius: 20,
            padding: 14,
            glowColor: isSelected ? WayPointTheme.cyanGlow : .clear
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Image(systemName: item.category.systemImage)
                                .font(.caption2.weight(.bold))
                            Text(item.category.displayName.uppercased())
                                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        }
                        .foregroundStyle(WayPointTheme.cyanGlow)

                        Text(item.title)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(WayPointTheme.textPrimary)
                            .lineLimit(1)

                        Text(item.timeRange)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(WayPointTheme.textSecondary)
                    }

                    Spacer(minLength: 8)

                    if hasValidCoord {
                        Button(action: { openInAppleMaps(item: item) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Directions")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundStyle(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(WayPointTheme.accentGradient, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "location.slash.fill")
                                .font(.caption2)
                            Text("Offline Stop")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(WayPointTheme.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(WayPointTheme.obsidianElevated, in: Capsule())
                        .overlay(Capsule().strokeBorder(WayPointTheme.glassBorder, lineWidth: 1))
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption2)
                        .foregroundStyle(WayPointTheme.textTertiary)
                    Text(item.location)
                        .font(.caption2)
                        .foregroundStyle(WayPointTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(width: 270)
        }
        .scaleEffect(isSelected ? 1.02 : 0.98)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(isSelected ? WayPointTheme.cyanGlow : WayPointTheme.glassBorder, lineWidth: isSelected ? 1.5 : 1)
        )
    }

    // MARK: - Camera & Routing Helpers

    private func updateCameraPosition(for item: ItineraryItem?) {
        if let item = item, let coord = item.coordinate, LocationService.isValidCoordinate(latitude: coord.latitude, longitude: coord.longitude) {
            let clCoord = CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
            let region = MKCoordinateRegion(
                center: clCoord,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
            position = .region(region)
        } else if let userLoc = locationService.currentLocation?.coordinate {
            let region = MKCoordinateRegion(
                center: userLoc,
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
            position = .region(region)
        } else if let firstCoord = coordinates.first {
            let region = MKCoordinateRegion(
                center: firstCoord,
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
            position = .region(region)
        }
    }

    private func openInAppleMaps(item: ItineraryItem) {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        routeSheetItem = item
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
        .animation(.spring(response: 0.38, dampingFraction: 0.8), value: isSelected)
    }
}
