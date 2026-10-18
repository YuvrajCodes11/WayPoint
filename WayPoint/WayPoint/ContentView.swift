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
    var body: some View {
        RootCoordinatorView()
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
