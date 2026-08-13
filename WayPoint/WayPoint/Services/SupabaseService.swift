//
//  SupabaseService.swift
//  WayPoint
//

import SwiftUI
import Observation
import Security
import Supabase

@MainActor
@Observable
class SupabaseService {
    static let shared = SupabaseService()

    let client = SupabaseClient(
        supabaseURL: URL(string: "https://ghqsjpsdpxswxwescjcm.supabase.co")!,
        supabaseKey: "sb_publishable_64GdTpBNAq2sXH1QTLIs4w_Ml-2EYKy"
    )

    var isAuthenticated: Bool = false
    var currentUserEmail: String? = nil
    var isSyncing: Bool = false
    var lastSyncedAt: Date? = nil
    var isOfflineMode: Bool = false
    var pendingEmailOrPhone: String? = nil
    var isOTPRequested: Bool = false

    private let keychainServiceKey = "app.waypoint.user_session"

    init() {
        // Restore persistent session token from iOS Keychain on startup
        if let savedSession = loadSessionFromKeychain() {
            self.isAuthenticated = true
            self.currentUserEmail = savedSession
        } else {
            self.isAuthenticated = false
            self.currentUserEmail = nil
        }
    }

    /// Sends a Supabase Auth OTP code to email or phone number
    func sendOTP(to phoneOrEmail: String) async throws {
        try await signInWithOTP(emailOrPhone: phoneOrEmail)
    }

    /// Sends a Supabase Auth OTP code to email or phone number
    func signInWithOTP(emailOrPhone: String) async throws {
        isSyncing = true
        defer { isSyncing = false }

        self.pendingEmailOrPhone = emailOrPhone
        self.isOTPRequested = true

        if emailOrPhone.contains("@") {
            try await client.auth.signInWithOTP(email: emailOrPhone)
        } else {
            try await client.auth.signInWithOTP(phone: emailOrPhone)
        }
        print("[SupabaseService] OTP code sent to \(emailOrPhone).")
    }

    /// Verifies 6-digit OTP code token via live Supabase Auth
    func verifyOTP(token: String) async throws -> Bool {
        isSyncing = true
        defer { isSyncing = false }

        let trimmedToken = token.trimmingCharacters(in: .whitespaces)
        guard let pending = pendingEmailOrPhone, !pending.isEmpty else {
            print("[SupabaseService] Error: No pending email/phone for verification.")
            return false
        }

        if pending.contains("@") {
            try await client.auth.verifyOTP(email: pending, token: trimmedToken, type: .email)
        } else {
            try await client.auth.verifyOTP(phone: pending, token: trimmedToken, type: .sms)
        }

        self.currentUserEmail = pending
        self.isAuthenticated = true
        self.lastSyncedAt = Date()
        saveSessionToKeychain(email: pending)
        print("[SupabaseService] OTP Verification successful for \(pending).")
        return true
    }

    func signIn(email: String) async throws {
        self.currentUserEmail = email
        self.isAuthenticated = true
        saveSessionToKeychain(email: email)
    }

    func signOut() async {
        try? await client.auth.signOut()
        self.isAuthenticated = false
        self.currentUserEmail = nil
        self.pendingEmailOrPhone = nil
        self.isOTPRequested = false
        clearKeychainSession()
    }

    /// Asynchronously fetches user trips from Supabase Postgres database
    func fetchUserTrips() async throws -> [Trip] {
        isSyncing = true
        defer { isSyncing = false }

        let trips: [Trip] = try await client
            .from("trips")
            .select("*, itinerary_items(*)")
            .execute()
            .value
        self.lastSyncedAt = Date()
        return trips
    }

    /// Asynchronously saves or updates trip row in Supabase database
    func saveTrip(trip: Trip) async throws {
        isSyncing = true
        defer { isSyncing = false }

        try await client
            .from("trips")
            .upsert(trip)
            .execute()
        lastSyncedAt = Date()
    }

    /// Asynchronously re-balances trip itinerary rows via Supabase Edge Functions
    func rebalanceTripItinerary(tripID: UUID) async throws -> Trip {
        isSyncing = true
        defer { isSyncing = false }

        let updatedTrip: Trip = try await client.functions
            .invoke(
                "rebalance-itinerary",
                options: FunctionInvokeOptions(
                    body: ["trip_id": tripID.uuidString]
                )
            )
        lastSyncedAt = Date()
        return updatedTrip
    }

    func syncOfflineChanges() async {
        isSyncing = true
        defer { isSyncing = false }
        lastSyncedAt = Date()
    }

    // MARK: - iOS Keychain Persistent Session Storage

    private func saveSessionToKeychain(email: String) {
        guard let data = email.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainServiceKey,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadSessionFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainServiceKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess, let data = dataTypeRef as? Data, let email = String(data: data, encoding: .utf8) {
            return email
        }
        return nil
    }

    private func clearKeychainSession() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainServiceKey
        ]
        SecItemDelete(query as CFDictionary)
    }
}
