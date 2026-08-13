//
//  GlassCardView.swift
//  WayPoint
//

import SwiftUI

struct GlassCardView<Content: View>: View {
    var cornerRadius: CGFloat = 24
    var padding: CGFloat = 20
    var glowColor: Color = WayPointTheme.cyanGlow
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background { glassBackground }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay { borderOverlay }
            .shadow(color: WayPointTheme.glassShadow, radius: 24, x: 0, y: 12)
            .shadow(color: glowColor.opacity(0.12), radius: 32, x: 0, y: 8)
    }

    private var glassBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(WayPointTheme.obsidianElevated.opacity(0.72))

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.35)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.10),
                            Color.white.opacity(0.02),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        WayPointTheme.glassHighlight,
                        WayPointTheme.glassBorder,
                        glowColor.opacity(0.18),
                        WayPointTheme.glassBorder.opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

#Preview {
    ZStack {
        WayPointTheme.obsidian.ignoresSafeArea()
        GlassCardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Glass Card")
                    .font(.headline)
                    .foregroundStyle(WayPointTheme.textPrimary)
                Text("Frosted surface with luminous edge highlights.")
                    .font(.subheadline)
                    .foregroundStyle(WayPointTheme.textSecondary)
            }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
