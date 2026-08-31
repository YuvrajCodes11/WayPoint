//
//  SupabaseConfig.swift
//  WayPoint
//
//  Task 3.1: Supabase Client Architecture & Auth Session Configuration
//

import Foundation

public struct SupabaseConfig {
    public static var urlString: String {
        if let envUrl = ProcessInfo.processInfo.environment["SUPABASE_URL"], !envUrl.isEmpty {
            return envUrl
        }
        if let configUrl = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String, !configUrl.isEmpty {
            return configUrl
        }
        return "https://ghqsjpsdpxswxwescjcm.supabase.co"
    }

    public static var publishableKey: String {
        if let envKey = ProcessInfo.processInfo.environment["SUPABASE_PUBLISHABLE_KEY"], !envKey.isEmpty {
            return envKey
        }
        if let configKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String, !configKey.isEmpty {
            return configKey
        }
        return "sb_publishable_64GdTpBNAq2sXH1QTLIs4w_Ml-2EYKy"
    }

    public static var url: URL {
        URL(string: urlString)!
    }

    public static func validateSecretsConfiguration() -> Bool {
        #if !DEBUG
        if publishableKey.contains("placeholder") || publishableKey.contains("CHANGE_ME") {
            print("[SECURITY WARNING] Release mode detected with unconfigured placeholder Supabase key!")
            return false
        }
        #endif
        return true
    }
}

public enum AuthState: Equatable {
    case unauthenticated
    case authenticating
    case authenticated(userID: String, email: String?)
    case error(String)
}

public struct AuthSession: Codable, Equatable {
    public let userID: String
    public let email: String?
    public let sessionToken: String
    public let refreshToken: String
    public let expiresAt: Date

    public var isExpired: Bool {
        Date() >= expiresAt
    }

    public init(userID: String, email: String?, sessionToken: String, refreshToken: String, expiresAt: Date) {
        self.userID = userID
        self.email = email
        self.sessionToken = sessionToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }
}

struct RemoteSyncResponse: Codable, Equatable {
    let syncedVersion: Int
    let remoteTrip: Trip?
    let timestamp: Date

    init(syncedVersion: Int, remoteTrip: Trip? = nil, timestamp: Date = Date()) {
        self.syncedVersion = syncedVersion
        self.remoteTrip = remoteTrip
        self.timestamp = timestamp
    }

    static func == (lhs: RemoteSyncResponse, rhs: RemoteSyncResponse) -> Bool {
        return lhs.syncedVersion == rhs.syncedVersion &&
               lhs.remoteTrip?.id == rhs.remoteTrip?.id &&
               lhs.remoteTrip?.version == rhs.remoteTrip?.version
    }
}

enum SupabaseSyncError: Error, Equatable {
    case unauthorized
    case conflict(remoteVersion: Int, remoteTrip: Trip)
    case networkUnavailable
    case serverError(code: Int)

    static func == (lhs: SupabaseSyncError, rhs: SupabaseSyncError) -> Bool {
        switch (lhs, rhs) {
        case (.unauthorized, .unauthorized):
            return true
        case (.networkUnavailable, .networkUnavailable):
            return true
        case (.serverError(let c1), .serverError(let c2)):
            return c1 == c2
        case (.conflict(let v1, let t1), .conflict(let v2, let t2)):
            return v1 == v2 && t1.id == t2.id && t1.version == t2.version
        default:
            return false
        }
    }
}
