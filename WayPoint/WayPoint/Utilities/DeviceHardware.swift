//
//  DeviceHardware.swift
//  WayPoint
//

import UIKit

public enum DeviceHardware {
    /// Dynamic Island devices have a top safe area inset of 54pt or greater.
    public static var hasDynamicIsland: Bool {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return false
        }
        return window.safeAreaInsets.top >= 54
    }

    public static var liveActivityDisplayLabel: String {
        hasDynamicIsland ? "LIVE RADAR ACTIVE ON DYNAMIC ISLAND" : "LIVE RADAR ACTIVE ON LOCK SCREEN"
    }
}
