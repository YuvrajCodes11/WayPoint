//
//  PaywallView.swift
//  WayPoint
//

import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var isAnnual = true

    private var isProcessing: Bool {
        subscriptionManager.isLoading
    }

    var body: some View {
        ZStack {
            WayPointTheme.obsidian
                .ignoresSafeArea()

            // Subtle background glow effects
            Circle()
                .fill(WayPointTheme.cyanGlow.opacity(0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -100, y: -200)

            Circle()
                .fill(WayPointTheme.violetGlow.opacity(0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(x: 120, y: 150)

            VStack(spacing: 24) {
                // Header Bar
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(WayPointTheme.textSecondary)
                    }
                }
                .padding(.horizontal)

                // Title Section
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption.weight(.bold))
                            .foregroundColor(WayPointTheme.cyanGlow)

                        Text("WAYPOINT PRO")
                            .font(.caption.weight(.bold))
                            .tracking(2)
                            .foregroundColor(WayPointTheme.cyanGlow)
                    }

                    Text("Unlock Your Travel Co-Pilot")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(WayPointTheme.textPrimary)

                    Text("Real-time AI itinerary re-balancing, live flight tracking, and offline digital passes.")
                        .font(.subheadline)
                        .foregroundColor(WayPointTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                // Features List
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "sparkles", title: "Unlimited AI Re-balancing", subtitle: "Instant schedule adjustments for weather & flight delays")
                    FeatureRow(icon: "airplane.circle.fill", title: "Flight Radar & Gate Alerts", subtitle: "Live lockscreen notifications for gate changes & delays")
                    FeatureRow(icon: "ticket.fill", title: "Offline Pass Vault", subtitle: "Access flight passes, QR tickets & maps without roaming data")
                }
                .padding(.horizontal, 20)

                // Subscription Plan Selector (Monthly vs. Annual)
                VStack(spacing: 12) {
                    // Annual Plan Card with 50% SAVINGS Badge
                    Button(action: { isAnnual = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text("Annual Pass")
                                        .font(.headline.weight(.bold))
                                        .foregroundColor(WayPointTheme.textPrimary)

                                    Text("SAVE 50%")
                                        .font(.caption2.weight(.heavy))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(WayPointTheme.cyanGlow, in: Capsule())
                                        .foregroundColor(.black)
                                }

                                Text("$59.99 / year ($4.99/mo)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(WayPointTheme.cyanGlow)
                            }

                            Spacer()

                            Image(systemName: isAnnual ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isAnnual ? WayPointTheme.cyanGlow : WayPointTheme.textTertiary)
                                .font(.title2)
                        }
                        .padding(16)
                        .background(
                            isAnnual ? WayPointTheme.cyanGlow.opacity(0.15) : WayPointTheme.obsidianElevated,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(
                                    isAnnual ? WayPointTheme.cyanGlow : WayPointTheme.glassBorder,
                                    lineWidth: 1.5
                                )
                        )
                    }
                    .buttonStyle(.plain)

                    // Monthly Plan Card
                    Button(action: { isAnnual = false }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Monthly Pass")
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(WayPointTheme.textPrimary)

                                Text("$9.99 / month")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(WayPointTheme.textSecondary)
                            }

                            Spacer()

                            Image(systemName: !isAnnual ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(!isAnnual ? WayPointTheme.cyanGlow : WayPointTheme.textTertiary)
                                .font(.title2)
                        }
                        .padding(16)
                        .background(
                            !isAnnual ? WayPointTheme.cyanGlow.opacity(0.15) : WayPointTheme.obsidianElevated,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(
                                    !isAnnual ? WayPointTheme.cyanGlow : WayPointTheme.glassBorder,
                                    lineWidth: 1.5
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)

                Spacer()

                // CTA Purchase Button
                Button(action: handlePurchase) {
                    HStack(spacing: 8) {
                        if isProcessing {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text(isAnnual ? "Start 7-Day Free Trial" : "Subscribe Now")
                                .font(.headline.weight(.bold))

                            Image(systemName: "arrow.right")
                                .font(.subheadline.weight(.bold))
                        }
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(WayPointTheme.accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: WayPointTheme.cyanGlow.opacity(0.4), radius: 14, x: 0, y: 6)
                }
                .disabled(isProcessing)
                .padding(.horizontal, 20)

                // Legal & Restore Links
                HStack(spacing: 12) {
                    Button("Restore Purchases", action: handleRestore)
                    Text("•")
                    Button("Terms of Service") {}
                    Text("•")
                    Button("Privacy Policy") {}
                }
                .font(.caption2)
                .foregroundColor(WayPointTheme.textTertiary)
                .padding(.bottom, 12)
            }
            .padding(.top, 12)
        }
        .preferredColorScheme(.dark)
    }

    private func handlePurchase() {
        Task {
            if let package = selectedPackage() {
                let success = await subscriptionManager.purchase(package: package)
                if success {
                    dismiss()
                }
            } else {
                await subscriptionManager.fetchOfferings()
                if let package = selectedPackage() {
                    let success = await subscriptionManager.purchase(package: package)
                    if success {
                        dismiss()
                    }
                }
            }
        }
    }

    private func selectedPackage() -> Package? {
        guard let offering = subscriptionManager.currentOffering else { return nil }
        return isAnnual ? offering.annual : offering.monthly
    }

    private func handleRestore() {
        Task {
            await subscriptionManager.restorePurchases()
            if subscriptionManager.isProUser {
                dismiss()
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(WayPointTheme.cyanGlow.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(WayPointTheme.cyanGlow)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(WayPointTheme.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(WayPointTheme.textSecondary)
            }
        }
    }
}

#Preview {
    PaywallView()
        .environment(SubscriptionManager.shared)
}