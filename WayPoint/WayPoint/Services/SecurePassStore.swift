//
//  SecurePassStore.swift
//  WayPoint
//
//  Phase 4: Encrypted Offline Pass Storage
//

import Foundation
import Observation

@MainActor
@Observable
public final class SecurePassStore {
    public static let shared = SecurePassStore()
    
    private let storageKey = "waypoint_secure_travel_passes_v1"
    public private(set) var passes: [TravelPass] = []

    private init() {
        loadPasses()
    }

    public func savePass(_ pass: TravelPass) {
        passes.append(pass)
        persistToDisk()
    }

    public func updatePass(_ pass: TravelPass) {
        if let index = passes.firstIndex(where: { $0.id == pass.id }) {
            passes[index] = pass
        } else {
            passes.append(pass)
        }
        persistToDisk()
    }

    public func removePass(id: UUID) {
        passes.removeAll(where: { $0.id == id })
        persistToDisk()
    }

    public func passes(for tripId: UUID) -> [TravelPass] {
        return passes.filter { $0.tripId == tripId }
    }

    private func loadPasses() {
        if let keychainData = KeychainService.shared.read(key: storageKey),
           let decoded = try? JSONDecoder().decode([TravelPass].self, from: keychainData) {
            self.passes = decoded
            return
        }
        
        // Migration fallback from legacy UserDefaults if present
        if let legacyData = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([TravelPass].self, from: legacyData) {
            self.passes = decoded
            persistToDisk()
            UserDefaults.standard.removeObject(forKey: storageKey)
            return
        }
        
        if self.passes.isEmpty {
            self.passes = Self.defaultSeedPasses()
            persistToDisk()
        }
    }

    public static func defaultSeedPasses() -> [TravelPass] {
        let sampleTripId = UUID()
        return [
            TravelPass(
                id: UUID(),
                tripId: sampleTripId,
                title: "Suica IC Transit Pass",
                providerName: "JR East / Tokyo Metro",
                passType: .transit,
                confirmationCode: "IC-889420-TYO",
                barcodePayload: "SUICA-889420-PASS",
                validFrom: Date(),
                seatOrRoom: "Balance: ¥5,400"
            ),
            TravelPass(
                id: UUID(),
                tripId: sampleTripId,
                title: "Shinkansen Bullet Train Ticket",
                providerName: "JR Tokaido Shinkansen",
                passType: .transit,
                confirmationCode: "SHK-772901-TYO",
                barcodePayload: "SHK-772901-TYO",
                validFrom: Date(),
                seatOrRoom: "Car 4, Seat 11A (Window)"
            ),
            TravelPass(
                id: UUID(),
                tripId: sampleTripId,
                title: "Oyster Contactless Pass",
                providerName: "Transport for London (TfL)",
                passType: .transit,
                confirmationCode: "TFL-994021-LON",
                barcodePayload: "TFL-994021-PASS",
                validFrom: Date(),
                seatOrRoom: "Zone 1-3 Travelcard"
            ),
            TravelPass(
                id: UUID(),
                tripId: sampleTripId,
                title: "Flight BA007 LHR to HND",
                providerName: "British Airways",
                passType: .flight,
                confirmationCode: "BA-984210",
                barcodePayload: "BA-984210-BOARDING",
                validFrom: Date(),
                seatOrRoom: "Seat 14K (Club World)"
            ),
            TravelPass(
                id: UUID(),
                tripId: sampleTripId,
                title: "The Ritz London 2-Night Stay",
                providerName: "The Ritz Hotel",
                passType: .hotel,
                confirmationCode: "RITZ-44810B",
                barcodePayload: "RITZ-44810B-GUEST",
                validFrom: Date(),
                seatOrRoom: "Deluxe Suite 204"
            )
        ]
    }

    private func persistToDisk() {
        guard let data = try? JSONEncoder().encode(passes) else { return }
        KeychainService.shared.save(key: storageKey, data: data)
    }
}
