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
    @Environment(TripStore.self) private var tripStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedFilter: VaultFilter = .all
    @State private var selectedPass: Booking? = nil

    private var filteredBookings: [Booking] {
        let list = tripStore.userBookings.isEmpty ? Booking.samplePasses : tripStore.userBookings
        switch selectedFilter {
        case .all:
            return list
        case .flight:
            return list.filter { $0.type == .flight }
        case .hotel:
            return list.filter { $0.type == .hotel }
        case .activity:
            return list.filter { $0.type == .activity }
        }
    }

    var body: some View {
        ZStack {
            WayPointTheme.oledBackground
                .ignoresSafeArea()
                .accessibilityHidden(true)

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
        .onAppear {
            if tripStore.userBookings.isEmpty {
                tripStore.userBookings = Booking.samplePasses
            }
        }
        .sheet(item: $selectedPass) { pass in
            QRPassModalView(booking: pass)
        }
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
                    Image(systemName: "shield.checkmark.fill")
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
                Text("Offline digital pass vault for flights, hotels, and activities.")
                    .font(.subheadline)
                    .foregroundStyle(WayPointTheme.textSecondary)

                Spacer()
            }
        }
        .padding(.top, 8)
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
                    .accessibilityLabel("Filter by \(filter.title)")
                    .accessibilityHint(selectedFilter == filter ? "Currently active pass filter" : "Double tap to view \(filter.title)")
                    .accessibilityAddTraits(selectedFilter == filter ? [.isSelected, .isButton] : [.isButton])
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
                    .symbolRenderingMode(.hierarchical)
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

                            Image(systemName: booking.type.icon)
                                .font(.caption.weight(.bold))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(WayPointTheme.sapphireAccent)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(booking.provider)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(WayPointTheme.sapphireAccent)

                            Text(booking.formattedDate)
                                .font(.caption2)
                                .foregroundStyle(WayPointTheme.textTertiary)
                        }
                    }

                    Spacer()

                    // Gold Protected Badge Pill
                    HStack(spacing: 3) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 8, weight: .bold))
                            .symbolRenderingMode(.hierarchical)
                        Text("🔒 PROTECTED")
                            .font(.system(size: 8.5, weight: .heavy, design: .monospaced))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(WayPointTheme.imperialGold.opacity(0.18), in: Capsule())
                    .overlay(Capsule().strokeBorder(WayPointTheme.imperialGold.opacity(0.5), lineWidth: 1))
                    .foregroundStyle(WayPointTheme.imperialGold)
                }

                // Title & Subtitle Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(WayPointTheme.textPrimary)
                        .lineLimit(nil)
                        .minimumScaleFactor(0.85)

                    if let seatOrRoom = booking.seatOrRoom {
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

                if let notes = booking.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(WayPointTheme.textTertiary)
                        .lineLimit(2)
                }

                Divider()
                    .overlay(WayPointTheme.hairlineStroke)

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
                                .minimumScaleFactor(0.8)
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
                    .accessibilityLabel("\(booking.title) pass for \(booking.provider)")
                    .accessibilityHint("Double tap to display scannable barcode")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(booking.title) pass for \(booking.provider)")
        .accessibilityHint("Double tap to display scannable barcode")
    }
}


// MARK: - QR Pass Modal Sheet

struct QRPassModalView: View {
    let booking: Booking
    @Environment(\.dismiss) private var dismiss
    @State private var showWalletAlert = false

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

                        // Vector CoreImage QR Code Display
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white)
                                    .frame(height: 180)

                                VStack(spacing: 8) {
                                    if let qrImage = generateVectorQRCode(from: booking.barcodeData ?? booking.confirmationCode) {
                                        Image(uiImage: qrImage)
                                            .resizable()
                                            .interpolation(.none)
                                            .scaledToFit()
                                            .frame(width: 130, height: 130)
                                    } else {
                                        Image(systemName: "qrcode")
                                            .resizable()
                                            .interpolation(.none)
                                            .scaledToFit()
                                            .frame(width: 120, height: 120)
                                            .foregroundColor(.black)
                                    }

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
        .alert("Apple Wallet Integration Notice", isPresented: $showWalletAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Apple Wallet PKPass creation requires signed Pass Type Certificates (.pkpass) configured with active Apple Developer Pass Type IDs.")
        }
    }

    /// Generates a vector 2D QR Code image using CIFilter.qrCodeGenerator
    func generateVectorQRCode(from string: String) -> UIImage? {
        #if canImport(UIKit)
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let ciImage = filter.outputImage else { return nil }

        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledCIImage = ciImage.transformed(by: transform)

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledCIImage, from: scaledCIImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
        #else
        return nil
        #endif
    }
}
