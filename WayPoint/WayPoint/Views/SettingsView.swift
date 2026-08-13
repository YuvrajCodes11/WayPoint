//
//  SettingsView.swift
//  WayPoint
//

import SwiftUI

struct SettingsView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(SupabaseService.self) private var supabaseService
    @Environment(NotificationManager.self) private var notificationManager

    @State private var showPaywall = false
    @State private var flightAlertsEnabled = true
    @State private var offlineCachingEnabled = true

    var body: some View {
        ZStack {
            WayPointTheme.obsidian.opacity(0.72)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    accountSyncSection
                    subscriptionSection
                    notificationSection
                    offlineSection
                    legalSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("PREFERENCES & SYSTEM")
                .font(.caption.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(WayPointTheme.cyanGlow)

            Text("Settings")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(WayPointTheme.textPrimary)
        }
        .padding(.top, 8)
    }

    // MARK: - Account Sync Section

    private var accountSyncSection: some View {
        GlassCardView(cornerRadius: 20, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "icloud.fill")
                        .font(.headline)
                        .foregroundStyle(WayPointTheme.cyanGlow)

                    Text("Cloud Sync & Account")
                        .font(.headline)
                        .foregroundStyle(WayPointTheme.textPrimary)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Logged in as")
                            .font(.caption)
                            .foregroundStyle(WayPointTheme.textTertiary)

                        Text(supabaseService.currentUserEmail ?? "Not signed in")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(WayPointTheme.textPrimary)
                    }

                    Spacer()

                    if supabaseService.isSyncing {
                        ProgressView()
                            .tint(WayPointTheme.cyanGlow)
                    } else {
                        Button(action: {
                            Task {
                                await supabaseService.syncOfflineChanges()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.caption.weight(.bold))
                                Text("Sync Now")
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundStyle(WayPointTheme.cyanGlow)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(WayPointTheme.obsidianSurface, in: Capsule())
                        }
                    }
                }

                if let lastSynced = supabaseService.lastSyncedAt {
                    Text("Last synced: \(lastSynced.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(WayPointTheme.textSecondary)
                }
            }
        }
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        GlassCardView(
            cornerRadius: 20,
            padding: 18,
            glowColor: subscriptionManager.isProMember ? WayPointTheme.violetGlow : WayPointTheme.cyanGlow
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.headline)
                            .foregroundStyle(WayPointTheme.cyanGlow)

                        Text("WayPoint Membership")
                            .font(.headline)
                            .foregroundStyle(WayPointTheme.textPrimary)
                    }

                    Spacer()

                    Text(subscriptionManager.isProMember ? "PRO ACTIVE" : "FREE PLAN")
                        .font(.caption2.weight(.heavy))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            subscriptionManager.isProMember
                                ? WayPointTheme.accentGradient
                                : LinearGradient(colors: [WayPointTheme.obsidianSurface], startPoint: .leading, endPoint: .trailing),
                            in: Capsule()
                        )
                        .foregroundStyle(subscriptionManager.isProMember ? .black : WayPointTheme.textSecondary)
                }

                Text(
                    subscriptionManager.isProMember
                        ? "Unlimited AI itinerary recalculations, offline maps, and flight alerts unlocked."
                        : "Upgrade to WayPoint Pro to unlock unlimited real-time AI re-balancing."
                )
                .font(.caption)
                .foregroundStyle(WayPointTheme.textSecondary)

                if !subscriptionManager.isProMember {
                    Button(action: { showPaywall = true }) {
                        HStack(spacing: 6) {
                            Text("Upgrade to Pro")
                                .font(.subheadline.weight(.bold))
                            Image(systemName: "arrow.right")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(WayPointTheme.accentGradient)
                        .cornerRadius(14)
                    }
                }
            }
        }
    }

    // MARK: - Notifications Section

    private var notificationSection: some View {
        GlassCardView(cornerRadius: 20, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "bell.fill")
                        .font(.headline)
                        .foregroundStyle(WayPointTheme.cyanGlow)

                    Text("Smart Notifications")
                        .font(.headline)
                        .foregroundStyle(WayPointTheme.textPrimary)
                }

                Toggle(isOn: $flightAlertsEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Flight & Gate Alerts")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(WayPointTheme.textPrimary)

                        Text("Lockscreen alerts for delays, gate changes, and departure updates.")
                            .font(.caption)
                            .foregroundStyle(WayPointTheme.textSecondary)
                    }
                }
                .tint(WayPointTheme.cyanGlow)
                .onChange(of: flightAlertsEnabled) { _, newValue in
                    if newValue {
                        Task {
                            _ = await notificationManager.requestAuthorization()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Offline Caching Section

    private var offlineSection: some View {
        GlassCardView(cornerRadius: 20, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "externaldrive.fill")
                        .font(.headline)
                        .foregroundStyle(WayPointTheme.cyanGlow)

                    Text("Offline Storage")
                        .font(.headline)
                        .foregroundStyle(WayPointTheme.textPrimary)
                }

                Toggle(isOn: $offlineCachingEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Offline Map Caching")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(WayPointTheme.textPrimary)

                        Text("Pre-load trip maps and passes for offline access without roaming data.")
                            .font(.caption)
                            .foregroundStyle(WayPointTheme.textSecondary)
                    }
                }
                .tint(WayPointTheme.cyanGlow)
            }
        }
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button("Privacy Policy") {}
                Text("•")
                Button("Terms of Service") {}
                Text("•")
                Button("Licenses") {}
            }
            .font(.caption)
            .foregroundStyle(WayPointTheme.textTertiary)

            Text("WayPoint v1.0.0 (Build 42)")
                .font(.caption2)
                .foregroundStyle(WayPointTheme.textTertiary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}

#Preview {
    SettingsView()
        .environment(SubscriptionManager.shared)
        .environment(SupabaseService.shared)
        .environment(NotificationManager.shared)
}
