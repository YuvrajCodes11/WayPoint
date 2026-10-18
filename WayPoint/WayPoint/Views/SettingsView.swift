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
    @State private var showConnectivityHub = false
    @State private var flightAlertsEnabled = true
    @State private var offlineCachingEnabled = true

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    connectivitySection
                    accountSyncSection
                    tripResetSection
                    subscriptionSection
                    notificationSection
                    offlineSection
                    logOutSection
                    legalSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .scrollContentBackground(.hidden)

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
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showConnectivityHub) {
            ConnectivityHubView()
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

    // MARK: - Connectivity Section

    private var connectivitySection: some View {
        GlassCardView(cornerRadius: 20, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.headline)
                            .foregroundStyle(WayPointTheme.cyanGlow)

                        Text("Travel & Cellular Connectivity")
                            .font(.headline)
                            .foregroundStyle(WayPointTheme.textPrimary)
                    }

                    Spacer()

                    Button(action: { showConnectivityHub = true }) {
                        Text("Open Hub")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(WayPointTheme.cyanGlow)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(WayPointTheme.obsidianSurface, in: Capsule())
                            .overlay(Capsule().strokeBorder(WayPointTheme.cyanGlow.opacity(0.4), lineWidth: 1))
                    }
                }

                Text("Manage SIM/eSIM roaming guides, carrier device unlocks, APN settings, and airport kiosk details.")
                    .font(.caption)
                    .foregroundStyle(WayPointTheme.textSecondary)
            }
        }
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

    // MARK: - Dynamic Trip Reset Section (Phase 1)

    private var tripResetSection: some View {
        GlassCardView(cornerRadius: 20, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "trash.circle.fill")
                        .font(.headline)
                        .foregroundStyle(WayPointTheme.crimsonAlert)

                    Text("Current Trip")
                        .font(.headline)
                        .foregroundStyle(WayPointTheme.textPrimary)
                }

                Text("Resetting your current active trip clears saved itinerary data and returns to the Trip Genesis setup flow.")
                    .font(.caption)
                    .foregroundStyle(WayPointTheme.textSecondary)

                Button(action: {
                    showResetConfirmation = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.subheadline.weight(.bold))
                        Text("Reset Current Trip")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(WayPointTheme.crimsonAlert.opacity(0.8))
                    )
                }
            }
        }
        .confirmationDialog("Reset Current Trip?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
            Button("Reset & Restart Setup", role: .destructive) {
                tripStore.clearCurrentTrip()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action clears your dynamic active trip and returns to the setup wizard.")
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

                HStack {
                    if !subscriptionManager.isProMember {
                        Button(action: { showPaywall = true }) {
                            HStack(spacing: 6) {
                                Text("Upgrade to Pro")
                                    .font(.subheadline.weight(.bold))
                                Image(systemName: "arrow.right")
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(WayPointTheme.accentGradient)
                            .cornerRadius(14)
                        }
                    }

                    Spacer()

                    Button(action: {
                        Task {
                            let restored = await subscriptionManager.restorePurchases()
                            if restored {
                                showToast("Purchases successfully restored!")
                            } else {
                                showToast(subscriptionManager.errorMessage ?? "No active subscription found.")
                            }
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption.weight(.bold))
                            Text("Restore Purchases")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(WayPointTheme.textSecondary)
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

    @State private var offlineSimulationMode: Bool = false
    @State private var toastMessage: String? = nil

    private func showToast(_ message: String) {
        Haptics.notification(.success)
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

                Toggle(isOn: $offlineSimulationMode) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Offline Simulation Mode")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(WayPointTheme.textPrimary)

                        Text("Simulates zero-network air-gapped environment.")
                            .font(.caption)
                            .foregroundStyle(WayPointTheme.textSecondary)
                    }
                }
                .tint(WayPointTheme.cyanGlow)
                .onChange(of: offlineSimulationMode) { _, enabled in
                    showToast(enabled ? "Offline Simulation Active" : "Online Mode Restored")
                }

                HStack {
                    Text("Current City")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(WayPointTheme.textPrimary)

                    Spacer()

                    Picker("Current City", selection: Binding(
                        get: { tripStore.activeCity },
                        set: { newCity in
                            withAnimation {
                                tripStore.activeCity = newCity
                            }
                        }
                    )) {
                        ForEach(City.allCases) { city in
                            Text("\(city.flag) \(city.rawValue)").tag(city)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Button(action: {
                    OfflineImageStore.shared.clearDiskCache()
                    showToast("Disk image cache cleared")
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.stack.fill")
                            .font(.caption.weight(.bold))
                        Text("Clear Image Cache")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(WayPointTheme.cyanGlow)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(WayPointTheme.cyanGlow.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                }

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

    @State private var showLogoutConfirmation = false

    private var logOutSection: some View {
        GlassCardView(cornerRadius: 20, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.headline)
                        .foregroundStyle(Color.red)

                    Text("Session & Account Switch")
                        .font(.headline)
                        .foregroundStyle(WayPointTheme.textPrimary)
                }

                Text("Sign out of your active account, clear cached session keys from Apple Keychain, and return to the onboarding screen.")
                    .font(.caption)
                    .foregroundStyle(WayPointTheme.textSecondary)

                Button(action: { showLogoutConfirmation = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "power")
                            .font(.subheadline.weight(.bold))
                        Text("Log Out / Switch Account")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.red, Color(red: 0.8, green: 0.1, blue: 0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .alert("Log Out of WayPoint?", isPresented: $showLogoutConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Log Out", role: .destructive) {
                        Task {
                            await supabaseService.signOut()
                            withAnimation(.easeInOut(duration: 0.25)) {
                                supabaseService.launchState = .onboarding
                            }
                        }
                    }
                } message: {
                    Text("This will purge active Keychain session tokens and return you to the onboarding sign-in screen.")
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
