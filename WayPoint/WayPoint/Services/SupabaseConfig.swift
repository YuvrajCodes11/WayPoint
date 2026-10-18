//
//  SupabaseConfig.swift
//  WayPoint
//
//  Task 3.1: Supabase Client Architecture & Auth Session Configuration
//

import Foundation

public struct SupabaseConfig {
    public static var isOfflineMode: Bool {
        guard let url = AppConfig.shared.supabaseURL else { return true }
        return url.absoluteString.contains("local.waypoint.internal") || !AppConfig.shared.isLiveBackendConfigured
    }

    public static var urlString: String {
        AppConfig.shared.supabaseURL?.absoluteString ?? "https://local.waypoint.internal"
    }

    public static var publishableKey: String {
        AppConfig.shared.supabaseAnonKey ?? ""
    }

    public static var url: URL {
        AppConfig.shared.supabaseURL ?? URL(string: "https://local.waypoint.internal")!
    }

    public static func validateSecretsConfiguration() -> Bool {
        return AppConfig.shared.isLiveBackendConfigured && !isOfflineMode
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
