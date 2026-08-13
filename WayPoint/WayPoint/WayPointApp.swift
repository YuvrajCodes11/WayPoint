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
            .preferredColorScheme(.dark)
            .task {
                try? await Task.sleep(for: .milliseconds(1400))
                withAnimation(.easeInOut(duration: 0.35)) {
                    showSplash = false
                }
            }
        }
    }
}