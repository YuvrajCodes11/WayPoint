//
//  AppConfig.swift
//  WayPoint
//
//  Module 1: Centralized Key-Agnostic Configuration Engine
//

import Foundation

public final class AppConfig {
    public static let shared = AppConfig()

    private init() {}

    /// Dynamically resolved Supabase URL from environment or Info.plist
    public var supabaseURL: URL? {
        if let envUrl = ProcessInfo.processInfo.environment["SUPABASE_URL"],
           !envUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let url = URL(string: envUrl) {
            return url
        }
        if let configUrl = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
           !configUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let url = URL(string: configUrl) {
            return url
        }
        return nil
    }

    /// Dynamically resolved Supabase Anon / Publishable Key
    public var supabaseAnonKey: String? {
        if let envKey = ProcessInfo.processInfo.environment["SUPABASE_PUBLISHABLE_KEY"],
           !envKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return envKey
        }
        if let configKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String,
           !configKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return configKey
        }
        return nil
    }

    /// Dynamically resolved Weather API Key
    public var weatherAPIKey: String? {
        if let envKey = ProcessInfo.processInfo.environment["WEATHER_API_KEY"],
           !envKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return envKey
        }
        if let configKey = Bundle.main.object(forInfoDictionaryKey: "WEATHER_API_KEY") as? String,
           !configKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return configKey
        }
        return nil
    }

    /// Dynamically resolved Transit API Endpoint
    public var transitAPIEndpoint: URL? {
        if let envUrl = ProcessInfo.processInfo.environment["TRANSIT_API_ENDPOINT"],
           !envUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let url = URL(string: envUrl) {
            return url
        }
        if let configUrl = Bundle.main.object(forInfoDictionaryKey: "TRANSIT_API_ENDPOINT") as? String,
           !configUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let url = URL(string: configUrl) {
            return url
        }
        return nil
    }

    // MARK: - Status Flags

    /// True if both Supabase URL and key are provided and valid
    public var isLiveBackendConfigured: Bool {
        guard let url = supabaseURL, !url.absoluteString.isEmpty else { return false }
        guard let key = supabaseAnonKey, !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        return true
    }

    /// True if Weather API Key or live weather endpoint is configured
    public var isLiveWeatherConfigured: Bool {
        guard let key = weatherAPIKey, !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        return true
    }
}
