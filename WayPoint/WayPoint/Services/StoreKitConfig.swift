//
//  StoreKitConfig.swift
//  WayPoint
//
//  WP8: StoreKit 2 & RevenueCat Production Security Configuration
//

import Foundation

public struct StoreKitConfig {
    public static var monthlyProductID: String {
        WayPointProductIdentifier.monthlyPro
    }

    public static var weeklyProductID: String {
        WayPointProductIdentifier.monthlyPro
    }

    public static var annualProductID: String {
        WayPointProductIdentifier.annualPro
    }

    public static var lifetimeProductID: String {
        WayPointProductIdentifier.lifetimePro
    }

    public static var subscriptionGroupID: String {
        ProcessInfo.processInfo.environment["STOREKIT_GROUP_ID"] ?? "WayPointProGroup"
    }

    public static var revenueCatAPIKey: String {
        if let envKey = ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String, !plistKey.isEmpty {
            return plistKey
        }
        return "appl_placeholder_key"
    }

    public static func validateStoreKitConfiguration() -> Bool {
        #if !DEBUG
        if revenueCatAPIKey == "appl_placeholder_key" || revenueCatAPIKey.contains("placeholder") {
            print("[SECURITY WARNING] Release mode detected with unconfigured RevenueCat API Key!")
            return false
        }
        #endif
        return true
    }
}
