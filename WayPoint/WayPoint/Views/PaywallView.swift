//
//  PaywallView.swift
//  WayPoint
//
//  Task 4.1 / WP4: Paywall UI Integration & Lifecycle Management
//

import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var isAnnual = true
    @State private var activeLegalDoc: LegalDocumentView.DocumentType? = nil
    @State private var restoreAlertMessage: String? = nil
    @State private var isRestoring: Bool = false
    @State private var isPurchasing: Bool = false

    private var isProcessing: Bool {
        subscriptionManager.isLoading || isRestoring || isPurchasing
    }

    var body: some View {
        ZStack {
            WayPointTheme.oledBackground
                .ignoresSafeArea()

            // Subtle ambient background glow effects
            Circle()
                .fill(WayPointTheme.sapphireAccent.opacity(0.14))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(x: -110, y: -220)

            Circle()
                .fill(WayPointTheme.emeraldRecovery.opacity(0.14))
                .frame(width: 340, height: 340)
                .blur(radius: 100)
                .offset(x: 130, y: 160)

            VStack(spacing: 20) {
                // Header Bar
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(WayPointTheme.textSecondary)
                    }
                }
                .padding(.horizontal)

                // Title Section
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.caption.weight(.bold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(WayPointTheme.sapphireAccent)

                        Text("WAYPOINT PRO")
                            .font(.caption.weight(.bold))
                            .tracking(2)
                            .foregroundColor(WayPointTheme.sapphireAccent)
                    }

                    Text("Instant Travel Resilience Engine")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(WayPointTheme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Never get stranded by rainstorms, transit cancellations, or flight delays again.")
                        .font(.subheadline)
                        .foregroundColor(WayPointTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                // Features List
                VStack(alignment: .leading, spacing: 14) {
                    FeatureRow(icon: "shield.checkmark.fill", title: "1-Tap Panic Pivot Recovery", subtitle: "Instant schedule re-balance preserving prepaid hotel & dining passes")
                    FeatureRow(icon: "airplane.circle.fill", title: "Live Flight Radar & Alerts", subtitle: "Real-time Dynamic Island lockscreen notifications for gate changes & delays")
                    FeatureRow(icon: "ticket.fill", title: "Offline Digital Pass Vault", subtitle: "Access boarding passes, hotel vouchers & vector QR codes without roaming data")
                }
                .padding(.horizontal, 20)

                // Subscription Plan Selector (Weekly vs. Annual)
                VStack(spacing: 12) {
                    // Annual Plan Card with 7-Day Free Trial
                    Button(action: { isAnnual = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text("Annual Pass")
                                        .font(.headline.weight(.bold))
                                        .foregroundColor(WayPointTheme.textPrimary)

                                    Text("BEST VALUE")
                                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(WayPointTheme.emeraldRecovery, in: Capsule())
                                        .foregroundColor(.white)
                                }

                                Text("$29.99 / year (7-Day Free Trial)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(WayPointTheme.emeraldRecovery)
                            }

                            Spacer()

                            Image(systemName: isAnnual ? "checkmark.circle.fill" : "circle")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(isAnnual ? WayPointTheme.emeraldRecovery : WayPointTheme.textTertiary)
                                .font(.title2)
                        }
                        .padding(16)
                        .background(
                            isAnnual ? WayPointTheme.emeraldRecovery.opacity(0.14) : WayPointTheme.cardSurface,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(
                                    isAnnual ? WayPointTheme.emeraldRecovery : WayPointTheme.hairlineStroke,
                                    lineWidth: 1.5
                                )
                        )
                    }
                    .buttonStyle(.plain)

                    // Weekly Pass Card with 3-Day Free Trial
                    Button(action: { isAnnual = false }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Weekly Pass")
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(WayPointTheme.textPrimary)

                                Text("$2.99 / week (3-Day Free Trial)")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(WayPointTheme.textSecondary)
                            }

                            Spacer()

                            Image(systemName: !isAnnual ? "checkmark.circle.fill" : "circle")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(!isAnnual ? WayPointTheme.sapphireAccent : WayPointTheme.textTertiary)
                                .font(.title2)
                        }
                        .padding(16)
                        .background(
                            !isAnnual ? WayPointTheme.sapphireAccent.opacity(0.14) : WayPointTheme.cardSurface,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(
                                    !isAnnual ? WayPointTheme.sapphireAccent : WayPointTheme.hairlineStroke,
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
                                .tint(.white)
                        } else {
                            Text(isAnnual ? "Start 7-Day Free Trial ($29.99/yr)" : "Start 3-Day Free Trial ($2.99/wk)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))

                            Image(systemName: "arrow.right")
                                .font(.subheadline.weight(.bold))
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [WayPointTheme.sapphireAccent, WayPointTheme.emeraldRecovery],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .shadow(color: WayPointTheme.emeraldRecovery.opacity(0.4), radius: 14, x: 0, y: 6)
                }
                .disabled(isProcessing)
                .padding(.horizontal, 20)

                // App Store Guideline 3.1.2 Disclosure Footer
                VStack(spacing: 8) {
                    Text("Auto-renewable subscription ($2.99/week or $29.99/year). Payment charged to Apple ID upon confirmation. Automatically renews unless cancelled 24 hours prior to current period end.")
                        .font(.caption2)
                        .foregroundStyle(WayPointTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    HStack(spacing: 12) {
                        Button(action: handleRestore) {
                            if isRestoring {
                                ProgressView().scaleEffect(0.7)
                            } else {
                                Text("Restore Purchases")
                            }
                        }
                        Text("•")
                        Button("Terms of Use (EULA)") { activeLegalDoc = .termsOfService }
                        Text("•")
                        Button("Privacy Policy") { activeLegalDoc = .privacyPolicy }
                    }
                    .font(.caption2.weight(.medium))
                    .foregroundColor(WayPointTheme.sapphireAccent)
                }
                .padding(.bottom, 12)
            }
            .padding(.top, 12)
        }
        .preferredColorScheme(.dark)

        .sheet(item: $activeLegalDoc) { doc in
            LegalDocumentView(documentType: doc)
        }
        .alert("Subscription Restore", isPresented: Binding(
            get: { restoreAlertMessage != nil },
            set: { if !$0 { restoreAlertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { restoreAlertMessage = nil }
        } message: {
            Text(restoreAlertMessage ?? "")
        }
        .onChange(of: subscriptionManager.isProUser) { _, isPro in
            if isPro {
                dismiss()
            }
        }
    }

    private func handlePurchase() {
        isPurchasing = true
        Task {
            let success: Bool
            if isAnnual {
                success = await subscriptionManager.purchaseAnnual()
            } else {
                success = await subscriptionManager.purchaseWeekly()
            }
            isPurchasing = false
            if success {
                dismiss()
            }
        }
    }

    private func handleRestore() {
        isRestoring = true
        Task {
            let restored = await subscriptionManager.restorePurchases()
            isRestoring = false
            if restored || subscriptionManager.isProUser {
                restoreAlertMessage = "Purchases restored successfully! Pro features unlocked."
            } else {
                restoreAlertMessage = "No active subscription found for your Apple ID account."
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