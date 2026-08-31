//
//  PanicPivotSheetView.swift
//  WayPoint
//
//  Task 4.1 / WP5: Panic Pivot UI & Visual Diff Integration
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct PanicPivotSheetView: View {
    @Environment(TripStore.self) private var tripStore
    var initialDisruption: DisruptionEvent? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var selectedType: DisruptionType = .weatherRain
    @State private var pivotResult: PivotResult? = nil
    @State private var isExecuting: Bool = false
    @State private var isRecovered: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var aiService = AIRecalculatorService.shared
    @State private var undoManager = UndoPivotManager.shared

    private var currentPlan: DayPlan {
        tripStore.currentDayPlan
    }

    var body: some View {
        ZStack {
            WayPointTheme.oledBackground
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack(spacing: 16) {
                // Header Bar & Drag Indicator
                headerSection

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 18) {
                        if isRecovered, let result = pivotResult {
                            // MARK: - SUCCESS VIEW (TRIP RECOVERED ✓)
                            tripRecoveredSuccessView(result: result)
                        } else {
                            // MARK: - 3-STEP REBUILD FLOW
                            // Disruption Selector / Context
                            disruptionSelectorSection

                            // Step 1: Disruption Context Card
                            step1DisruptionCard

                            // Step 2: Impact Breakdown (Red/Green/Gold)
                            step2ImpactBreakdownCard

                            // Step 3: WayPoint Plan (Re-balance Preview & CTAs)
                            if let result = pivotResult {
                                step3WayPointPlanCard(result: result)
                            } else if isExecuting {
                                loadingOptimizationCard
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }

                Spacer(minLength: 0)

                // Bottom Primary CTA Actions
                if isRecovered {
                    successBottomActions
                } else {
                    rebuildBottomAction
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showShareSheet) {
            StoryRecapView(trip: tripStore.activeTrip, dayPlan: currentPlan)
        }
        .onAppear {
            if let initial = initialDisruption {
                self.selectedType = initial.type
            }
            runPivotOptimization(for: selectedType)
        }
        .onChange(of: selectedType) { _, newType in
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
            runPivotOptimization(for: newType)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(WayPointTheme.hairlineStroke)
                .frame(width: 40, height: 5)
                .accessibilityHidden(true)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.caption.weight(.bold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(WayPointTheme.sapphireAccent)

                        Text("PANIC PIVOT ENGINE")
                            .font(.caption.weight(.bold))
                            .tracking(1.4)
                            .foregroundStyle(WayPointTheme.sapphireAccent)
                    }

                    Text(isRecovered ? "Trip Recovered ✓" : "3-Step Itinerary Rebuild")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(WayPointTheme.textPrimary)

                    Text(isRecovered ? "Schedule conflict neutralized. Protected reservations preserved." : "Zero-friction 1-tap re-balance preserving fixed reservations.")
                        .font(.caption)
                        .foregroundStyle(WayPointTheme.textSecondary)
                }

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(WayPointTheme.textSecondary)
                }
                .accessibilityLabel("Close Panic Pivot Sheet")
                .accessibilityHint("Dismisses the recovery solver")
                .accessibilityAddTraits(.isButton)
            }
        }
    }

    // MARK: - Disruption Selector Bar

    private var disruptionSelectorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DISRUPTION SCENARIO")
                .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                .tracking(1.2)
                .foregroundStyle(WayPointTheme.textTertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(DisruptionType.allCases) { type in
                        Button(action: { selectedType = type }) {
                            HStack(spacing: 6) {
                                Text(type.emoji)
                                    .font(.subheadline)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(type.badgeText)
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundStyle(selectedType == type ? .black : type.badgeColor)

                                    Text(type.title)
                                        .font(.caption2.weight(.semibold))
                                        .lineLimit(1)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedType == type ? type.badgeColor : WayPointTheme.cardSurface, in: Capsule())
                            .overlay(Capsule().strokeBorder(selectedType == type ? type.badgeColor : WayPointTheme.hairlineStroke, lineWidth: 1))
                            .foregroundStyle(selectedType == type ? .black : WayPointTheme.textPrimary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(type.badgeText): \(type.title)")
                        .accessibilityHint(selectedType == type ? "Currently selected disruption scenario" : "Double tap to select this disruption scenario")
                        .accessibilityAddTraits(selectedType == type ? [.isSelected, .isButton] : [.isButton])
                    }
                }
            }
        }
    }

    // MARK: - Step 1: Disruption Card

    private var step1DisruptionCard: some View {
        GlassCardView(
            cornerRadius: 18,
            padding: 16,
            glowColor: WayPointTheme.crimsonAlert
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text("STEP 1")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(WayPointTheme.crimsonAlert.opacity(0.2), in: Capsule())
                        .foregroundStyle(WayPointTheme.crimsonAlert)

                    Text("DISRUPTION DETECTED")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .tracking(1.2)
                        .foregroundStyle(WayPointTheme.crimsonAlert)

                    Spacer()

                    MetricPill(icon: "clock.fill", text: "+\(selectedType.estimatedTimeImpactMinutes)m impact", color: WayPointTheme.crimsonAlert)
                }

                HStack(spacing: 12) {
                    Image(systemName: disruptionSFIcon(for: selectedType))
                        .font(.title)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(WayPointTheme.crimsonAlert)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedType.title)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(WayPointTheme.textPrimary)

                        Text(disruptionRootCauseText(for: selectedType))
                            .font(.caption)
                            .foregroundStyle(WayPointTheme.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Step 2: Impact Breakdown (Red / Green / Gold)

    private var step2ImpactBreakdownCard: some View {
        GlassCardView(
            cornerRadius: 18,
            padding: 16,
            glowColor: WayPointTheme.imperialGold
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("STEP 2")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(WayPointTheme.imperialGold.opacity(0.2), in: Capsule())
                        .foregroundStyle(WayPointTheme.imperialGold)

                    Text("IMPACT BREAKDOWN")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .tracking(1.2)
                        .foregroundStyle(WayPointTheme.imperialGold)

                    Spacer()

                    Text("\(currentPlan.items.count) Total Stops")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(WayPointTheme.textTertiary)
                }

                VStack(spacing: 8) {
                    ForEach(currentPlan.items) { item in
                        impactItemRow(item: item)
                    }
                }
            }
        }
    }

    private func impactItemRow(item: ItineraryItem) -> some View {
        let isBroken = isItemDisruptedBySelectedScenario(item)
        let isProtected = item.isPreservedReservation

        let statusColor: Color = isProtected ? WayPointTheme.imperialGold : (isBroken ? WayPointTheme.crimsonAlert : WayPointTheme.emeraldRecovery)
        let statusTitle: String = isProtected ? "Protected Reservation" : (isBroken ? "Broken / Impossible" : "Unaffected")
        let iconName: String = isProtected ? "lock.shield.fill" : (isBroken ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")

        return HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.subheadline.weight(.bold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(statusColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WayPointTheme.textPrimary)
                    .lineLimit(1)

                Text("\(item.timeRange) • \(item.isIndoor ? "Indoor" : "Outdoor")")
                    .font(.caption2)
                    .foregroundStyle(WayPointTheme.textSecondary)
            }

            Spacer()

            if isProtected {
                HStack(spacing: 3) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8, weight: .bold))
                    Text("🔒 PROTECTED")
                        .font(.system(size: 8.5, weight: .heavy, design: .monospaced))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(WayPointTheme.imperialGold.opacity(0.2), in: Capsule())
                .foregroundStyle(WayPointTheme.imperialGold)
            } else {
                Text(statusTitle)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor.opacity(0.18), in: Capsule())
                    .foregroundStyle(statusColor)
            }
        }
        .padding(10)
        .background(WayPointTheme.cardSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(statusColor.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Step 3: WayPoint Plan Card

    private func step3WayPointPlanCard(result: PivotResult) -> some View {
        let diff = result.diffReport
        let timeText = diff != nil ? "+\(diff!.timeImpactMinutes)m delay" : result.formattedTimeRecovered
        let passText = diff != nil ? "\(diff!.preservedReservationsCount) passes kept" : "100% passes kept"

        return GlassCardView(
            cornerRadius: 18,
            padding: 16,
            glowColor: WayPointTheme.sapphireAccent
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text("STEP 3")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(WayPointTheme.sapphireAccent.opacity(0.2), in: Capsule())
                        .foregroundStyle(WayPointTheme.sapphireAccent)

                    Text("WAYPOINT RECOVER PLAN")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .tracking(1.2)
                        .foregroundStyle(WayPointTheme.sapphireAccent)
                }

                Text(diff?.explanationSummary ?? "All schedule conflicts resolved gracefully preserving fixed reservations.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(WayPointTheme.textPrimary)

                HStack(spacing: 8) {
                    MetricPill(icon: "clock.fill", text: timeText, color: WayPointTheme.sapphireAccent)
                    MetricPill(icon: "shield.fill", text: passText, color: WayPointTheme.emeraldRecovery)
                }

                if let replacements = diff?.replacedItems, !replacements.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("EXACT VENUE SWAPS (<2.5KM)")
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(WayPointTheme.textTertiary)

                        ForEach(replacements) { rep in
                            HStack(spacing: 6) {
                                Text("❌ \(rep.original.title)")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(WayPointTheme.crimsonAlert)
                                    .strikethrough()

                                Image(systemName: "arrow.right")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(WayPointTheme.sapphireAccent)

                                Text("✓ \(rep.replacement.title)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(WayPointTheme.emeraldRecovery)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(WayPointTheme.cardSurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }
            }
        }
    }

    private var loadingOptimizationCard: some View {
        GlassCardView(
            cornerRadius: 18,
            padding: 16,
            glowColor: WayPointTheme.sapphireAccent
        ) {
            HStack(spacing: 14) {
                ProgressView()
                    .tint(WayPointTheme.sapphireAccent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("WAYPOINT RE-BALANCE ENGINE ACTIVE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(WayPointTheme.sapphireAccent)

                    Text("Solving indoor venue swaps & timeline bounds...")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(WayPointTheme.textPrimary)
                }
                Spacer()
            }
        }
    }

    // MARK: - Success View Component ("TRIP RECOVERED ✓")

    private func tripRecoveredSuccessView(result: PivotResult) -> some View {
        VStack(spacing: 16) {
            GlassCardView(
                cornerRadius: 20,
                padding: 18,
                glowColor: WayPointTheme.emeraldRecovery
            ) {
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(WayPointTheme.emeraldRecovery.opacity(0.2))
                            .frame(width: 54, height: 54)

                        Image(systemName: "sparkles")
                            .font(.title.weight(.bold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(WayPointTheme.emeraldRecovery)
                    }

                    VStack(spacing: 4) {
                        Text("TRIP RECOVERED ✓")
                            .font(.system(size: 20, weight: .heavy, design: .monospaced))
                            .tracking(1.4)
                            .foregroundStyle(WayPointTheme.emeraldRecovery)

                        Text("Schedule neutralized with zero reservation friction")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(WayPointTheme.textSecondary)
                    }

                    HStack(spacing: 10) {
                        MetricPill(icon: "clock.fill", text: result.formattedTimeRecovered, color: WayPointTheme.emeraldRecovery)
                        MetricPill(icon: "lock.shield.fill", text: "100% Passes Kept", color: WayPointTheme.imperialGold)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            // Before ❌ vs After ✓ Diff Comparison
            diffPreviewSection(result: result)
        }
    }

    // MARK: - Live Diff Section (Before ❌ vs After ✓)

    private func diffPreviewSection(result: PivotResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("BEFORE ❌ vs AFTER ✓ TIMELINE")
                    .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(WayPointTheme.textTertiary)

                Spacer()

                Text("\(result.rebalancedPlan.items.count) Stops Re-balanced")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(WayPointTheme.textSecondary)
            }

            VStack(spacing: 8) {
                ForEach(Array(zip(result.previousPlan.items.indices, result.previousPlan.items)), id: \.1.id) { index, oldItem in
                    if index < result.rebalancedPlan.items.count {
                        let newItem = result.rebalancedPlan.items[index]
                        diffCardRow(oldItem: oldItem, newItem: newItem)
                    }
                }
            }
        }
    }

    private func diffCardRow(oldItem: ItineraryItem, newItem: ItineraryItem) -> some View {
        let isModified = oldItem.title != newItem.title || oldItem.startTime != newItem.startTime

        return GlassCardView(
            cornerRadius: 14,
            padding: 12,
            glowColor: isModified ? WayPointTheme.emeraldRecovery.opacity(0.4) : Color.clear
        ) {
            if !isModified {
                HStack {
                    Text(newItem.timeRange)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(WayPointTheme.textTertiary)

                    Text(newItem.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(WayPointTheme.textSecondary)

                    Spacer()

                    if newItem.isPreservedReservation {
                        Text("🔒 Fixed Pass ✓")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(WayPointTheme.imperialGold)
                    } else {
                        Text("Unchanged")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(WayPointTheme.textTertiary)
                    }
                }
            } else {
                HStack(alignment: .center, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("BEFORE")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(WayPointTheme.crimsonAlert)

                            Text(oldItem.originalTimeSlot ?? oldItem.timeRange)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(WayPointTheme.textTertiary)
                                .strikethrough()
                        }

                        Text(oldItem.title)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(WayPointTheme.textTertiary)
                            .strikethrough()
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(WayPointTheme.emeraldRecovery)

                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(newItem.timeRange)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(WayPointTheme.emeraldRecovery)

                            Text("AFTER ✓")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(WayPointTheme.emeraldRecovery)
                        }

                        Text(newItem.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(WayPointTheme.textPrimary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Bottom Actions

    private var rebuildBottomAction: some View {
        Button(action: applyRebalance) {
            HStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                    .font(.headline.weight(.bold))

                Text("[ ⚡ REBUILD MY DAY ]")
                    .font(.system(size: 17, weight: .heavy, design: .monospaced))
                    .tracking(0.8)
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
            .shadow(color: WayPointTheme.sapphireAccent.opacity(0.5), radius: 14, x: 0, y: 6)
            .sensoryFeedback(.impact(weight: .heavy), trigger: isRecovered)
        }
        .disabled(pivotResult == nil || isExecuting)
        .buttonStyle(.plain)
        .accessibilityLabel("Rebuild My Day Panic Pivot")
        .accessibilityHint("Applies itinerary re-balance algorithm to neutralize disruptions")
        .accessibilityAddTraits(.isButton)
    }

    private var successBottomActions: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Text("[ Done ]")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(WayPointTheme.emeraldRecovery, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: { showShareSheet = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up.fill")
                            .font(.caption.weight(.bold))
                        Text("[ Share Recovery ]")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(WayPointTheme.sapphireAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(WayPointTheme.sapphireAccent.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(WayPointTheme.sapphireAccent.opacity(0.5), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            if undoManager.canUndo(dayID: currentPlan.id) {
                Button(action: handleUndo) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.caption.weight(.bold))
                        Text("Undo Last Pivot")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(WayPointTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helper Utilities

    private func disruptionSFIcon(for type: DisruptionType) -> String {
        switch type {
        case .weatherRain: return "cloud.rain.fill"
        case .transitDelay: return "tram.fill"
        case .flightDelay: return "airplane.departure"
        case .attractionClosure: return "exclamationmark.triangle.fill"
        case .scheduleDisruption: return "clock.badge.exclamationmark.fill"
        }
    }

    private func disruptionRootCauseText(for type: DisruptionType) -> String {
        switch type {
        case .weatherRain: return "Heavy rainfall forecasted. Outdoor walking stops compromised."
        case .transitDelay: return "Yamanote line suspended. Transit times expanded by +30m."
        case .flightDelay: return "Flight arrival delayed by 45 mins. Evening schedule shifted."
        case .attractionClosure: return "Emergency venue maintenance closure detected."
        case .scheduleDisruption: return "Schedule running behind estimated timeline bounds."
        }
    }

    private func isItemDisruptedBySelectedScenario(_ item: ItineraryItem) -> Bool {
        if item.isPreservedReservation { return false }
        switch selectedType {
        case .weatherRain: return !item.isIndoor
        case .transitDelay: return item.category == .transit || item.category == .transport || item.durationMinutes > 60
        case .flightDelay: return item.title.contains("Flight") || item.category == .transit || item.category == .transport
        case .attractionClosure: return item.title.contains("Garden") || item.title.contains("Tower") || item.title.contains("Park")
        case .scheduleDisruption: return item.durationMinutes > 90
        }
    }


    private func runPivotOptimization(for type: DisruptionType) {
        isExecuting = true
        Task {
            let result = await aiService.executePanicPivot(currentPlan: currentPlan, disruptionType: type)
            withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)) {
                self.pivotResult = result
                self.isExecuting = false
            }
        }
    }

    private func applyRebalance() {
        guard let result = pivotResult else { return }
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif

        withAnimation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.8)) {
            tripStore.commitPivot(result, dayID: currentPlan.id)
            self.isRecovered = true
        }
    }

    private func handleUndo() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        if tripStore.undoLastPivot(for: currentPlan.id) != nil {
            withAnimation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.8)) {
                self.isRecovered = false
            }
            dismiss()
        }
    }
}


// MARK: - Metric Pill View Helper

struct MetricPill: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(color)

            Text(text)
                .font(.system(size: 9.5, weight: .bold))
                .foregroundStyle(WayPointTheme.textPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12), in: Capsule())
        .overlay(Capsule().strokeBorder(color.opacity(0.3), lineWidth: 1))
    }
}
