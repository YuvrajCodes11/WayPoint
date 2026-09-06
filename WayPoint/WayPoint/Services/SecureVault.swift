//
//  SecureVault.swift
//  WayPoint
//
//  Created by Yuvraj for RevenueCat #Shipaton 2026
//  Task 3: Apple Secure Enclave Pass Vault (Hardware & Simulator Hardened)
//

import Foundation
import Security
@preconcurrency import LocalAuthentication
import Combine

// MARK: - Domain Specific Vault Errors
public enum VaultError: LocalizedError, Equatable {
    case passNotFound
    case biometricsUnavailable(String)
    case userCancelled
    case keychainError(OSStatus)
    case accessControlCreationFailed
    case invalidPayload
    
    public var errorDescription: String? {
        switch self {
        case .passNotFound:
            return "Ticket or pass not found in Secure Enclave Vault."
        case .biometricsUnavailable(let reason):
            return "Biometrics unavailable: \(reason)"
        case .userCancelled:
            return "Authentication was cancelled by the user."
        case .keychainError(let status):
            return "Keychain system error (OSStatus: \(status))."
        case .accessControlCreationFailed:
            return "Failed to configure Secure Enclave access control flags."
        case .invalidPayload:
            return "The stored ticket payload is invalid or corrupted."
        }
    }
}

// MARK: - Local Pass Ticket Model
public struct OfflineTicket: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let passType: String
    public let carrier: String
    public let seat: String
    public let qrCodePayload: String
    public let issueDate: Date
    
    public init(
        id: String,
        title: String,
        passType: String,
        carrier: String,
        seat: String,
        qrCodePayload: String,
        issueDate: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.passType = passType
        self.carrier = carrier
        self.seat = seat
        self.qrCodePayload = qrCodePayload
        self.issueDate = issueDate
    }
}

// MARK: - Apple Secure Enclave Pass Vault Manager (Hardware & Simulator Hardened)
public final class SecureVault: @unchecked Sendable {
    public static let shared = SecureVault()
    private let serviceName = "com.waypoint.passvault"
    
    private init() {}
    
    // MARK: - Biometric Capability Check
    public var isBiometricsAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    public var biometricTypeString: String {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return "Device Passcode"
        }
        switch context.biometryType {
        case .none: return "Device Passcode"
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        @unknown default: return "Biometrics"
        }
    }
    
    // MARK: - Store Ticket Gated by Secure Enclave / Keychain (Result API)
    @discardableResult
    public func storeTicket(passId: String, rawData: Data) -> Result<Void, Error> {
        var error: Unmanaged<CFError>?
        
        // Primary Attempt: Gated by biometryCurrentSet
        let primaryAccessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryCurrentSet,
            &error
        )
        
        // Fallback for Simulator or hardware without configured biometrics
        let finalAccessControl: SecAccessControl? = primaryAccessControl ?? SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .userPresence,
            &error
        )
        
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: passId
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: passId,
            kSecValueData as String: rawData
        ]
        
        if let ac = finalAccessControl {
            query[kSecAttrAccessControl as String] = ac
        }
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            return .failure(VaultError.keychainError(status))
        }
        
        print("[SecureVault] Successfully stored ticket '\(passId)' in Secure Enclave / Keychain.")
        return .success(())
    }
    
    public func storeTicket(_ ticket: OfflineTicket) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(ticket)
        let result = storeTicket(passId: ticket.id, rawData: data)
        if case .failure(let err) = result {
            throw err
        }
    }
    
    // MARK: - Unlock Ticket Offline (Completion Handler API on Main Thread)
    public func unlockTicketOffline(passId: String, completion: @escaping (Result<Data, Error>) -> Void) {
        Task {
            do {
                let data = try await unlockTicketOfflineAsync(id: passId)
                await MainActor.run {
                    completion(.success(data))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Unlock Ticket Offline (Combine Publisher)
    public func unlockTicketOffline(id: String) -> AnyPublisher<Data, Error> {
        return Future<Data, Error> { promise in
            self.unlockTicketOffline(passId: id) { result in
                switch result {
                case .success(let data): promise(.success(data))
                case .failure(let err): promise(.failure(err))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Unlock Ticket Offline (Async/Await)
    public func unlockTicketOfflineAsync(id: String) async throws -> Data {
        let laContext = LAContext()
        laContext.localizedFallbackTitle = "Enter Device Passcode"
        laContext.touchIDAuthenticationAllowableReuseDuration = 0
        
        let authReason = "Unlock offline travel pass via Secure Enclave"
        let targetService = self.serviceName
        
        return try await withCheckedThrowingContinuation { continuation in
            laContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: authReason) { success, authError in
                if !success {
                    if let err = authError as? LAError {
                        switch err.code {
                        case .userCancel, .appCancel, .systemCancel:
                            continuation.resume(throwing: VaultError.userCancelled)
                            return
                        case .biometryNotAvailable, .biometryNotEnrolled:
                            continuation.resume(throwing: VaultError.biometricsUnavailable(err.localizedDescription))
                            return
                        default:
                            break
                        }
                    }
                    let reason = authError?.localizedDescription ?? "Authentication cancelled or failed"
                    continuation.resume(throwing: VaultError.biometricsUnavailable(reason))
                    return
                }
                
                // Biometrics / Passcode passed locally on-device. Query Keychain.
                let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: targetService,
                    kSecAttrAccount as String: id,
                    kSecReturnData as String: true,
                    kSecMatchLimit as String: kSecMatchLimitOne,
                    kSecUseAuthenticationContext as String: laContext
                ]
                
                var dataTypeRef: CFTypeRef?
                let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
                
                if status == errSecItemNotFound {
                    continuation.resume(throwing: VaultError.passNotFound)
                } else if status == errSecSuccess, let data = dataTypeRef as? Data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: VaultError.keychainError(status))
                }
            }
        }
    }
    
    // MARK: - Delete Ticket
    public func deleteTicket(id: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: id
        ]
        SecItemDelete(query as CFDictionary)
    }
}
