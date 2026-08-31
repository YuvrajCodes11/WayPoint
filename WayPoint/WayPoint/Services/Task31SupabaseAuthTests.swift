//
//  Task31SupabaseAuthTests.swift
//  WayPoint
//
//  Task 3.1: Supabase Client Architecture, Auth Session & User Isolation Automated Test Suite
//

import Foundation
import SwiftUI

@MainActor
final class Task31SupabaseAuthTests {
    static let shared = Task31SupabaseAuthTests()

    private init() {}

    struct TestResult {
        let name: String
        let passed: Bool
        let details: String
    }

    /// Runs all Task 3.1 test scenarios (A, B, C, D) and returns structured results.
    func runAllTask31Tests() async -> [TestResult] {
        var results: [TestResult] = []

        results.append(await testA_SessionStateMachine())
        results.append(await testB_SignOutDataIsolation())
        results.append(await testC_MultiUserNamespacing())
        results.append(await testD_TokenExpirationRecovery())

        for res in results {
            print("[TASK-3.1-TEST] \(res.passed ? "✅ PASS" : "❌ FAIL") - \(res.name): \(res.details)")
        }

        return results
    }

    // MARK: - Test A: Session State Machine
    private func testA_SessionStateMachine() async -> TestResult {
        let service = SupabaseService.shared

        // Test Invalid Token Failure
        let invalidRes = await service.signIn(email: "test_a@waypoint.ai", token: "invalid_token")
        var invalidHandled = false
        if case .failure = invalidRes, case .error = service.authState {
            invalidHandled = true
        }

        // Test Valid Token Sign In
        let validRes = await service.signIn(email: "test_a@waypoint.ai", token: "valid_token_123")
        var validHandled = false
        if case .success(let userID) = validRes, case .authenticated(let authedID, _) = service.authState, authedID == userID {
            validHandled = true
        }

        let passed = invalidHandled && validHandled

        return TestResult(
            name: "Test A: Session State Machine",
            passed: passed,
            details: "Invalid token error handled: \(invalidHandled). Valid auth transition: \(validHandled)."
        )
    }

    // MARK: - Test B: Sign Out Data Isolation
    private func testB_SignOutDataIsolation() async -> TestResult {
        let service = SupabaseService.shared
        let store = TripStore.shared

        // User A signs in and makes sensitive mutations
        _ = await service.signIn(email: "user_a_isolation@waypoint.ai", token: "valid_token_a")
        store.mutate("sensitive_user_a_mutation") { trip in
            trip.destination = "Confidential User A Trip Location"
        }

        let preSignOutQueueCount = store.pendingQueueCount
        let preSignOutDest = store.activeTrip.destination

        // User A signs out
        await service.signOut()

        let postSignOutQueueCount = store.pendingQueueCount
        let postSignOutDest = store.activeTrip.destination
        let postAuthState = service.authState

        let queueCleared = (preSignOutQueueCount > 0 && postSignOutQueueCount == 0)
        let destReset = (preSignOutDest == "Confidential User A Trip Location" && postSignOutDest != "Confidential User A Trip Location")
        let isUnauthed = (postAuthState == .unauthenticated)

        let passed = queueCleared && destReset && isUnauthed

        return TestResult(
            name: "Test B: Sign Out Data Isolation",
            passed: passed,
            details: "Pre-signOut queue: \(preSignOutQueueCount) ('\(preSignOutDest)'), Post-signOut queue: \(postSignOutQueueCount) ('\(postSignOutDest)'), AuthState: \(postAuthState)."
        )
    }

    // MARK: - Test C: Multi-User Namespacing
    private func testC_MultiUserNamespacing() async -> TestResult {
        let service = SupabaseService.shared
        let store = TripStore.shared

        // 1. User A signs in and creates custom trip
        let resA = await service.signIn(email: "user_alpha@waypoint.ai", token: "valid_token_alpha")
        guard case .success(let userAID) = resA else {
            return TestResult(name: "Test C: Multi-User Namespacing", passed: false, details: "User A sign in failed.")
        }
        store.mutate("user_a_trip_setup") { trip in
            trip.destination = "Tokyo Alpha Base"
        }

        // 2. User B signs in and creates different custom trip
        let resB = await service.signIn(email: "user_beta@waypoint.ai", token: "valid_token_beta")
        guard case .success(let userBID) = resB else {
            return TestResult(name: "Test C: Multi-User Namespacing", passed: false, details: "User B sign in failed.")
        }
        store.mutate("user_b_trip_setup") { trip in
            trip.destination = "Kyoto Beta Base"
        }
        let userBDest = store.activeTrip.destination

        // 3. Re-sign in as User A and verify Tokyo Alpha Base is re-loaded
        _ = await service.signIn(email: "user_alpha@waypoint.ai", token: "valid_token_alpha")
        let reloadedUserADest = store.activeTrip.destination

        let noCrossLeakage = (userBDest == "Kyoto Beta Base" && reloadedUserADest == "Tokyo Alpha Base")

        return TestResult(
            name: "Test C: Multi-User Namespacing",
            passed: noCrossLeakage,
            details: "User A (id: \(userAID)): '\(reloadedUserADest)'. User B (id: \(userBID)): '\(userBDest)'."
        )
    }

    // MARK: - Test D: Token Expiration Recovery
    private func testD_TokenExpirationRecovery() async -> TestResult {
        let service = SupabaseService.shared

        // Save expired session token (expired 1 hour ago)
        let expiredSession = AuthSession(
            userID: "expired_user_123",
            email: "expired@waypoint.ai",
            sessionToken: "session_expired",
            refreshToken: "refresh_expired",
            expiresAt: Date().addingTimeInterval(-3600)
        )
        service.saveAuthSession(expiredSession)

        // Validate session
        let isValid = service.validateSession()
        let postState = service.authState

        let recovered = (!isValid && postState == .unauthenticated)

        return TestResult(
            name: "Test D: Token Expiration Recovery",
            passed: recovered,
            details: "Expired token validation result: \(isValid). AuthState transitioned to: \(postState)."
        )
    }
}
