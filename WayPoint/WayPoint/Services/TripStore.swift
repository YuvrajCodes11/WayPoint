import Foundation
import SwiftUI
import Observation
import Network

// MARK: - Sync Queue Item

enum ReconciliationResult: Equatable {
    case appliedRemote(reason: String)
    case retainedLocal(reason: String)
}

struct SyncQueueItem: Codable, Identifiable {
    let id: UUID
    let tripID: UUID
    let mutationReason: String
    let timestamp: Date
    let tripVersion: Int

    init(id: UUID = UUID(), tripID: UUID, mutationReason: String, timestamp: Date = Date(), tripVersion: Int) {
        self.id = id
        self.tripID = tripID
        self.mutationReason = mutationReason
        self.timestamp = timestamp
        self.tripVersion = tripVersion
    }
}

@MainActor
@Observable
final class TripStore {
    static let shared = TripStore()

    private let tripStorageKey = "waypoint_persisted_trip_data_v2"
    private let legacyTripStorageKey = "waypoint_persisted_trip_data_v1"
    private let bookingStorageKey = "waypoint_user_bookings_v1"
    private let commissionKey = "waypoint_total_commission_earned_v1"
    private let syncPendingKey = "waypoint_trip_sync_pending_v1"
    private let localMutationKey = "waypoint_trip_local_mutation_v1"
    private let syncQueueStorageKey = "waypoint_pending_sync_queue_v1"

    private(set) var currentUserID: String = "guest_user"

    var currentTripStorageKey: String {
        "waypoint_persisted_trip_data_v2_\(currentUserID)"
    }

    var currentSyncQueueStorageKey: String {
        "waypoint_pending_sync_queue_v1_\(currentUserID)"
    }

