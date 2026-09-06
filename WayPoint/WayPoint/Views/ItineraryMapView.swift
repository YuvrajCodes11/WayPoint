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
    @State private var selectedStopIndex: Int = 0
    @State private var position: MapCameraPosition = .automatic
    @State private var locationService = LocationService.shared
    @State private var directionError: String? = nil
    @State private var activeRouteStop: ItineraryItem? = nil
    @State private var openMapsToast: String? = nil

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

    var body: some View {
        ZStack {
            // Layer 1: Native Interactive Map View
            Map(position: $position, selection: $selectedItem) {
                UserAnnotation()

                if coordinates.count > 1 {
                    MapPolyline(coordinates: coordinates)
                        .stroke(WayPointTheme.sapphireAccent, lineWidth: 3.5)
                }

                ForEach(Array(currentDayPlan.items.enumerated()), id: \.element.id) { index, item in
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
                                        selectedStopIndex = index
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
                    .background(WayPointTheme.emeraldRecovery, in: Capsule())
                    .shadow(color: WayPointTheme.emeraldRecovery.opacity(0.4), radius: 10, x: 0, y: 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
                }

                Spacer()
            }
            .allowsHitTesting(false)

            // Layer 3: Synchronized Paging Carousel Overlay (Prevent MapKit Touch Hijacking)
            VStack {
                Spacer()
                pagingCardCarousel
                    .padding(.bottom, 95)
                    .allowsHitTesting(true)
            }
            .allowsHitTesting(true)
            .zIndex(100)
        }
        .background(Color.clear)
        .scrollContentBackground(.hidden)
        .preferredColorScheme(.dark)
        .onAppear {
            if selectedItem == nil, let first = currentDayPlan.items.first {
                selectedItem = first
                selectedStopIndex = 0
            }
            updateCameraPosition(for: selectedItem)
        }
        .onChange(of: selectedStopIndex) { _, newIndex in
            if currentDayPlan.items.indices.contains(newIndex) {
                let targetItem = currentDayPlan.items[newIndex]
                selectedItem = targetItem
                withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                    updateCameraPosition(for: targetItem)
                }
            }
        }
        .onChange(of: tripStore.activeTrip.selectedDayIndex) {
            selectedStopIndex = 0
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
        .sheet(item: $activeRouteStop) { item in
            InAppRouteSheet(item: item)
        }
    }

    // MARK: - Top Header Overlay

    private var topHeaderOverlay: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("GPS RADAR & MAP")
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .tracking(1.4)
                    .foregroundStyle(WayPointTheme.sapphireAccent)

                Text(currentDayPlan.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(WayPointTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 8)

            Menu {
                ForEach(Array(tripStore.activeTrip.days.enumerated()), id: \.element.id) { index, day in
                    Button("Day \(index + 1): \(day.title)") {
                        #if canImport(UIKit)
                        UISelectionFeedbackGenerator().selectionChanged()
                        #endif
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                            tripStore.selectDay(index)
                            selectedStopIndex = 0
                            selectedItem = tripStore.currentDayPlan.items.first
                            updateCameraPosition(for: selectedItem)
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
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(WayPointTheme.sapphireAccent, in: Capsule())
                .shadow(color: WayPointTheme.sapphireAccent.opacity(0.4), radius: 8, x: 0, y: 3)
            }
            .buttonStyle(.scalePress)
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(WayPointTheme.hairlineStroke, lineWidth: 1))
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    // MARK: - Synchronized Horizontal Paging Card Carousel Overlay

    private var pagingCardCarousel: some View {
        TabView(selection: $selectedStopIndex) {
            ForEach(Array(currentDayPlan.items.enumerated()), id: \.offset) { index, item in
                venueCard(item: item, index: index)
                    .tag(index)
                    .padding(.horizontal, 16)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 140)
    }

    private func venueCard(item: ItineraryItem, index: Int) -> some View {
        let isSelected = selectedItem?.id == item.id

        return GlassCardView(
            cornerRadius: 20,
            padding: 14,
            glowColor: isSelected ? WayPointTheme.sapphireAccent : .clear
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("STOP \(index + 1)")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(WayPointTheme.sapphireAccent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(WayPointTheme.sapphireAccent.opacity(0.18), in: Capsule())

                            Image(systemName: item.category.systemImage)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(WayPointTheme.textSecondary)

                            Text(item.category.displayName.uppercased())
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundStyle(WayPointTheme.textSecondary)
                        }

                        Text(item.title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(WayPointTheme.textPrimary)
                            .lineLimit(1)

                        Text(item.timeRange)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(WayPointTheme.textSecondary)
                    }

                    Spacer(minLength: 8)

                    Button(action: {
                        activeRouteStop = item
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                .font(.caption.weight(.bold))
                            Text("Directions")
                                .font(.caption2.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            LinearGradient(
                                colors: [WayPointTheme.sapphireAccent, WayPointTheme.emeraldRecovery],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                        .shadow(color: WayPointTheme.sapphireAccent.opacity(0.4), radius: 8, x: 0, y: 3)
                    }
                    .buttonStyle(.scalePress)
                }

                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption2)
                        .foregroundStyle(WayPointTheme.sapphireAccent)

                    Text(item.location)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(WayPointTheme.textSecondary)
                        .lineLimit(1)
                }
            }
        }
    }

    // MARK: - Camera & Routing Helpers

    private func updateCameraPosition(for item: ItineraryItem?) {
        if let item = item, let coord = item.coordinate, LocationService.isValidCoordinate(latitude: coord.latitude, longitude: coord.longitude) {
            let clCoord = CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
            let region = MKCoordinateRegion(
                center: clCoord,
                span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
            )
            position = .region(region)
        } else if let userLoc = locationService.currentLocation?.coordinate {
            let region = MKCoordinateRegion(
                center: userLoc,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            position = .region(region)
        } else if let firstCoord = coordinates.first {
            let region = MKCoordinateRegion(
                center: firstCoord,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            position = .region(region)
        }
    }
}

// MARK: - Map Marker Pin

private struct MapMarkerPin: View {
    let item: ItineraryItem
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? WayPointTheme.sapphireAccent : WayPointTheme.cardSurface)
                .frame(width: 38, height: 38)
                .shadow(color: WayPointTheme.sapphireAccent.opacity(isSelected ? 0.6 : 0.2), radius: 8)

            Image(systemName: item.category.systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(isSelected ? .white : WayPointTheme.sapphireAccent)
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.38, dampingFraction: 0.8), value: isSelected)
    }
}
