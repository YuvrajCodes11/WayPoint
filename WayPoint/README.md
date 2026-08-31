# WayPoint — AI-Resilient Travel Companion & Panic Pivot Engine

> **Production-Grade iOS 17+ Application for Intelligent Itinerary Recovery, Real-Time Radar & Digital Pass Management.**

---

## 🌟 Overview

Travel plans break. Rainstorms strike, Yamanote line trains get delayed, and flight arrivals shift. Traditional itinerary apps leave travelers stranded, forcing painful manual schedule rebuilds.

**WayPoint** is the AI-resilient travel companion powered by the **Panic Pivot Engine**. With a single tap, WayPoint neutralizes disruptions—substituting outdoor stops for indoor venues within 2.5km, shifting transit timelines, and strictly preserving prepaid hotel, flight, and Michelin dining reservations.

---

## ⚡ Core Feature Highlights

### 1. 🌧️ Panic Pivot Engine
- **Instant 1-Tap Recovery**: Solves schedule conflicts triggered by weather rain, flight delays, transit outages, or unexpected venue closures.
- **Reservation Protection Guarantee**: Prepaid hotel check-ins, flight departures, and dining reservations remain 100% fixed while leisure stops adapt.
- **Visual Diff Report**: Clear *Before ❌ vs After ✓* schedule comparison with time, budget, and distance impact metrics.
- **Day-Scoped Undo Stack**: 1-tap state restoration powered by `UndoPivotManager`.

### 2. 🏝️ Dynamic Island & Live Activities
- **Real-Time Live Radar**: Dynamic Island pill displaying active venue name, next stop countdown, and real-time walking distance.
- **ActivityKit Integration**: 8-hour auto-expiring live activity lifecycle.

### 3. 🎫 Digital Pass Vault & Vector QR Generator
- **Offline Pass Management**: Secure local storage for boarding passes, hotel vouchers, and activity tickets.
- **Vector CoreImage Barcodes**: High-resolution 2D QR code generator (`CIFilter.qrCodeGenerator`) rendered on crisp vector canvas.
- **Apple Wallet Disclosure**: Transparent disclosure dialog for `.pkpass` certificate provisioning.

### 4. 🔄 Local-First Sync Queue & Remote Reconciliation
- **Idempotent FIFO Queue**: Bounded local queue persisting offline mutations (`TripStore`).
- **Supabase Remote Reconciliation**: Seamless background sync with PostgreSQL + Row Level Security (RLS) policies.

### 5. 💳 Native StoreKit 2 Monetization
- **JWS Verification**: Cryptographically verified auto-renewable subscriptions (`com.waypoint.weekly` & `com.waypoint.annual`).
- **Offline Entitlement Caching**: Uninterrupted Pro features even when offline.

---

## 🛠️ Tech Stack & Requirements

| Layer | Technology |
| :--- | :--- |
| **Target Platform** | iOS 17.0+ / iPadOS 17.0+ |
| **Language & Framework** | Swift 5.9 / SwiftUI / Swift Concurrency |
| **Hardware Rendering** | Metal acceleration via `.drawingGroup()` |
| **Hardware & Native Frameworks** | ActivityKit, CoreLocation, VisionKit, CoreImage, StoreKit 2 |
| **Backend & Sync** | Supabase PostgreSQL + Auth + RLS Policies |
| **Privacy & Release** | Official Apple Privacy Manifest (`PrivacyInfo.xcprivacy` with `CA92.1`) |

---

## 🚀 Quick-Start Guide

1. **Clone & Open Project**:
   ```bash
   cd WayPoint
   open WayPoint.xcodeproj
   ```
2. **Select Target & Scheme**:
   - Scheme: `WayPoint`
   - Destination: `iPhone 17` Simulator (or physical device running iOS 17+)
3. **Build & Run**:
   - Press `Cmd + R` in Xcode or run via terminal:
   ```bash
   xcodebuild -project WayPoint.xcodeproj -scheme WayPoint -destination 'platform=iOS Simulator,name=iPhone 17' build
   ```
4. **Interactive Demo Toolbar**:
   - Under `#if DEBUG`, use the top **Shipaton Demo Simulator** toolbar to trigger preset disruptions (*☀️ Nominal Day*, *🌧️ Weather Defense*, *⚡ Transit Shift*, *✈️ Flight Rescue*).
