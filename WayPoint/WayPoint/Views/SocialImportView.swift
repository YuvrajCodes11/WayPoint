//
//  SocialImportView.swift
//  WayPoint
//
//  Task 4.1 / WP7: Itinerary Text & Travel Notes Parser (Honest De-Faked Importer)
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SocialImportView: View {
    @Environment(TripStore.self) private var tripStore
    @Environment(\.dismiss) private var dismiss

    @State private var inputText: String = ""
    @State private var candidates: [CandidateItineraryItem] = []
    @State private var selectedDemoChip: String? = nil

    var acceptedCount: Int {
        candidates.filter(\.isAccepted).count
    }

    var body: some View {
        ZStack {
            WayPointTheme.obsidian
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        inputCardSection

                        if !candidates.isEmpty {
                            verificationReviewDeck
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                }

                if !candidates.isEmpty {
                    commitCTASection
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Top Header

    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(WayPointTheme.cyanGlow)

                    Text("Deterministic Parser")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(WayPointTheme.cyanGlow)
                }

                Text("Itinerary Text & Travel Notes Parser")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(WayPointTheme.textPrimary)
            }

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(WayPointTheme.textSecondary)
                    .padding(10)
                    .background(WayPointTheme.obsidianElevated, in: Circle())
                    .overlay(Circle().strokeBorder(WayPointTheme.glassBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    // MARK: - Input Section Card

    private var inputCardSection: some View {
        GlassCardView(glowColor: WayPointTheme.cyanGlow) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Paste Itinerary Notes or Travel Captions")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(WayPointTheme.textPrimary)

                    Spacer()

                    Button(action: pasteFromClipboard) {
                        HStack(spacing: 4) {
                            Text("📋")
                                .font(.caption2)
                            Text("Paste Clipboard")
                                .font(.caption2.weight(.bold))
                        }
                        .foregroundStyle(WayPointTheme.cyanGlow)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(WayPointTheme.cyanGlow.opacity(0.15), in: Capsule())
                        .overlay(Capsule().strokeBorder(WayPointTheme.cyanGlow.opacity(0.4), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }

                ZStack(alignment: .topLeading) {
                    if inputText.isEmpty {
                        Text("Paste travel notes, hotel lists, flight emails, or itinerary captions...")
                            .font(.subheadline)
                            .foregroundStyle(WayPointTheme.textTertiary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                    }

                    TextEditor(text: $inputText)
                        .font(.subheadline)
                        .foregroundStyle(WayPointTheme.textPrimary)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(minHeight: 76, maxHeight: 110)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
                .background(WayPointTheme.obsidianSurface.opacity(0.7), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(WayPointTheme.glassBorder, lineWidth: 1)
                )

                // Quick-test Sample Chips
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sample Notes:")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(WayPointTheme.textSecondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            demoChip(title: "📱 Tokyo Highlights Note", key: "tokyo") {
                                inputText = "1. Ichiran Ramen Shibuya @ 12:30pm ($15)\n2. Shibuya Sky Observatory @ 4:00pm ($25)\n3. Ginza Michelin Omakase @ 7:30pm ($250)"
                                runInstantExtraction()
                            }

                            demoChip(title: "☕ Aesthetic Cafe List", key: "cafes") {
                                inputText = "1. Koffee Mameya Omotesando @ 10:00am ($10)\n2. Cafe Reissue 3D Latte Art @ 2:00pm ($12)\n3. Bear Pond Espresso @ 4:30pm ($8)"
                                runInstantExtraction()
                            }

                            demoChip(title: "📝 Raw Hostel Board", key: "hostel") {
                                inputText = "Roppongi Hills Sunset Terrace @ 6:00pm ($25)\nMemory Lane Yakitori Alley @ 7:45pm ($30)\nUnderground Jazz Speakeasy @ 10:15pm ($50)"
                                runInstantExtraction()
                            }
                        }
                    }
                }

                // Extract Button
                Button(action: runInstantExtraction) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.body.weight(.bold))
                        Text("Parse Itinerary Notes")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? LinearGradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                            : WayPointTheme.accentGradient
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: WayPointTheme.cyanGlow.opacity(inputText.isEmpty ? 0 : 0.35), radius: 10, x: 0, y: 4)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.plain)
            }
        }
    }

    private func demoChip(title: String, key: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(selectedDemoChip == key ? WayPointTheme.cyanGlow : WayPointTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    selectedDemoChip == key ? WayPointTheme.cyanGlow.opacity(0.18) : WayPointTheme.obsidianSurface,
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .strokeBorder(selectedDemoChip == key ? WayPointTheme.cyanGlow : WayPointTheme.glassBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Verification Review Deck

    private var verificationReviewDeck: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Parsed Candidate Stops")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(WayPointTheme.textPrimary)

                    Text("Deterministic parser identified \(candidates.count) stops")
                        .font(.caption)
                        .foregroundStyle(WayPointTheme.textSecondary)
                }

                Spacer()

                Text("\(acceptedCount)/\(candidates.count) Kept")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WayPointTheme.cyanGlow)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(WayPointTheme.cyanGlow.opacity(0.15), in: Capsule())
            }

            VStack(spacing: 12) {
                ForEach(candidates.indices, id: \.self) { index in
                    candidateReviewCard(index: index)
                }
            }
        }
    }

    private func candidateReviewCard(index: Int) -> some View {
        let candidate = candidates[index]
        return GlassCardView(
            cornerRadius: 18,
            padding: 14,
            glowColor: candidate.isAccepted ? WayPointTheme.cyanGlow : Color.gray
        ) {
            VStack(alignment: .leading, spacing: 12) {
                // Header: Status Tag + Quick Action Buttons
                HStack(alignment: .center) {
                    // Tag Pill
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .font(.caption2)
                        Text(candidate.detectedTag)
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(WayPointTheme.cyanGlow)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(WayPointTheme.cyanGlow.opacity(0.15), in: Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(WayPointTheme.cyanGlow.opacity(0.4), lineWidth: 1)
                    )

                    Spacer()

                    // Quick Action Toggle Pill Buttons (Keep / Skip)
                    HStack(spacing: 8) {
                        Button(action: { toggleCandidate(at: index, accept: true) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                Text("Keep")
                                    .font(.caption2.weight(.bold))
                            }
                            .foregroundStyle(candidate.isAccepted ? WayPointTheme.cyanGlow : WayPointTheme.textTertiary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                candidate.isAccepted ? WayPointTheme.cyanGlow.opacity(0.2) : WayPointTheme.obsidianSurface,
                                in: Capsule()
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(candidate.isAccepted ? WayPointTheme.cyanGlow : WayPointTheme.glassBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        Button(action: { toggleCandidate(at: index, accept: false) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.caption.weight(.semibold))
                                Text("Skip")
                                    .font(.caption2.weight(.semibold))
                            }
                            .foregroundStyle(!candidate.isAccepted ? WayPointTheme.budgetOver : WayPointTheme.textTertiary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                !candidate.isAccepted ? WayPointTheme.budgetOver.opacity(0.2) : WayPointTheme.obsidianSurface,
                                in: Capsule()
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(!candidate.isAccepted ? WayPointTheme.budgetOver : WayPointTheme.glassBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Details Row
                HStack(alignment: .top, spacing: 12) {
                    placeholderView(category: candidate.category)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(candidate.title)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(WayPointTheme.textPrimary)
                            .strikethrough(!candidate.isAccepted, color: WayPointTheme.textTertiary)

                        Text(candidate.location)
                            .font(.caption)
                            .foregroundStyle(WayPointTheme.textSecondary)
                            .lineLimit(2)

                        HStack(spacing: 8) {
                            Text("\(candidate.category.emoji) \(candidate.category.displayName)")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(WayPointTheme.textPrimary)

                            Text("•")
                                .font(.caption2)
                                .foregroundStyle(WayPointTheme.textTertiary)

                            Text("⏰ \(candidate.suggestedTime)")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(WayPointTheme.cyanGlow)

                            Text("•")
                                .font(.caption2)
                                .foregroundStyle(WayPointTheme.textTertiary)

                            Text(candidate.estimatedCost > 0 ? "$\(NSDecimalNumber(decimal: candidate.estimatedCost).intValue)" : "Free")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(WayPointTheme.textSecondary)
                        }
                        .padding(.top, 2)
                    }
                }
            }
        }
        .opacity(candidate.isAccepted ? 1.0 : 0.55)
    }

    private func placeholderView(category: ItemCategory) -> some View {
        ZStack {
            WayPointTheme.obsidianSurface
            Image(systemName: category.systemImage)
                .font(.subheadline)
                .foregroundStyle(WayPointTheme.cyanGlow)
        }
        .frame(width: 50, height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(WayPointTheme.glassBorder, lineWidth: 1))
    }

    // MARK: - Commit CTA Bottom Button

    private var commitCTASection: some View {
        VStack(spacing: 0) {
            Divider()
                .background(WayPointTheme.glassBorder)

            Button(action: commitAcceptedStops) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.headline)
                    Text("Add (\(acceptedCount)) Stops to Trip")
                        .font(.headline.weight(.bold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    acceptedCount > 0
                        ? WayPointTheme.accentGradient
                        : LinearGradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: WayPointTheme.cyanGlow.opacity(acceptedCount > 0 ? 0.4 : 0), radius: 12, x: 0, y: 6)
            }
            .disabled(acceptedCount == 0)
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 24)
            .background(WayPointTheme.obsidian)
        }
    }

    // MARK: - Helper Actions

    private func pasteFromClipboard() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if let text = UIPasteboard.general.string, !text.isEmpty {
            self.inputText = text
        }
        #endif
    }

    private func toggleCandidate(at index: Int, accept: Bool) {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            candidates[index].isAccepted = accept
        }
    }

    private func runInstantExtraction() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.candidates = TravelNotesParserService.shared.parseTravelNotes(inputText)
        }
    }

    private func commitAcceptedStops() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
        let acceptedCandidates = candidates.filter(\.isAccepted)
        guard !acceptedCandidates.isEmpty else { return }

        let targetDay = tripStore.currentDayPlan
        let baseDate = targetDay.date
        let newItems = acceptedCandidates.map { $0.toItineraryItem(baseDate: baseDate) }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            tripStore.appendImportedItems(newItems, to: targetDay.id)
        }

        dismiss()
    }
}
