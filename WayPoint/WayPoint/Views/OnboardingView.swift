//
//  OnboardingView.swift
//  WayPoint
//

import SwiftUI
#if canImport(WebKit) && canImport(UIKit)
import WebKit
import UIKit
#endif

struct OnboardingPage: Identifiable {
    let id: Int
    let icon: String
    let tag: String
    let title: String
    let description: String
    let glowColor: Color
}

// MARK: - 3D Background Subview

struct Onboarding3DBackground: View {
    var body: some View {
        #if canImport(WebKit) && canImport(UIKit)
        SplineWebContainer(urlString: "https://my.spline.design/customlinepathwithcustommatcap-Oken3h6jm2uzoJ2BVGzdfhQe/")
            .scaleEffect(1.06)
            .clipped()
            .ignoresSafeArea(.all)
            .allowsHitTesting(false)
        #else
        fallbackMeshBackground
        #endif
    }

    private var fallbackMeshBackground: some View {
        ZStack {
            WayPointTheme.obsidian.ignoresSafeArea()
            Circle()
                .fill(WayPointTheme.cyanGlow.opacity(0.22))
                .frame(width: 340, height: 340)
                .blur(radius: 80)
                .offset(x: -90, y: -180)
            Circle()
                .fill(WayPointTheme.violetGlow.opacity(0.20))
                .frame(width: 380, height: 380)
                .blur(radius: 95)
                .offset(x: 140, y: 120)
        }
    }
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @Environment(SupabaseService.self) private var supabaseService
    @State private var currentPage: Int = 0
    @State private var showAuthSheet: Bool = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            icon: "sparkles",
            tag: "AI RE-BALANCING ENGINE",
            title: "AI Travel Co-Pilot",
            description: "Real-time itinerary optimization for sudden weather shifts, flight delays & daily pacing.",
            glowColor: WayPointTheme.cyanGlow
        ),
        OnboardingPage(
            id: 1,
            icon: "map.fill",
            tag: "SPATIAL RADAR & ROUTING",
            title: "GPS Radar & Spatial Maps",
            description: "Dark-mode spatial radar, live polyline routes, and Apple Maps turn-by-turn navigation.",
            glowColor: WayPointTheme.violetGlow
        ),
        OnboardingPage(
            id: 2,
            icon: "ticket.fill",
            tag: "DIGITAL PASS VAULT",
            title: "Scannable Pass Vault",
            description: "Store offline boarding passes, hotel vouchers, and instant QR barcodes anywhere in the world.",
            glowColor: WayPointTheme.cyanGlow
        )
    ]

    var body: some View {
        ZStack {
            // Live 3D Spline Scene Web Canvas at the bottom layer of root ZStack
            Onboarding3DBackground()

            VStack(spacing: 0) {
                // Top Header Branding
                headerBranding
                    .padding(.top, 24)

                Spacer()

                // 3-Page Value Proposition Carousel with Dark Glass Protection Card
                TabView(selection: $currentPage) {
                    ForEach(pages) { page in
                        carouselPageCard(page: page)
                            .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 400)

                // Page Indicator Dots
                pageIndicatorDots
                    .padding(.bottom, 24)

                // Primary Glassmorphic Action Button
                actionButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showAuthSheet) {
            OTPAuthSheetView()
                .environment(supabaseService)
        }
    }

    // MARK: - Top Header Branding

    private var headerBranding: some View {
        BrandHeaderView(height: 32)
    }

    // MARK: - Carousel Page Card with Legibility Backdrop Protection

    private func carouselPageCard(page: OnboardingPage) -> some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(page.glowColor.opacity(0.18))
                    .frame(width: 80, height: 80)
                    .shadow(color: page.glowColor.opacity(0.4), radius: 12)

                Image(systemName: page.icon)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(page.glowColor)
            }

            VStack(spacing: 8) {
                Text(page.tag)
                    .font(.caption.weight(.bold))
                    .tracking(1.8)
                    .foregroundStyle(WayPointTheme.cyanGlow)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black, radius: 4, x: 0, y: 2)

                Text(page.title)
                    .font(.title.bold())
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.95), radius: 10, x: 0, y: 4)

                Text(page.description)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .shadow(color: .black, radius: 6, x: 0, y: 2)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(WayPointTheme.glassBorder, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 15, x: 0, y: 8)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Page Indicator Dots

    private var pageIndicatorDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(
                        currentPage == index
                            ? WayPointTheme.cyanGlow
                            : WayPointTheme.textTertiary.opacity(0.4)
                    )
                    .frame(width: currentPage == index ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentPage)
            }
        }
    }

    // MARK: - Primary Action Button

    private var actionButton: some View {
        VStack(spacing: 12) {
            Button(action: { showAuthSheet = true }) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3.weight(.semibold))

                    Text("Get Started with Phone / Email")
                        .font(.headline.weight(.bold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(WayPointTheme.accentGradient)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: WayPointTheme.cyanGlow.opacity(0.4), radius: 14, x: 0, y: 6)
            }
            .buttonStyle(.plain)

            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    supabaseService.signInAsGuest()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption.weight(.bold))
                    Text("Explore Demo Mode")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(WayPointTheme.textSecondary)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    OnboardingView()
        .environment(SupabaseService.shared)
}
