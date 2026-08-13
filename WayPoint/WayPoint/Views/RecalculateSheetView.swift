//
//  RecalculateSheetView.swift
//  WayPoint
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct RecalculateSheetView: View {
    @Binding var currentPlan: DayPlan
    @Environment(AIRecalculatorService.self) private var aiService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTrigger: RecalculationTrigger = .userPreference
    @State private var rotationAngle: Double = 0

    var body: some View {
        ZStack {
            WayPointTheme.obsidian
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Drag Indicator & Header
                headerSection

                // Trigger Selector Options Grid
                triggerOptionsGrid

                Spacer()

                // Live Progress / Status Banner with Glowing Micro-Animation
                if aiService.isRecalculating {
                    recalculatingStatusBanner
                }

                // CTA Button
                optimizeCTAButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(WayPointTheme.glassBorder)
                .frame(width: 36, height: 5)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(WayPointTheme.cyanGlow)

                        Text("AI CO-PILOT OPTIMIZER")
                            .font(.caption.weight(.bold))
                            .tracking(1.5)
                            .foregroundStyle(WayPointTheme.cyanGlow)
                    }

                    Text("Recalculate Itinerary")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(WayPointTheme.textPrimary)

                    Text("Select a trigger to re-balance your itinerary in real time.")
                        .font(.subheadline)
                        .foregroundStyle(WayPointTheme.textSecondary)
                }

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(WayPointTheme.textSecondary)
                }
                .disabled(aiService.isRecalculating)
            }
        }
    }

    // MARK: - Trigger Options Grid

    private var triggerOptionsGrid: some View {
        VStack(spacing: 12) {
            ForEach(RecalculationTrigger.allCases) { trigger in
                TriggerOptionCard(
                    trigger: trigger,
                    isSelected: selectedTrigger == trigger,
                    isDisabled: aiService.isRecalculating
                ) {
                    #if canImport(UIKit)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTrigger = trigger
                    }
                }
            }
        }
    }

    // MARK: - Live Status Banner with Animated Glowing Ring

    private var recalculatingStatusBanner: some View {
        GlassCardView(
            cornerRadius: 18,
            padding: 16,
            glowColor: WayPointTheme.cyanGlow
        ) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [WayPointTheme.cyanGlow, WayPointTheme.violetGlow, WayPointTheme.cyanGlow],
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 38, height: 38)
                        .rotationEffect(.degrees(rotationAngle))
                        .onAppear {
                            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                                rotationAngle = 360
                            }
                        }

                    Image(systemName: "sparkles")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(WayPointTheme.cyanGlow)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Optimization Active")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(WayPointTheme.cyanGlow)

                    Text(aiService.statusMessage.isEmpty ? "Checking satellite radar & pacing..." : aiService.statusMessage)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(WayPointTheme.textPrimary)
                }

                Spacer()
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - CTA Button

    private var optimizeCTAButton: some View {
        Button(action: handleOptimization) {
            HStack(spacing: 10) {
                if aiService.isRecalculating {
                    ProgressView()
                        .tint(.black)
                } else {
                    Image(systemName: selectedTrigger.icon)
                        .font(.body.weight(.bold))

                    Text("Optimize Itinerary Now")
                        .font(.headline.weight(.bold))
                }
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(WayPointTheme.accentGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: WayPointTheme.cyanGlow.opacity(0.35), radius: 12, x: 0, y: 6)
        }
        .disabled(aiService.isRecalculating)
    }

    // MARK: - Actions

    private func handleOptimization() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        Task {
            let updatedPlan = await aiService.recalculate(plan: currentPlan, trigger: selectedTrigger)
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentPlan = updatedPlan
            }
            dismiss()
        }
    }
}

// MARK: - Trigger Option Card Component

private struct TriggerOptionCard: View {
    let trigger: RecalculationTrigger
    let isSelected: Bool
    let isDisabled: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            GlassCardView(
                cornerRadius: 16,
                padding: 14,
                glowColor: isSelected ? WayPointTheme.cyanGlow : Color.clear
            ) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(isSelected ? WayPointTheme.cyanGlow.opacity(0.2) : WayPointTheme.obsidianSurface)
                            .frame(width: 42, height: 42)

                        Image(systemName: trigger.icon)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(isSelected ? WayPointTheme.cyanGlow : WayPointTheme.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(trigger.title)
                            .font(.headline)
                            .foregroundStyle(WayPointTheme.textPrimary)

                        Text(trigger.description)
                            .font(.caption)
                            .foregroundStyle(WayPointTheme.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? WayPointTheme.cyanGlow : WayPointTheme.textTertiary)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isSelected ? WayPointTheme.cyanGlow.opacity(0.6) : Color.clear,
                        lineWidth: 1.5
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

#Preview {
    RecalculateSheetView(currentPlan: .constant(DayPlan(date: Date(), title: "Day 1", budgetLimit: 500, spentAmount: 100, items: [])))
        .environment(AIRecalculatorService.shared)
}
