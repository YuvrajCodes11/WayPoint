//
//  HapticManager.swift
//  WayPoint
//
//  Phase 2: Tactile Haptic Feedback Utility for Native Apple HIG Ergonomics
//

import UIKit
import SwiftUI

public enum Haptics {
    /// Trigger impact feedback (default .medium style)
    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Trigger selection feedback for scrolling, picker selections, or segment toggles
    public static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    /// Trigger notification feedback (.success, .warning, .error)
    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
