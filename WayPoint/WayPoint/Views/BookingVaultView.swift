//
//  BookingVaultView.swift
//  WayPoint
//
//  Task 4.1 / WP7: Digital Pass Vault, Vector QR Generator & Apple Wallet Disclosure
//

import SwiftUI
import CoreImage.CIFilterBuiltins
#if canImport(UIKit)
import UIKit
#endif

enum VaultFilter: String, CaseIterable, Identifiable {
    case all
    case transit
    case flight
    case hotel
    case activity
    case keys

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All Passes"
        case .transit: "Transit"
        case .flight: "Flights"
        case .hotel: "Stay"
        case .activity: "Activities"
        case .keys: "Keys & PINs"
        }
    }
}

struct BookingVaultView: View {
    @State private var tripStore = TripStore.shared
    @State private var passStore = SecurePassStore.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedFilter: VaultFilter = .all
    @State private var selectedPass: TravelPass? = nil
    @State private var searchQuery: String = ""

    @State private var showAddPassSheet: Bool = false
    @State private var showConnectivitySheet: Bool = false
    @State private var toastMessage: String? = nil

    private var displayPasses: [TravelPass] {
        let list = passStore.passes.isEmpty ? samplePasses : passStore.passes
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let filteredByTag: [TravelPass]
        switch selectedFilter {
        case .all:
            filteredByTag = list
        case .flight:
            filteredByTag = list.filter { $0.passType == .flight }
        case .hotel:
            filteredByTag = list.filter { $0.passType == .hotel }
        case .activity:
            filteredByTag = list.filter { $0.passType == .activity }
        case .transit:
            filteredByTag = list.filter { $0.passType == .transit }
        case .keys:
            filteredByTag = list.filter { $0.passType == .key }
        }

        if query.isEmpty { return filteredByTag }
        return filteredByTag.filter { pass in
            pass.title.lowercased().contains(query) ||
            pass.providerName.lowercased().contains(query) ||
            pass.confirmationCode.lowercased().contains(query) ||
            (pass.seatOrRoom?.lowercased().contains(query) ?? false) ||
            (pass.notes?.lowercased().contains(query) ?? false)
        }
    }

    private var samplePasses: [TravelPass] {
        let activeId = tripStore.currentTrip?.id ?? UUID()
        return [
            TravelPass(
                id: UUID(),
                tripId: activeId,
                title: "Suica IC Transit Pass",
                providerName: "JR East / Tokyo Metro",
                passType: .transit,
                confirmationCode: "IC-889420-TYO",
                barcodePayload: "SUICA-889420-PASS",
                validFrom: Date(),
                seatOrRoom: "Balance: ¥5,400"
            ),
            TravelPass(
                id: UUID(),
                tripId: activeId,
                title: "Flight JL005 JFK to NRT",
                providerName: "Japan Airlines",
                passType: .flight,
                confirmationCode: "JAL-984210",
                barcodePayload: "JAL-984210-PASS",
                validFrom: Date(),
                seatOrRoom: "Seat 12A (Business)"
            ),
            TravelPass(
                id: UUID(),
                tripId: activeId,
                title: "Park Hyatt Tokyo 3-Night Stay",
                providerName: "Hyatt Hotels",
                passType: .hotel,
                confirmationCode: "HY-77491A",
                barcodePayload: "HY-77491A-GUEST",
                validFrom: Date(),
                seatOrRoom: "Park Suite 402"
            ),
            TravelPass(
                id: UUID(),
                tripId: activeId,
                title: "Omakase Dining Experience",
                providerName: "Narisawa Tokyo",
                passType: .activity,
                confirmationCode: "NAR-5501",
                barcodePayload: "NAR-5501-RESV",
                validFrom: Date(),
                seatOrRoom: "Table for 2"
            ),
            TravelPass(
                id: UUID(),
                tripId: activeId,
                title: "AirBnB Smart Lock PIN",
                providerName: "Shibuya Loft Residency",
                passType: .key,
                confirmationCode: "KEY-9042#",
                barcodePayload: "KEY-9042#",
                validFrom: Date(),
                seatOrRoom: "Door 3B",
                notes: "Press # after entering 9042"
            )
        ]
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection
                        topActionButtons
                        searchBarInput
                        filterSegmentPicker
                        bookingCardsList
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
                .scrollContentBackground(.hidden)
            }

