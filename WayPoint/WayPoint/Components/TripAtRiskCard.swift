//
//  TripAtRiskCard.swift
//  WayPoint
//
//  Phase 2: Native Apple HIG Resilient Itinerary Card
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
            cornerRadius: 16,
            padding: 16
        ) {
            VStack(alignment: .leading, spacing: 14) {
                // Top Risk Alert Banner Header
                HStack(alignment: .center) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color(uiColor: .systemRed))

                        Text("DISRUPTION DETECTED")
                            .font(.system(.caption, design: .monospaced, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(Color(uiColor: .systemRed))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(uiColor: .systemRed).opacity(0.12), in: Capsule())

                    Spacer()

                    Text(disruption.type.badgeText)
                        .font(.system(.caption2, design: .monospaced, weight: .medium))
                        .foregroundStyle(Color.secondary)
                }

                // Disruption Title & Description
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(disruption.type.emoji)
                            .font(.title3)

                        Text(disruption.title)
                            .font(.system(.title3, design: .default, weight: .bold))
                            .foregroundStyle(Color.primary)
                    }

                    Text(disruption.description)
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(2)
                }

                Divider()
                    .overlay(Color.primary.opacity(0.06))

                // Impact Grid
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AFFECTED STOPS")
                            .font(.system(.caption2, design: .monospaced, weight: .medium))
                            .foregroundStyle(Color.secondary)

                        Text(disruption.type.defaultImpactText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.primary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("ESTIMATED IMPACT")
                            .font(.system(.caption2, design: .monospaced, weight: .medium))
                            .foregroundStyle(Color.secondary)

                        Text("+\(disruption.estimatedTimeImpactMinutes) mins impact")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color(uiColor: .systemRed))
                    }
                }

                // CTA Button ("See Impact & Fix")
                Button(action: {
                    Haptics.impact(.medium)
                    onTapPanicPivot()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.body.weight(.bold))

                        Text("See Impact & Fix")
                            .font(.system(.headline, design: .default, weight: .bold))

                        Spacer()

                        Image(systemName: "arrow.right.circle.fill")
                            .font(.body.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(uiColor: .systemRed), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(uiColor: .systemRed).opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Nominal Card View (Everything Looking Good)

    private var nominalCardView: some View {
        GlassCardView(
            cornerRadius: 16,
            padding: 16
        ) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(uiColor: .systemGreen).opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "checkmark.shield.fill")
                        .font(.body.weight(.bold))
                        .foregroundStyle(Color(uiColor: .systemGreen))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("ON TRACK")
                            .font(.system(.caption2, design: .monospaced, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(Color(uiColor: .systemGreen))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(uiColor: .systemGreen).opacity(0.12), in: Capsule())
                    }

                    Text("All \(currentPlan.items.count) stops on schedule")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)

                    if let next = currentPlan.items.first(where: { !$0.isCompleted }) {
                        Text("Next stop: \(next.title) • \(next.timeRange)")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    } else {
                        Text("Real-time resilience active • 0 disruptions")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                }

                Spacer()
            }
        }
    }
}
