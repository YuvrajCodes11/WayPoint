//
//  RootCoordinatorView.swift
//  WayPoint
//

import SwiftUI

struct RootCoordinatorView: View {
    @Environment(SupabaseService.self) private var supabaseService
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch supabaseService.launchState {
            case .loading:
                Color.black.ignoresSafeArea()

            case .onboarding:
                if !hasCompletedOnboarding {
                    OnboardingView()
                } else if TripStore.shared.currentTrip == nil {
                    TripGenesisView()
                } else {
                    MainTabView()
                }

            case .authenticated:
                if !hasCompletedOnboarding {
                    OnboardingView()
                } else if TripStore.shared.currentTrip == nil {
                    TripGenesisView()
                } else {
                    MainTabView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: supabaseService.launchState)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    RootCoordinatorView()
        .environment(SupabaseService.shared)
}
