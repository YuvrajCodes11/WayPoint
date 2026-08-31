//
//  GlobalAmbientBackground.swift
//  WayPoint
//

import SwiftUI

/// Animated radial mesh gradient backdrop that renders consistently behind all main screens.
public struct GlobalAmbientBackground: View {
    @State private var animateGradient = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public var body: some View {
        ZStack {
            WayPointTheme.oledBackground
                .ignoresSafeArea()

            // Primary Sapphire Accent Orb
            Circle()
                .fill(WayPointTheme.sapphireAccent.opacity(0.32))
                .frame(width: 380, height: 380)
                .blur(radius: 95)
                .offset(
                    x: animateGradient ? -90 : -140,
                    y: animateGradient ? -240 : -290
                )

            // Secondary Emerald Recovery Orb
            Circle()
                .fill(WayPointTheme.emeraldRecovery.opacity(0.28))
                .frame(width: 360, height: 360)
                .blur(radius: 90)
                .offset(
                    x: animateGradient ? 130 : 90,
                    y: animateGradient ? 160 : 120
                )

            // Tertiary Imperial Gold Orb
            Circle()
                .fill(WayPointTheme.imperialGold.opacity(0.22))
                .frame(width: 320, height: 320)
                .blur(radius: 85)
                .offset(
                    x: animateGradient ? -120 : 60,
                    y: animateGradient ? 400 : 340
                )
        }
        .ignoresSafeArea()
        .drawingGroup()
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

#Preview {
    GlobalAmbientBackground()
}
