//
//  ShipatonDemoToolbar.swift
//  WayPoint
//
//  WP10: Shipaton 15-Second Hero Demo Simulator & Toolbar
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

#if DEBUG
struct ShipatonDemoToolbar: View {
    @Binding var activeDisruption: DisruptionEvent?
    @Binding var isVisible: Bool
    var onTriggerPivotSheet: (() -> Void)? = nil
    var onResetNominal: (() -> Void)? = nil

    var body: some View {
        if isVisible {
            VStack(spacing: 8) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(WayPointTheme.cyanGlow)

                        Text("SHIPATON 2026 DEMO SIMULATOR")
                            .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                            .tracking(1.2)
                            .foregroundStyle(WayPointTheme.cyanGlow)
                    }

                    Spacer()

                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isVisible = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(WayPointTheme.textSecondary)
                    }
                    .accessibilityLabel("Dismiss Demo Simulator")
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Clear / Nominal Pristine Itinerary
                        demoOptionChip(
                            emoji: "☀️",
                            title: "Nominal Day",
                            isSelected: activeDisruption == nil,
                            color: Color.green
                        ) {
                            activeDisruption = nil
                            onResetNominal?()
                        }

                        // Disruption Scenarios (Weather Defense, Flight Rescue, Transit Delay, Closure Pivot, Pacing)
                        ForEach(DisruptionType.allCases) { type in
                            demoOptionChip(
                                emoji: type.emoji,
                                title: type.badgeText,
                                isSelected: activeDisruption?.type == type,
                                color: type.badgeColor
                            ) {
                                activeDisruption = DisruptionEvent(type: type)
                                onTriggerPivotSheet?()
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(10)
            .background(WayPointTheme.obsidianElevated.opacity(0.95), in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(WayPointTheme.cyanGlow.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: WayPointTheme.cyanGlow.opacity(0.2), radius: 8, x: 0, y: 4)
        }
    }

    private func demoOptionChip(
        emoji: String,
        title: String,
        isSelected: Bool,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            #if canImport(UIKit)
            UISelectionFeedbackGenerator().selectionChanged()
            #endif
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                action()
            }
        }) {
            HStack(spacing: 4) {
                Text(emoji)
                    .font(.caption2)

                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
            }
            .foregroundStyle(isSelected ? .black : WayPointTheme.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? color : WayPointTheme.obsidianElevated, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? color : WayPointTheme.glassBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) Preset")
        .accessibilityHint("Activates \(title) demo scenario")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
    }
}
#endif
