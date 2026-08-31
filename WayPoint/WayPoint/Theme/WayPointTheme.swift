//
//  WayPointTheme.swift
//  WayPoint
//

import SwiftUI

enum WayPointTheme {
    static let obsidian = Color(red: 0.06, green: 0.07, blue: 0.10)
    static let obsidianElevated = Color(red: 0.10, green: 0.11, blue: 0.15)
    static let obsidianSurface = Color(red: 0.14, green: 0.15, blue: 0.20)

    // Premium Apple Native Tokens
    static let oledBackground = Color.black
    static let cardSurface = Color(red: 0.08, green: 0.08, blue: 0.10)
    static let hairlineStroke = Color.white.opacity(0.12)

    static let emeraldRecovery = Color(red: 0.06, green: 0.73, blue: 0.51) // #10B981
    static let crimsonAlert = Color(red: 0.94, green: 0.27, blue: 0.27)    // #EF4444
    static let imperialGold = Color(red: 0.96, green: 0.62, blue: 0.04)    // #F59E0B
    static let sapphireAccent = Color(red: 0.23, green: 0.51, blue: 0.96)  // #3B82F6

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

    static let budgetHealthy = emeraldRecovery
    static let budgetWarning = imperialGold
    static let budgetOver = crimsonAlert
}

