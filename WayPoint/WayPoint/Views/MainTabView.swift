//
//  MainTabView.swift
//  WayPoint
//

import SwiftUI
#if canImport(WebKit) && canImport(UIKit)
import WebKit
import UIKit
#endif

enum AppTab: Int, CaseIterable, Identifiable {
    case dashboard = 0
    case map = 1
    case vault = 2
    case settings = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .map: "Map Radar"
        case .vault: "Pass Vault"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: "house.fill"
        case .map: "map.fill"
        case .vault: "ticket.fill"
        case .settings: "gearshape.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        ZStack(alignment: .bottom) {
            // Layer 1: Persistent 3D Canvas (Never reset or unmounted on tab change)
            #if canImport(WebKit) && canImport(UIKit)
            SplineWebContainer(urlString: "https://my.spline.design/iridescenttorusanimation-34cvLNege0W70WxpEm6Aml6d/")
                .id("persistent_spline_canvas")
                .scaleEffect(1.08)
                .padding(.bottom, -35)
                .clipped()
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .compositingGroup()
            #else
            WayPointTheme.obsidian.ignoresSafeArea()
            #endif

            Color.black.opacity(0.18)
                .ignoresSafeArea()

            // Layer 2: Persistent ZStack Tab Views (All child views stay mounted)
            ZStack {
                HomeView()
                    .opacity(selectedTab == .dashboard ? 1 : 0)
                    .allowsHitTesting(selectedTab == .dashboard)

                ItineraryMapView()
                    .opacity(selectedTab == .map ? 1 : 0)
                    .allowsHitTesting(selectedTab == .map)

                BookingVaultView()
                    .opacity(selectedTab == .vault ? 1 : 0)
                    .allowsHitTesting(selectedTab == .vault)

                SettingsView()
                    .opacity(selectedTab == .settings ? 1 : 0)
                    .allowsHitTesting(selectedTab == .settings)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Layer 3: Floating Dark-Mode Glass Tab Bar Overlay
            floatingTabBar
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .preferredColorScheme(.dark)
    }

    // MARK: - Floating Tab Bar

    private var floatingTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.body.weight(selectedTab == tab ? .bold : .medium))
                            .scaleEffect(selectedTab == tab ? 1.15 : 1.0)

                        Text(tab.title)
                            .font(.caption2.weight(selectedTab == tab ? .bold : .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .foregroundStyle(
                        selectedTab == tab
                            ? WayPointTheme.cyanGlow
                            : WayPointTheme.textSecondary
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background {
            Capsule()
                .fill(WayPointTheme.obsidianElevated)
                .overlay {
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    WayPointTheme.glassHighlight,
                                    WayPointTheme.glassBorder,
                                    WayPointTheme.cyanGlow.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: WayPointTheme.glassShadow, radius: 20, x: 0, y: 10)
                .shadow(color: WayPointTheme.cyanGlow.opacity(0.1), radius: 15, x: 0, y: 5)
        }
        .contentShape(Capsule())
        .allowsHitTesting(true)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

#Preview {
    MainTabView()
        .environment(SubscriptionManager.shared)
        .environment(SupabaseService.shared)
        .environment(NotificationManager.shared)
        .environment(AIRecalculatorService.shared)
}
