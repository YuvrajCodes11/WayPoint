//
//  WayPointApp.swift
//  WayPoint
//

import SwiftUI

@main
struct WayPointApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var supabaseService = SupabaseService.shared
    @State private var notificationManager = NotificationManager.shared
    @State private var aiService = AIRecalculatorService.shared
    @State private var tripStore = TripStore.shared

    var body: some Scene {
        WindowGroup {
            RootCoordinatorView()
                .environmentObject(subscriptionManager)
                .environment(subscriptionManager)
                .environment(supabaseService)
                .environment(notificationManager)
                .environment(aiService)
                .environment(tripStore)
                .preferredColorScheme(.dark)
                .task {
                    try? await Task.sleep(for: .milliseconds(600))
                    withAnimation(.easeInOut(duration: 0.2)) {
                        supabaseService.finishLoading()
                    }
                    #if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("-runIntegrationTests") {
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
                    }
                    #endif
                }
        }
    }
}