            // Toast Notification Overlay
            if let toast = toastMessage {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(WayPointTheme.emeraldRecovery)
                        Text(toast)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(WayPointTheme.obsidianElevated, in: Capsule())
                    .overlay(Capsule().strokeBorder(WayPointTheme.emeraldRecovery.opacity(0.4), lineWidth: 1))
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                    .padding(.top, 10)

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(200)
            }
        }
        .background(Color.clear)
        .preferredColorScheme(.dark)
        .sheet(item: $selectedPass) { pass in
            QRPassModalView(pass: pass)
        }
        .sheet(isPresented: $showAddPassSheet) {
            AddPassSheetView { newPass in
                passStore.savePass(newPass)
                showToast("Pass saved to encrypted vault")
            }
        }
        .sheet(isPresented: $showConnectivitySheet) {
            ConnectivityHubView()
        }
    }

    private func showToast(_ message: String) {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            toastMessage = message
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation(.easeInOut(duration: 0.3)) {
                if toastMessage == message {
                    toastMessage = nil
                }
            }
        }
    }

    // MARK: - Search Bar Input

    private var searchBarInput: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(WayPointTheme.sapphireAccent)

            TextField("Search passes, codes, hotels, flights...", text: $searchQuery)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(WayPointTheme.textPrimary)

            if !searchQuery.isEmpty {
                Button(action: { searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(WayPointTheme.textSecondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(WayPointTheme.obsidianElevated, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(WayPointTheme.glassBorder, lineWidth: 1)
        )
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "ticket.fill")
                        .font(.caption.weight(.bold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(WayPointTheme.sapphireAccent)

                    Text("DIGITAL PASS VAULT")
                        .font(.caption.weight(.bold))
                        .tracking(1.5)
                        .foregroundStyle(WayPointTheme.sapphireAccent)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 9, weight: .bold))
                        .symbolRenderingMode(.hierarchical)
                    Text("Secure Local Storage")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(WayPointTheme.emeraldRecovery)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(WayPointTheme.emeraldRecovery.opacity(0.15), in: Capsule())
                .overlay(Capsule().strokeBorder(WayPointTheme.emeraldRecovery.opacity(0.4), lineWidth: 1))
            }

            Text("Bookings & Passes")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(WayPointTheme.textPrimary)

            HStack {
                Text("Offline Passes & Tickets for transit, flights, hotels, and keys.")
                    .font(.subheadline)
                    .foregroundStyle(WayPointTheme.textSecondary)

                Spacer()
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Top Action Buttons

    private var topActionButtons: some View {
        HStack(spacing: 12) {
            Button(action: { showAddPassSheet = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.body.weight(.bold))
                    Text("Add Pass")
                        .font(.subheadline.weight(.bold))
                        .lineLimit(1)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [WayPointTheme.sapphireAccent, WayPointTheme.emeraldRecovery],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .shadow(color: WayPointTheme.sapphireAccent.opacity(0.3), radius: 8)
            }
            .buttonStyle(.plain)

            Button(action: { showConnectivitySheet = true }) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(WayPointTheme.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(WayPointTheme.obsidianElevated, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(WayPointTheme.glassBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Filter Segment Picker

    private var filterSegmentPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(VaultFilter.allCases) { filter in
                    Button(action: {
                        withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedFilter = filter
                        }
                    }) {
                        Text(filter.title)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                selectedFilter == filter
                                    ? WayPointTheme.sapphireAccent.opacity(0.2)
                                    : WayPointTheme.cardSurface,
                                in: Capsule()
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        selectedFilter == filter
                                            ? WayPointTheme.sapphireAccent
                                            : WayPointTheme.hairlineStroke,
                                        lineWidth: 1
                                    )
                            )
                            .foregroundStyle(
                                selectedFilter == filter
                                    ? WayPointTheme.sapphireAccent
                                    : WayPointTheme.textSecondary
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Booking Cards List

    private var bookingCardsList: some View {
        VStack(spacing: 16) {
            if displayPasses.isEmpty {
                emptyStateCard
            } else {
                ForEach(displayPasses) { pass in
                    BookingCardView(pass: pass, onShowPass: {
                        selectedPass = pass
                    }, onCopyCode: { code in
                        #if canImport(UIKit)
                        UIPasteboard.general.string = code
                        #endif
                        showToast("Copied '\(code)' to clipboard")
                    }, onDelete: {
                        passStore.removePass(id: pass.id)
                        showToast("Pass deleted")
                    })
                }
            }
        }
    }

    private var emptyStateCard: some View {
        GlassCardView(cornerRadius: 20, padding: 24) {
            VStack(spacing: 12) {
                Image(systemName: "tray.fill")
                    .font(.largeTitle)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(WayPointTheme.textTertiary)

                Text("No Passes Found")
                    .font(.headline)
                    .foregroundStyle(WayPointTheme.textPrimary)

                Text("No digital passes match filter '\(selectedFilter.title)'. Tap '+ Add Pass' to store tickets, confirmation codes, and PINs.")
                    .font(.caption)
                    .foregroundStyle(WayPointTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Booking Card View

private struct BookingCardView: View {
    let pass: TravelPass
    let onShowPass: () -> Void
    let onCopyCode: (String) -> Void
    let onDelete: () -> Void

    private var formattedDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: pass.validFrom)
    }

    var body: some View {
        GlassCardView(
            cornerRadius: 16,
            padding: 18,
            glowColor: WayPointTheme.sapphireAccent
        ) {
            VStack(alignment: .leading, spacing: 14) {
                // Top Header Row
                HStack(alignment: .top) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(WayPointTheme.sapphireAccent.opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: pass.passType.iconName)
                                .font(.caption.weight(.bold))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(WayPointTheme.sapphireAccent)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(pass.providerName)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(WayPointTheme.sapphireAccent)

                            Text(formattedDateString)
                                .font(.caption2)
                                .foregroundStyle(WayPointTheme.textTertiary)
                        }
                    }

                    Spacer()

                    // Gold Protected Badge Pill
                    Button(action: onDelete) {
                        Image(systemName: "trash.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.red.opacity(0.7))
                            .padding(6)
                    }
                }

                // Title & Subtitle Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(pass.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(WayPointTheme.textPrimary)
                        .lineLimit(nil)
                        .minimumScaleFactor(0.85)

                    if let seatOrRoom = pass.seatOrRoom {
                        HStack(spacing: 6) {
                            Image(systemName: "tag.fill")
                                .font(.caption2)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(WayPointTheme.sapphireAccent)

                            Text(seatOrRoom)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(WayPointTheme.textSecondary)
                        }
                    }
                }

                Divider()
                    .overlay(WayPointTheme.hairlineStroke)

                // Action Bar
                HStack {
                    Button(action: {
                        onCopyCode(pass.confirmationCode)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.on.doc.fill")
                                .font(.caption2)
                                .foregroundStyle(WayPointTheme.sapphireAccent)

                            Text(pass.confirmationCode)
                                .font(.caption.weight(.bold))
                                .fontDesign(.monospaced)
                                .foregroundStyle(WayPointTheme.textPrimary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(WayPointTheme.obsidianSurface, in: RoundedRectangle(cornerRadius: 8))
                    }

                    Spacer()

                    Button(action: onShowPass) {
                        HStack(spacing: 6) {
                            Image(systemName: "qrcode")
                                .font(.caption.weight(.bold))

                            Text("Show Pass")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [WayPointTheme.sapphireAccent, WayPointTheme.emeraldRecovery],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                        .shadow(color: WayPointTheme.sapphireAccent.opacity(0.25), radius: 8)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onShowPass()
        }
    }
}


// MARK: - QR Pass Modal Sheet

struct QRPassModalView: View {
    let pass: TravelPass
    @Environment(\.dismiss) private var dismiss
    @State private var showWalletAlert = false
    @State private var originalBrightness: CGFloat = 0.5

    var body: some View {
        ZStack {
            WayPointTheme.obsidian
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Drag Pill & Dismiss Header
                HStack {
                    Capsule()
                        .fill(WayPointTheme.glassBorder)
                        .frame(width: 36, height: 5)
                }
                .frame(maxWidth: .infinity)
                .overlay(alignment: .trailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(WayPointTheme.textSecondary)
                    }
                }

                // Pass Card
                GlassCardView(
                    cornerRadius: 24,
                    padding: 24,
                    glowColor: WayPointTheme.cyanGlow
                ) {
                    VStack(spacing: 20) {
                        // Pass Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(pass.providerName.uppercased())
                                    .font(.caption.weight(.bold))
                                    .tracking(1.5)
                                    .foregroundStyle(WayPointTheme.cyanGlow)

                                Text(pass.title)
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(WayPointTheme.textPrimary)
                            }
                            Spacer()

                            Image(systemName: pass.passType.iconName)
                                .font(.title2)
                                .foregroundStyle(WayPointTheme.cyanGlow)
                        }

                        Divider().overlay(WayPointTheme.glassBorder)

                        // Confirmation Details Grid
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("CONFIRMATION")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(WayPointTheme.textTertiary)

                                Text(pass.confirmationCode)
                                    .font(.subheadline.weight(.bold))
                                    .fontDesign(.monospaced)
                                    .foregroundStyle(WayPointTheme.textPrimary)
                            }
                            Spacer()

                            if let seatOrRoom = pass.seatOrRoom {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("SEAT / ROOM")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(WayPointTheme.textTertiary)

                                    Text(seatOrRoom)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(WayPointTheme.violetGlow)
                                }
                            }
                        }

                        // Vector CoreImage Barcode / QR Code Display
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white)
                                    .frame(height: 180)

                                VStack(spacing: 8) {
                                    if let qrImage = PassBarcodeGenerator.generateQRCode(from: pass.barcodePayload) {
                                        Image(uiImage: qrImage)
                                            .resizable()
                                            .interpolation(.none)
                                            .scaledToFit()
                                            .frame(width: 130, height: 130)
                                    } else if let code128 = PassBarcodeGenerator.generateCode128Barcode(from: pass.barcodePayload) {
                                        Image(uiImage: code128)
                                            .resizable()
                                            .interpolation(.none)
                                            .scaledToFit()
                                            .frame(width: 200, height: 100)
                                    } else {
                                        Image(systemName: "qrcode")
                                            .resizable()
                                            .interpolation(.none)
                                            .scaledToFit()
                                            .frame(width: 120, height: 120)
                                            .foregroundColor(.black)
                                    }

                                    Text(pass.barcodePayload)
                                        .font(.caption2.weight(.bold))
                                        .fontDesign(.monospaced)
                                        .foregroundColor(.black)
                                }
                            }

                            HStack(spacing: 4) {
                                Image(systemName: "sun.max.fill")
                                    .font(.caption2)
                                    .foregroundStyle(WayPointTheme.imperialGold)

                                Text("Screen brightness boosted for high-contrast optical scanner entry")
                                    .font(.caption2)
                                    .foregroundStyle(WayPointTheme.textSecondary)
                            }
                        }

                        // Add to Apple Wallet Button
                        Button(action: { showWalletAlert = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "wallet.pass.fill")
                                    .font(.body.weight(.bold))
                                Text("Add to Apple Wallet")
                                    .font(.subheadline.weight(.bold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.black, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(WayPointTheme.glassBorder, lineWidth: 1)
                            )
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            #if canImport(UIKit)
            originalBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1.0
            #endif
        }
        .onDisappear {
            #if canImport(UIKit)
            UIScreen.main.brightness = originalBrightness
            #endif
        }
        .alert("Apple Wallet Integration Notice", isPresented: $showWalletAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Apple Wallet PKPass creation requires signed Pass Type Certificates (.pkpass) configured with active Apple Developer Pass Type IDs.")
        }
    }
}

// MARK: - Add Pass Sheet View

struct AddPassSheetView: View {
    let onSave: (TravelPass) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var passType: PassType = .flight
    @State private var name: String = ""
    @State private var codeOrPin: String = ""
    @State private var validFrom: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Pass Details") {
                    Picker("Category", selection: $passType) {
                        Text("Flight ✈️").tag(PassType.flight)
                        Text("Train 🚆").tag(PassType.transit)
                        Text("Stay 🏨").tag(PassType.hotel)
                        Text("Activity 🎟️").tag(PassType.activity)
                        Text("Keys 🔑").tag(PassType.key)
                    }
                    .pickerStyle(.menu)

                    TextField("Name (e.g. British Airways BA117, Suica Card)", text: $name)

                    TextField("Code / PIN (e.g. BA-984210, 4092#)", text: $codeOrPin)

                    DatePicker("Valid Date", selection: $validFrom, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                }
            }
            .navigationTitle("Add Travel Pass")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedCode = codeOrPin.trimmingCharacters(in: .whitespacesAndNewlines)
                        let newPass = TravelPass(
                            tripId: TripStore.shared.currentTrip?.id ?? UUID(),
                            title: trimmedName.isEmpty ? passType.displayName : trimmedName,
                            providerName: passType.displayName,
                            passType: passType,
                            confirmationCode: trimmedCode.isEmpty ? "CONF-PASS" : trimmedCode,
                            barcodePayload: trimmedCode.isEmpty ? "CONF-PASS" : trimmedCode,
                            validFrom: validFrom
                        )
                        onSave(newPass)
                        dismiss()
                    }
                    .bold()
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || codeOrPin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

