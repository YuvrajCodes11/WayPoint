//
//  WayPointPaywallView.swift
//  WayPoint
//
//  Module 3: RevenueCat & StoreKit Production Native Paywall View
//

import SwiftUI
import RevenueCat
import RevenueCatUI

struct WayPointPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @State private var selectedProductID: String = WayPointProductIdentifier.annualPro
    @State private var activeLegalDoc: LegalDocumentView.DocumentType? = nil
    @State private var statusMessage: String? = nil
    @State private var isPurchasing: Bool = false
    @State private var isRestoring: Bool = false

    private var isProcessing: Bool {
        subscriptionManager.isLoading || isPurchasing || isRestoring
    }

    private var currentOffering: Offering? {
        subscriptionManager.offerings?.current
    }

    private var selectedPackage: Package? {
        currentOffering?.availablePackages.first(where: { $0.storeProduct.productIdentifier == selectedProductID })
    }

    var body: some View {
        ZStack {
            WayPointTheme.obsidian
                .ignoresSafeArea()

            // Ambient Background Lighting
            Circle()
                .fill(WayPointTheme.sapphireAccent.opacity(0.15))
                .frame(width: 340, height: 340)
                .blur(radius: 90)
                .offset(x: -120, y: -220)

            Circle()
                .fill(WayPointTheme.emeraldRecovery.opacity(0.12))
                .frame(width: 360, height: 360)
                .blur(radius: 100)
                .offset(x: 140, y: 200)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header Bar
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(WayPointTheme.textSecondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Hero Title
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(WayPointTheme.cyanGlow)

                            Text("WAYPOINT PRO")
                                .font(.caption.weight(.bold))
                                .tracking(2)
                                .foregroundStyle(WayPointTheme.cyanGlow)
                        }

                        Text("Instant Travel Resilience Engine")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(WayPointTheme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Never get stranded by weather, transit cancellations, or flight delays again.")
                            .font(.subheadline)
                            .foregroundStyle(WayPointTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    // Feature Bullets
                    VStack(alignment: .leading, spacing: 14) {
                        paywallFeatureRow(
                            icon: "checkmark.shield.fill",
                            title: "1-Tap Schedule Reroute Recovery",
                            subtitle: "Instant schedule re-balance preserving hard reservations."
                        )
                        paywallFeatureRow(
                            icon: "airplane.circle.fill",
                            title: "Live Flight Radar & Alerts",
                            subtitle: "Real-time gate changes & delay tracking on Dynamic Island."
                        )
                        paywallFeatureRow(
                            icon: "key.fill",
                            title: "Hardware-Encrypted Pass Vault",
                            subtitle: "Offline passes & scannable QR codes secured in iOS Keychain."
                        )
                        paywallFeatureRow(
                            icon: "antenna.radiowaves.left.and.right",
                            title: "Global Cellular & eSIM Hub",
                            subtitle: "Airport kiosk maps, carrier unlock guides, and roaming APN setups."
                        )
                    }
                    .padding(.horizontal, 20)

                    // Tier Selection Cards
                    VStack(spacing: 12) {
                        tierCard(
                            id: WayPointProductIdentifier.annualPro,
                            title: "Annual Pro Pass",
                            badge: "SAVE 40%",
                            priceText: annualDisplayPrice,
                            subtitle: "Includes 14-Day Free Trial",
                            isBestValue: true
                        )

                        tierCard(
                            id: WayPointProductIdentifier.monthlyPro,
                            title: "Monthly Pro Pass",
                            badge: nil,
                            priceText: monthlyDisplayPrice,
                            subtitle: "Includes 7-Day Free Trial",
                            isBestValue: false
                        )

                        tierCard(
                            id: WayPointProductIdentifier.lifetimePro,
                            title: "Lifetime Unlimited Pass",
                            badge: "ONE-TIME",
                            priceText: lifetimeDisplayPrice,
                            subtitle: "Pay once, own forever with zero recurring fees",
                            isBestValue: false
                        )
                    }
                    .padding(.horizontal, 20)

                    if let status = statusMessage {
                        Text(status)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(WayPointTheme.cyanGlow)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    // CTA Button
                    Button(action: executePurchase) {
                        HStack(spacing: 8) {
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.body.weight(.bold))
                                Text("Subscribe & Unlock WayPoint Pro")
                                    .font(.headline.weight(.bold))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [WayPointTheme.sapphireAccent, WayPointTheme.emeraldRecovery],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .shadow(color: WayPointTheme.sapphireAccent.opacity(0.35), radius: 12)
                    }
                    .disabled(isProcessing)
                    .padding(.horizontal, 20)

                    // Restore & Legal Footer
                    VStack(spacing: 12) {
                        Button(action: executeRestore) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise.circle")
                                    .font(.caption)
                                Text("Restore Purchases")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(WayPointTheme.textSecondary)
                        }
                        .disabled(isProcessing)

                        HStack(spacing: 16) {
                            Button("Terms of Service") {
                                activeLegalDoc = .termsOfService
                            }
                            Text("•")
                                .foregroundStyle(WayPointTheme.textTertiary)
                            Button("Privacy Policy") {
                                activeLegalDoc = .privacyPolicy
                            }
                        }
                        .font(.caption2)
                        .foregroundStyle(WayPointTheme.textTertiary)
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await subscriptionManager.loadOfferings()
        }
        .sheet(item: $activeLegalDoc) { doc in
            LegalDocumentView(documentType: doc)
        }
    }

    // MARK: - Price Accessors

    private var monthlyDisplayPrice: String {
        if let pkg = currentOffering?.availablePackages.first(where: { $0.storeProduct.productIdentifier == WayPointProductIdentifier.monthlyPro }) {
            return "\(pkg.localizedPriceString) / month"
        }
        return "$2.99 / month"
    }

    private var annualDisplayPrice: String {
        if let pkg = currentOffering?.availablePackages.first(where: { $0.storeProduct.productIdentifier == WayPointProductIdentifier.annualPro }) {
            return "\(pkg.localizedPriceString) / year"
        }
        return "$29.99 / year"
    }

    private var lifetimeDisplayPrice: String {
        if let pkg = currentOffering?.availablePackages.first(where: { $0.storeProduct.productIdentifier == WayPointProductIdentifier.lifetimePro }) {
            return "\(pkg.localizedPriceString) one-time"
        }
        return "$14.99 one-time"
    }

    // MARK: - UI Helpers

    private func paywallFeatureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(WayPointTheme.cyanGlow.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WayPointTheme.cyanGlow)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(WayPointTheme.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(WayPointTheme.textSecondary)
            }

            Spacer()
        }
    }

    private func tierCard(id: String, title: String, badge: String?, priceText: String, subtitle: String, isBestValue: Bool) -> some View {
        let isSelected = selectedProductID == id
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedProductID = id
            }
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(WayPointTheme.textPrimary)

                        if let badgeText = badge {
                            Text(badgeText)
                                .font(.system(size: 9, weight: .heavy))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(isBestValue ? WayPointTheme.imperialGold : WayPointTheme.sapphireAccent, in: Capsule())
                                .foregroundStyle(isBestValue ? Color.black : Color.white)
                        }
                    }

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(WayPointTheme.textSecondary)
                }

                Spacer()

                Text(priceText)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isSelected ? WayPointTheme.cyanGlow : WayPointTheme.textPrimary)
            }
            .padding(16)
            .background(
                isSelected ? WayPointTheme.sapphireAccent.opacity(0.18) : WayPointTheme.obsidianElevated,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? WayPointTheme.cyanGlow : WayPointTheme.glassBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func executePurchase() {
        isPurchasing = true
        statusMessage = "Processing purchase via RevenueCat..."
        Task {
            let success: Bool
            if let pkg = selectedPackage {
                success = await subscriptionManager.purchase(package: pkg)
            } else {
                success = await subscriptionManager.purchaseProduct(id: selectedProductID)
            }
            isPurchasing = false
            if success {
                statusMessage = "Purchase successful! WayPoint Pro active."
                dismiss()
            } else if let errorMsg = subscriptionManager.errorMessage {
                statusMessage = "Purchase: \(errorMsg)"
            } else {
                statusMessage = nil
            }
        }
    }

    private func executeRestore() {
        isRestoring = true
        statusMessage = "Restoring purchases..."
        Task {
            let restored = await subscriptionManager.restorePurchases()
            isRestoring = false
            if restored {
                statusMessage = "Purchases restored! WayPoint Pro active."
                dismiss()
            } else {
                statusMessage = subscriptionManager.errorMessage ?? "No active subscription found to restore."
            }
        }
    }
}
