//
//  HomeView.swift
//  WayPoint
//

import SwiftUI

struct HomeView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager

    @State private var trip = Trip.empty
    @State private var aiService = AIRecalculatorService()
    @State private var locationService = LocationService.shared

    @State private var selectedItemID: UUID?
    @State private var detailItem: ItineraryItem? = nil
    @State private var showPaywall = false
    @State private var showRecalculateSheet = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }

    private var currentDayPlan: DayPlan {
        trip.currentDayPlan
    }

    private var budgetStatusColor: Color {
        if currentDayPlan.isOverBudget { return WayPointTheme.budgetOver }
        if currentDayPlan.budgetProgress > 0.85 { return WayPointTheme.budgetWarning }
        return WayPointTheme.budgetHealthy
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundLayer

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    daySelectorSection
                    budgetTrackerSection
                    timelineSection

                    Color.clear
                        .frame(height: 120)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            floatingRecalculateFAB
                .padding(.bottom, 92)
                .allowsHitTesting(true)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showRecalculateSheet) {
            RecalculateSheetView(currentPlan: $trip.currentDayPlan)
                .environment(aiService)
        }
        .sheet(item: $detailItem) { item in
            ItineraryDetailView(
                item: bindingForDetailItem(item),
                onToggleCompletion: {
                    updateSpentAmountForCurrentDay()
                }
            )
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            WayPointTheme.obsidian.opacity(0.72).ignoresSafeArea()

            Circle()
                .fill(WayPointTheme.cyanGlow.opacity(0.08))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(x: -120, y: -280)

            Circle()
                .fill(WayPointTheme.violetGlow.opacity(0.08))
                .frame(width: 360, height: 360)
                .blur(radius: 100)
                .offset(x: 140, y: 120)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(WayPointTheme.textSecondary)

                    Text(trip.travelerName)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(WayPointTheme.textPrimary)
                }

                Spacer()

                Button(action: { showPaywall = true }) {
                    proBadge
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.caption.weight(.semibold))
                Text(locationService.currentCityCountry == "Detecting location..." ? trip.destination : locationService.currentCityCountry)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(WayPointTheme.accentGradient)
        }
        .padding(.top, 16)
    }

    private var proBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.caption2.weight(.bold))
            Text(subscriptionManager.isProMember ? "PRO" : "GET PRO")
                .font(.caption2.weight(.heavy))
        }
        .foregroundStyle(WayPointTheme.obsidian)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(WayPointTheme.accentGradient, in: Capsule())
    }

    // MARK: - Day Selector Bar

    private var daySelectorSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(trip.days.enumerated()), id: \.element.id) { index, day in
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            trip.selectedDayIndex = index
                        }
                    }) {
                        VStack(spacing: 2) {
                            Text("Day \(index + 1)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(
                                    trip.selectedDayIndex == index
                                        ? WayPointTheme.cyanGlow
                                        : WayPointTheme.textTertiary
                                )

                            Text(day.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(
                                    trip.selectedDayIndex == index
                                        ? WayPointTheme.textPrimary
                                        : WayPointTheme.textSecondary
                                )
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            trip.selectedDayIndex == index
                                ? WayPointTheme.cyanGlow.opacity(0.18)
                                : WayPointTheme.obsidianElevated,
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    trip.selectedDayIndex == index
                                        ? WayPointTheme.cyanGlow.opacity(0.6)
                                        : WayPointTheme.glassBorder,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Budget Tracker

    private var budgetTrackerSection: some View {
        GlassCardView(glowColor: budgetStatusColor) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Day \(trip.selectedDayIndex + 1) Budget Pace")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(WayPointTheme.textSecondary)

                        Text(currentDayPlan.title)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(WayPointTheme.textPrimary)
                    }

                    Spacer()

                    budgetRing
                }

                HStack {
                    budgetStat(label: "Spent", value: currentDayPlan.formatCurrency(currentDayPlan.spentAmount), color: budgetStatusColor)
                    Spacer()
                    budgetStat(label: "Remaining", value: currentDayPlan.formattedRemaining, color: WayPointTheme.textPrimary)
                    Spacer()
                    budgetStat(label: "Limit", value: currentDayPlan.formatCurrency(currentDayPlan.budgetLimit), color: WayPointTheme.textSecondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(WayPointTheme.obsidianSurface)
                            .frame(height: 6)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [budgetStatusColor, budgetStatusColor.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * min(currentDayPlan.budgetProgress, 1.0), height: 6)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentDayPlan.spentAmount)
                    }
                }
                .frame(height: 6)
            }
        }
    }

    private var budgetRing: some View {
        ZStack {
            Circle()
                .stroke(WayPointTheme.obsidianSurface, lineWidth: 6)
                .frame(width: 68, height: 68)

            Circle()
                .trim(from: 0, to: min(currentDayPlan.budgetProgress, 1.0))
                .stroke(budgetStatusColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 68, height: 68)
                .animation(.spring(response: 0.5), value: currentDayPlan.spentAmount)

            VStack(spacing: 0) {
                Text("\(Int(min(currentDayPlan.budgetProgress, 1.0) * 100))%")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(WayPointTheme.textPrimary)

                Text("USED")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(WayPointTheme.textTertiary)
            }
        }
    }

    private func budgetStat(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(WayPointTheme.textTertiary)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
        }
    }

    // MARK: - Timeline Section

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Day Schedule")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(WayPointTheme.textPrimary)

                Spacer()

                Text("\(currentDayPlan.items.filter(\.isCompleted).count)/\(currentDayPlan.items.count) completed")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(WayPointTheme.textSecondary)
            }

            VStack(spacing: 0) {
                ForEach(Array(currentDayPlan.items.enumerated()), id: \.element.id) { index, item in
                    TimelineCard(
                        item: item,
                        isFirst: index == 0,
                        isLast: index == currentDayPlan.items.count - 1,
                        isSelected: selectedItemID == item.id
                    ) {
                        detailItem = item
                    } onToggleComplete: {
                        toggleItemCompletion(item)
                    }
                }
            }
        }
    }

    // MARK: - Floating Action Button (FAB)

    private var floatingRecalculateFAB: some View {
        Button(action: {
            if subscriptionManager.isProUser {
                showRecalculateSheet = true
            } else {
                showPaywall = true
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.body.weight(.bold))
                    .foregroundStyle(.black)
                    .rotationEffect(.degrees(aiService.isRecalculating ? 360 : 0))
                    .animation(
                        aiService.isRecalculating
                            ? .linear(duration: 1.2).repeatForever(autoreverses: false)
                            : .default,
                        value: aiService.isRecalculating
                    )

                Text(aiService.isRecalculating ? "Re-balancing..." : "AI Re-balance Itinerary")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(WayPointTheme.accentGradient, in: Capsule())
            .shadow(color: WayPointTheme.cyanGlow.opacity(0.5), radius: 12, x: 0, y: 4)
            .shadow(color: WayPointTheme.violetGlow.opacity(0.3), radius: 18, x: 0, y: 6)
        }
        .contentShape(Capsule())
        .buttonStyle(.plain)
    }

    // MARK: - Helper Actions & Bindings

    private func toggleItemCompletion(_ item: ItineraryItem) {
        guard let index = trip.days[trip.selectedDayIndex].items.firstIndex(where: { $0.id == item.id }) else { return }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            let willComplete = !trip.days[trip.selectedDayIndex].items[index].isCompleted
            trip.days[trip.selectedDayIndex].items[index].isCompleted = willComplete
            updateSpentAmountForCurrentDay()
        }
    }

    private func updateSpentAmountForCurrentDay() {
        let completedItems = trip.days[trip.selectedDayIndex].items.filter(\.isCompleted)
        trip.days[trip.selectedDayIndex].spentAmount = completedItems.reduce(Decimal(0)) { $0 + $1.estimatedCost }
    }

    private func bindingForDetailItem(_ targetItem: ItineraryItem) -> Binding<ItineraryItem> {
        Binding(
            get: {
                trip.days[trip.selectedDayIndex].items.first(where: { $0.id == targetItem.id }) ?? targetItem
            },
            set: { updatedItem in
                if let index = trip.days[trip.selectedDayIndex].items.firstIndex(where: { $0.id == updatedItem.id }) {
                    trip.days[trip.selectedDayIndex].items[index] = updatedItem
                }
            }
        )
    }
}

