//
//  TripAtRiskCard.swift
//  WayPoint
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct TripAtRiskCard: View {
    let currentPlan: DayPlan
    let activeDisruption: DisruptionEvent?
    let onTapPanicPivot: () -> Void
    let onSelectDisruption: (DisruptionType) -> Void

    @State private var isPulsing: Bool = false

    var body: some View {
        Group {
            if let disruption = activeDisruption {
                atRiskCardView(disruption: disruption)
            } else {
                nominalCardView
            }
        }
    }

    // MARK: - At Risk Banner Card (Hero Interaction)

    private func atRiskCardView(disruption: DisruptionEvent) -> some View {
        GlassCardView(
            cornerRadius: 22,
            padding: 18,
            glowColor: WayPointTheme.crimsonAlert
        ) {
            VStack(alignment: .leading, spacing: 14) {
                // Top Risk Alert Banner Header
                HStack(alignment: .top) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption.weight(.bold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(WayPointTheme.crimsonAlert)

                        Text("⚠️ DISRUPTION DETECTED")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .tracking(1.4)
                            .foregroundStyle(WayPointTheme.crimsonAlert)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(WayPointTheme.crimsonAlert.opacity(0.16), in: Capsule())
                    .overlay(Capsule().strokeBorder(WayPointTheme.crimsonAlert.opacity(0.4), lineWidth: 1))

                    Spacer()

                    Text(disruption.type.badgeText)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(WayPointTheme.textTertiary)
                }

                // Disruption Title & Detailed Cause Breakdown
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(disruption.type.emoji)
                            .font(.title2)

                        Text(disruption.title)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(WayPointTheme.textPrimary)
                    }

                    Text(disruption.description)
                        .font(.subheadline)
                        .foregroundStyle(WayPointTheme.textSecondary)
                        .lineLimit(2)
                }

                Divider()
                    .overlay(WayPointTheme.hairlineStroke)

                // Impact & Recovery Stats Grid
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AFFECTED STOPS")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(WayPointTheme.textTertiary)

                        Text(disruption.type.defaultImpactText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(WayPointTheme.textPrimary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("ESTIMATED IMPACT")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(WayPointTheme.textTertiary)

                        Text("+\(disruption.estimatedTimeImpactMinutes) mins impact")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(WayPointTheme.crimsonAlert)
                    }
                }

                // Dominant CTA Button ("See Impact & Fix")
                Button(action: {
                    #if canImport(UIKit)
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    #endif
                    onTapPanicPivot()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.title3.weight(.bold))
                            .symbolRenderingMode(.hierarchical)

                        VStack(alignment: .leading, spacing: 0) {
                            Text("See Impact & Fix")
                                .font(.system(size: 17, weight: .heavy, design: .rounded))
                                .tracking(0.6)

                            Text("1-Tap Panic Pivot Recovery Engine")
                                .font(.system(size: 10, weight: .medium))
                                .opacity(0.9)
                        }

                        Spacer()

                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2.weight(.bold))
                            .symbolRenderingMode(.hierarchical)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(WayPointTheme.crimsonAlert, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: WayPointTheme.crimsonAlert.opacity(0.5), radius: 14, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("See Impact & Fix Panic Pivot")
                .accessibilityHint("Opens Panic Pivot recovery sheet to solve itinerary disruption")
                .accessibilityAddTraits(.isButton)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(WayPointTheme.crimsonAlert.opacity(0.6), lineWidth: 1.5)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }

    // MARK: - Nominal Card View (Everything Looking Good)

    private var nominalCardView: some View {
        GlassCardView(
            cornerRadius: 20,
            padding: 16,
            glowColor: WayPointTheme.emeraldRecovery.opacity(0.4)
        ) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(WayPointTheme.emeraldRecovery.opacity(0.18))
                        .frame(width: 44, height: 44)

                    Image(systemName: "shield.checkmark.fill")
                        .font(.title3.weight(.bold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(WayPointTheme.emeraldRecovery)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("🟢 Day \(currentPlan.id.uuidString.prefix(1).lowercased() == "a" ? "1" : "1") on Track")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .tracking(1.0)
                            .foregroundStyle(WayPointTheme.emeraldRecovery)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(WayPointTheme.emeraldRecovery.opacity(0.15), in: Capsule())
                            .overlay(Capsule().strokeBorder(WayPointTheme.emeraldRecovery.opacity(0.4), lineWidth: 1))
                    }

                    Text("All \(currentPlan.items.count) stops on schedule")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(WayPointTheme.textPrimary)

                    if let next = currentPlan.items.first(where: { !$0.isCompleted }) {
                        Text("Next stop: \(next.title) • \(next.timeRange)")
                            .font(.caption)
                            .foregroundStyle(WayPointTheme.textSecondary)
                    } else {
                        Text("Real-time resilience active • 0 disruptions detected")
                            .font(.caption)
                            .foregroundStyle(WayPointTheme.textSecondary)
                    }
                }

                Spacer()
            }
        }
    }

}
