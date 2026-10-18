//
//  ProductionArchitectureTests.swift
//  WayPoint
//
//  Module 5: Integration Tests for Production Architecture (AppConfig, Keychain, StoreKit, Network)
//

import Foundation

@MainActor
public final class ProductionArchitectureTests {
    public static func runAllTests() {
        print("\n--- Running Production Architecture Tests ---")

        testAppConfigFlags()
        testKeychainServiceOperations()
        testStoreKitProductsCatalog()
        testNetworkServiceOfflineFallback()

        print("--- Production Architecture Tests Finished Successfully ---\n")
    }

    private static func testAppConfigFlags() {
        let config = AppConfig.shared
        // Verify key-agnostic accessors don't crash
        _ = config.supabaseURL
        _ = config.supabaseAnonKey
        _ = config.weatherAPIKey
        _ = config.transitAPIEndpoint

        let _ = config.isLiveBackendConfigured
        let _ = config.isLiveWeatherConfigured
        print("✅ testAppConfigFlags passed")
    }

    private static func testKeychainServiceOperations() {
        let keychain = KeychainService.shared
        let testKey = "waypoint_unit_test_keychain_key"
        let testValue = "hardware_backed_secret_12345"

        let saved = keychain.saveString(testValue, forKey: testKey)
        assert(saved, "Failed to save string to Keychain")

        let readValue = keychain.readString(forKey: testKey)
        assert(readValue == testValue, "Keychain read value mismatch")

        let deleted = keychain.delete(key: testKey)
        assert(deleted, "Failed to delete string from Keychain")

        assert(keychain.readString(forKey: testKey) == nil, "Keychain key not deleted")
        print("✅ testKeychainServiceOperations passed")
    }

    private static func testStoreKitProductsCatalog() {
        let catalog = StoreKitManager.productCatalog
        assert(catalog.count == 3, "Product catalog expected 3 production products")

        let ids = Set(catalog.map(\.id))
        assert(ids.contains(WayPointProductIdentifier.monthlyPro), "Missing monthly product ID")
        assert(ids.contains(WayPointProductIdentifier.annualPro), "Missing annual product ID")
        assert(ids.contains(WayPointProductIdentifier.lifetimePro), "Missing lifetime product ID")

        print("✅ testStoreKitProductsCatalog passed")
    }

    private static func testNetworkServiceOfflineFallback() {
        Task {
            let report = await NetworkService.shared.fetchWeather(latitude: 35.6762, longitude: 139.6503)
            assert(report.latitude == 35.6762, "Latitude mismatch in weather report")
            print("✅ testNetworkServiceOfflineFallback passed")
        }
    }
}
