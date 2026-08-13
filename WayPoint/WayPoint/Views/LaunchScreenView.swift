//
//  LaunchScreenView.swift
//  WayPoint
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var logoScale: CGFloat = 0.95
    @State private var logoOpacity: Double = 0.0

    var body: some View {
        ZStack {
            // Full-Screen Dark Obsidian Background
            WayPointTheme.obsidian
                .ignoresSafeArea()

            // Central Glowing Aura Backdrop
            ZStack {
                Circle()
                    .fill(WayPointTheme.cyanGlow.opacity(0.24))
                    .frame(width: 270, height: 270)
                    .blur(radius: 75)
                    .scaleEffect(logoScale)

                Circle()
                    .fill(WayPointTheme.violetGlow.opacity(0.20))
                    .frame(width: 290, height: 290)
                    .blur(radius: 90)
                    .scaleEffect(logoScale == 0.95 ? 1.05 : 0.95)
            }

            // Central Unified Brand Header & Tagline
            VStack(spacing: 16) {
                BrandHeaderView(height: 44)
                    .shadow(color: WayPointTheme.cyanGlow.opacity(0.6), radius: 28, x: 0, y: 8)
                    .shadow(color: WayPointTheme.violetGlow.opacity(0.4), radius: 35, x: 0, y: 12)

                Text("AI TRAVEL CO-PILOT")
                    .font(.caption.weight(.bold))
                    .tracking(2.5)
                    .foregroundStyle(WayPointTheme.cyanGlow)
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                logoScale = 1.05
            }
            withAnimation(.easeIn(duration: 0.6)) {
                logoOpacity = 1.0
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
