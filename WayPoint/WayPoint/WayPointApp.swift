//
//  WayPointApp.swift
//  WayPoint
//

import SwiftUI

@main
struct WayPointApp: App {
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var supabaseService = SupabaseService.shared
    @State private var notificationManager = NotificationManager.shared
    @State private var aiService = AIRecalculatorService.shared
    @State private var tripStore = TripStore.shared

    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    LaunchScreenView()
                        .transition(.opacity.animation(.easeInOut(duration: 0.35)))
                        .zIndex(2)
                } else {
                    Group {
                        if supabaseService.isAuthenticated {
                            MainTabView()
                                .transition(.opacity.combined(with: .scale(scale: 1.05)))
                        } else {
                            OnboardingView()
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                    .zIndex(1)
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: supabaseService.isAuthenticated)
            .environment(subscriptionManager)
            .environment(supabaseService)
            .environment(notificationManager)
            .environment(aiService)
            .environment(tripStore)
            .preferredColorScheme(.dark)
            .task {
                try? await Task.sleep(for: .milliseconds(1400))
                withAnimation(.easeInOut(duration: 0.35)) {
                    showSplash = false
                }
                #if DEBUG
                _ = await WPACoreDataIntegrityTests.shared.runAllWPATests()
                _ = await WPBWorldwideReadinessTests.shared.runAllWPBTests()
                _ = await WPCBackendArchitectureTests.shared.runAllWPCTests()
                _ = await WPDMonetizationTests.shared.runAllWPDTests()
                _ = await WPEPanicPivotTests.shared.runAllWPETests()
                _ = await WPFNativeIOSTests.shared.runAllWPFTests()
                _ = await WPGImportTrustTests.shared.runAllWPGTests()
                _ = await WPHSecurityPrivacyTests.shared.runAllWPHTests(skipMaster: true)
                _ = await WPIPerformanceAccessibilityTests.shared.runAllWPITests()
                _ = await WPJShipatonPackageTests.shared.runAllWPJTests()
                _ = await WayPointMasterTestSuite.shared.runMasterTestSuite()
                #endif
            }
        }
    }
}
