//
//  GlobalAmbientBackground.swift
//  WayPoint
//

import SwiftUI

public struct GlobalAmbientBackground: View {
    public var splineURL: String

    public init(splineURL: String = "https://my.spline.design/iridescenttorusanimation-34cvLNege0W70WxpEm6Aml6d/") {
        self.splineURL = splineURL
    }

    public var body: some View {
        ZStack {
            (Color(hex: "070B14") ?? Color.black)
                .ignoresSafeArea()

            // Fullscreen Corner-to-Corner 3D Spline Canvas
            SplineWebContainer(embedURL: splineURL)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            // Legibility Scrim Overlay
            LinearGradient(
                colors: [Color.black.opacity(0.15), Color.black.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

#Preview {
    GlobalAmbientBackground()
}