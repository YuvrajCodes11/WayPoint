# WayPoint — Shipaton 2026 Pitch & Demo Scripts

> **Comprehensive Judge Pitching Guide, 60-Second Video Script, and 3-Minute Technical Walkthrough.**

---

## ⚡ 1. The 15-Second Pitch (Elevator Pitch for Judges)

> *"Travel plans break—rain happens, flights get delayed, and transit halts. Traditional travel apps force you into manual, stress-filled schedule rebuilds. WayPoint is the AI-resilient travel companion that neutralizes disruptions in 1 tap. Powered by our Panic Pivot Engine, WayPoint automatically swaps outdoor stops for indoor venues within 2.5km, shifts transit timelines, and strictly protects your prepaid hotel & flight passes—keeping your trip effortless, on schedule, and on budget."*

---

## 🎬 2. The 60-Second Demo Video Script

| Time | Visual / Screen Action | Voiceover Script | Technical Highlight |
| :--- | :--- | :--- | :--- |
| **0:00 - 0:10** | Opening on `HomeView` with active Tokyo Day 1 itinerary. Sudden torrential rain notification appears on Dynamic Island. | *"You're in Tokyo, exploring Shibuya outdoor gardens, when sudden torrential rain strikes. Your afternoon is ruined, right?"* | `LiveActivityManager` & Dynamic Island Pill |
| **0:10 - 0:25** | Tap top Demo Simulator chip **🌧️ Weather Defense**. `PanicPivotSheetView` auto-presents with spring animation. | *"Not with WayPoint. Tap 'Weather Defense' and our Panic Pivot Engine instantly resolves the conflict."* | `AIRecalculatorService` constraint solver |
| **0:25 - 0:40** | Highlight **Visual Diff Report** showing outdoor garden replaced by Mori Art Museum (1.2km away), 100% passes kept. | *"Look at the diff: outdoor stops are swapped for indoor museums within 2.5km, while your prepaid hotel check-in and Michelin dinner reservation remain 100% untouched."* | `PivotDiffReport` & Fixed Reservation Invariant |
| **0:40 - 0:50** | Tap **Confirm & Apply Panic Pivot**. App returns to `HomeView`, Live Radar updates countdown. | *"One tap commits the re-balanced schedule, updating your live radar countdown seamlessly."* | `TripStore` local-first commit |
| **0:50 - 1:00** | Switch to **Digital Pass Vault** (show vector QR pass) and tap **Share Pulse** recap card. | *"Store offline boarding passes in your vault and export your Travel Pulse recap card. WayPoint: Travel without fear."* | `BookingVaultView` & `StoryRecapView` |

---

## 🔬 3. The 3-Minute Technical Deep Dive (For Engineering Judges)

### Part 1: Algorithmic Constraint Solver & Panic Pivot (0:00 - 1:00)
- **Problem**: Real-world travel disruptions introduce cascading temporal and geographic conflicts.
- **Solution**: `AIRecalculatorService` uses a multi-objective constraint solver. Outdoor venues are evaluated against indoor POIs within a strict **2.5 km geofence radius**.
- **Invariant**: `isFixedReservation = true` items act as immovable temporal anchors (flights, hotel vouchers, reserved dining).
- **Undo Safety**: `UndoPivotManager` captures pre-pivot state snapshots for 1-tap state restoration.

### Part 2: Local-First Core Architecture & FIFO Sync Queue (1:00 - 2:00)
- **Problem**: International roaming networks fail frequently in subways, flights, or rural areas.
- **Solution**: `TripStore` provides local-first mutation guarantees. Operations append to an in-memory & disk-persisted **bounded FIFO queue**.
- **Reconciliation**: Background sync thread handles remote Supabase PostgreSQL synchronization with Row Level Security (`auth.uid() = user_id`).

### Part 3: Native iOS 17 Hardware Integration & Release Quality (2:00 - 3:00)
- **Dynamic Island & Live Activities**: `LiveActivityManager` coordinates real-time venue countdowns using ActivityKit.
- **Vector QR Pass Vault**: High-res QR rendering using CoreImage (`CIFilter.qrCodeGenerator`) with Apple Wallet disclosure compliance.
- **Privacy & App Store Compliance**: 100% compliance with Apple's Privacy Manifest (`PrivacyInfo.xcprivacy` declaring `NSPrivacyTracking = false` & `CA92.1` UserDefaults access).