// MARK: - Timeline Card Component with Press Feedback

private struct TimelineCard: View {
    let item: ItineraryItem
    let isFirst: Bool
    let isLast: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onToggleComplete: () -> Void

    @State private var isPressed: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            timelineRail

            GlassCardView(
                cornerRadius: 18,
                padding: 16,
                glowColor: item.isCompleted ? WayPointTheme.violetGlow : WayPointTheme.cyanGlow
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.timeRange)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(WayPointTheme.cyanGlow)

                            Text(item.title)
                                .font(.headline)
                                .foregroundStyle(WayPointTheme.textPrimary)
                        }

                        Spacer()

                        Button(action: onToggleComplete) {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(
                                    item.isCompleted
                                        ? WayPointTheme.violetGlow
                                        : WayPointTheme.textTertiary
                                )
                                .symbolEffect(.bounce, value: item.isCompleted)
                        }
                        .buttonStyle(.plain)
                    }

                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundStyle(WayPointTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
            .opacity(item.isCompleted ? 0.72 : 1.0)
            .onTapGesture {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isPressed = false
                    onTap()
                }
            }
        }
        .padding(.bottom, isLast ? 0 : 12)
    }

    private var timelineRail: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(isFirst ? Color.clear : WayPointTheme.glassBorder)
                .frame(width: 2, height: 12)

            Circle()
                .fill(item.isCompleted ? WayPointTheme.violetGlow : WayPointTheme.cyanGlow)
                .frame(width: 10, height: 10)
                .shadow(color: (item.isCompleted ? WayPointTheme.violetGlow : WayPointTheme.cyanGlow).opacity(0.5), radius: 6)

            Rectangle()
                .fill(isLast ? Color.clear : WayPointTheme.glassBorder)
                .frame(width: 2)
                .frame(maxHeight: .infinity)
        }
        .frame(width: 10)
        .padding(.top, 4)
    }
}

#Preview {
    HomeView()
        .environment(SubscriptionManager.shared)
}