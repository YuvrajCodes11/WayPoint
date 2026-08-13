//
//  BookingVaultView.swift
//  WayPoint
//

import SwiftUI

enum VaultFilter: String, CaseIterable, Identifiable {
    case all
    case flight
    case hotel
    case activity

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All Passes"
        case .flight: "Flights"
        case .hotel: "Hotels"
        case .activity: "Activities"
        }
    }
}

struct BookingVaultView: View {
    @State private var bookings: [Booking] = []
    @State private var selectedFilter: VaultFilter = .all
    @State private var selectedPass: Booking? = nil

    private var filteredBookings: [Booking] {
        switch selectedFilter {
        case .all:
            return bookings
        case .flight:
            return bookings.filter { $0.type == .flight }
        case .hotel:
            return bookings.filter { $0.type == .hotel }
        case .activity:
            return bookings.filter { $0.type == .activity }
        }
    }

    var body: some View {
        ZStack {
            WayPointTheme.obsidian.opacity(0.72)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    filterSegmentPicker
                    bookingCardsList
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(item: $selectedPass) { pass in
            QRPassModalView(booking: pass)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "ticket.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WayPointTheme.cyanGlow)

                Text("DIGITAL PASS VAULT")
                    .font(.caption.weight(.bold))
                    .tracking(1.5)
                    .foregroundStyle(WayPointTheme.cyanGlow)
            }

            Text("Bookings & Passes")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(WayPointTheme.textPrimary)

            Text("Store boarding passes, hotel vouchers, and activity tickets.")
                .font(.subheadline)
                .foregroundStyle(WayPointTheme.textSecondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Filter Segment Picker

    private var filterSegmentPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(VaultFilter.allCases) { filter in
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedFilter = filter
                        }
                    }) {
                        Text(filter.title)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                selectedFilter == filter
                                    ? WayPointTheme.cyanGlow.opacity(0.2)
                                    : WayPointTheme.obsidianElevated,
                                in: Capsule()
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        selectedFilter == filter
                                            ? WayPointTheme.cyanGlow
                                            : WayPointTheme.glassBorder,
                                        lineWidth: 1
                                    )
                            )
                            .foregroundStyle(
                                selectedFilter == filter
                                    ? WayPointTheme.cyanGlow
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
            if filteredBookings.isEmpty {
                emptyStateCard
            } else {
                ForEach(filteredBookings) { booking in
                    BookingCardView(booking: booking) {
                        selectedPass = booking
                    }
                }
            }
        }
    }

    private var emptyStateCard: some View {
        GlassCardView(cornerRadius: 20, padding: 24) {
            VStack(spacing: 12) {
                Image(systemName: "tray.fill")
                    .font(.largeTitle)
                    .foregroundStyle(WayPointTheme.textTertiary)

                Text("No Passes Found")
                    .font(.headline)
                    .foregroundStyle(WayPointTheme.textPrimary)

                Text("No digital passes available under \(selectedFilter.title).")
                    .font(.caption)
                    .foregroundStyle(WayPointTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Booking Card View

private struct BookingCardView: View {
    let booking: Booking
    let onShowPass: () -> Void

    var body: some View {
        GlassCardView(
            cornerRadius: 20,
            padding: 18,
            glowColor: WayPointTheme.cyanGlow
        ) {
            VStack(alignment: .leading, spacing: 14) {
                // Top Header Row
                HStack(alignment: .top) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(WayPointTheme.cyanGlow.opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: booking.type.icon)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(WayPointTheme.cyanGlow)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(booking.provider)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(WayPointTheme.cyanGlow)

                            Text(booking.formattedDate)
                                .font(.caption2)
                                .foregroundStyle(WayPointTheme.textTertiary)
                        }
                    }

                    Spacer()

                    Text(booking.confirmationCode)
                        .font(.caption.weight(.bold))
                        .fontDesign(.monospaced)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(WayPointTheme.obsidianSurface, in: Capsule())
                        .foregroundStyle(WayPointTheme.textPrimary)
                }

                // Title & Subtitle Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(WayPointTheme.textPrimary)

                    if let seatOrRoom = booking.seatOrRoom {
                        HStack(spacing: 6) {
                            Image(systemName: "tag.fill")
                                .font(.caption2)
                                .foregroundStyle(WayPointTheme.violetGlow)

                            Text(seatOrRoom)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(WayPointTheme.textSecondary)
                        }
                    }
                }

                if let notes = booking.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(WayPointTheme.textTertiary)
                        .lineLimit(1)
                }

                Divider()
                    .overlay(WayPointTheme.glassBorder)

                // Action Bar
                HStack {
                    if let location = booking.location {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.caption2)
                                .foregroundStyle(WayPointTheme.textTertiary)

                            Text(location)
                                .font(.caption)
                                .foregroundStyle(WayPointTheme.textSecondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Button(action: onShowPass) {
                        HStack(spacing: 6) {
                            Image(systemName: "qrcode")
                                .font(.caption.weight(.bold))

                            Text("Show QR Pass")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(WayPointTheme.accentGradient, in: Capsule())
                        .shadow(color: WayPointTheme.cyanGlow.opacity(0.25), radius: 8)
                    }
                }
            }
        }
    }
}

// MARK: - QR Pass Modal Sheet

struct QRPassModalView: View {
    let booking: Booking
    @Environment(\.dismiss) private var dismiss

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
                                Text(booking.provider.uppercased())
                                    .font(.caption.weight(.bold))
                                    .tracking(1.5)
                                    .foregroundStyle(WayPointTheme.cyanGlow)

                                Text(booking.title)
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(WayPointTheme.textPrimary)
                            }
                            Spacer()

                            Image(systemName: booking.type.icon)
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

                                Text(booking.confirmationCode)
                                    .font(.subheadline.weight(.bold))
                                    .fontDesign(.monospaced)
                                    .foregroundStyle(WayPointTheme.textPrimary)
                            }
                            Spacer()

                            if let seatOrRoom = booking.seatOrRoom {
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

                        // Simulated QR Barcode Display
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white)
                                    .frame(height: 180)

                                VStack(spacing: 8) {
                                    Image(systemName: "qrcode")
                                        .resizable()
                                        .interpolation(.none)
                                        .scaledToFit()
                                        .frame(width: 120, height: 120)
                                        .foregroundColor(.black)

                                    Text(booking.barcodeData ?? booking.confirmationCode)
                                        .font(.caption2.weight(.bold))
                                        .fontDesign(.monospaced)
                                        .foregroundColor(.black)
                                }
                            }

                            Text("Scan at gate or counter for instant entry")
                                .font(.caption)
                                .foregroundStyle(WayPointTheme.textSecondary)
                        }

                        // Add to Apple Wallet Button
                        Button(action: {}) {
                            HStack(spacing: 8) {
                                Image(systemName: "wallet.pass.fill")
                                    .font(.body.weight(.bold))
                                Text("Add to Apple Wallet")
                                    .font(.subheadline.weight(.bold))
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
    }
}

#Preview {
    BookingVaultView()
}
