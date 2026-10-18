//
//  BudgetRebalanceSheet.swift
//  WayPoint
//
//  Native Apple HIG Budget Envelope Optimizer & Smart Cash Re-Distributor Sheet
//

import SwiftUI

public struct BudgetRebalanceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TripStore.self) private var tripStore

    @State private var transitLimit: Double
    @State private var stayLimit: Double
    @State private var foodLimit: Double
    @State private var activityLimit: Double
    @State private var isOptimized: Bool = false

    public init() {
        let activeTrip = TripStore.shared.activeTrip
        let dayPlan = activeTrip.currentDayPlan
        let total = Double(truncating: dayPlan.budgetLimit as NSDecimalNumber)
        _transitLimit = State(initialValue: total * 0.25)
        _stayLimit = State(initialValue: total * 0.35)
        _foodLimit = State(initialValue: total * 0.25)
        _activityLimit = State(initialValue: total * 0.15)
    }

    private var currentDayPlan: DayPlan {
        tripStore.activeTrip.currentDayPlan
    }

    private var totalBudgetLimit: Double {
        Double(truncating: currentDayPlan.budgetLimit as NSDecimalNumber)
    }

    private var totalSpent: Double {
        Double(truncating: currentDayPlan.spentAmount as NSDecimalNumber)
    }

    private var allocatedTotal: Double {
        transitLimit + stayLimit + foodLimit + activityLimit
    }

    private var remainingSurplus: Double {
        totalBudgetLimit - allocatedTotal
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                WayPointTheme.oledBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        // Header Summary Card
                        summaryHeaderCard

                        // Smart Re-Distribute Banner
                        smartRedistributeBanner

                        // Category Sliders
                        VStack(alignment: .leading, spacing: 18) {
                            Text("CATEGORY ENVELOPE ALLOCATIONS")
                                .font(.caption.weight(.bold))
                                .tracking(1.4)
                                .foregroundStyle(WayPointTheme.textTertiary)

                            envelopeSliderRow(
                                title: "Transit Envelope",
                                icon: "car.fill",
                                color: WayPointTheme.sapphireAccent,
                                value: $transitLimit
                            )

                            envelopeSliderRow(
                                title: "Stay Envelope",
                                icon: "bed.double.fill",
                                color: WayPointTheme.violetGlow,
                                value: $stayLimit
                            )

                            envelopeSliderRow(
                                title: "Dining & Food Envelope",
                                icon: "fork.knife",
                                color: WayPointTheme.imperialGold,
                                value: $foodLimit
                            )

                            envelopeSliderRow(
                                title: "Activities Envelope",
                                icon: "ticket.fill",
                                color: WayPointTheme.emeraldRecovery,
                                value: $activityLimit
                            )
                        }

                        // Apply Button
                        Button(action: applyOptimization) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.body.weight(.bold))
                                Text("Apply Budget Optimization")
                                    .font(.headline.weight(.bold))
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(WayPointTheme.accentGradient, in: RoundedRectangle(cornerRadius: 16))
                            .shadow(color: WayPointTheme.cyanGlow.opacity(0.4), radius: 12, x: 0, y: 4)
                        }
                        .buttonStyle(.scalePress)
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Budget Optimizer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(WayPointTheme.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var summaryHeaderCard: some View {
        GlassCardView(cornerRadius: 20, padding: 20, glowColor: WayPointTheme.cyanGlow) {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TOTAL DAY BUDGET")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(WayPointTheme.textTertiary)

                        Text(currentDayPlan.formatCurrency(currentDayPlan.budgetLimit))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(WayPointTheme.textPrimary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("TOTAL SPENT")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(WayPointTheme.textTertiary)

                        Text(currentDayPlan.formatCurrency(currentDayPlan.spentAmount))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(WayPointTheme.cyanGlow)
                    }
                }

                Divider().overlay(WayPointTheme.glassBorder)

                HStack {
                    Text("Unallocated Surplus:")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WayPointTheme.textSecondary)

                    Spacer()

                    Text(String(format: "$%.2f", max(0, remainingSurplus)))
                        .font(.caption.weight(.bold))
                        .fontDesign(.monospaced)
                        .foregroundStyle(remainingSurplus >= 0 ? WayPointTheme.emeraldRecovery : WayPointTheme.crimsonAlert)
                }
            }
        }
    }

    private var smartRedistributeBanner: some View {
        Button(action: smartRedistribute) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(WayPointTheme.emeraldRecovery.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.body.weight(.bold))
                        .foregroundStyle(WayPointTheme.emeraldRecovery)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto Smart Re-Distribute")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(WayPointTheme.textPrimary)

                    Text("Evenly balance remaining funds across active itinerary days.")
                        .font(.caption)
                        .foregroundStyle(WayPointTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WayPointTheme.emeraldRecovery)
            }
            .padding(14)
            .background(WayPointTheme.emeraldRecovery.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(WayPointTheme.emeraldRecovery.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func envelopeSliderRow(title: String, icon: String, color: Color, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(color)

                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(WayPointTheme.textPrimary)
                }

                Spacer()

                Text(String(format: "$%.0f", value.wrappedValue))
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
            }

            Slider(value: value, in: 0...max(100, totalBudgetLimit))
                .tint(color)
        }
        .padding(14)
        .background(WayPointTheme.obsidianSurface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(WayPointTheme.glassBorder, lineWidth: 1))
    }

    private func smartRedistribute() {
        Haptics.selection()
        let available = max(0, totalBudgetLimit - totalSpent)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            transitLimit = (totalSpent * 0.2) + (available * 0.25)
            stayLimit = (totalSpent * 0.3) + (available * 0.35)
            foodLimit = (totalSpent * 0.3) + (available * 0.25)
            activityLimit = (totalSpent * 0.2) + (available * 0.15)
            isOptimized = true
        }
    }

    private func applyOptimization() {
        _ = tripStore.rebalanceBudget()
        Haptics.notification(.success)
        dismiss()
    }
}

#Preview {
    BudgetRebalanceSheet()
        .environment(TripStore.shared)
}
