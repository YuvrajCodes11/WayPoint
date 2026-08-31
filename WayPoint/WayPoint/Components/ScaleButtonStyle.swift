//
//  ScaleButtonStyle.swift
//  WayPoint
//

import SwiftUI

/// Custom ButtonStyle providing smooth 0.98x spring scale feedback on press
/// while preventing layout shifting or jitter across interactive cards and buttons.
public struct ScaleButtonStyle: ButtonStyle {
    public var scaleAmount: CGFloat
    public var animation: Animation

    public init(scaleAmount: CGFloat = 0.98, animation: Animation = .spring(response: 0.25, dampingFraction: 0.7)) {
        self.scaleAmount = scaleAmount
        self.animation = animation
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .animation(animation, value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == ScaleButtonStyle {
    static var scalePress: ScaleButtonStyle {
        ScaleButtonStyle()
    }
}
