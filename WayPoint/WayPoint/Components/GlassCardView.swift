//
//  GlassCardView.swift
//  WayPoint
//
//  Phase 2: Native Apple HIG Card Container
//

import SwiftUI

struct GlassCardView<Content: View>: View {
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 16
    var glowColor: Color = Color.clear
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )
    }
}

#Preview {
    ZStack {
        Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
        GlassCardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Grouped System Card")
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                Text("Clean iOS secondary system grouped container.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
