//
//  OTPAuthSheetView.swift
//  WayPoint
//

import SwiftUI
#if canImport(WebKit) && canImport(UIKit)
import WebKit
import UIKit
#endif

enum AuthStep {
    case input
    case verify
}

struct OTPAuthSheetView: View {
    @Environment(SupabaseService.self) private var supabaseService
    @Environment(\.dismiss) private var dismiss

    @State private var step: AuthStep = .input
    @State private var countryCode: String = "🇺🇸 +1"
    @State private var contactInput: String = ""
    @State private var otpCode: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var countdown: Int = 30
    @State private var timer: Timer? = nil

    private let countryCodes = ["🇺🇸 +1", "🇦🇪 +971", "🇬🇧 +44", "🇮🇳 +91", "🇯🇵 +81", "🇫🇷 +33"]

    var body: some View {
        ZStack {
            // Live 3D Liquid Line Path Scene Background
            #if canImport(WebKit) && canImport(UIKit)
            SplineWebContainer(urlString: "https://my.spline.design/customlinepathwithcustommatcap-Oken3h6jm2uzoJ2BVGzdfhQe/")
                .scaleEffect(1.06)
                .clipped()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            WayPointTheme.obsidian.opacity(0.85)
                .ignoresSafeArea()
            #else
            WayPointTheme.obsidian.ignoresSafeArea()
            #endif

            VStack(spacing: 20) {
                // Header Drag Indicator
                Capsule()
                    .fill(WayPointTheme.glassBorder)
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)

                // Distinct Step Header & Content View Blocks
                if step == .input {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: "lock.shield.fill")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(WayPointTheme.cyanGlow)

                                    Text("SUPABASE AUTH")
                                        .font(.caption.weight(.bold))
                                        .tracking(1.5)
                                        .foregroundStyle(WayPointTheme.cyanGlow)
                                }

                                Text("Sign In / Register")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(WayPointTheme.textPrimary)
                            }

