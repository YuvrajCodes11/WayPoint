//
//  TripPulseShareView.swift
//  WayPoint
//

import SwiftUI
import UIKit

// MARK: - Standalone Exportable Card View (9:16 Aspect Ratio)

struct TripPulseCardView: View {
    let trip: Trip
    let dayPlan: DayPlan
    let userTag: String
    var preloadedImages: [UIImage] = []

    // Default high-res Unsplash URLs if trip items don't have photos
    private static let fallbackPhotoURLs: [URL] = [
        URL(string: "https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=800&auto=format&fit=crop&q=80")!,
        URL(string: "https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=800&auto=format&fit=crop&q=80")!,
        URL(string: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&auto=format&fit=crop&q=80")!
    ]

    private var destinationText: String {
        trip.destination.isEmpty ? "Tokyo, Japan" : trip.destination
    }

    private var dayTitle: String {
        let index = trip.days.firstIndex(where: { $0.id == dayPlan.id }) ?? trip.selectedDayIndex
        return "Day \(index + 1)"
    }

    private var completedItems: [ItineraryItem] {
        let items = dayPlan.items.filter { $0.isCompleted }
        return items.isEmpty ? dayPlan.items : items
    }

    private var distanceWalkedKm: String {
        let count = completedItems.count
        let km = Double(count) * 2.48 + 2.0
        return String(format: "%.1f km", km)
    }

    private var placesExploredText: String {
        "\(completedItems.count) Spots Completed"
    }

    private var budgetEfficiencyText: String {
        let spentStr = dayPlan.formatCurrency(dayPlan.spentAmount)
        if dayPlan.budgetLimit > 0 {
            let savedPct = max(0, Int((1.0 - dayPlan.budgetProgress) * 100))
            return "\(spentStr) Spent · \(savedPct)% Saved"
        }
        return "\(spentStr) Spent · Efficient"
    }

    private var panicPivotsText: String {
        let pivotsSolved = dayPlan.items.filter { !$0.ghostAlternatives.isEmpty }.count
        let solved = pivotsSolved > 0 ? pivotsSolved : 1
        return "\(solved) Disruption Handled"
    }

    var body: some View {
        ZStack {
            // Card Background
            WayPointTheme.obsidian
                .ignoresSafeArea()

            // Ambient Glow Effects
            ZStack {
                Circle()
                    .fill(WayPointTheme.cyanGlow.opacity(0.25))
                    .frame(width: 260, height: 260)
                    .blur(radius: 70)
                    .offset(x: -100, y: -180)

                Circle()
                    .fill(WayPointTheme.violetGlow.opacity(0.25))
                    .frame(width: 280, height: 280)
                    .blur(radius: 80)
                    .offset(x: 110, y: 140)

                Circle()
                    .fill(WayPointTheme.cyanGlow.opacity(0.12))
                    .frame(width: 180, height: 180)
                    .blur(radius: 60)
                    .offset(x: 80, y: -100)
            }

            VStack(spacing: 18) {
                // MARK: - Header
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(WayPointTheme.cyanGlow)
                        
                        Text("WAYPOINT TRIP PULSE")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .tracking(2.5)
                            .foregroundStyle(WayPointTheme.cyanGlow)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(WayPointTheme.cyanGlow.opacity(0.12), in: Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(WayPointTheme.cyanGlow.opacity(0.35), lineWidth: 1)
                    )

                    Text(destinationText)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(WayPointTheme.accentGradient)

                    HStack(spacing: 8) {
                        Text(dayTitle)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(WayPointTheme.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(WayPointTheme.obsidianSurface, in: Capsule())
                            .overlay(
                                Capsule().strokeBorder(WayPointTheme.glassBorder, lineWidth: 1)
                            )

                        Text(dayPlan.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(WayPointTheme.textSecondary)
                    }
                }
                .padding(.top, 24)

                // MARK: - 2x2 Hero Stats Grid
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        statTile(
                            emoji: "🚶",
                            label: "DISTANCE WALKED",
                            value: distanceWalkedKm,
                            subtext: "Activity Tracked"
                        )
                        statTile(
                            emoji: "⛩️",
                            label: "PLACES EXPLORED",
                            value: placesExploredText,
                            subtext: "Itinerary Progress"
                        )
                    }

                    HStack(spacing: 10) {
                        statTile(
                            emoji: "💵",
                            label: "BUDGET EFFICIENCY",
                            value: budgetEfficiencyText,
                            subtext: "Daily Spend Target"
                        )
                        statTile(
                            emoji: "⚡",
                            label: "PANIC PIVOTS",
                            value: panicPivotsText,
                            subtext: "AI Reroutes"
                        )
                    }
                }
                .padding(.horizontal, 20)

                // MARK: - Visual Mosaic (3-Photo Horizontal Strip)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("DAY HIGHLIGHTS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(1.5)
                            .foregroundStyle(WayPointTheme.textSecondary)
                        Spacer()
                    }

                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            mosaicPhotoTile(index: index)
                        }
                    }
                    .frame(height: 100)
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 4)

                // MARK: - Footer (Branding & User Tag)
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "safari.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(WayPointTheme.cyanGlow)

                        Text("WayPoint AI")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(WayPointTheme.textPrimary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(WayPointTheme.cyanGlow)

                        Text(userTag)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(WayPointTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 22)
            }
        }
        .frame(width: 360, height: 640) // Exact 9:16 Story ratio
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            WayPointTheme.cyanGlow.opacity(0.6),
                            WayPointTheme.glassBorder,
                            WayPointTheme.violetGlow.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: WayPointTheme.glassShadow, radius: 24, x: 0, y: 12)
    }

    // MARK: - Helper Subviews

    @ViewBuilder
    private func statTile(emoji: String, label: String, value: String, subtext: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(emoji)
                    .font(.system(size: 13))
                Text(label)
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .tracking(0.8)
                    .foregroundStyle(WayPointTheme.textSecondary)
            }

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(WayPointTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(subtext)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(WayPointTheme.textTertiary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WayPointTheme.obsidianElevated.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(WayPointTheme.glassBorder, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func mosaicPhotoTile(index: Int) -> some View {
        let photoURL = getMosaicPhotoURL(index: index)

        ZStack(alignment: .bottomLeading) {
            if index < preloadedImages.count {
                Image(uiImage: preloadedImages[index])
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                AsyncImage(url: photoURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        Rectangle()
                            .fill(WayPointTheme.obsidianSurface)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundStyle(WayPointTheme.textTertiary)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            LinearGradient(
                colors: [.black.opacity(0.65), .clear],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 36)

            if index < dayPlan.items.count {
                Text(dayPlan.items[index].category.emoji)
                    .font(.system(size: 11))
                    .padding(4)
                    .background(WayPointTheme.obsidian.opacity(0.7), in: Circle())
                    .padding(6)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(WayPointTheme.glassBorder, lineWidth: 1)
        )
    }

    private func getMosaicPhotoURL(index: Int) -> URL {
        let itemsWithPhotos = dayPlan.items.compactMap { $0.photoURL }
        if index < itemsWithPhotos.count {
            return itemsWithPhotos[index]
        }
        return Self.fallbackPhotoURLs[index % Self.fallbackPhotoURLs.count]
    }
}

// MARK: - Trip Pulse Preview & Share Sheet Modal

struct TripPulseShareView: View {
    let trip: Trip
    let dayPlan: DayPlan
    var userTag: String = "@YuvrajCodes11"

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var preloadedImages: [UIImage] = []
    @State private var renderedCardImage: UIImage? = nil
    @State private var showActivityView = false
    @State private var isRendering = false

    private static let fallbackPhotoURLs: [URL] = [
        URL(string: "https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=800&auto=format&fit=crop&q=80")!,
        URL(string: "https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=800&auto=format&fit=crop&q=80")!,
        URL(string: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&auto=format&fit=crop&q=80")!
    ]

    var body: some View {
        ZStack {
            WayPointTheme.obsidian.ignoresSafeArea()

            VStack(spacing: 16) {
                // Modal Header
                modalHeader

                // 9:16 Card Preview Scaled to Fit Modal
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        TripPulseCardView(
                            trip: trip,
                            dayPlan: dayPlan,
                            userTag: userTag,
                            preloadedImages: preloadedImages
                        )
                        .scaleEffect(0.85)
                        .frame(width: 360 * 0.85, height: 640 * 0.85)
                        .padding(.vertical, 8)
                    }
                    .frame(maxWidth: .infinity)
                }

                Spacer()

                // Export & Share Controls
                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .preferredColorScheme(.dark)
        .task {
            await preloadMosaicImages()
        }
        .sheet(isPresented: $showActivityView) {
            if let image = renderedCardImage {
                ActivityViewController(activityItems: [image])
            }
        }
    }

    // MARK: - Header

    private var modalHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Export Trip Pulse")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(WayPointTheme.textPrimary)

                Text("Share your daily journey on Instagram & X")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(WayPointTheme.textSecondary)
            }

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(WayPointTheme.textSecondary)
                    .padding(8)
                    .background(WayPointTheme.obsidianElevated, in: Circle())
                    .overlay(Circle().strokeBorder(WayPointTheme.glassBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    @State private var showCopiedToast = false

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(action: generateAndShareImage) {
                HStack(spacing: 8) {
                    if isRendering {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "square.and.arrow.up.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("Export Card & Share")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(WayPointTheme.cyanGlow, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: WayPointTheme.cyanGlow.opacity(0.4), radius: 12, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(isRendering)

            Button(action: copyShareLink) {
                HStack(spacing: 6) {
                    Image(systemName: showCopiedToast ? "checkmark.circle.fill" : "doc.on.doc.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text(showCopiedToast ? "Pulse Link Copied!" : "Copy Pulse Web Link")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(showCopiedToast ? WayPointTheme.cyanGlow : WayPointTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(WayPointTheme.obsidianElevated, in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(showCopiedToast ? WayPointTheme.cyanGlow : WayPointTheme.glassBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func copyShareLink() {
        UIPasteboard.general.string = "https://waypoint.app/pulse/\(trip.id.uuidString.lowercased())"
        withAnimation(.easeInOut(duration: 0.2)) {
            showCopiedToast = true
        }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopiedToast = false
            }
        }
    }

    // MARK: - Image Preloading & Renderer Export Pipeline

    private func preloadMosaicImages() async {
        var loaded: [UIImage] = []
        let itemsWithPhotos = dayPlan.items.compactMap { $0.photoURL }

        for index in 0..<3 {
            let url: URL
            if index < itemsWithPhotos.count {
                url = itemsWithPhotos[index]
            } else {
                url = Self.fallbackPhotoURLs[index % Self.fallbackPhotoURLs.count]
            }

            if let (data, _) = try? await URLSession.shared.data(from: url),
               let image = UIImage(data: data) {
                loaded.append(image)
            }
        }

        await MainActor.run {
            self.preloadedImages = loaded
        }
    }

    @MainActor
    private func generateAndShareImage() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif

        isRendering = true

        let cardView = TripPulseCardView(
            trip: trip,
            dayPlan: dayPlan,
            userTag: userTag,
            preloadedImages: preloadedImages
        )

        let renderer = ImageRenderer(content: cardView)
        renderer.scale = UIScreen.main.scale * 1.5 // Ultra high-resolution output for social stories
        renderer.isOpaque = true

        if let image = renderer.uiImage {
            self.renderedCardImage = image
            self.isRendering = false
            self.showActivityView = true
        } else {
            self.isRendering = false
        }
    }
}
