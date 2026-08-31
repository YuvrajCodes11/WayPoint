//
//  WayPointLiveActivityWidget.swift
//  WayPoint
//

import SwiftUI
import WidgetKit
import ActivityKit

struct WayPointLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WayPointActivityAttributes.self) { context in
            // Lock Screen / Notification Center Banner
            lockScreenBannerView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Layout
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("📍")
                            Text("CURRENT STOP")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(WayPointTheme.cyanGlow)
                        }

                        Text(context.state.currentVenueName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(WayPointTheme.textPrimary)
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("⏳ 45m")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(WayPointTheme.cyanGlow)
                            Image(systemName: "location.north.line.fill")
                                .font(.caption2)
                                .foregroundStyle(WayPointTheme.cyanGlow)
                        }

                        Text("\(context.state.distanceMeters)m ↗")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(WayPointTheme.textPrimary)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        // Budget Bar
                        HStack {
                            Text("Spent \(context.state.spentAmount)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(WayPointTheme.textSecondary)

                            Spacer()

                            Text("Rem. \(context.state.remainingAmount)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(WayPointTheme.cyanGlow)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(WayPointTheme.obsidianSurface)
                                    .frame(height: 5)

                                Capsule()
                                    .fill(WayPointTheme.accentGradient)
                                    .frame(width: geo.size.width * min(max(context.state.budgetUsedPercent, 0), 1.0), height: 5)
                            }
                        }
                        .frame(height: 5)

                        HStack {
                            if !context.state.nextVenueName.isEmpty {
                                HStack(spacing: 4) {
                                    Text("NEXT:")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(WayPointTheme.textTertiary)

                                    Text("\(context.state.nextVenueName) (\(context.state.nextVenueTime))")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(WayPointTheme.textSecondary)
                                        .lineLimit(1)
                                }
                            }

                            Spacer()

                            // Panic Pivot Indicator Badge
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 8, weight: .bold))
                                Text("Panic Pivot Ready")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundStyle(WayPointTheme.obsidian)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(WayPointTheme.accentGradient, in: Capsule())
                        }
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Text("📍")
                        .font(.caption2)
                    Text(context.state.currentVenueName)
                        .font(.caption2.weight(.bold))
                        .lineLimit(1)
                        .frame(maxWidth: 70)
                }
            } compactTrailing: {
                HStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .stroke(WayPointTheme.obsidianSurface, lineWidth: 2)
                            .frame(width: 14, height: 14)

                        Circle()
                            .trim(from: 0, to: min(max(context.state.budgetUsedPercent, 0), 1.0))
                            .stroke(WayPointTheme.cyanGlow, lineWidth: 2)
                            .rotationEffect(.degrees(-90))
                            .frame(width: 14, height: 14)
                    }

                    Text("\(context.state.distanceMeters)m ↗")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(WayPointTheme.cyanGlow)
                }
            } minimal: {
                ZStack {
                    Circle()
                        .fill(WayPointTheme.cyanGlow.opacity(0.2))
                        .frame(width: 22, height: 22)

                    Image(systemName: "location.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(WayPointTheme.cyanGlow)
                }
            }
        }
    }

    // MARK: - Lock Screen Banner View

    @ViewBuilder
    private func lockScreenBannerView(context: ActivityViewContext<WayPointActivityAttributes>) -> some View {
        ZStack {
            WayPointTheme.obsidian
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 12) {
                // Header Row
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "location.north.circle.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(WayPointTheme.cyanGlow)

                        Text("WAYPOINT CO-PILOT")
                            .font(.caption2.weight(.bold))
                            .tracking(1.4)
                            .foregroundStyle(WayPointTheme.cyanGlow)
                    }

                    Spacer()

                    Text(context.attributes.dayTitle)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(WayPointTheme.textSecondary)
                }

                // Center Hero Row
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.currentVenueName)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(WayPointTheme.textPrimary)
                            .lineLimit(1)

                        if !context.state.nextVenueName.isEmpty {
                            Text("Next up: \(context.state.nextVenueName) at \(context.state.nextVenueTime)")
                                .font(.caption)
                                .foregroundStyle(WayPointTheme.textSecondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("DISTANCE")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(WayPointTheme.textTertiary)

                        Text("\(context.state.distanceMeters)m ↗")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(WayPointTheme.cyanGlow)
                    }
                }

                Divider()
                    .overlay(WayPointTheme.glassBorder)

                // Footer Dual Metric Bar
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "banknote.fill")
                            .font(.caption2)
                            .foregroundStyle(WayPointTheme.cyanGlow)

                        Text("Spent \(context.state.spentAmount) / Rem. \(context.state.remainingAmount)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(WayPointTheme.textSecondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9, weight: .bold))
                        Text("Panic Pivot")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(WayPointTheme.obsidian)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(WayPointTheme.accentGradient, in: Capsule())
                }
            }
            .padding(16)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(WayPointTheme.glassBorder, lineWidth: 1)
        )
    }
}
