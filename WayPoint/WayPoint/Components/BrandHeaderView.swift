//
//  BrandHeaderView.swift
//  WayPoint
//
//  Phase 2: Native Apple HIG Brand Navigation Header
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
                    .fill(Color(uiColor: .systemBlue))
                    .frame(width: height, height: height)

                Image(systemName: "location.north.fill")
                    .font(.system(size: height * 0.46, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("WAYPOINT")
                    .font(.system(size: height * 0.58, weight: .bold, design: .default))
                    .tracking(2)
                    .foregroundColor(Color.primary)
                Text("TRAVEL RESILIENCE")
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .tracking(1)
                    .foregroundColor(Color.secondary)
            }
        }
    }
}

#Preview {
    BrandHeaderView()
        .preferredColorScheme(.dark)
}
