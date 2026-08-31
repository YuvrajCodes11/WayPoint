//
//  GlobalAmbientBackground.swift
//  WayPoint
//

import SwiftUI
import Foundation

/// Animated radial mesh gradient backdrop that renders consistently behind all main screens.
public struct GlobalAmbientBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public var body: some View {
        TimelineView(.animation) { timeline in
            let time = reduceMotion ? 0.0 : timeline.date.timeIntervalSinceReferenceDate

            let sapphireX = -115.0 + sin(time * 0.4) * 45.0
            let sapphireY = -265.0 + cos(time * 0.3) * 35.0

            let emeraldX = 110.0 + cos(time * 0.35) * 40.0
            let emeraldY = 140.0 + sin(time * 0.45) * 30.0

            let goldX = -30.0 + sin(time * 0.25) * 50.0
            let goldY = 370.0 + cos(time * 0.2) * 40.0

            ZStack {
                WayPointTheme.oledBackground
                    .ignoresSafeArea()

                // Primary Sapphire Accent Orb
                Circle()
                    .fill(WayPointTheme.sapphireAccent.opacity(0.32))
                    .frame(width: 380, height: 380)
                    .blur(radius: 95)
                    .offset(x: sapphireX, y: sapphireY)

                // Secondary Emerald Recovery Orb
                Circle()
                    .fill(WayPointTheme.emeraldRecovery.opacity(0.28))
                    .frame(width: 360, height: 360)
                    .blur(radius: 90)
                    .offset(x: emeraldX, y: emeraldY)

                // Tertiary Imperial Gold Orb
                Circle()
                    .fill(WayPointTheme.imperialGold.opacity(0.22))
                    .frame(width: 320, height: 320)
                    .blur(radius: 85)
                    .offset(x: goldX, y: goldY)
            }
            .ignoresSafeArea()
            .drawingGroup()
            .accessibilityHidden(true)
        }
    }
}

#Preview {
    GlobalAmbientBackground()
}
