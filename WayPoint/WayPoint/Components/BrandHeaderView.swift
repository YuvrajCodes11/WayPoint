//
//  BrandHeaderView.swift
//  WayPoint
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BrandHeaderView: View {
    var height: CGFloat = 32

    var body: some View {
        HStack(spacing: 12) {
            #if canImport(UIKit)
            if UIImage(named: "BrandLogo") != nil {
                Image("BrandLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: height)
            } else {
                fallbackBrandView
            }
            #else
            fallbackBrandView
            #endif
        }
    }

    private var fallbackBrandView: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [WayPointTheme.cyanGlow, Color(red: 0.6, green: 0.4, blue: 1.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: height, height: height)
                    .shadow(color: WayPointTheme.cyanGlow.opacity(0.4), radius: 10, x: 0, y: 2)

                Image(systemName: "location.north.fill")
                    .font(.system(size: height * 0.48, weight: .bold))
                    .foregroundColor(.black)
            }

            Text("WAYPOINT")
                .font(.system(size: height * 0.65, weight: .bold, design: .rounded))
                .tracking(3)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    BrandHeaderView()
        .preferredColorScheme(.dark)
}
