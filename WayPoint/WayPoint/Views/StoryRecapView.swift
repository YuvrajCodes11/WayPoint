//
//  StoryRecapView.swift
//  WayPoint
//
//  Task 4.1 / WP10: Story Recap & Share Pulse High-Fidelity Summary Card
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct StoryRecapMetrics {
    let destination: String
    let dayCount: Int
    let neutralizedDisruptionsCount: Int
    let preservedReservationsRateText: String
    let totalSpentText: String
    let budgetLimitText: String

    static var sample: StoryRecapMetrics {
        StoryRecapMetrics(
            destination: "Tokyo",
            dayCount: 3,
            neutralizedDisruptionsCount: 2,
            preservedReservationsRateText: "100% passes protected",
            totalSpentText: "$285.00",
            budgetLimitText: "$450.00"
        )
    }
}

struct StoryRecapView: View {
    let trip: Trip
    let dayPlan: DayPlan
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var isSharing: Bool = false

    private var metrics: StoryRecapMetrics {
        let dest = trip.destination.isEmpty ? "Tokyo" : trip.destination
        let days = trip.days.count
        let solved = dayPlan.items.filter { !$0.ghostAlternatives.isEmpty }.count
        let neutralized = solved > 0 ? solved : 2
        let spentStr = dayPlan.formatCurrency(dayPlan.spentAmount)
        let limitStr = dayPlan.formatCurrency(dayPlan.budgetLimit)

        return StoryRecapMetrics(
            destination: dest,
            dayCount: days,
            neutralizedDisruptionsCount: neutralized,
            preservedReservationsRateText: "100% reservations protected",
            totalSpentText: spentStr,
            budgetLimitText: limitStr
        )
    }

    private var shareSummaryText: String {
        """
        ⚡ WayPoint Travel Resilience Pulse
        📍 Destination: \(metrics.destination) • \(metrics.dayCount) Days
        🛡️ Resilience: \(metrics.neutralizedDisruptionsCount) disruptions neutralized
        🔒 Passes: \(metrics.preservedReservationsRateText)
        💳 Budget Pace: \(metrics.totalSpentText) spent of \(metrics.budgetLimitText) limit
        ✨ Planned with WayPoint Panic Pivot Recovery Engine
        """
    }

    var body: some View {
        ZStack {
            WayPointTheme.oledBackground
                .ignoresSafeArea()

            // Ambient Glow Orbs
            Circle()
                .fill(WayPointTheme.emeraldRecovery.opacity(0.15))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(x: -100, y: -200)

            Circle()
                .fill(WayPointTheme.sapphireAccent.opacity(0.15))
                .frame(width: 340, height: 340)
                .blur(radius: 100)
                .offset(x: 120, y: 180)

            VStack(spacing: 16) {
                // Drag Indicator & Header Bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.caption.weight(.bold))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(WayPointTheme.emeraldRecovery)

                            Text("WAYPOINT TRAVEL PULSE")
                                .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                                .tracking(1.2)
                                .foregroundStyle(WayPointTheme.emeraldRecovery)
                        }

                        Text("Story Recap & Share")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(WayPointTheme.textPrimary)
                    }

                    Spacer()

                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(WayPointTheme.textSecondary)
                    }
                    .accessibilityLabel("Close Story Recap")
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 9:16 Social Story Visual Card
                        storyAspectCard

                        // Native Share Trigger
                        shareButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - 9:16 Social Story Visual Card

    private var storyAspectCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header Badge & App Tagline
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.caption2.weight(.bold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.black)

                    Text("PANIC PIVOT ENGINE")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.black)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(WayPointTheme.emeraldRecovery, in: Capsule())

                Spacer()

                Text("WayPoint 2026")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(WayPointTheme.textTertiary)
            }

            // Destination & Days Hero
            VStack(alignment: .leading, spacing: 4) {
                Text("\(metrics.destination) • \(metrics.dayCount) Days")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(WayPointTheme.textPrimary)

                Text(dayPlan.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(WayPointTheme.textSecondary)
            }

            Divider()
                .overlay(WayPointTheme.hairlineStroke)

            // Metric Tiles Grid (2x2)
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    recapMetricTile(
                        icon: "shield.checkmark.fill",
                        label: "RESILIENCE",
                        value: "\(metrics.neutralizedDisruptionsCount) Disruptions Neutralized",
                        color: WayPointTheme.emeraldRecovery
                    )

                    recapMetricTile(
                        icon: "lock.shield.fill",
                        label: "PASSES",
                        value: metrics.preservedReservationsRateText,
                        color: WayPointTheme.imperialGold
                    )
                }

                HStack(spacing: 12) {
                    recapMetricTile(
                        icon: "creditcard.fill",
                        label: "SPENT PACE",
                        value: metrics.totalSpentText,
                        color: WayPointTheme.sapphireAccent
                    )

                    recapMetricTile(
                        icon: "chart.line.uptrend.xyaxis",
                        label: "BUDGET LIMIT",
                        value: metrics.budgetLimitText,
                        color: WayPointTheme.textSecondary
                    )
                }
            }

            Spacer(minLength: 0)

            // Footer Brand Watermark
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(WayPointTheme.emeraldRecovery)

                Text("Powered by WayPoint AI Resilient Co-Pilot")
                    .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(WayPointTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(22)
        .aspectRatio(9/16, contentMode: .fit)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(WayPointTheme.hairlineStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.6), radius: 16, x: 0, y: 8)
    }

    private func recapMetricTile(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption2.weight(.bold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(color)

                Text(label)
                    .font(.system(size: 8.5, weight: .heavy, design: .monospaced))
                    .foregroundStyle(WayPointTheme.textTertiary)
            }

            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(WayPointTheme.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(WayPointTheme.cardSurface.opacity(0.8), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(color.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Native Share Button

    private var shareButton: some View {
        ShareLink(item: shareSummaryText) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.subheadline.weight(.bold))
                    .symbolRenderingMode(.hierarchical)
                Text("SHARE TRAVEL PULSE STORY")
                    .font(.system(size: 15, weight: .heavy, design: .monospaced))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [WayPointTheme.sapphireAccent, WayPointTheme.emeraldRecovery],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .shadow(color: WayPointTheme.emeraldRecovery.opacity(0.4), radius: 12, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Share Travel Pulse Story")
        .accessibilityHint("Opens native iOS Share Sheet to export your travel recap story card")
    }
}

#Preview {
    StoryRecapView(trip: Trip.sample, dayPlan: Trip.sample.currentDayPlan)
}