    var currentBookingStorageKey: String {
        "waypoint_user_bookings_v1_\(currentUserID)"
    }

    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "waypoint.network.monitor")
    private(set) var isNetworkReachable: Bool = true

    var activeTrip: Trip
    var totalCommissionEarned: Double
    var userBookings: [Booking]
    private(set) var hasPendingRemoteSync: Bool
    private(set) var syncQueue: [SyncQueueItem] = []
    var pendingQueueCount: Int { syncQueue.count }
    private(set) var isSyncing: Bool = false
    private(set) var syncError: String? = nil
    private(set) var lastSyncedAt: Date? = nil
    var hasRecoveredFromCorruptedTrip: Bool = false
    var lastPersistedAt: Date? = nil

    private init() {
        let loadedQueue = Self.loadSyncQueue()
        totalCommissionEarned = UserDefaults.standard.double(forKey: commissionKey)

        let (loadedBookings, bookingsCorrupted) = Self.loadBookingsWithStatus()
        userBookings = loadedBookings
        syncQueue = loadedQueue
        hasPendingRemoteSync = !loadedQueue.isEmpty || UserDefaults.standard.bool(forKey: syncPendingKey)

        let (loadedTrip, tripCorrupted) = Self.loadPersistedTripWithStatus()
        activeTrip = loadedTrip ?? Trip.createSampleTrip()
        hasRecoveredFromCorruptedTrip = tripCorrupted || bookingsCorrupted

        setupNetworkMonitoring()
    }

    private func setupNetworkMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let reachable = path.status == .satisfied
                self?.isNetworkReachable = reachable
                if reachable {
                    print("[TripStore] Network connection satisfied. Attempting to flush sync queue.")
                    await self?.processSyncQueue()
                }
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }

    var currentDayPlan: DayPlan { activeTrip.currentDayPlan }

    /// The sole canonical mutation boundary for trip state. Increments revision version,
    /// persists locally, enqueues to durable sync queue, updates live activity, and flushes sync queue.
    func mutate(_ reason: String, _ body: (Trip) -> Void) {
        activeTrip.version += 1
        activeTrip.updatedAt = Date()
        body(activeTrip)
        persistLocal(reason: reason)
        enqueueSyncQueue(reason: reason)
        updateLiveActivityIfActive()
        Task { await processSyncQueue() }
    }

    /// Explicit reconciliation boundary comparing remote trip version & timestamp against local activeTrip.
    /// Prunes pending sync queue items acknowledged by the remote version upon adoption.
    @discardableResult
    func reconcileRemoteTrip(_ remoteTrip: Trip) -> ReconciliationResult {
        if remoteTrip.version > activeTrip.version {
            activeTrip = remoteTrip
            pruneSyncQueue(upToVersion: remoteTrip.version)
            persistLocal(reason: "reconciled remote trip (v\(remoteTrip.version) > v\(activeTrip.version))")
            updateLiveActivityIfActive()
            let reason = "Remote version v\(remoteTrip.version) > local version v\(activeTrip.version)"
            print("[TripStore] Reconciled: Applied remote trip. Reason: \(reason).")
            return .appliedRemote(reason: reason)
        } else if remoteTrip.version < activeTrip.version {
            let reason = "Local version v\(activeTrip.version) > remote version v\(remoteTrip.version)"
            print("[TripStore] Reconciled: Retained local trip. Reason: \(reason).")
            return .retainedLocal(reason: reason)
        } else {
            // Version numbers equal: tie-break on updatedAt timestamp
            if remoteTrip.updatedAt > activeTrip.updatedAt {
                activeTrip = remoteTrip
                pruneSyncQueue(upToVersion: remoteTrip.version)
                persistLocal(reason: "reconciled remote trip (newer timestamp at v\(remoteTrip.version))")
                updateLiveActivityIfActive()
                let reason = "Remote timestamp newer than local timestamp at version v\(remoteTrip.version)"
                print("[TripStore] Reconciled: Applied remote trip. Reason: \(reason).")
                return .appliedRemote(reason: reason)
            } else {
                let reason = "Local timestamp newer than or equal to remote timestamp at version v\(remoteTrip.version)"
                print("[TripStore] Reconciled: Retained local trip. Reason: \(reason).")
                return .retainedLocal(reason: reason)
            }
        }
    }

    /// Prunes pending sync queue items whose tripVersion <= specified version.
    func pruneSyncQueue(upToVersion version: Int) {
        let initialCount = syncQueue.count
        syncQueue.removeAll(where: { $0.tripVersion <= version })
        if syncQueue.count != initialCount {
            saveSyncQueue()
            print("[TripStore] Pruned \(initialCount - syncQueue.count) queue item(s) acknowledged up to version v\(version).")
        }
    }

    func replaceActiveTrip(_ trip: Trip, reason: String) {
        activeTrip = trip
        pruneSyncQueue(upToVersion: trip.version)
        persistLocal(reason: reason)
        updateLiveActivityIfActive()
        Task { await processSyncQueue() }
    }

    func selectDay(_ index: Int) {
        guard activeTrip.days.indices.contains(index), activeTrip.selectedDayIndex != index else { return }
        mutate("day selection") { $0.selectedDayIndex = index }
    }

    func updateDayPlan(_ plan: DayPlan, reason: String) {
        guard let index = activeTrip.days.firstIndex(where: { $0.id == plan.id }) else { return }
        mutate(reason) { $0.days[index] = plan }
    }

    func toggleItemCompletion(itemID: UUID) {
        mutate("activity completion") { trip in
            for dayIndex in trip.days.indices {
                guard let itemIndex = trip.days[dayIndex].items.firstIndex(where: { $0.id == itemID }) else { continue }
                trip.days[dayIndex].items[itemIndex].isCompleted.toggle()
                recalculateSpentAmount(for: dayIndex, in: trip)
                return
            }
        }
    }

    func updateItem(_ item: ItineraryItem) {
        mutate("activity update") { trip in
            for dayIndex in trip.days.indices {
                guard let itemIndex = trip.days[dayIndex].items.firstIndex(where: { $0.id == item.id }) else { continue }
                trip.days[dayIndex].items[itemIndex] = item
                recalculateSpentAmount(for: dayIndex, in: trip)
                return
            }
        }
    }

    func appendImportedItems(_ items: [ItineraryItem], to dayID: UUID) {
        guard !items.isEmpty, let dayIndex = activeTrip.days.firstIndex(where: { $0.id == dayID }) else { return }
        mutate("imported itinerary stops") { trip in
            trip.days[dayIndex].items.append(contentsOf: items)
            recalculateSpentAmount(for: dayIndex, in: trip)
        }
    }

    func logExpense(_ receipt: ScannedReceipt, to dayID: UUID) {
        guard let dayIndex = activeTrip.days.firstIndex(where: { $0.id == dayID }) else { return }
        let item = ItineraryItem(
            title: receipt.merchantName,
            subtitle: "OCR Receipt (\(receipt.formattedOriginal))",
            startTime: receipt.timestamp,
            endTime: receipt.timestamp.addingTimeInterval(1800),
            location: activeTrip.days[dayIndex].title,
            category: receipt.category,
            estimatedCost: receipt.convertedAmount,
            isCompleted: true
        )
        mutate("receipt expense") { trip in
            trip.days[dayIndex].items.append(item)
            recalculateSpentAmount(for: dayIndex, in: trip)
        }
    }

    func commitPivot(_ result: PivotResult, dayID: UUID) {
        guard let dayIndex = activeTrip.days.firstIndex(where: { $0.id == dayID }) else { return }
        let originalDay = activeTrip.days[dayIndex]
        UndoPivotManager.shared.pushState(dayID: dayID, tripID: activeTrip.id, originalDay: originalDay, result: result)
        mutate("panic pivot") { $0.days[dayIndex] = result.rebalancedPlan }
    }

    func undoLastPivot(for dayID: UUID? = nil) -> PivotResult? {
        let targetDayID = dayID ?? activeTrip.currentDayPlan.id
        guard let dayIndex = activeTrip.days.firstIndex(where: { $0.id == targetDayID }) else { return nil }
        let restoredDay = UndoPivotManager.shared.undoLastPivot(dayID: targetDayID, in: &activeTrip)
        if restoredDay != nil {
            mutate("undo panic pivot") { _ in } // persist local & queue sync mutation
        }
        return UndoPivotManager.shared.lastResult(for: targetDayID)
    }

    func recordBooking(for item: ItineraryItem) {
        let booking = Booking(
            title: item.title,
            provider: "WayPoint Concierge",
            confirmationCode: "WP-\(Int.random(in: 100000...999999))",
            type: .activity,
            date: item.startTime,
            seatOrRoom: "Confirmed Pass",
            location: item.location,
            cost: item.estimatedCost
        )
        userBookings.insert(booking, at: 0)
        persistLocal(reason: "booking")
        enqueueSyncQueue(reason: "booking pass creation")
        Task { await processSyncQueue() }
    }

    /// Revision-aware remote loading using canonical reconcileRemoteTrip.
    func loadRemoteTripIfNoLocalState() async {
        do {
            let trips = try await SupabaseService.shared.fetchUserTrips()
            if let remoteTrip = trips.first {
                if !hasPersistedTrip {
                    replaceActiveTrip(remoteTrip, reason: "initial remote trip adoption")
                } else {
                    reconcileRemoteTrip(remoteTrip)
                }
            }
        } catch {
            syncError = "Remote fetch error: \(error.localizedDescription)"
        }
    }

    /// Flushes the durable sync queue to Supabase remote database with network reachability,
    /// exponential backoff retry, version conflict reconciliation, and auth state guards.
    func processSyncQueue() async {
        guard !isSyncing else { return }
        guard isNetworkReachable else {
            print("[TripStore] Network unreachable. Retaining \(syncQueue.count) pending item(s) in queue.")
            hasPendingRemoteSync = !syncQueue.isEmpty
            isSyncing = false
            return
        }

        isSyncing = true
        syncError = nil
        defer {
            isSyncing = false
            hasPendingRemoteSync = !syncQueue.isEmpty
        }

        queueLoop: while !syncQueue.isEmpty {
            guard isNetworkReachable else {
                print("[TripStore] Network connectivity dropped during queue processing.")
                hasPendingRemoteSync = !syncQueue.isEmpty
                break queueLoop
            }

            let currentItem = syncQueue[0]
            let result = await SupabaseService.shared.syncTripRecord(activeTrip, reason: currentItem.mutationReason)

            switch result {
            case .success(let response):
                pruneSyncQueue(upToVersion: response.syncedVersion)
                if !syncQueue.isEmpty && syncQueue[0].id == currentItem.id {
                    syncQueue.removeFirst()
                }
                saveSyncQueue()
                lastSyncedAt = Date()
                print("[TripStore] Successfully synced '\(currentItem.mutationReason)' (v\(response.syncedVersion)).")

            case .failure(.conflict(let remoteVersion, let remoteTrip)):
                print("[TripStore] Version conflict (remote v\(remoteVersion) vs local v\(activeTrip.version)). Reconciling.")
                _ = reconcileRemoteTrip(remoteTrip)
                pruneSyncQueue(upToVersion: remoteVersion)
                saveSyncQueue()

            case .failure(.networkUnavailable), .failure(.serverError):
                print("[TripStore] Network unavailable or server error. Retaining queue items for backoff retry.")
                hasPendingRemoteSync = true
                saveSyncQueue()
                break queueLoop

            case .failure(.unauthorized):
                print("[TripStore] Unauthorized session. Pausing queue dispatch without clearing user data.")
                hasPendingRemoteSync = true
                saveSyncQueue()
                break queueLoop
            }
        }
    }

    func retryFailedSync() async {
        if syncQueue.isEmpty {
            enqueueSyncQueue(reason: "manual retry")
        }
        await processSyncQueue()
    }

    func resetLocalStoreToSample() {
        UserDefaults.standard.removeObject(forKey: tripStorageKey)
        UserDefaults.standard.removeObject(forKey: legacyTripStorageKey)
        UserDefaults.standard.removeObject(forKey: bookingStorageKey)
        UserDefaults.standard.removeObject(forKey: syncQueueStorageKey)
        UserDefaults.standard.removeObject(forKey: syncPendingKey)
        userBookings = Booking.samplePasses
        syncQueue = []
        hasPendingRemoteSync = false
        activeTrip = Trip.sample
        persistLocal(reason: "store reset")
    }

    func savePersistedTrip() {
        do {
            let data = try JSONEncoder().encode(activeTrip)
            UserDefaults.standard.set(data, forKey: currentTripStorageKey)
            UserDefaults.standard.set(data, forKey: tripStorageKey)
            let now = Date()
            UserDefaults.standard.set(now, forKey: localMutationKey)
            lastPersistedAt = now
            print("[TripStore] Saved active trip to disk.")
        } catch {
            print("[TripStore] Failed to encode/save active trip: \(error.localizedDescription)")
        }
    }

    func saveBookings() {
        do {
            let data = try JSONEncoder().encode(userBookings)
            UserDefaults.standard.set(data, forKey: currentBookingStorageKey)
            UserDefaults.standard.set(data, forKey: bookingStorageKey)
            let now = Date()
            lastPersistedAt = now
            print("[TripStore] Saved bookings to disk.")
        } catch {
            print("[TripStore] Failed to encode/save bookings: \(error.localizedDescription)")
        }
    }

    func resetStoreWithFreshSample() {
        hasRecoveredFromCorruptedTrip = false
        activeTrip = Trip.createSampleTrip()
        userBookings = Booking.samplePasses
        clearPendingQueue()

        UserDefaults.standard.removeObject(forKey: "waypoint_persisted_trip_data_v2_corrupted_backup")
        UserDefaults.standard.removeObject(forKey: "waypoint_user_bookings_v1_corrupted_backup")

        persistLocal(reason: "store reset with fresh sample")
        print("[TripStore] Store reset with fresh sample trip and bookings.")
    }

    func reloadFromDisk() {
        let (loadedTrip, tripCorrupted) = Self.loadPersistedTripWithStatus()
        let (loadedBookings, bookingsCorrupted) = Self.loadBookingsWithStatus()

        activeTrip = loadedTrip ?? Trip.createSampleTrip()
        userBookings = loadedBookings
        hasRecoveredFromCorruptedTrip = tripCorrupted || bookingsCorrupted
    }

    private var hasPersistedTrip: Bool {
        UserDefaults.standard.data(forKey: tripStorageKey) != nil || UserDefaults.standard.data(forKey: legacyTripStorageKey) != nil
    }

    /// Clears all pending mutations from the durable sync queue and updates local persistence immediately.
    func clearPendingQueue() {
        syncQueue.removeAll()
        saveSyncQueue()
        print("[TripStore] Cleared pending sync queue.")
    }

    // MARK: - User Lifecycle & Auth Isolation
    
    func handleUserSignOut() {
        currentUserID = "guest_user"
        syncQueue = []
        activeTrip = Trip.createSampleTrip()
        hasPendingRemoteSync = false
        saveSyncQueue()
        persistLocal(reason: "user_sign_out")
        print("[TripStore] User signed out. Data re-isolated to guest state.")
    }

    func handleUserSignIn(userID: String) {
        currentUserID = userID
        if let data = UserDefaults.standard.data(forKey: currentTripStorageKey),
           let loaded = try? JSONDecoder().decode(Trip.self, from: data) {
            activeTrip = loaded
        } else {
            let newTrip = Trip.createSampleTrip()
            if let uuid = UUID(uuidString: userID) {
                newTrip.userID = uuid
            }
            activeTrip = newTrip
            persistLocal(reason: "user_sign_in_initialization")
        }

        if let qData = UserDefaults.standard.data(forKey: currentSyncQueueStorageKey),
           let loadedQueue = try? JSONDecoder().decode([SyncQueueItem].self, from: qData) {
            syncQueue = loadedQueue
        } else {
            syncQueue = []
        }
        hasPendingRemoteSync = !syncQueue.isEmpty
        print("[TripStore] User signed in as '\(userID)'. Storage re-scoped to user namespace.")
    }

    private func persistLocal(reason: String) {
        do {
            let tripData = try JSONEncoder().encode(activeTrip)
            let bookingData = try JSONEncoder().encode(userBookings)

            UserDefaults.standard.set(tripData, forKey: currentTripStorageKey)
            UserDefaults.standard.set(tripData, forKey: tripStorageKey)
            UserDefaults.standard.set(bookingData, forKey: currentBookingStorageKey)
            UserDefaults.standard.set(bookingData, forKey: bookingStorageKey)
            UserDefaults.standard.set(totalCommissionEarned, forKey: commissionKey)

            let now = Date()
            UserDefaults.standard.set(now, forKey: localMutationKey)
            lastPersistedAt = now
            print("[TripStore] Persisted \(reason) (v\(activeTrip.version)) under namespace '\(currentUserID)'.")
        } catch {
            print("[TripStore] Failed to persist \(reason): \(error.localizedDescription)")
        }
    }

    /// Enqueues a SyncQueueItem with consecutive 1.0s deduplication and strict max 100 capacity.
    func enqueueSyncItem(_ item: SyncQueueItem) {
        // Deduplication: prevent consecutive duplicate mutations for same tripID & mutationReason within 1.0s
        if let lastItem = syncQueue.last,
           lastItem.tripID == item.tripID,
           lastItem.mutationReason == item.mutationReason,
           abs(item.timestamp.timeIntervalSince(lastItem.timestamp)) <= 1.0 {
            print("[TripStore] Deduplicated queue item '\(item.mutationReason)' (same tripID & reason within 1.0s).")
            return
        }

        // Bounded Queue: max capacity 100
        while syncQueue.count >= 100 {
            let pruned = syncQueue.removeFirst()
            print("[TripStore] Queue capacity (100) reached. Pruned oldest item '\(pruned.mutationReason)' (v\(pruned.tripVersion)).")
        }

        syncQueue.append(item)
        saveSyncQueue()
    }

    private func enqueueSyncQueue(reason: String) {
        let item = SyncQueueItem(tripID: activeTrip.id, mutationReason: reason, tripVersion: activeTrip.version)
        enqueueSyncItem(item)
    }

    private func saveSyncQueue() {
        if let data = try? JSONEncoder().encode(syncQueue) {
            UserDefaults.standard.set(data, forKey: currentSyncQueueStorageKey)
            UserDefaults.standard.set(data, forKey: syncQueueStorageKey)
        }
        hasPendingRemoteSync = !syncQueue.isEmpty
        UserDefaults.standard.set(hasPendingRemoteSync, forKey: syncPendingKey)
    }

    private func recalculateSpentAmount(for dayIndex: Int, in trip: Trip) {
        trip.days[dayIndex].spentAmount = trip.days[dayIndex].items
            .filter(\.isCompleted)
            .reduce(Decimal(0)) { $0 + $1.estimatedCost }
    }

    private func updateLiveActivityIfActive() {
        guard LiveActivityManager.shared.isActivityActive else { return }
        let day = activeTrip.currentDayPlan
        let activeItem = day.items.first(where: { !$0.isCompleted }) ?? day.items.first ?? ItineraryItem(title: "Hotel Check-in", subtitle: "", startTime: Date(), endTime: Date(), location: activeTrip.destination, category: .stay, estimatedCost: 0)
        let nextItem = day.items.first(where: { $0.id != activeItem.id && !$0.isCompleted })
        LiveActivityManager.shared.updateCurrentStop(
            currentItem: activeItem,
            nextItem: nextItem,
            distanceMeters: LiveActivityManager.shared.activeVenueDistance,
            budgetProgress: day.budgetProgress,
            spentAmount: day.formatCurrency(day.spentAmount),
            remainingAmount: day.formattedRemaining
        )
    }

    static func loadPersistedTripWithStatus() -> (trip: Trip?, wasCorrupted: Bool) {
        let defaults = UserDefaults.standard
        for key in ["waypoint_persisted_trip_data_v2", "waypoint_persisted_trip_data_v1"] {
            guard let data = defaults.data(forKey: key) else { continue }
            do {
                let trip = try JSONDecoder().decode(Trip.self, from: data)
                return (trip, false)
            } catch {
                let backupKey = "waypoint_persisted_trip_data_v2_corrupted_backup"
                defaults.set(data, forKey: backupKey)
                print("[TripStore] Corrupted trip data detected for key '\(key)': \(error.localizedDescription). Archived backup copy at '\(backupKey)'. Falling back to sample trip.")
                return (Trip.createSampleTrip(), true)
            }
        }
        return (nil, false)
    }

    private static func loadPersistedTrip() -> Trip? {
        let (trip, _) = loadPersistedTripWithStatus()
        return trip
    }

    static func loadBookingsWithStatus() -> (bookings: [Booking], wasCorrupted: Bool) {
        guard let data = UserDefaults.standard.data(forKey: "waypoint_user_bookings_v1") else {
            return (Booking.samplePasses, false)
        }
        do {
            let bookings = try JSONDecoder().decode([Booking].self, from: data)
            return (bookings, false)
        } catch {
            let backupKey = "waypoint_user_bookings_v1_corrupted_backup"
            UserDefaults.standard.set(data, forKey: backupKey)
            print("[TripStore] Corrupted bookings data detected: \(error.localizedDescription). Archived backup copy at '\(backupKey)'. Defaulting userBookings to empty array.")
            return ([], true)
        }
    }

    private static func loadBookings() -> [Booking]? {
        let (bookings, _) = loadBookingsWithStatus()
        return bookings
    }

    private static func loadSyncQueue() -> [SyncQueueItem] {
        guard let data = UserDefaults.standard.data(forKey: "waypoint_pending_sync_queue_v1") else { return [] }
        return (try? JSONDecoder().decode([SyncQueueItem].self, from: data)) ?? []
    }
}
