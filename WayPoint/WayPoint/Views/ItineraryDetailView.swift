//
//  ItineraryDetailView.swift
//  WayPoint
//

import SwiftUI

struct ItineraryDetailView: View {
    @Binding var item: ItineraryItem
    var onToggleCompletion: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var showInAppRouteSheet: Bool = false

    var body: some View {
        ZStack {
            WayPointTheme.oledBackground
                .ignoresSafeArea()
                .accessibilityHidden(true)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header Bar & Category Badge
                    headerSection

                    // Main Info Card
                    mainInfoCard

                    // Location / Address Section
                    locationSection

                    // Notes Section
                    if let notes = item.notes, !notes.isEmpty {
                        notesSection(notes: notes)
                    }

                    // Cost & 3% Fee Breakdown Card
                    priceBreakdownCard

                    // 1-Tap Apple Pay Checkout Button
                    applePayBookingButton

                    Spacer(minLength: 12)

                    // Completion Toggle CTA
                    completionToggleButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showInAppRouteSheet) {
            InAppRouteSheet(item: item)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(WayPointTheme.hairlineStroke)
                .frame(width: 36, height: 5)
                .accessibilityHidden(true)

            HStack {
                HStack(spacing: 6) {
                    Image(systemName: item.category.systemImage)
                        .font(.caption.weight(.bold))
                        .symbolRenderingMode(.hierarchical)
                    Text(item.category.displayName.uppercased())
                        .font(.caption.weight(.bold))
                        .tracking(1.2)
                }
                .foregroundStyle(WayPointTheme.sapphireAccent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(WayPointTheme.sapphireAccent.opacity(0.15), in: Capsule())
                .overlay(Capsule().strokeBorder(WayPointTheme.sapphireAccent.opacity(0.3), lineWidth: 1))

                if item.isPreservedReservation {
                    HStack(spacing: 3) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 9, weight: .bold))
                            .symbolRenderingMode(.hierarchical)
                        Text("PROTECTED")
                            .font(.system(size: 8.5, weight: .heavy, design: .monospaced))
                    }
                    .foregroundStyle(WayPointTheme.imperialGold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(WayPointTheme.imperialGold.opacity(0.18), in: Capsule())
                    .overlay(Capsule().strokeBorder(WayPointTheme.imperialGold.opacity(0.5), lineWidth: 1))
                }

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(WayPointTheme.textSecondary)
                }
                .buttonStyle(.scalePress)
                .accessibilityLabel("Close item details")
                .accessibilityHint("Dismisses the itinerary item detail sheet")
                .accessibilityAddTraits(.isButton)
            }
        }
    }

    // MARK: - Main Info Card

    private var mainInfoCard: some View {
        GlassCardView(
            cornerRadius: 16,
            padding: 20,
            glowColor: item.isCompleted ? WayPointTheme.emeraldRecovery : WayPointTheme.sapphireAccent
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(item.timeRange)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(WayPointTheme.sapphireAccent)

                    Spacer()

                    if item.isCompleted {
                        Text("✓ Completed & Paid")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(WayPointTheme.emeraldRecovery)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(WayPointTheme.emeraldRecovery.opacity(0.18), in: Capsule())
                            .overlay(Capsule().strokeBorder(WayPointTheme.emeraldRecovery.opacity(0.4), lineWidth: 1))
                    } else {
                        Text("\(item.durationMinutes) min")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(WayPointTheme.textTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(WayPointTheme.cardSurface, in: Capsule())
                    }
                }

                Text(item.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(WayPointTheme.textPrimary)
                    .strikethrough(item.isCompleted)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.8)

                Text(item.subtitle)
                    .font(.body)
                    .foregroundStyle(WayPointTheme.textSecondary)
            }
        }
    }

    // MARK: - Location Section

    private var locationSection: some View {
        GlassCardView(cornerRadius: 16, padding: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(WayPointTheme.sapphireAccent.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "mappin.and.ellipse")
                        .font(.body.weight(.semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(WayPointTheme.sapphireAccent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Location & Address")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WayPointTheme.textTertiary)

                    Text(item.location)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(WayPointTheme.textPrimary)
                }

                Spacer()

                Button(action: openInAppleMaps) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                            .font(.caption.weight(.bold))
                            .symbolRenderingMode(.hierarchical)
                        Text("Maps")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(WayPointTheme.sapphireAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(WayPointTheme.sapphireAccent.opacity(0.18), in: Capsule())
                    .overlay(Capsule().strokeBorder(WayPointTheme.sapphireAccent.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(.scalePress)
            }
        }
    }

    private func openInAppleMaps() {
        showInAppRouteSheet = true
    }

    // MARK: - Notes Section

    private func notesSection(notes: String) -> some View {
        GlassCardView(cornerRadius: 16, padding: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.caption.weight(.semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(WayPointTheme.emeraldRecovery)

                    Text("Co-Pilot Notes")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(WayPointTheme.textSecondary)
                }

                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(WayPointTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Cost & 3% Fee Breakdown Section

    private var priceBreakdownCard: some View {
        let baseCost = item.estimatedCost == 0 ? Decimal(45.0) : item.estimatedCost
        let (baseDec, feeDec, totalDec) = FeeEngine.calculate(basePrice: baseCost)

        return GlassCardView(cornerRadius: 16, padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("PRICING & PLATFORM COMMISSION")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .tracking(1.0)
                        .foregroundStyle(WayPointTheme.textSecondary)
                    Spacer()
                    Text("3% FEE ACTIVE")
                        .font(.system(size: 8.5, weight: .heavy, design: .monospaced))
                        .foregroundStyle(WayPointTheme.sapphireAccent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(WayPointTheme.sapphireAccent.opacity(0.15), in: Capsule())
                }

                VStack(spacing: 6) {
                    HStack {
                        Text("Ticket / Booking Subtotal")
                            .font(.subheadline)
                            .foregroundStyle(WayPointTheme.textSecondary)
                        Spacer()
                        Text(FeeEngine.format(amount: baseDec, currencyCode: item.currencyCode))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(WayPointTheme.textPrimary)
                    }

                    HStack {
                        Text("WayPoint Concierge & Auto-Sync (3%)")
                            .font(.subheadline)
                            .foregroundStyle(WayPointTheme.textSecondary)
                        Spacer()
                        Text("+\(FeeEngine.format(amount: feeDec, currencyCode: item.currencyCode))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(WayPointTheme.sapphireAccent)
                    }

                    Divider().overlay(WayPointTheme.hairlineStroke)

                    HStack {
                        Text("Total Charged")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(WayPointTheme.textPrimary)
                        Spacer()
                        Text(FeeEngine.format(amount: totalDec, currencyCode: item.currencyCode))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(WayPointTheme.emeraldRecovery)
                    }
                }
            }
        }
    }

    private var applePayBookingButton: some View {
        let baseCost = item.estimatedCost == 0 ? Decimal(45.0) : item.estimatedCost
        let (_, _, totalDec) = FeeEngine.calculate(basePrice: baseCost)
        let totalStr = FeeEngine.format(amount: totalDec, currencyCode: item.currencyCode)

        return Button(action: executeApplePayBooking) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title3.weight(.bold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(WayPointTheme.emeraldRecovery)
                Text("Confirm Pass Reservation (\(totalStr))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(WayPointTheme.hairlineStroke, lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.6), radius: 10, x: 0, y: 4)
            .sensoryFeedback(.impact(weight: .medium), trigger: item.isCompleted)
        }
        .buttonStyle(.scalePress)
        .accessibilityLabel("Confirm Pass Reservation for \(totalStr) with Apple Pay")
        .accessibilityHint("Double tap to confirm reservation and mark activity complete")
        .accessibilityAddTraits(.isButton)
    }

    private func executeApplePayBooking() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif

        withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.38, dampingFraction: 0.8)) {
            item.isCompleted = true
            onToggleCompletion?()
        }

        dismiss()
    }

    // MARK: - Completion Toggle Button

    private var completionToggleButton: some View {
        Button(action: toggleCompletion) {
            HStack(spacing: 10) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.bold))

                Text(item.isCompleted ? "Mark as Pending" : "Mark as Paid & Completed")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundColor(item.isCompleted ? WayPointTheme.textSecondary : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                if item.isCompleted {
                    WayPointTheme.cardSurface
                } else {
                    LinearGradient(
                        colors: [WayPointTheme.emeraldRecovery, WayPointTheme.sapphireAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        item.isCompleted ? WayPointTheme.hairlineStroke : Color.clear,
                        lineWidth: 1
                    )
            )
            .shadow(
                color: item.isCompleted ? Color.clear : WayPointTheme.emeraldRecovery.opacity(0.4),
                radius: 12, x: 0, y: 6
            )
        }
        .buttonStyle(.scalePress)
        .accessibilityLabel(item.isCompleted ? "Mark as Pending" : "Mark as Paid & Completed")
        .accessibilityValue(item.isCompleted ? "Completed" : "Not completed")
        .accessibilityAddTraits(.isButton)
    }

    private func toggleCompletion() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            item.isCompleted.toggle()
            onToggleCompletion?()
        }
    }
}

#Preview {
    ItineraryDetailView(
        item: .constant(
            ItineraryItem(
                title: "Boutique Hotel Breakfast",
                subtitle: "Artisan coffee & terrace dining",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                location: "Central Arts District",
                category: .dining,
                estimatedCost: 45
            )
        )
    )
}
