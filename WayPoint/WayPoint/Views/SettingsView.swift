//
//  SettingsView.swift
//  WayPoint
//

import SwiftUI

struct SettingsView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(SupabaseService.self) private var supabaseService
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(TripStore.self) private var tripStore

    @State private var showPaywall = false
    @State private var flightAlertsEnabled = true
    @State private var offlineCachingEnabled = true

    var body: some View {
        ZStack {
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
            .scrollContentBackground(.hidden)
        }
        .background(Color.clear)
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

    @State private var showResetConfirmation = false

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

                        Text(supabaseService.currentUserEmail ?? "Guest Traveler")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(WayPointTheme.textPrimary)
                    }

                    Spacer()

                    if tripStore.isSyncing {
                        ProgressView()
                            .tint(WayPointTheme.cyanGlow)
                    } else {
                        Button(action: {
                            Task {
                                await tripStore.retryFailedSync()
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

                if !tripStore.syncQueue.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.2.circlepath")
                            .font(.caption)
                            .foregroundStyle(WayPointTheme.budgetWarning)
                        Text("\(tripStore.syncQueue.count) pending mutations in sync queue")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(WayPointTheme.budgetWarning)
                    }
                }

                if let syncError = tripStore.syncError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.red)
                        Text(syncError)
                            .font(.caption)
                            .foregroundStyle(Color.red)
                    }
                } else if let lastSynced = tripStore.lastSyncedAt {
                    Text("Last synced: \(lastSynced.formatted(date: .abbreviated, time: .shortened)) (Revision v\(tripStore.activeTrip.version))")
                        .font(.caption2)
                        .foregroundStyle(WayPointTheme.textSecondary)
                } else {
                    Text("Device Revision: v\(tripStore.activeTrip.version)")
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

                    Text("Offline Storage & Reset")
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

                Button(action: { showResetConfirmation = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash.fill")
                            .font(.caption.weight(.bold))
                        Text("Reset Local Cache to Demo State")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(Color.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                }
                .alert("Reset Local Data?", isPresented: $showResetConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Reset Data", role: .destructive) {
                        tripStore.resetLocalStoreToSample()
                    }
                } message: {
                    Text("This will clear local trip caches and restore the Tokyo demo itinerary state.")
                }
            }
        }
    }

    @State private var activeLegalDoc: LegalDocumentView.DocumentType? = nil

    private var legalSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button("Privacy Policy") { activeLegalDoc = .privacyPolicy }
                Text("•")
                Button("Terms of Service") { activeLegalDoc = .termsOfService }
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(WayPointTheme.cyanGlow)

            Text("WayPoint v1.0.0 (Build 42) — All Rights Reserved")
                .font(.caption2)
                .foregroundStyle(WayPointTheme.textTertiary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .sheet(item: $activeLegalDoc) { doc in
            LegalDocumentView(documentType: doc)
        }
    }
}

#Preview {
    SettingsView()
        .environment(SubscriptionManager.shared)
        .environment(SupabaseService.shared)
        .environment(NotificationManager.shared)
}