                            Spacer()

                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(WayPointTheme.textSecondary)
                            }
                        }

                        inputStepView
                    }
                    .transition(.opacity.combined(with: .move(edge: .leading)))
                } else {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(WayPointTheme.cyanGlow)

                                    Text("VERIFICATION CODE")
                                        .font(.caption.weight(.bold))
                                        .tracking(1.5)
                                        .foregroundStyle(WayPointTheme.cyanGlow)
                                }

                                Text("Enter 6-Digit Code")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(WayPointTheme.textPrimary)
                            }

                            Spacer()

                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(WayPointTheme.textSecondary)
                            }
                        }

                        verifyStepView
                    }
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .preferredColorScheme(.dark)
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Step 1: Input

    private var inputStepView: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Enter your phone number or email address to receive a secure 6-digit access code.")
                .font(.subheadline)
                .foregroundStyle(WayPointTheme.textSecondary)

            HStack(spacing: 10) {
                // Country Code Picker Menu
                Menu {
                    ForEach(countryCodes, id: \.self) { code in
                        Button(code) {
                            countryCode = code
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(countryCode)
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(WayPointTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .background(WayPointTheme.obsidianElevated, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(WayPointTheme.glassBorder, lineWidth: 1)
                    )
                }

            // Phone/Email TextField
                TextField("Phone or Email", text: $contactInput)
                    .font(.body.weight(.medium))
                    .foregroundStyle(WayPointTheme.textPrimary)
                    .textInputAutocapitalization(.never)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(WayPointTheme.obsidianElevated, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(WayPointTheme.cyanGlow.opacity(0.4), lineWidth: 1)
                    )
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(WayPointTheme.budgetOver)
            }

            // Action Button
            Button(action: handleSendOTP) {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Text("Send Verification Code")
                            .font(.headline.weight(.bold))
                        Image(systemName: "arrow.right")
                            .font(.subheadline.weight(.bold))
                    }
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(WayPointTheme.accentGradient)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: WayPointTheme.cyanGlow.opacity(0.35), radius: 12, x: 0, y: 6)
            }
            .disabled(contactInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
    }

    // MARK: - Step 2: Verify

    private var verifyStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 8) {
                (Text("Sent 6-digit code to ")
                    .font(.subheadline)
                    .foregroundStyle(WayPointTheme.textSecondary)
                + Text(formattedContactForAuth)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(WayPointTheme.cyanGlow))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                Button("Edit") {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        step = .input
                    }
                }
                .font(.caption.weight(.bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(WayPointTheme.obsidianElevated, in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(WayPointTheme.glassBorder, lineWidth: 1)
                )
                .foregroundStyle(WayPointTheme.violetGlow)
            }

            // 6-digit OTP Box Input
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(WayPointTheme.obsidianElevated)
                            .frame(height: 54)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(
                                        digitAtIndex(index) != nil
                                            ? WayPointTheme.cyanGlow
                                            : WayPointTheme.glassBorder,
                                        lineWidth: 1.5
                                    )
                            )

                        if let char = digitAtIndex(index) {
                            Text(String(char))
                                .font(.title2.weight(.bold))
                                .fontDesign(.monospaced)
                                .foregroundStyle(WayPointTheme.textPrimary)
                        }
                    }
                }
            }
            .overlay {
                TextField("", text: $otpCode)
                    .keyboardType(.numberPad)
                    .font(.body)
                    .foregroundColor(.clear)
                    .accentColor(.clear)
                    .onChange(of: otpCode) { _, newValue in
                        if newValue.count > 6 {
                            otpCode = String(newValue.prefix(6))
                        }
                        if otpCode.count == 6 {
                            handleVerifyOTP()
                        }
                    }
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(WayPointTheme.budgetOver)
            }

            // Resend Countdown & Demo Code Hint
            HStack {
                if countdown > 0 {
                    Text("Resend code in \(countdown)s")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WayPointTheme.textTertiary)
                } else {
                    Button("Resend Code Now") {
                        startTimer()
                        handleSendOTP()
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WayPointTheme.cyanGlow)
                }

                Spacer()

                #if DEBUG
                HStack(spacing: 4) {
                    Image(systemName: "key.fill")
                        .font(.caption2)
                    Text("Demo: 123456")
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(WayPointTheme.cyanGlow)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(WayPointTheme.cyanGlow.opacity(0.12), in: Capsule())
                #endif
            }

            // Verify Button
            Button(action: handleVerifyOTP) {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Text("Verify & Sign In")
                            .font(.headline.weight(.bold))
                        Image(systemName: "checkmark.seal.fill")
                            .font(.subheadline.weight(.bold))
                    }
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(WayPointTheme.accentGradient)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: WayPointTheme.cyanGlow.opacity(0.35), radius: 12, x: 0, y: 6)
            }
            .disabled(otpCode.count < 6 || isLoading)
        }
    }

    private func digitAtIndex(_ index: Int) -> Character? {
        guard index < otpCode.count else { return nil }
        let charIndex = otpCode.index(otpCode.startIndex, offsetBy: index)
        return otpCode[charIndex]
    }

    // MARK: - Helper Formatting & Actions

    private var sanitizedContactInput: String {
        contactInput.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var formattedContactForAuth: String {
        let trimmed = sanitizedContactInput
        if trimmed.contains("@") {
            return trimmed.lowercased()
        } else {
            let digits = trimmed.filter { $0.isNumber || $0 == "+" }
            if digits.hasPrefix("+") {
                return digits
            }
            let prefix = countryCode.components(separatedBy: " ").last ?? "+1"
            return "\(prefix)\(digits)"
        }
    }

    private func handleSendOTP() {
        let target = formattedContactForAuth
        guard !target.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await supabaseService.signInWithOTP(emailOrPhone: target)
                isLoading = false
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    step = .verify
                }
                startTimer()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func handleVerifyOTP() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let success = try await supabaseService.verifyOTP(token: otpCode)
                isLoading = false
                if success {
                    dismiss()
                } else {
                    errorMessage = "Invalid verification code. Please try again."
                }
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func startTimer() {
        countdown = 30
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdown > 0 {
                countdown -= 1
            } else {
                timer?.invalidate()
            }
        }
    }
}

#Preview {
    OTPAuthSheetView()
        .environment(SupabaseService.shared)
}
