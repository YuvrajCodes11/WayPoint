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

    @State private var isSplashTimerActive = true

    private var appStage: RootViewStage {
        if isSplashTimerActive || supabaseService.appStage == .splash {
            return .splash
        }
        return supabaseService.appStage
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                switch appStage {
                case .splash:
                    LaunchScreenView()
                        .transition(.opacity)
                case .unauthenticated:
                    OnboardingView()
                        .transition(.opacity)
                case .authenticated:
                    MainTabView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: appStage)
            .environment(subscriptionManager)
            .environment(supabaseService)
            .environment(notificationManager)
            .environment(aiService)
            .environment(tripStore)
            .preferredColorScheme(.dark)
            .task {
                try? await Task.sleep(for: .milliseconds(800))
                withAnimation(.easeInOut(duration: 0.2)) {
                    isSplashTimerActive = false
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
