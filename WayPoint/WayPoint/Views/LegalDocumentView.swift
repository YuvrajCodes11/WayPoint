//
//  LegalDocumentView.swift
//  WayPoint
//

import SwiftUI

struct LegalDocumentView: View {
    enum DocumentType: String, Identifiable {
        case privacyPolicy = "Privacy Policy"
        case termsOfService = "Terms of Service"

        var id: String { rawValue }

        var title: String { rawValue }
        var icon: String {
            switch self {
            case .privacyPolicy: return "lock.shield.fill"
            case .termsOfService: return "doc.text.fill"
            }
        }
    }

    let documentType: DocumentType
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                WayPointTheme.obsidian.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: documentType.icon)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(WayPointTheme.cyanGlow)
                            Text(documentType.title)
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundStyle(WayPointTheme.textPrimary)
                        }
                        .padding(.top, 8)

                        Text("Last Updated: August 19, 2026")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(WayPointTheme.textSecondary)

                        Divider()
                            .overlay(WayPointTheme.glassBorder)

                        if documentType == .privacyPolicy {
                            privacyPolicyContent
                        } else {
                            termsOfServiceContent
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body.weight(.bold))
                    .foregroundStyle(WayPointTheme.cyanGlow)
                }
            }
        }
    }

    private var privacyPolicyContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("1. On-Device Local OCR Processing")
            sectionText("WayPoint utilizes Apple VisionKit directly on your iOS device to parse paper travel receipts and foreign menus. Optical character recognition (OCR) image processing occurs 100% locally on your iPhone hardware. Raw receipt photo data is never transmitted to third-party tracking servers or external ad networks.")

            sectionHeader("2. Zero Data Selling & Privacy First")
            sectionText("We guarantee that your personal trip details, location coordinates, scan logs, and spending habits are never sold, rented, or monetized for advertising purposes.")

            sectionHeader("3. Supabase Cloud Isolation & Row Level Security (RLS)")
            sectionText("When cloud synchronization is enabled, trip data is stored in Supabase PostgreSQL database tables protected by Row Level Security (RLS) policies enforcing auth.uid() = user_id authorization. Your itinerary items, bookings, and receipts remain strictly private and accessible only by your authenticated user account.")

            sectionHeader("4. Location Data & Navigation")
            sectionText("Location coordinates requested by WayPoint are strictly used to calculate real-time walking distances to your next scheduled stop and present interactive MapKit radar pins. Location data is not stored permanently or shared with third parties.")
        }
    }

    private var termsOfServiceContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("1. Service Level & AI Itinerary Generation")
            sectionText("WayPoint provides AI-assisted travel itinerary generation, disruption re-balancing, and budget tracking tools. While our constraint solver optimizes schedules based on venue hours and real-time weather alerts, users are advised to verify flight gate changes and venue operating hours independently.")

            sectionHeader("2. Concierge Platform Fee Disclosure")
            sectionText("When confirming pass reservations or booking travel passes through the WayPoint Concierge engine, a standard 3% platform processing fee is applied to cover ticket distribution and instant digital pass issuance.")

            sectionHeader("3. Auto-Renewable Subscription Terms (EULA)")
            sectionText("WayPoint Pro subscription options include $2.99/week and $29.99/year auto-renewable passes. Payment will be charged to your Apple ID account upon purchase confirmation. Subscriptions automatically renew unless cancelled at least 24 hours prior to the end of the current billing period. You may manage or cancel subscriptions in your iOS App Store Account Settings.")

            sectionHeader("4. Standard Apple End User License Agreement")
            sectionText("Use of WayPoint is governed by the standard Apple Licensed Application End User License Agreement (EULA). All rights not expressly granted are reserved.")
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(.headline, design: .rounded, weight: .bold))
            .foregroundStyle(WayPointTheme.cyanGlow)
            .padding(.top, 6)
    }

    private func sectionText(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .lineSpacing(4)
            .foregroundStyle(WayPointTheme.textSecondary)
    }
}
