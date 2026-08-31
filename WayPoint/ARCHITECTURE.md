# WayPoint — System Architecture & Technical Specifications

> **Comprehensive Technical Breakdown of Data Flow, Constraint Solving, Security, and Monetization.**

---

## 🏗️ Architectural Overview

WayPoint is built on a **Local-First, Offline-Engineered Architecture** designed for high reliability under adverse mobile network conditions (roaming in foreign countries, subway tunnels, offline flight mode).

```
                      ┌─────────────────────────────────────────┐
                      │              SwiftUI Views              │
                      │  (HomeView, PanicPivotSheetView, etc.)  │
                      └────────────────────┬────────────────────┘
                                           │
                                           ▼
                      ┌─────────────────────────────────────────┐
                      │                TripStore                │
                      │      (Local CoreState / Persistence)    │
                      └────────────┬────────────────┬───────────┘
                                   │                │
           ┌───────────────────────┘                └───────────────────────┐
           ▼                                                                ▼
┌─────────────────────┐                                          ┌─────────────────────┐
│ Panic Pivot Engine  │                                          │  FIFO Sync Queue    │
│(AIRecalculatorServ) │                                          │(Offline Mutations)  │
└─────────────────────┘                                          └──────────┬──────────┘
                                                                            │
                                                                            ▼
                                                                 ┌─────────────────────┐
                                                                 │  Supabase Remote    │
                                                                 │(PostgreSQL + RLS)   │
                                                                 └─────────────────────┘
```

---

## 1. 🔄 Data Flow & Offline Synchronization Subsystem

- **Local-First State**: `TripStore` acts as the single source of truth (`@Observable` class). All user edits, completion toggles, and pivot commits execute instantly on local state without blocking UI threads.
- **Idempotent FIFO Queue**:
  - Offline mutations (adds, updates, deletes, pivot commits) are appended to a persistent FIFO operation queue.
  - When connection is restored, operations replay sequentially with exponential backoff (`Task11SyncQueueTests`).
- **Remote Reconciliation**:
  - Remote state sync with Supabase PostgreSQL using deterministic timestamp-based vector reconciliation (`Task33RemoteSyncReconciliationTests`).

---

## 2. 🌧️ Disruption Engine & Constraint Solver

- **Constraint Optimization Logic**:
  - When a disruption occurs (e.g., *🌧️ Torrential Rain*), `AIRecalculatorService` evaluates active day plan items against environmental constraints.
  - Outdoor stops are filtered against indoor substitutes within a **2.5 km geofence radius**.
- **Fixed Reservation Protection Invariant**:
  - Items flagged as `isFixedReservation = true` (prepaid hotel check-ins, flights, Michelin dining) are non-negotiable hard bounds. The solver adjusts flexible leisure items around these fixed anchors.
- **Visual Diff Report**:
  - Computes `PivotDiffReport` calculating net delay impact (minutes), budget delta ($), distance saved (meters), and preserved pass count.
- **Day-Scoped Undo Stack**:
  - `UndoPivotManager` captures pre-pivot state snapshots, enabling immediate 1-tap rollback (`undoLastPivot`).

---

## 3. 🔒 Security & Privacy Model

- **Keychain Storage**: User auth tokens and credentials are securely stored using Apple Keychain (`kSecClassGenericPassword`), guaranteeing zero plaintext secret exposure (`WP8SecurityPrivacyTests`).
- **Row Level Security (RLS)**: Supabase PostgreSQL database tables enforce strict multi-tenant isolation policies (`auth.uid() = user_id`).
- **Apple Privacy Manifest (`PrivacyInfo.xcprivacy`)**:
  - `NSPrivacyTracking`: `false`
  - `NSPrivacyAccessedAPITypes`: `NSPrivacyAccessedAPICategoryUserDefaults` with reason code `CA92.1`.
  - `NSPrivacyCollectedDataTypes`: Coarse Location & User ID.

---

## 4. 💳 Monetization Architecture

- **StoreKit 2 Native Catalog**: In-app purchases for Pro tier (`com.waypoint.weekly` & `com.waypoint.annual`) use StoreKit 2 native async APIs (`Transaction.currentEntitlements`).
- **JWS Verification**: JWS cryptographic signature validation guarantees entitlement legitimacy without mandatory server calls (`WP4MonetizationTests`).
- **Offline Entitlement Cache**: Pro subscription status caches locally to ensure zero loss of access during offline travel.
