# WayPoint — RevenueCat Shipathon 2026 Submission

![WayPoint Hero](https://img.shields.io/badge/Platform-iOS%2017%2B-blue?style=for-the-badge&logo=apple)
![StoreKit 2](https://img.shields.io/badge/Monetization-StoreKit%202%20%2B%20RevenueCat-orange?style=for-the-badge)
![Tests](https://img.shields.io/badge/Tests-119%2F119%20PASSING-emerald?style=for-the-badge)

---

## 📌 Project Overview

* **Project Name**: WayPoint
* **Tagline**: Your trip changed. WayPoint fixes it.
* **Developer**: Yuvraj Sidhu
* **GitHub Repository**: [https://github.com/YuvrajCodes11/WayPoint](https://github.com/YuvrajCodes11/WayPoint)
* **Showcase Landing**: [https://waypoint-landing.vercel.app](https://waypoint-landing.vercel.app) *(or local `waypoint-landing/index.html`)*

---

## 💡 The Problem & Pitch

Travel disruptions—rainstorms, sudden transit strikes, and 2-hour flight delays—ruin itineraries. Existing travel apps break when you lose cell service in underground subways or remote mountain towns, and automated recalculators frequently overwrite non-refundable hotel check-ins or pre-paid flight reservations.

**WayPoint** is an offline-first native iOS travel resilience companion. Built with SwiftUI, SwiftData, StoreKit 2, and Supabase, WayPoint instant-pivots disrupted daily itineraries in under 3 seconds while strictly preserving fixed reservations.

---

## ⚡ Core Features

1. **⚡ Hero Panic Pivot Engine**:
   * Analyzes real-time disruptions (rain, flight delays, transit line outages).
   * Swaps compromised outdoor stops with nearby indoor alternatives (<2.5km radius).
   * Reroutes schedule timeline bounds instantly with 1-tap Undo protection.

2. **🔒 Protected Bookings Safeguard**:
   * Flags non-refundable flight tickets, hotel vouchers, and paid tour bookings with a gold monospaced `🔒 PROTECTED` pill badge.
   * Ensures fixed time slots are never mutated during automated itinerary re-balancing.

3. **🏝️ 100% Offline-First Architecture**:
   * Operates completely without internet connectivity using local SwiftData persistence and offline mutation queues (`SyncQueue`).
   * Automatically reconciles versioned state with live Supabase Postgres backend when connection restores.

4. **🎫 Digital Pass Vault & 3% Concierge Fee Engine**:
   * Apple Wallet style pass cards with high-resolution vector CoreImage QR codes.
   * Built-in fee breakdown calculation engine for concierge bookings and 1-tap Apple Pay checkout.

5. **📱 Viral 9:16 Travel Pulse Story Recap**:
   * Generates a 9:16 vertical social story card detailing disruptions neutralized, budget pace, and protected reservations for instant sharing.

---

## 🏗️ Technical Architecture & Quality Assurance

* **UI Layer**: Pure Apple Native SwiftUI, dark-mode OLED canvas (`#000000`), 16pt continuous squircles, 0.5pt hairline strokes (`white.opacity(0.12)`), and hierarchical SF Symbols (`.symbolRenderingMode(.hierarchical)`).
* **Monetization**: StoreKit 2 transaction pipeline with RevenueCat SDK integration supporting Annual ($29.99/yr with 7-day free trial) and Weekly ($2.99/wk with 3-day free trial) subscriptions.
* **Backend**: Supabase Auth (Keychain-backed token storage), PostgreSQL with Row-Level Security (RLS) policies, and version-vector optimistic locking.
* **Test Suite Compliance**: 119/119 unit and integration tests passing across 10 test sub-suites (WP1 to WP10 / WP-A to WP-J) in `Services/WayPointMasterTestSuite.swift`.

---

## 🎬 45-Second Demo Script

| Time | Scene / Screen | Script & Visual Action |
| :--- | :--- | :--- |
| **00:00 - 00:10** | **Home Screen Cockpit** | App opens to `🟢 Day X on Track` cockpit card. Trigger rainstorm disruption. Card flips to high-contrast `⚠️ DISRUPTION DETECTED` card (+45m impact). Tap *"See Impact & Fix"*. |
| **00:10 - 00:25** | **3-Step Panic Pivot** | Sheet opens. **Step 1**: Disruption context. **Step 2**: Impact breakdown categorizing stops into Red 🔴 Broken, Green 🟢 Unaffected, and Gold 🟡 `🔒 PROTECTED`. **Step 3**: Tap `[ ⚡ REBUILD MY DAY ]`. |
| **00:25 - 00:35** | **Trip Recovered & Diff** | Screen transforms to **`TRIP RECOVERED ✓`**. Show Before ❌ vs After ✓ live timeline comparison. Demonstrate 1-tap Undo. |
| **00:35 - 00:45** | **Pass Vault & Story Recap** | Swipe to **Digital Pass Vault** (vector QR pass) and export 9:16 **Travel Pulse Social Story** card via native `ShareLink`. |

---

## 📦 Repository Structure

```
WayPoint/
├── WayPoint/
│   ├── Theme/WayPointTheme.swift              # Centralized Design Tokens (OLED, Hairlines, Colors)
│   ├── Components/TripAtRiskCard.swift        # Hero Recovery Cockpit Component
│   ├── Views/
│   │   ├── HomeView.swift                     # Main Cockpit & Timeline View
│   │   ├── PanicPivotSheetView.swift          # 3-Step Hero Rebuild & Success View
│   │   ├── StoryRecapView.swift               # 9:16 Social Story Recap Card
│   │   ├── PaywallView.swift                  # Instant Travel Resilience Paywall
│   │   ├── BookingVaultView.swift             # Digital Pass Vault & Vector QR Modal
│   │   └── ItineraryDetailView.swift          # Item Details & 3% Fee Engine
│   └── Services/
│       ├── SupabaseConfig.swift               # Live Supabase Endpoint & Anon Key
│       ├── SubscriptionManager.swift          # StoreKit 2 & RevenueCat Pipeline
│       └── WayPointMasterTestSuite.swift      # Master Orchestrator (119/119 Tests)
├── waypoint-landing/
│   └── index.html                             # Showcase Landing Page (Tailwind CSS)
├── record_demo.sh                             # Simulator HD Video Recorder Script
└── SUBMISSION.md                              # Final Shipathon Submission Document
```
