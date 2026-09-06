//
//  ContentView.swift
//  WayPoint
//
//  Created by Yuvraj for RevenueCat #Shipaton 2026
//  Task 5: Air-Gap Parity & UI Integration
//

import SwiftUI
import Combine

struct ContentView: View {
    // Shared Services
    @State private var budgetRouter = BudgetGraphRouter.shared
    @State private var graphRouter = GraphRouter.shared
    @State private var vault = SecureVault.shared
    
    // UI Navigation State
    @State private var activeSegment: Int = 0 // 0: Planner, 1: Enclave Vault, 2: Legacy App
    
    // Secure Enclave Ticket State
    @State private var ticketStored: Bool = false
    @State private var unlockedTicketPayload: String? = nil
    @State private var vaultErrorMessage: String? = nil
    @State private var isAuthenticatingVault: Bool = false
    
    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.05, blue: 0.08).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Persistent Top Air-Gapped Status Banner
                VStack(spacing: 8) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "location.north.line.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(red: 0.0, green: 1.0, blue: 0.53))
                            
                            Text("WayPoint")
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Picker("", selection: $activeSegment) {
                            Text("Itinerary Solver").tag(0)
                            Text("Pass Vault").tag(1)
                            Text("Full App").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 220)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    // PERSISTENT AIR-GAPPED STATUS BANNER
                    AirGappedBannerView()
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, 8)
                .background(Color(white: 0.07).ignoresSafeArea(edges: .top))
                
                // MARK: - Active Section Content
                if activeSegment == 0 {
                    // 100% Offline Trip Planner & Vector Map
                    ScrollView {
                        VStack(spacing: 20) {
                            // Trip Planner & Disruption Solver
                            TripPlannerView(router: budgetRouter)
                            
                            // Interactive Vector Transit Canvas
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "map.fill")
                                        .foregroundColor(Color(hex: "#FF9500") ?? .orange)
                                    Text("Tokyo Metro Vector Canvas")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Text("Pure SwiftUI • 0 Tiles")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.cyan)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill(Color.cyan.opacity(0.15)))
                                }
                                .padding(.horizontal, 12)
                                .padding(.top, 12)
                                
                                OfflineMapView(router: graphRouter)
                                    .frame(height: 280)
                                    .cornerRadius(12)
                                    .padding(.horizontal, 8)
                                    .padding(.bottom, 8)
                            }
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.1)))
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                        }
                        .padding(.vertical, 12)
                    }
                } else if activeSegment == 1 {
                    // Apple Secure Enclave Pass Vault Card
                    ScrollView {
                        VStack(spacing: 16) {
                            PassVaultSectionCard(
                                vault: vault,
                                ticketStored: $ticketStored,
                                unlockedTicketPayload: $unlockedTicketPayload,
                                vaultErrorMessage: $vaultErrorMessage,
                                isAuthenticatingVault: $isAuthenticatingVault,
                                onStoreTicket: storeSampleTicket,
                                onUnlockTicket: unlockTicketWithBiometrics
                            )
                        }
                        .padding(16)
                    }
                } else {
                    // Legacy Full App Experience
                    HomeView()
                        .environment(SubscriptionManager.shared)
                }
            }
        }
    }
    
    // MARK: - Secure Enclave Pass Vault Operations
    private func storeSampleTicket() {
        let ticket = OfflineTicket(
            id: "tokyo_metro_pass_2026",
            title: "Tokyo Metro 24hr Unlimited Pass",
            passType: "QR Express Transit",
            carrier: "Tokyo Metro",
            seat: "Car 3 / Door 2",
            qrCodePayload: "WAYPOINT-OFFLINE-ENCLAVE-PASS-KEY-998877665544332211"
        )
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(ticket) {
            let result = vault.storeTicket(passId: ticket.id, rawData: data)
            switch result {
            case .success:
                ticketStored = true
                vaultErrorMessage = nil
            case .failure(let err):
                vaultErrorMessage = err.localizedDescription
            }
        }
    }
    
    private func unlockTicketWithBiometrics() {
        guard ticketStored else {
            storeSampleTicket()
            unlockTicketWithBiometrics()
            return
        }
        
        isAuthenticatingVault = true
        vaultErrorMessage = nil
        
        vault.unlockTicketOffline(passId: "tokyo_metro_pass_2026") { result in
            DispatchQueue.main.async {
                self.isAuthenticatingVault = false
                switch result {
                case .success(let data):
                    let decoder = JSONDecoder()
                    if let ticket = try? decoder.decode(OfflineTicket.self, from: data) {
                        self.unlockedTicketPayload = "PASS: \(ticket.title) | QR: \(ticket.qrCodePayload)"
                    } else {
                        self.unlockedTicketPayload = "UNLOCKED RAW DATA (\(data.count) bytes)"
                    }
                case .failure(let err):
                    self.vaultErrorMessage = err.localizedDescription
                }
            }
        }
    }
}

// MARK: - Air Gapped Status Banner Subview
struct AirGappedBannerView: View {
    var body: some View {
        HStack(spacing: 8) {
            BannerItemView(iconName: nil, text: "Local Silicon Engine", color: Color(red: 0.0, green: 1.0, blue: 0.53))
            Text("•").foregroundColor(.gray)
            BannerItemView(iconName: "airplane", text: "Air-Gapped Core", color: .white)
            Text("•").foregroundColor(.gray)
            BannerItemView(iconName: "antenna.radiowaves.left.and.right.slash", text: "0 KB Cellular", color: .white)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.0, green: 0.8, blue: 0.4).opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(red: 0.0, green: 1.0, blue: 0.53).opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct BannerItemView: View {
    let iconName: String?
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            if let icon = iconName {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }
            Text(text)
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
    }
}

// MARK: - Pass Vault Section Subview
struct PassVaultSectionCard: View {
    let vault: SecureVault
    @Binding var ticketStored: Bool
    @Binding var unlockedTicketPayload: String?
    @Binding var vaultErrorMessage: String?
    @Binding var isAuthenticatingVault: Bool
    
    let onStoreTicket: () -> Void
    let onUnlockTicket: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.green)
                Text("Apple Secure Enclave Pass Vault")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text(vault.biometricTypeString)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.green.opacity(0.15)))
            }
            
            Text("Boarding passes and QR travel tickets are encrypted locally using kSecAccessControlBiometryCurrentSet. No network token validation required.")
                .font(.system(size: 13))
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                Button(action: onStoreTicket) {
                    HStack {
                        Image(systemName: "key.fill")
                        Text(ticketStored ? "Ticket Secured" : "Encrypt Ticket to Enclave")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(Capsule().fill(ticketStored ? Color.green.opacity(0.8) : Color.blue))
                }
                
                Button(action: onUnlockTicket) {
                    HStack {
                        if isAuthenticatingVault {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "faceid")
                            Text("Unlock via Face ID")
                                .font(.system(size: 13, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(Capsule().fill(Color.purple))
                }
            }
            
            if let unlocked = unlockedTicketPayload {
                VStack(alignment: .leading, spacing: 4) {
                    Text("UNLOCKED ENCLAVE PAYLOAD:")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                    Text(unlocked)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(3)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.green.opacity(0.12)))
            }
            
            if let err = vaultErrorMessage {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.1)))
    }
}

#Preview {
    ContentView()
}
