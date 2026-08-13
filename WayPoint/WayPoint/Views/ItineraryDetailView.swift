//
//  ItineraryDetailView.swift
//  WayPoint
//

import SwiftUI

struct ItineraryDetailView: View {
    @Binding var item: ItineraryItem
    var onToggleCompletion: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            WayPointTheme.obsidian
                .ignoresSafeArea()

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

                    // Cost Breakdown Card
                    costBreakdownSection

                    Spacer(minLength: 20)

                    // Completion Toggle CTA
                    completionToggleButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(WayPointTheme.glassBorder)
                .frame(width: 36, height: 5)

            HStack {
                HStack(spacing: 6) {
                    Image(systemName: item.category.systemImage)
                        .font(.caption.weight(.bold))
                    Text(item.category.displayName.uppercased())
                        .font(.caption.weight(.bold))
                        .tracking(1.2)
                }
                .foregroundStyle(WayPointTheme.cyanGlow)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(WayPointTheme.cyanGlow.opacity(0.15), in: Capsule())
                .overlay(Capsule().strokeBorder(WayPointTheme.cyanGlow.opacity(0.3), lineWidth: 1))

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(WayPointTheme.textSecondary)
                }
            }
        }
    }

    // MARK: - Main Info Card

    private var mainInfoCard: some View {
        GlassCardView(
            cornerRadius: 20,
            padding: 20,
            glowColor: item.isCompleted ? WayPointTheme.violetGlow : WayPointTheme.cyanGlow
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(item.timeRange)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(WayPointTheme.cyanGlow)

                    Spacer()

                    Text("\(item.durationMinutes) min")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(WayPointTheme.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(WayPointTheme.obsidianSurface, in: Capsule())
                }

                Text(item.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(WayPointTheme.textPrimary)

                Text(item.subtitle)
                    .font(.body)
                    .foregroundStyle(WayPointTheme.textSecondary)
            }
        }
    }

    // MARK: - Location Section

    private var locationSection: some View {
        GlassCardView(cornerRadius: 18, padding: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(WayPointTheme.cyanGlow.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "mappin.and.ellipse")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(WayPointTheme.cyanGlow)
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
            }
        }
    }

    // MARK: - Notes Section

    private func notesSection(notes: String) -> some View {
        GlassCardView(cornerRadius: 18, padding: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WayPointTheme.violetGlow)

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

    // MARK: - Cost Breakdown Section

    private var costBreakdownSection: some View {
        GlassCardView(cornerRadius: 18, padding: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Estimated Cost")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(WayPointTheme.textSecondary)

                    Text(item.formattedCost)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(WayPointTheme.cyanGlow)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Category")
                        .font(.caption)
                        .foregroundStyle(WayPointTheme.textTertiary)

                    Text(item.category.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(WayPointTheme.textPrimary)
                }
            }
        }
    }

    // MARK: - Completion Toggle Button

    private var completionToggleButton: some View {
        Button(action: toggleCompletion) {
            HStack(spacing: 10) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)

                Text(item.isCompleted ? "Completed" : "Mark as Completed")
                    .font(.headline.weight(.bold))
            }
            .foregroundColor(item.isCompleted ? .white : .black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                if item.isCompleted {
                    WayPointTheme.obsidianElevated
                } else {
                    WayPointTheme.accentGradient
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        item.isCompleted ? WayPointTheme.violetGlow.opacity(0.6) : Color.clear,
                        lineWidth: 1
                    )
            )
            .shadow(
                color: (item.isCompleted ? WayPointTheme.violetGlow : WayPointTheme.cyanGlow).opacity(0.3),
                radius: 12, x: 0, y: 6
            )
        }
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
