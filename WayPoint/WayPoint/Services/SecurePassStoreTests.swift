//
//  SecurePassStoreTests.swift
//  WayPoint
//
//  Phase 4: Unit Tests for Secure Pass Vault Storage & Barcode Generation
//

import Foundation
import SwiftUI

@MainActor
public final class SecurePassStoreTests {
    public static func runAllTests() {
        print("\n--- Running SecurePassStore & Phase 4 Vault Tests ---")

        testSaveAndRetrievePass()
        testRemovePass()
        testBarcodeGeneration()

        print("--- SecurePassStore Tests Finished Successfully ---\n")
    }

    private static func testSaveAndRetrievePass() {
        let store = SecurePassStore.shared
        let initialCount = store.passes.count

        let testTripId = UUID()
        let pass = TravelPass(
            id: UUID(),
            tripId: testTripId,
            title: "Unit Test Flight Pass",
            providerName: "Test Airlines",
            passType: .flight,
            confirmationCode: "TEST-12345",
            barcodePayload: "TEST-12345-PAYLOAD",
            validFrom: Date(),
            seatOrRoom: "Seat 1A"
        )

        store.savePass(pass)
        assert(store.passes.count == initialCount + 1, "Save pass failed to increment count")

        let retrieved = store.passes(for: testTripId)
        assert(retrieved.count == 1, "Failed to retrieve pass by trip ID")
        assert(retrieved.first?.confirmationCode == "TEST-12345", "Retrieved pass confirmation code mismatch")

        // Cleanup
        store.removePass(id: pass.id)
        assert(store.passes.count == initialCount, "Failed to clean up test pass")
        print("✅ testSaveAndRetrievePass passed")
    }

    private static func testRemovePass() {
        let store = SecurePassStore.shared
        let initialCount = store.passes.count

        let pass = TravelPass(
            id: UUID(),
            tripId: UUID(),
            title: "Temp Hotel Pass",
            providerName: "Temp Hotel",
            passType: .hotel,
            confirmationCode: "TEMP-999",
            barcodePayload: "TEMP-999"
        )

        store.savePass(pass)
        assert(store.passes.count == initialCount + 1, "Failed to add temp pass")

        store.removePass(id: pass.id)
        assert(store.passes.count == initialCount, "Failed to remove pass by ID")
        print("✅ testRemovePass passed")
    }

    private static func testBarcodeGeneration() {
        let qrImage = PassBarcodeGenerator.generateQRCode(from: "WAYPOINT-TEST-QR")
        assert(qrImage != nil, "QR Code generator output nil image")

        let code128 = PassBarcodeGenerator.generateCode128Barcode(from: "WAYPOINT-TEST-BARCODE")
        assert(code128 != nil, "Code 128 barcode generator output nil image")

        print("✅ testBarcodeGeneration passed")
    }
}
