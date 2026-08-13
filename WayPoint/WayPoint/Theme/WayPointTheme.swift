//
//  WayPointTheme.swift
//  WayPoint
//

import SwiftUI

enum WayPointTheme {
    static let obsidian = Color(red: 0.06, green: 0.07, blue: 0.10)
    static let obsidianElevated = Color(red: 0.10, green: 0.11, blue: 0.15)
    static let obsidianSurface = Color(red: 0.14, green: 0.15, blue: 0.20)

    static let cyanGlow = Color(red: 0.20, green: 0.85, blue: 0.95)
    static let violetGlow = Color(red: 0.62, green: 0.38, blue: 0.98)
    static let accentGradient = LinearGradient(
        colors: [cyanGlow, violetGlow],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.62)
    static let textTertiary = Color.white.opacity(0.38)

    static let glassBorder = Color.white.opacity(0.14)
    static let glassHighlight = Color.white.opacity(0.22)
    static let glassShadow = Color.black.opacity(0.45)

    static let budgetHealthy = cyanGlow
    static let budgetWarning = Color(red: 1.0, green: 0.72, blue: 0.28)
    static let budgetOver = Color(red: 1.0, green: 0.38, blue: 0.42)
}
