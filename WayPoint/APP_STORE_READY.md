# WayPoint — App Store Release & Submission Readiness

> **Official App Store Connect Copy, Metadata, Screenshot Matrix & Review Notes.**

---

## 1. App Store Name, Subtitle & Promotional Text

- **App Name**: WayPoint — AI Travel Itinerary & Panic Pivot
- **Subtitle** (28 / 30 chars): `Instant Itinerary Re-balance`
- **Promotional Text**:
  Never get stranded by unexpected rain, transit delays, or closed venues. WayPoint dynamically re-balances your travel itinerary in seconds while strictly preserving your hotel and flight reservations.

---

## 2. Keyword Strategy (100-Character String)

`travel,itinerary,planner,japan,tokyo,trip,rebalance,budget,currency,wallet,transit,weather,schedule`
*(Exact Character Count: 93 / 100 characters)*

---

## 3. 5-Screenshot Value Proposition Matrix

| Screenshot | Hero Feature Name | Value Proposition & Visual Headline | Key Technical Subsystem |
| :--- | :--- | :--- | :--- |
| **1** | **Panic Pivot Solver** | *"Instant 1-Tap Itinerary Re-balance"* — Neutralize rain, flight delays & venue closures without losing reservations. | `AIRecalculatorService` & `PanicPivotSheetView` |
| **2** | **Dynamic Radar Map** | *"Live Distance & Proximity Navigation"* — Real-time venue distance calculations and MapKit coordinate handoff. | `LocationService` & `ItineraryMapView` |
| **3** | **Multi-Currency Pass Vault** | *"Offline Passes & Vector QR Generator"* — CoreImage high-res QR rendering with automatic multi-currency conversion. | `BookingVaultView` & `CurrencyFormatterService` |
| **4** | **Live Activity Dynamic Island** | *"Glanceable Live Travel Status"* — Real-time next-stop countdowns on Dynamic Island and Lock Screen. | `LiveActivityManager` & ActivityKit |
| **5** | **Instant Travel Notes Parser** | *"Turn Raw Notes into Structured Trips"* — Paste social media notes or menus to parse times, costs, and locations in seconds. | `TravelNotesParserService` & `SocialImportView` |

---

## 4. App Review Notes (For Apple Reviewers)

### StoreKit 2 Sandbox Configuration
- WayPoint uses StoreKit 2 native APIs for auto-renewable subscriptions (`com.waypoint.weekly` at $2.99/wk and `com.waypoint.annual` at $29.99/yr).
- In Sandbox/TestFlight environments without an active RevenueCat network key, the app gracefully falls back to native StoreKit 2 transaction verification without throwing 401 error loops.

### Location & Privacy Permissions
- `NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysAndWhenInUseUsageDescription` are utilized strictly for calculating real-time walking/transit distances to user itinerary stops and triggering location-aware disruption alerts.
- Zero user location or personal data is sold or shared with third parties, as declared in `PrivacyInfo.xcprivacy` with reason code `CA92.1`.
