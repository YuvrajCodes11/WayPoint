//
//  WayPointTheme.swift
//  WayPoint
//
//  Module 1: Native Apple HIG Design System & Standard System Hierarchy
//

import SwiftUI

public enum WayPointTheme {
    // Native Apple iOS System Grouped Background Materials
    public static let obsidian = Color(uiColor: .systemGroupedBackground)
    public static let obsidianElevated = Color(uiColor: .secondarySystemGroupedBackground)
    public static let obsidianSurface = Color(uiColor: .tertiarySystemGroupedBackground)

    // Standardized Apple Native Surface Tokens
    public static let oledBackground = Color(uiColor: .systemBackground)
    public static let cardSurface = Color(uiColor: .secondarySystemGroupedBackground)
    public static let hairlineStroke = Color.primary.opacity(0.06)

    // iOS Standardized Semantic Status Colors
    public static let emeraldRecovery = Color(uiColor: .systemGreen)
    public static let crimsonAlert = Color(uiColor: .systemRed)
    public static let imperialGold = Color(uiColor: .systemOrange)
    public static let sapphireAccent = Color(uiColor: .systemBlue)

    // Clean Apple System Tints (Replacing Gratuitous Neon Glows)
    public static let cyanGlow = Color(uiColor: .systemBlue)
    public static let violetGlow = Color(uiColor: .systemIndigo)
    public static let accentGradient = LinearGradient(
        colors: [Color(uiColor: .systemBlue), Color(uiColor: .systemIndigo)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // San Francisco Semantic Text Hierarchy
    public static let textPrimary = Color.primary
    public static let textSecondary = Color.secondary
    public static let textTertiary = Color(uiColor: .tertiaryLabel)

    // Standard Apple Spec Borders & Dividers
    public static let glassBorder = Color.primary.opacity(0.06)
    public static let glassHighlight = Color.primary.opacity(0.10)
    public static let glassShadow = Color.black.opacity(0.08)

    // Budget Engine Status Tints
    public static let budgetHealthy = emeraldRecovery
    public static let budgetWarning = imperialGold
    public static let budgetOver = crimsonAlert
}

extension Color {
    public init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexSanitized.hasPrefix("#") {
            hexSanitized.removeFirst()
        }
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let length = hexSanitized.count
        if length == 6 {
            let r = Double((rgb & 0xFF0000) >> 16) / 255.0
            let g = Double((rgb & 0x00FF00) >> 8) / 255.0
            let b = Double(rgb & 0x0000FF) / 255.0
            self.init(red: r, green: g, blue: b)
        } else if length == 8 {
            let r = Double((rgb & 0xFF000000) >> 24) / 255.0
            let g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            let b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            let a = Double(rgb & 0x000000FF) / 255.0
            self.init(red: r, green: g, blue: b, opacity: a)
        } else {
            return nil
        }
    }
}
