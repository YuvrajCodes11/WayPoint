//
//  ConnectivityHubView.swift
//  WayPoint
//
//  Phase 4: Global Connectivity, Carrier Unlock & eSIM/Physical SIM Hub
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ConnectivityHubView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tripStore = TripStore.shared

    // Checklist State
    @State private var isUnlocked: Bool = false
    @State private var isSupportSaved: Bool = false
    @State private var isBandVerified: Bool = false
    @State private var isAPNConfigured: Bool = false

    private var destination: String {
        tripStore.currentTrip?.destination ?? "Tokyo, Japan"
    }

    var body: some View {
        ZStack {
            WayPointTheme.obsidian
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    connectivityStatusBanner
                    carrierUnlockChecklistSection
                    esimHandoffSection
                    airportKiosksSection
                    apnGuideSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 60)
            }
        }
        .preferredColorScheme(.dark)
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
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WayPointTheme.cyanGlow)

                Text("GLOBAL CONNECTIVITY HUB")
                    .font(.caption.weight(.bold))
                    .tracking(1.5)
                    .foregroundStyle(WayPointTheme.cyanGlow)
            }

            Text("Cellular & eSIM Handoff")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(WayPointTheme.textPrimary)

            Text("Prepare your iPhone for seamless high-speed mobile data in \(destination).")
                .font(.subheadline)
                .foregroundStyle(WayPointTheme.textSecondary)
        }
    }

    // MARK: - Status Banner

    private var connectivityStatusBanner: some View {
        GlassCardView(cornerRadius: 18, padding: 16, glowColor: allChecked ? WayPointTheme.emeraldRecovery : WayPointTheme.imperialGold) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill((allChecked ? WayPointTheme.emeraldRecovery : WayPointTheme.imperialGold).opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: allChecked ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .font(.title3)
                        .foregroundStyle(allChecked ? WayPointTheme.emeraldRecovery : WayPointTheme.imperialGold)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(allChecked ? "Roaming Ready" : "Pre-Travel Action Required")
                        .font(.headline)
                        .foregroundStyle(WayPointTheme.textPrimary)

                    Text(allChecked ? "All carrier unlock & roaming steps are complete." : "Complete the checklist below before boarding your flight.")
                        .font(.caption)
                        .foregroundStyle(WayPointTheme.textSecondary)
                }
            }
        }
    }

    private var allChecked: Bool {
        isUnlocked && isSupportSaved && isBandVerified && isAPNConfigured
    }

    // MARK: - Carrier Unlock Checklist

    private var carrierUnlockChecklistSection: some View {
        GlassCardView(cornerRadius: 20, padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "checklist")
                        .foregroundStyle(WayPointTheme.sapphireAccent)
                    Text("Pre-Departure Checklist")
                        .font(.headline)
                        .foregroundStyle(WayPointTheme.textPrimary)
                }

                VStack(spacing: 12) {
                    checklistRow(
                        title: "Request Carrier Unlock",
                        description: "Contact your primary carrier 48h prior to unlock SIM restrictions for international eSIMs.",
                        isChecked: $isUnlocked
                    )

                    checklistRow(
                        title: "Save Carrier Support Line Offline",
                        description: "Save international roaming customer service phone numbers in phone contacts.",
                        isChecked: $isSupportSaved
                    )

                    checklistRow(
                        title: "Verify Network Band Compatibility",
                        description: "Ensure device supports 5G NR/LTE Bands 1, 3, 8, 19, 28, 41 used in \(destination).",
                        isChecked: $isBandVerified
                    )

                    checklistRow(
                        title: "Enable Data Roaming Toggle",
                        description: "Go to Settings > Cellular > Data Roaming and toggle ON for seamless overseas connection.",
                        isChecked: $isAPNConfigured
                    )
                }
            }
        }
    }

    private func checklistRow(title: String, description: String, isChecked: Binding<Bool>) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isChecked.wrappedValue.toggle()
            }
        }) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isChecked.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isChecked.wrappedValue ? WayPointTheme.emeraldRecovery : WayPointTheme.textTertiary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(WayPointTheme.textPrimary)

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(WayPointTheme.textSecondary)
                }

                Spacer()
            }
            .padding(10)
            .background(WayPointTheme.obsidianElevated, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isChecked.wrappedValue ? WayPointTheme.emeraldRecovery.opacity(0.4) : WayPointTheme.glassBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - eSIM Providers Launchers

    private var esimHandoffSection: some View {
        GlassCardView(cornerRadius: 20, padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "simcard.fill")
                        .foregroundStyle(WayPointTheme.cyanGlow)
                    Text("Instant eSIM Data Plans")
                        .font(.headline)
                        .foregroundStyle(WayPointTheme.textPrimary)
                }

                Text("Purchase & install digital eSIM profiles instantly without swapping physical SIM cards:")
                    .font(.caption)
                    .foregroundStyle(WayPointTheme.textSecondary)

                VStack(spacing: 10) {
                    esimButton(
                        name: "Airalo",
                        tagline: "World's leading travel eSIM store with 200+ regions.",
                        url: "https://www.airalo.com"
                    )

                    esimButton(
                        name: "Nomad eSIM",
                        tagline: "High-speed 5G data packages with instant iOS QR activation.",
                        url: "https://www.getnomad.app"
                    )

                    esimButton(
                        name: "Ubigi",
                        tagline: "Global cellular network partner with prepaid data passes.",
                        url: "https://cellulardata.ubigi.com"
                    )
                }
            }
        }
    }

    private func esimButton(name: String, tagline: String, url: String) -> some View {
        Button(action: {
            if let link = URL(string: url) {
                #if canImport(UIKit)
                UIApplication.shared.open(link)
                #endif
            }
        }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(WayPointTheme.cyanGlow.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "bolt.horizontal.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(WayPointTheme.cyanGlow)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(WayPointTheme.textPrimary)

                    Text(tagline)
                        .font(.caption2)
                        .foregroundStyle(WayPointTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WayPointTheme.cyanGlow)
            }
            .padding(12)
            .background(WayPointTheme.obsidianElevated, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(WayPointTheme.glassBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Destination Airport Kiosks

    private var airportKiosksSection: some View {
        GlassCardView(cornerRadius: 20, padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "building.2.crop.circle.fill")
                        .foregroundStyle(WayPointTheme.imperialGold)
                    Text("Airport Physical SIM Kiosks")
                        .font(.headline)
                        .foregroundStyle(WayPointTheme.textPrimary)
                }

                Text("If your device is locked or lacks eSIM support, pick up a physical prepaid SIM at airport arrivals:")
                    .font(.caption)
                    .foregroundStyle(WayPointTheme.textSecondary)

                VStack(alignment: .leading, spacing: 12) {
                    kioskCard(
                        airport: "Tokyo Haneda (HND) / Narita (NRT)",
                        location: "Arrivals Hall Counter (NTT Docomo / SoftBank)",
                        hours: "06:00 - 23:00 Daily",
                        notes: "Passport required. Cash (JPY) or Credit Card accepted. Multi-day unlimited data passes available."
                    )

                    kioskCard(
                        airport: "Paris Charles de Gaulle (CDG)",
                        location: "Terminal 2E / 2F Relay & Telecom Counter",
                        hours: "06:00 - 22:00 Daily",
                        notes: "Orange Holiday / SFR Tourist SIM available. Valid across EU member states."
                    )

                    kioskCard(
                        airport: "London Heathrow (LHR)",
                        location: "Terminals 2, 3, 4, 5 Arrivals (EE / Vodafone / 3)",
                        hours: "06:00 - 22:30 Daily",
                        notes: "Contactless payment accepted. Automated SIM vending machines available 24/7."
                    )
                }
            }
        }
    }

    private func kioskCard(airport: String, location: String, hours: String, notes: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(airport)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(WayPointTheme.imperialGold)

            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(WayPointTheme.textTertiary)
                Text(location)
                    .font(.caption)
                    .foregroundStyle(WayPointTheme.textPrimary)
            }

            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .font(.caption2)
                    .foregroundStyle(WayPointTheme.textTertiary)
                Text(hours)
                    .font(.caption2)
                    .foregroundStyle(WayPointTheme.textSecondary)
            }

            Text(notes)
                .font(.caption2)
                .foregroundStyle(WayPointTheme.textTertiary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WayPointTheme.obsidianElevated, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(WayPointTheme.glassBorder, lineWidth: 1)
        )
    }

    // MARK: - APN Guide Section

    private var apnGuideSection: some View {
        GlassCardView(cornerRadius: 20, padding: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "gearshape.2.fill")
                        .foregroundStyle(WayPointTheme.emeraldRecovery)
                    Text("iOS Network & APN Configuration")
                        .font(.headline)
                        .foregroundStyle(WayPointTheme.textPrimary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    apnStepRow(number: "1", text: "Open Settings > Cellular > Cellular Data Network.")
                    apnStepRow(number: "2", text: "Under Cellular Data, check if your provider requires a custom APN name (e.g., 'globaldata' or 'mobile').")
                    apnStepRow(number: "3", text: "Restart your iPhone after switching network profiles overseas.")
                }
            }
        }
    }

    private func apnStepRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(WayPointTheme.emeraldRecovery)
                .frame(width: 20, height: 20)
                .background(WayPointTheme.emeraldRecovery.opacity(0.15), in: Circle())

            Text(text)
                .font(.caption)
                .foregroundStyle(WayPointTheme.textSecondary)
        }
    }
}
