//
//  HomeView.swift
//  WayPoint
//

import SwiftUI

struct HomeView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(SupabaseService.self) private var supabaseService
    @Environment(TripStore.self) private var tripStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var aiService = AIRecalculatorService()
    @State private var locationService = LocationService.shared
    @State private var liveActivityManager = LiveActivityManager.shared
    @State private var undoManager = UndoPivotManager.shared

    @State private var activeDisruption: DisruptionEvent? = nil
    @State private var showDemoToolbar: Bool = true

    @State private var selectedItemID: UUID?
    @State private var detailItem: ItineraryItem? = nil
    @State private var routeItem: ItineraryItem? = nil
    @State private var showPaywall = false
    @State private var showRecalculateSheet = false
    @State private var showSocialImportSheet = false
    @State private var showSharePulseSheet = false
    @State private var showCameraScannerSheet = false

    private var trip: Trip { tripStore.activeTrip }

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
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    daySelectorSection

                    // Post-Pivot Success Banner on Home (when undo snapshot available for current day)
                    if undoManager.canUndo(for: currentDayPlan.id) {
                        postPivotConfirmationBanner
                    }

                    // Hero Disruption Recovery Banner & Panic Pivot CTA (Day 1 context sensitive)
                    TripAtRiskCard(
                        currentPlan: currentDayPlan,
                        activeDisruption: trip.selectedDayIndex == 0 ? activeDisruption : nil,
                        onTapPanicPivot: {
                            showRecalculateSheet = true
                        },
                        onSelectDisruption: { type in
                            activeDisruption = DisruptionEvent(type: type)
                        }
                    )

                    timelineSection

                    Color.clear
                        .frame(height: 120)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .scrollContentBackground(.hidden)
            .safeAreaInset(edge: .top) {
                VStack(spacing: 8) {
#if DEBUG
                    if showDemoToolbar {
                        ShipatonDemoToolbar(
                            activeDisruption: $activeDisruption,
                            isVisible: $showDemoToolbar,
                            onTriggerPivotSheet: {
                                showRecalculateSheet = true
                            },
                            onResetNominal: {
                                tripStore.resetStoreWithFreshSample()
                            }
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                    }
#endif

                    if liveActivityManager.isActivityActive {
                        simulatedDynamicIslandPill
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .padding(.top, 4)
                    }
                }
                .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: showDemoToolbar)
                .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: liveActivityManager.isActivityActive)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            floatingRecalculateFAB
                .padding(.bottom, 80)
                .allowsHitTesting(true)
        }
        .background(Color.clear)
        .preferredColorScheme(.dark)
        .task { await tripStore.loadRemoteTripIfNoLocalState() }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showRecalculateSheet) {
            PanicPivotSheetView(
                initialDisruption: activeDisruption
            )
        }
        .sheet(isPresented: $showSocialImportSheet) {
            SocialImportView()
        }
        .sheet(isPresented: $showSharePulseSheet) {
            StoryRecapView(trip: trip, dayPlan: currentDayPlan)
        }
        .sheet(isPresented: $showCameraScannerSheet) {
            CameraScannerView(dayPlan: currentDayPlanBinding, baseCurrencyCode: trip.currencyCode)
        }
        .sheet(item: $detailItem) { item in
            ItineraryDetailView(
                item: bindingForDetailItem(item)
            )
        }
        .sheet(item: $routeItem) { item in
            InAppRouteSheet(item: item)
        }
    }

    // MARK: - Post-Pivot Confirmation Banner

    private var postPivotConfirmationBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.green)

            VStack(alignment: .leading, spacing: 1) {
                Text("TRIP RECOVERED ✓")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Color.green)

                Text(undoManager.lastResult(for: currentDayPlan.id)?.formattedTimeRecovered ?? "Schedule optimized")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(WayPointTheme.textPrimary)
            }

            Spacer()

            Button(action: {
                withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.4, dampingFraction: 0.8)) {
                    _ = tripStore.undoLastPivot(for: currentDayPlan.id)
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.caption2.weight(.bold))
                    Text("Undo")
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(WayPointTheme.cyanGlow)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(WayPointTheme.cyanGlow.opacity(0.18), in: Capsule())
                .overlay(Capsule().strokeBorder(WayPointTheme.cyanGlow.opacity(0.5), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Undo schedule optimization")
            .accessibilityHint("Restores schedule prior to the last panic pivot")
            .accessibilityAddTraits(.isButton)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.green.opacity(0.4), lineWidth: 1))
        .transition(.scale.combined(with: .opacity))
        .accessibilityElement(children: .contain)
    }

    // MARK: - Dynamic Island Overlay Pill

    private var simulatedDynamicIslandPill: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 7, height: 7)
                    .shadow(color: .green, radius: 4)

                Text(liveActivityManager.activeVenueName.isEmpty ? "Shibuya Crossing" : liveActivityManager.activeVenueName)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "location.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(WayPointTheme.cyanGlow)

                Text("\(liveActivityManager.activeVenueDistance)m")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(WayPointTheme.cyanGlow)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(width: 220)
        .background(Color.black.opacity(0.92), in: Capsule())
        .overlay(Capsule().strokeBorder(WayPointTheme.cyanGlow.opacity(0.6), lineWidth: 1.5))
        .shadow(color: WayPointTheme.cyanGlow.opacity(0.4), radius: 10, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Dynamic Island Radar: \(liveActivityManager.activeVenueName.isEmpty ? "Shibuya Crossing" : liveActivityManager.activeVenueName), distance \(liveActivityManager.activeVenueDistance) meters")
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        Color.clear
    }

    private var displayTravelerName: String {
        if let email = supabaseService.currentUserEmail, !email.isEmpty {
            let prefix = email.components(separatedBy: "@").first ?? ""
            let lettersOnly = prefix.components(separatedBy: CharacterSet.letters.inverted).joined()
            if lettersOnly.lowercased().hasPrefix("yuvraj") {
                return "Yuvraj"
            }
            if !lettersOnly.isEmpty {
                return lettersOnly.prefix(1).uppercased() + lettersOnly.dropFirst()
            }
        }
        if !trip.travelerName.isEmpty && trip.travelerName != "Alex Vance" && trip.travelerName != "Traveler" {
            return trip.travelerName
        }
        return "Yuvraj"
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(greeting), \(displayTravelerName)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(WayPointTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .layoutPriority(1)

                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption2.weight(.semibold))
                        Text(locationService.currentCityCountry == "Detecting location..." ? (trip.destination.isEmpty ? "Tokyo, Japan" : trip.destination) : locationService.currentCityCountry)
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(WayPointTheme.sapphireAccent)
                }

                Spacer()

                HStack(spacing: 6) {
                    liveActivityPill

                    Button(action: { showSocialImportSheet = true }) {
                        HStack(spacing: 3) {
                            Image(systemName: "link.badge.plus")
                                .font(.caption2.weight(.bold))
                            Text("IMPORT")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .lineLimit(1)
                        }
                        .foregroundStyle(WayPointTheme.sapphireAccent)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 7)
                        .background(WayPointTheme.sapphireAccent.opacity(0.18), in: Capsule())
                        .overlay(Capsule().strokeBorder(WayPointTheme.sapphireAccent.opacity(0.4), lineWidth: 1))
                    }
                    .buttonStyle(.scalePress)

                    Button(action: { showPaywall = true }) {
                        proBadge
                    }
                    .buttonStyle(.scalePress)
                }
                .fixedSize(horizontal: true, vertical: false)
            }

            if liveActivityManager.isActivityActive {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text(DeviceHardware.liveActivityDisplayLabel)
                        .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Color.green)
                }
            }
        }
    }

    private var liveActivityPill: some View {
        Button(action: toggleLiveActivity) {
            HStack(spacing: 4) {
                Image(systemName: liveActivityManager.isActivityActive ? "location.fill" : "location.circle")
                    .font(.caption2.weight(.bold))
                Text(liveActivityManager.isActivityActive ? "LIVE" : "START LIVE")
                    .font(.caption2.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(liveActivityManager.isActivityActive ? WayPointTheme.cyanGlow : WayPointTheme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                liveActivityManager.isActivityActive
                    ? WayPointTheme.cyanGlow.opacity(0.2)
                    : WayPointTheme.obsidianElevated,
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        liveActivityManager.isActivityActive
                            ? WayPointTheme.cyanGlow
                            : WayPointTheme.glassBorder,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(liveActivityManager.isActivityActive ? "Live Activity Active" : "Start Live Activity")
        .accessibilityHint(liveActivityManager.isActivityActive ? "Double tap to end Live Activity radar" : "Double tap to start Dynamic Island Live Activity radar")
        .accessibilityAddTraits(liveActivityManager.isActivityActive ? [.isSelected, .isButton] : [.isButton])
    }

    private func toggleLiveActivity() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        if liveActivityManager.isActivityActive {
            liveActivityManager.endTripActivity()
        } else {
            let activeItem = currentDayPlan.items.first(where: { !$0.isCompleted }) ?? currentDayPlan.items.first ?? ItineraryItem(title: "Hotel Check-in", subtitle: "", startTime: Date(), endTime: Date(), location: "Tokyo", category: .stay, estimatedCost: 0)
            let nextItem = currentDayPlan.items.first(where: { $0.id != activeItem.id && !$0.isCompleted })
            liveActivityManager.startTripActivity(trip: trip, currentItem: activeItem, nextItem: nextItem)
        }
    }

    private var proBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.caption2.weight(.bold))
            Text(subscriptionManager.isProMember ? "PRO" : "GET PRO")
                .font(.caption2.weight(.heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundStyle(WayPointTheme.obsidian)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(WayPointTheme.accentGradient, in: Capsule())
    }

    // MARK: - Day Selector Bar

    private var daySelectorSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(trip.days.enumerated()), id: \.element.id) { index, day in
                    Button(action: {
                        #if canImport(UIKit)
                        UISelectionFeedbackGenerator().selectionChanged()
                        #endif
                        withAnimation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.8)) {
                            tripStore.selectDay(index)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text("Day \(index + 1)")
                                .font(.caption.weight(.bold))

                            if trip.selectedDayIndex == index {
                                Circle()
                                    .fill(WayPointTheme.sapphireAccent)
                                    .frame(width: 5, height: 5)
                            }
                        }
                        .foregroundStyle(
                            trip.selectedDayIndex == index
                                ? WayPointTheme.sapphireAccent
                                : WayPointTheme.textSecondary
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            trip.selectedDayIndex == index
                                ? WayPointTheme.sapphireAccent.opacity(0.18)
                                : WayPointTheme.cardSurface,
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    trip.selectedDayIndex == index
                                        ? WayPointTheme.sapphireAccent
                                        : WayPointTheme.hairlineStroke,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.scalePress)
                    .accessibilityLabel("Day \(index + 1)")
                    .accessibilityHint(trip.selectedDayIndex == index ? "Currently active day plan" : "Double tap to view Day \(index + 1) schedule")
                    .accessibilityAddTraits(trip.selectedDayIndex == index ? [.isSelected, .isButton] : [.isButton])
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
    }

    private func formattedDayTitle(for day: DayPlan, index: Int) -> String {
        let dayHeader = "Day \(index + 1)"
        let rawTitle = day.title.trimmingCharacters(in: .whitespacesAndNewlines)

        if rawTitle.isEmpty || rawTitle.lowercased() == dayHeader.lowercased() || rawTitle.lowercased() == "day plan" {
            return "Schedule"
        }

        if rawTitle.lowercased().hasPrefix("\(dayHeader.lowercased()):") {
            let stripped = rawTitle.dropFirst("\(dayHeader):".count).trimmingCharacters(in: .whitespacesAndNewlines)
            return stripped.isEmpty ? "Schedule" : stripped
        }

        if rawTitle.lowercased().hasPrefix("\(dayHeader.lowercased()) -") {
            let stripped = rawTitle.dropFirst("\(dayHeader) -".count).trimmingCharacters(in: .whitespacesAndNewlines)
            return stripped.isEmpty ? "Schedule" : stripped
        }

        if rawTitle.lowercased().hasPrefix(dayHeader.lowercased()) {
            let stripped = rawTitle.dropFirst(dayHeader.count).trimmingCharacters(in: .whitespacesAndNewlines)
            return stripped.isEmpty ? "Schedule" : stripped
        }

        return rawTitle
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
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Spacer()

                    HStack(spacing: 10) {
                        Button(action: { showCameraScannerSheet = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "camera.viewfinder")
                                    .font(.caption2.weight(.bold))
                                Text("SCAN")
                                    .font(.caption2.weight(.heavy))
                            }
                            .foregroundStyle(WayPointTheme.cyanGlow)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(WayPointTheme.cyanGlow.opacity(0.18), in: Capsule())
                            .overlay(
                                Capsule().strokeBorder(WayPointTheme.cyanGlow.opacity(0.5), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        budgetRing
                    }
                }

                ViewThatFits(in: .horizontal) {
                    HStack {
                        budgetStat(label: "Spent", value: currentDayPlan.formatCurrency(currentDayPlan.spentAmount), color: budgetStatusColor)
                        Spacer()
                        budgetStat(label: "Remaining", value: currentDayPlan.formattedRemaining, color: WayPointTheme.textPrimary)
                        Spacer()
                        budgetStat(label: "Limit", value: currentDayPlan.formatCurrency(currentDayPlan.budgetLimit), color: WayPointTheme.textSecondary)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        budgetStat(label: "Spent", value: currentDayPlan.formatCurrency(currentDayPlan.spentAmount), color: budgetStatusColor)
                        budgetStat(label: "Remaining", value: currentDayPlan.formattedRemaining, color: WayPointTheme.textPrimary)
                        budgetStat(label: "Limit", value: currentDayPlan.formatCurrency(currentDayPlan.budgetLimit), color: WayPointTheme.textSecondary)
                    }
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
                            .animation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.5, dampingFraction: 0.8), value: currentDayPlan.spentAmount)
                    }
                }
                .frame(height: 6)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Budget progress: \(currentDayPlan.formatCurrency(currentDayPlan.spentAmount)) spent of \(currentDayPlan.formatCurrency(currentDayPlan.budgetLimit)) daily limit")
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
                .animation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.5), value: currentDayPlan.spentAmount)

            VStack(spacing: 0) {
                Text("\(Int(min(currentDayPlan.budgetProgress, 1.0) * 100))%")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(WayPointTheme.textPrimary)
                    .minimumScaleFactor(0.8)

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
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    // MARK: - Timeline Section

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Day Schedule")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(WayPointTheme.textPrimary)

                    Text("\(currentDayPlan.items.filter(\.isCompleted).count)/\(currentDayPlan.items.count) completed")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(WayPointTheme.textSecondary)
                }

                Spacer()

                Button(action: { showSocialImportSheet = true }) {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.caption2.weight(.bold))
                        Text("Import / Paste Link")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(WayPointTheme.cyanGlow)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(WayPointTheme.cyanGlow.opacity(0.18), in: Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(WayPointTheme.cyanGlow.opacity(0.5), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            LazyVStack(spacing: 0) {
                ForEach(Array(currentDayPlan.items.enumerated()), id: \.element.id) { index, item in
                    TimelineCard(
                        item: item,
                        isFirst: index == 0,
                        isLast: index == currentDayPlan.items.count - 1,
                        isSelected: selectedItemID == item.id,
                        onTap: { detailItem = item },
                        onToggleComplete: { toggleItemCompletion(item) },
                        onOpenRoute: { targetItem in routeItem = targetItem }
                    )
                }
            }
        }
    }

    // MARK: - Floating Action Bar

    private var floatingRecalculateFAB: some View {
        let isDisrupted = (trip.selectedDayIndex == 0 && activeDisruption != nil)

        return Group {
            if isDisrupted {
                Button(action: {
                    showRecalculateSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.body.weight(.bold))

                        Text("⚡ Fix My Day Plan")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [WayPointTheme.crimsonAlert, WayPointTheme.imperialGold],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
                    .shadow(color: WayPointTheme.crimsonAlert.opacity(0.4), radius: 12, x: 0, y: 4)
                }
                .buttonStyle(.scalePress)
                .accessibilityLabel("Fix My Day Plan")
                .accessibilityHint("Opens panic pivot sheet to resolve schedule disruption")
            } else {
                Button(action: {
                    showRecalculateSheet = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(WayPointTheme.emeraldRecovery)

                        Text("✓ Trip is Optimized")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(WayPointTheme.textPrimary)

                        Spacer()

                        Text("Re-balance")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(WayPointTheme.sapphireAccent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(WayPointTheme.sapphireAccent.opacity(0.18), in: Capsule())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(WayPointTheme.cardSurface, in: Capsule())
                    .overlay(Capsule().strokeBorder(WayPointTheme.emeraldRecovery.opacity(0.4), lineWidth: 1))
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(.scalePress)
                .accessibilityLabel("Trip is Optimized")
                .accessibilityHint("Double tap to re-balance schedule")
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Helper Actions & Bindings

    private func toggleItemCompletion(_ item: ItineraryItem) {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            tripStore.toggleItemCompletion(itemID: item.id)
        }
    }

    private func bindingForDetailItem(_ targetItem: ItineraryItem) -> Binding<ItineraryItem> {
        Binding(
            get: {
                trip.days[trip.selectedDayIndex].items.first(where: { $0.id == targetItem.id }) ?? targetItem
            },
            set: { updatedItem in
                tripStore.updateItem(updatedItem)
            }
        )
    }

    private var currentDayPlanBinding: Binding<DayPlan> {
        Binding(
            get: { tripStore.currentDayPlan },
            set: { tripStore.updateDayPlan($0, reason: "day plan update") }
        )
    }
}

// MARK: - Timeline Card Component with Press Feedback & Rich Venue Metadata

private struct TimelineCard: View {
    let item: ItineraryItem
    let isFirst: Bool
    let isLast: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onToggleComplete: () -> Void
    var onOpenRoute: ((ItineraryItem) -> Void)? = nil

    @State private var isPressed: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            timelineRail

            GlassCardView(
                cornerRadius: 18,
                padding: 14,
                glowColor: item.isCompleted ? WayPointTheme.emeraldRecovery : WayPointTheme.sapphireAccent
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    // Header Row: Time range + Indoor Pill + Protected Pill + Checkmark
                    HStack(alignment: .center) {
                        HStack(spacing: 6) {
                            Text(item.timeRange)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(WayPointTheme.sapphireAccent)

                            Text(item.isIndoor ? "🏛️ Indoor" : "☀️ Outdoor")
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(WayPointTheme.cardSurface, in: Capsule())
                                .foregroundStyle(WayPointTheme.textSecondary)

                            if item.isPreservedReservation {
                                HStack(spacing: 3) {
                                    Image(systemName: "lock.shield.fill")
                                        .font(.system(size: 9, weight: .bold))
                                        .symbolRenderingMode(.hierarchical)
                                    Text("PROTECTED")
                                        .font(.system(size: 8.5, weight: .heavy, design: .monospaced))
                                }
                                .foregroundStyle(WayPointTheme.imperialGold)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2.5)
                                .background(WayPointTheme.imperialGold.opacity(0.18), in: Capsule())
                                .overlay(Capsule().strokeBorder(WayPointTheme.imperialGold.opacity(0.5), lineWidth: 1))
                            }
                        }

                        Spacer()

                        Button(action: onToggleComplete) {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(
                                    item.isCompleted
                                        ? WayPointTheme.emeraldRecovery
                                        : WayPointTheme.textTertiary
                                )
                                .symbolEffect(.bounce, value: item.isCompleted)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(item.isCompleted ? "Mark incomplete" : "Mark complete")
                        .accessibilityAddTraits(.isButton)
                    }

                    // Content Row: Thumbnail Image + Details
                    Button(action: onTap) {
                        HStack(alignment: .top, spacing: 12) {
                            thumbnailImageView

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(WayPointTheme.textPrimary)
                                    .strikethrough(item.isCompleted)
                                    .lineLimit(2)

                                Text(item.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(WayPointTheme.textSecondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.scalePress)

                    // Footer Metadata Row: Left (Star Rating + Category) | Right (Price + Apple Maps Directions)
                    HStack(spacing: 8) {
                        // Left side: Rating & Category
                        HStack(spacing: 6) {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.orange)

                                Text(String(format: "%.1f", item.rating))
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(WayPointTheme.textPrimary)
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3.5)
                            .background(Color.orange.opacity(0.15), in: Capsule())

                            Text(item.category.displayName)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(WayPointTheme.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3.5)
                                .background(WayPointTheme.cardSurface, in: Capsule())
                        }

                        Spacer()

                        // Right side: Price & Apple Maps Button
                        HStack(spacing: 6) {
                            Text(item.priceTier)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(WayPointTheme.emeraldRecovery)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3.5)
                                .background(WayPointTheme.emeraldRecovery.opacity(0.15), in: Capsule())

                            Button(action: { openInAppleMaps(for: item) }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                        .font(.caption.weight(.bold))
                                        .symbolRenderingMode(.hierarchical)
                                    Text("Maps")
                                        .font(.caption2.weight(.bold))
                                }
                                .foregroundStyle(WayPointTheme.sapphireAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3.5)
                                .background(WayPointTheme.sapphireAccent.opacity(0.18), in: Capsule())
                                .overlay(Capsule().strokeBorder(WayPointTheme.sapphireAccent.opacity(0.4), lineWidth: 1))
                            }
                            .buttonStyle(.scalePress)
                        }
                    }
                }
            }
            .opacity(item.isCompleted ? 0.72 : 1.0)
        }
        .padding(.bottom, isLast ? 0 : 12)
    }

    private func openInAppleMaps(for item: ItineraryItem) {
        onOpenRoute?(item)
    }

    private var thumbnailImageView: some View {
        ZStack {
            if let photoURL = item.photoURL {
                AsyncImage(url: photoURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderImage
                    case .empty:
                        ZStack {
                            WayPointTheme.obsidianElevated
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(WayPointTheme.glassBorder, lineWidth: 1)
        )
    }

    private var placeholderImage: some View {
        ZStack {
            LinearGradient(
                colors: [WayPointTheme.obsidianElevated, WayPointTheme.obsidianSurface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: item.category.systemImage)
                .font(.title3.weight(.medium))
                .foregroundStyle(WayPointTheme.cyanGlow.opacity(0.7))
        }
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
