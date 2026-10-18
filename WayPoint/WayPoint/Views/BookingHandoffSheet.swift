//
//  BookingHandoffSheet.swift
//  WayPoint
//
//  Phase 4: Real-World Provider Search Handoff & Confirmation Capture Sheet
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BookingHandoffSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tripStore = TripStore.shared
    @State private var passStore = SecurePassStore.shared

    // Search query default
    @State private var searchQuery: String = ""

    // Booking Capture Form State
    @State private var providerName: String = ""
    @State private var title: String = ""
    @State private var passType: PassType = .hotel
    @State private var confirmationCode: String = ""
    @State private var seatOrRoom: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
    @State private var hasEndDate: Bool = false
    @State private var barcodePayload: String = ""

    // UI Feedback
    @State private var showSavedAlert: Bool = false
    @State private var formErrorMessage: String? = nil

    private var destinationName: String {
        tripStore.currentTrip?.destination ?? "Tokyo"
    }

    var body: some View {
        ZStack {
            WayPointTheme.obsidian
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    searchHandoffSection
                    dividerSection
                    manualCaptureSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            searchQuery = destinationName
        }
        .alert("Reservation & Pass Imported", isPresented: $showSavedAlert) {
            Button("Done") {
                dismiss()
            }
        } message: {
            Text("Your pass has been stored in your offline Pass Vault and added to your Trip Itinerary as a confirmed reservation.")
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
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
            .padding(.bottom, 4)

            HStack(spacing: 6) {
                Image(systemName: "arrow.up.right.square.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WayPointTheme.sapphireAccent)

                Text("REAL-WORLD BOOKINGS")
                    .font(.caption.weight(.bold))
                    .tracking(1.5)
                    .foregroundStyle(WayPointTheme.sapphireAccent)
            }

            Text("Book & Import Passes")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(WayPointTheme.textPrimary)

            Text("Search genuine travel providers or capture confirmation codes to populate your offline Pass Vault.")
                .font(.subheadline)
                .foregroundStyle(WayPointTheme.textSecondary)
        }
    }

    // MARK: - Search Handoff Section

    private var searchHandoffSection: some View {
        GlassCardView(cornerRadius: 20, padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(WayPointTheme.cyanGlow)
                    Text("Search Live Travel Providers")
                        .font(.headline)
                        .foregroundStyle(WayPointTheme.textPrimary)
                }

                Text("Launch verified provider platforms pre-filled for \(destinationName):")
                    .font(.caption)
                    .foregroundStyle(WayPointTheme.textSecondary)

                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        providerButton(
                            title: "Booking.com",
                            subtitle: "Hotels & Stays",
                            icon: "bed.double.fill",
                            color: Color.blue,
                            urlString: "https://www.booking.com/searchresults.html?ss=\(encodedDestination)"
                        )

                        providerButton(
                            title: "Google Hotels",
                            subtitle: "Compare Prices",
                            icon: "building.2.fill",
                            color: Color.red,
                            urlString: "https://www.google.com/travel/hotels?q=\(encodedDestination)"
                        )
                    }

                    HStack(spacing: 10) {
                        providerButton(
                            title: "OpenTable",
                            subtitle: "Dining & Tables",
                            icon: "fork.knife",
                            color: Color.orange,
                            urlString: "https://www.opentable.com/s?term=\(encodedDestination)"
                        )

                        providerButton(
                            title: "Google Maps",
                            subtitle: "Local Discovery",
                            icon: "map.fill",
                            color: Color.green,
                            urlString: "https://www.google.com/maps/search/?api=1&query=\(encodedDestination)"
                        )
                    }
                }
            }
        }
    }

    private var encodedDestination: String {
        destinationName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? destinationName
    }

    private func providerButton(title: String, subtitle: String, icon: String, color: Color, urlString: String) -> some View {
        Button(action: {
            if let url = URL(string: urlString) {
                #if canImport(UIKit)
                UIApplication.shared.open(url)
                #endif
            }
        }) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(WayPointTheme.textPrimary)

                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(WayPointTheme.textTertiary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(WayPointTheme.textTertiary)
            }
            .padding(10)
            .background(WayPointTheme.obsidianElevated, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(WayPointTheme.glassBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Divider

    private var dividerSection: some View {
        HStack {
            Rectangle()
                .fill(WayPointTheme.hairlineStroke)
                .frame(height: 1)

            Text("OR IMPORT CONFIRMATION")
                .font(.caption2.weight(.heavy))
                .tracking(1.5)
                .foregroundStyle(WayPointTheme.textTertiary)
                .layoutPriority(1)

            Rectangle()
                .fill(WayPointTheme.hairlineStroke)
                .frame(height: 1)
        }
    }

    // MARK: - Manual Capture Section

    private var manualCaptureSection: some View {
        GlassCardView(cornerRadius: 20, padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(WayPointTheme.emeraldRecovery)
                    Text("Capture Confirmation Code")
                        .font(.headline)
                        .foregroundStyle(WayPointTheme.textPrimary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    // Category Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PASS CATEGORY")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(WayPointTheme.textTertiary)

                        HStack(spacing: 8) {
                            ForEach(PassType.allCases) { type in
                                Button(action: { passType = type }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: type.iconName)
                                            .font(.caption2)
                                        Text(type.rawValue)
                                            .font(.caption.weight(.semibold))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(
                                        passType == type
                                            ? WayPointTheme.sapphireAccent.opacity(0.2)
                                            : WayPointTheme.obsidianElevated,
                                        in: Capsule()
                                    )
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(
                                                passType == type ? WayPointTheme.sapphireAccent : WayPointTheme.hairlineStroke,
                                                lineWidth: 1
                                            )
                                    )
                                    .foregroundStyle(passType == type ? WayPointTheme.sapphireAccent : WayPointTheme.textSecondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Provider Name
                    customTextField(
                        title: "PROVIDER / CARRIER NAME",
                        placeholder: "e.g. Japan Airlines, Park Hyatt Tokyo, Narisawa",
                        text: $providerName
                    )

                    // Title
                    customTextField(
                        title: "RESERVATION TITLE",
                        placeholder: "e.g. Flight JL005, Grand King Suite, Dinner Table",
                        text: $title
                    )

                    // Confirmation Code
                    customTextField(
                        title: "CONFIRMATION CODE / PNR",
                        placeholder: "e.g. JAL-984210, BK-77491",
                        text: $confirmationCode
                    )

                    // Seat / Room / Table
                    customTextField(
                        title: "SEAT / ROOM / TABLE (OPTIONAL)",
                        placeholder: "e.g. Seat 12A, Room 402, Table for 2",
                        text: $seatOrRoom
                    )

                    // Start Date Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("RESERVATION DATE & TIME")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(WayPointTheme.textTertiary)

                        DatePicker("", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .tint(WayPointTheme.cyanGlow)
                            .background(WayPointTheme.obsidianElevated, in: RoundedRectangle(cornerRadius: 12))
                    }

                    // Barcode Payload (Optional)
                    customTextField(
                        title: "BARCODE / QR PAYLOAD STRING (OPTIONAL)",
                        placeholder: "Leave empty to use Confirmation Code for QR generation",
                        text: $barcodePayload
                    )

                    if let error = formErrorMessage {
                        Text(error)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(WayPointTheme.crimsonAlert)
                    }

                    // Save Button
                    Button(action: savePassAndReservation) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.body.weight(.bold))
                            Text("Save Pass & Confirm Reservation")
                                .font(.subheadline.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [WayPointTheme.sapphireAccent, WayPointTheme.emeraldRecovery],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .shadow(color: WayPointTheme.sapphireAccent.opacity(0.3), radius: 10)
                    }
                    .padding(.top, 8)
                }
            }
        }
    }

    private func customTextField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(WayPointTheme.textTertiary)

            TextField(placeholder, text: text)
                .font(.subheadline)
                .padding(12)
                .background(WayPointTheme.obsidianElevated, in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(WayPointTheme.glassBorder, lineWidth: 1)
                )
                .foregroundStyle(WayPointTheme.textPrimary)
        }
    }

    // MARK: - Save Action

    private func savePassAndReservation() {
        formErrorMessage = nil

        let trimmedProvider = providerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCode = confirmationCode.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedProvider.isEmpty else {
            formErrorMessage = "Please enter a provider or carrier name."
            return
        }

        guard !trimmedTitle.isEmpty else {
            formErrorMessage = "Please enter a title for this reservation."
            return
        }

        guard !trimmedCode.isEmpty else {
            formErrorMessage = "Please enter a confirmation code."
            return
        }

        let activeTripId = tripStore.currentTrip?.id ?? UUID()
        let payload = barcodePayload.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? trimmedCode : barcodePayload.trimmingCharacters(in: .whitespacesAndNewlines)
        let optionalSeat = seatOrRoom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : seatOrRoom.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Create and save TravelPass
        let newPass = TravelPass(
            id: UUID(),
            tripId: activeTripId,
            title: trimmedTitle,
            providerName: trimmedProvider,
            passType: passType,
            confirmationCode: trimmedCode,
            barcodePayload: payload,
            validFrom: startDate,
            validUntil: hasEndDate ? endDate : nil,
            seatOrRoom: optionalSeat
        )
        passStore.savePass(newPass)

        // 2. Create hard reservation stop and insert into TripStore
        let stopType: StopType
        switch passType {
        case .flight: stopType = .flight
        case .transit: stopType = .transit
        case .hotel: stopType = .hotel
        case .activity: stopType = .activity
        case .key: stopType = .hotel
        }

        let newStop = TripStop(
            id: UUID(),
            title: "\(trimmedProvider) - \(trimmedTitle)",
            type: stopType,
            scheduledTime: startDate,
            durationMinutes: 60,
            estimatedCost: 0.0,
            isHardReservation: true,
            bookingReference: trimmedCode,
            notes: optionalSeat
        )

        tripStore.addStop(to: 0, stop: newStop)

        showSavedAlert = true
    }
}
