import SwiftUI
import MapKit

enum MapViewMode: String, CaseIterable {
    case cityMap = "City Map"
    case transitRadar = "Transit Network"
}

struct ItineraryMapView: View {
    @Environment(TripStore.self) private var tripStore
    @State private var viewMode: MapViewMode = .cityMap
    @State private var selectedStopIndex: Int = 0
    @State private var position: MapCameraPosition = .automatic
    @State private var activeRouteStop: ItineraryItem? = nil

    private var currentItems: [ItineraryItem] {
        if let dynamic = tripStore.currentTrip, dynamic.days.indices.contains(tripStore.selectedDayIndex) {
            let dayStops = dynamic.days[tripStore.selectedDayIndex].stops
            return dayStops.map { stop in
                ItineraryItem(
                    title: stop.title,
                    subtitle: stop.bookingReference ?? stop.notes ?? "Scheduled Stop",
                    startTime: stop.scheduledTime,
                    endTime: stop.scheduledTime.addingTimeInterval(TimeInterval(stop.durationMinutes * 60)),
                    location: dynamic.destination,
                    category: stop.type == .dining ? .dining : (stop.type == .hotel ? .stay : .sightseeing),
                    estimatedCost: Decimal(stop.estimatedCost),
                    coordinate: coordinateForStop(stop.title, city: dynamic.destination)
                )
            }
        }
        return tripStore.currentDayPlan.items
    }

    private var activeSelectedItem: ItineraryItem? {
        currentItems.indices.contains(selectedStopIndex) ? currentItems[selectedStopIndex] : currentItems.first
    }

    var body: some View {
        ZStack(alignment: .top) {
            // LAYER 1: BASE MAP VIEW
            if viewMode == .cityMap {
                // REAL NATIVE APPLE MAPKIT
                Map(position: $position) {
                    ForEach(Array(currentItems.enumerated()), id: \.offset) { index, item in
                        if let coord = item.coordinate, LocationService.isValidCoordinate(latitude: coord.latitude, longitude: coord.longitude) {
                            Annotation(item.title, coordinate: CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)) {
                                ZStack {
                                    Circle()
                                        .fill(selectedStopIndex == index ? WayPointTheme.sapphireAccent : Color.black.opacity(0.8))
                                        .frame(width: 36, height: 36)
                                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                        .shadow(radius: 6)

                                    Image(systemName: item.category.systemImage)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                                .scaleEffect(selectedStopIndex == index ? 1.25 : 1.0)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        selectedStopIndex = index
                                        updateCamera(for: item)
                                    }
                                }
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .ignoresSafeArea()
            } else {
                // OFFLINE SCHEMATIC TRANSIT NETWORK
                OfflineTransitCanvasView()
                    .ignoresSafeArea()
            }

            // LAYER 2: TOP HEADER WITH CLEAN MODE TOGGLE (NO OVERLAPPING HEADERS)
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("City Navigation")
                            .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                            .tracking(1.2)
                            .foregroundStyle(WayPointTheme.sapphireAccent)

                        Text(tripStore.currentTrip?.destination ?? tripStore.activeTrip.destination)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    Picker("Mode", selection: $viewMode) {
                        Text("🗺️ Map").tag(MapViewMode.cityMap)
                        Text("🚇 Transit").tag(MapViewMode.transitRadar)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 170)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                .padding(.horizontal, 16)
                .padding(.top, 10)

                Spacer()
            }

            // LAYER 3: BOTTOM STOP CAROUSEL OVERLAY
            if viewMode == .cityMap && !currentItems.isEmpty {
                VStack {
                    Spacer()

                    TabView(selection: $selectedStopIndex) {
                        ForEach(Array(currentItems.enumerated()), id: \.offset) { index, item in
                            bottomStopCard(item: item, index: index)
                                .tag(index)
                                .padding(.horizontal, 16)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 140)
                    .padding(.bottom, 95)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if let first = currentItems.first {
                updateCamera(for: first)
            }
        }
        .onChange(of: selectedStopIndex) { _, newIndex in
            if currentItems.indices.contains(newIndex) {
                updateCamera(for: currentItems[newIndex])
            }
        }
        .sheet(item: $activeRouteStop) { item in
            InAppRouteSheet(item: item)
        }
    }

    private func bottomStopCard(item: ItineraryItem, index: Int) -> some View {
        GlassCardView(cornerRadius: 18, padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("STOP \(index + 1)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(WayPointTheme.sapphireAccent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(WayPointTheme.sapphireAccent.opacity(0.18), in: Capsule())

                    Text(item.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer()

                    Button(action: { activeRouteStop = item }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            Text("Directions")
                        }
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(WayPointTheme.sapphireAccent, in: Capsule())
                    }
                }

                HStack {
                    Text(item.timeRange)
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                    Spacer()
                    Text(item.formattedCost)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(WayPointTheme.cyanGlow)
                }
            }
        }
    }

    private func updateCamera(for item: ItineraryItem) {
        if let coord = item.coordinate, LocationService.isValidCoordinate(latitude: coord.latitude, longitude: coord.longitude) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                position = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                ))
            }
        }
    }

    private func coordinateForStop(_ title: String, city: String) -> LocationCoordinate {
        let t = title.lowercased()
        if city.lowercased().contains("london") {
            if t.contains("paddington") || t.contains("central station") { return LocationCoordinate(latitude: 51.5154, longitude: -0.1755) }
            if t.contains("hotel") { return LocationCoordinate(latitude: 51.5136, longitude: -0.1365) }
            if t.contains("covent garden") { return LocationCoordinate(latitude: 51.5117, longitude: -0.1232) }
            if t.contains("soho") { return LocationCoordinate(latitude: 51.5126, longitude: -0.1270) }
            if t.contains("museum") { return LocationCoordinate(latitude: 51.5194, longitude: -0.1270) }
            if t.contains("borough") { return LocationCoordinate(latitude: 51.5055, longitude: -0.0910) }
            if t.contains("westminster") { return LocationCoordinate(latitude: 51.5007, longitude: -0.1246) }
            if t.contains("pub") { return LocationCoordinate(latitude: 51.5073, longitude: -0.1945) }
            if t.contains("hyde park") { return LocationCoordinate(latitude: 51.5073, longitude: -0.1696) }
            return LocationCoordinate(latitude: 51.5074, longitude: -0.1278) // Central London
        } else {
            if t.contains("shibuya") { return LocationCoordinate(latitude: 35.6580, longitude: 139.7016) }
            if t.contains("hotel") { return LocationCoordinate(latitude: 35.6653, longitude: 139.7025) }
            if t.contains("shinjuku") { return LocationCoordinate(latitude: 35.6909, longitude: 139.7003) }
            if t.contains("ginza") { return LocationCoordinate(latitude: 35.6719, longitude: 139.7639) }
            if t.contains("tokyo") { return LocationCoordinate(latitude: 35.6812, longitude: 139.7671) }
            return LocationCoordinate(latitude: 35.6762, longitude: 139.6503)
        }
    }
}
