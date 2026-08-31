//
//  CameraScannerView.swift
//  WayPoint
//
//  Task 4.1 / WP6: Camera Lifecycle, VisionKit OCR & Permission Machine
//

import SwiftUI
import AVFoundation
import Vision
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - AVFoundation Live Camera Preview UIViewRepresentable

struct CameraPreviewView: UIViewRepresentable {
    @Binding var isCameraAvailable: Bool
    var onFrameCaptured: ((CGImage) -> Void)? = nil

    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }

    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .black

        let session = AVCaptureSession()
        session.sessionPreset = .photo

        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            DispatchQueue.main.async {
                isCameraAvailable = false
            }
            return view
        }

        if session.canAddInput(input) {
            session.addInput(input)
            view.videoPreviewLayer.session = session
            view.videoPreviewLayer.videoGravity = .resizeAspectFill
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
            DispatchQueue.main.async {
                isCameraAvailable = true
            }
        } else {
            DispatchQueue.main.async {
                isCameraAvailable = false
            }
        }

        return view
    }

    func updateUIView(_ uiView: VideoPreviewView, context: Context) {}

    static func dismantleUIView(_ uiView: VideoPreviewView, coordinator: ()) {
        if let session = uiView.videoPreviewLayer.session {
            DispatchQueue.global(qos: .userInitiated).async {
                session.stopRunning()
            }
        }
    }
}

// MARK: - Camera Permission Recovery Card

struct CameraPermissionRecoveryCard: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        GlassCardView(cornerRadius: 20, padding: 18, glowColor: WayPointTheme.violetGlow) {
            VStack(spacing: 14) {
                Image(systemName: "camera.badge.ellipsis")
                    .font(.system(size: 36))
                    .foregroundStyle(WayPointTheme.violetGlow)

                VStack(spacing: 4) {
                    Text("Camera Access Disabled")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(WayPointTheme.textPrimary)

                    Text("To scan receipts with your camera, enable camera access in System Settings or pick a photo from your library.")
                        .font(.caption)
                        .foregroundStyle(WayPointTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                HStack(spacing: 12) {
                    Button(action: openAppSettings) {
                        HStack(spacing: 6) {
                            Image(systemName: "gear")
                                .font(.caption.weight(.bold))
                            Text("Open Settings")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(WayPointTheme.violetGlow, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack(spacing: 6) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.caption.weight(.bold))
                            Text("Choose from Photos")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(WayPointTheme.cyanGlow)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(WayPointTheme.cyanGlow.opacity(0.15), in: Capsule())
                        .overlay(Capsule().strokeBorder(WayPointTheme.cyanGlow.opacity(0.4), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func openAppSettings() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
        #endif
    }
}

// MARK: - Main Camera & Receipt OCR Scanner View

struct CameraScannerView: View {
    @Environment(TripStore.self) private var tripStore
    @Binding var dayPlan: DayPlan
    var baseCurrencyCode: String = "USD"

    @Environment(\.dismiss) private var dismiss

    @State private var isCameraAvailable = false
    @State private var cameraAuthStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var selectedSampleIndex: Int? = 1 // Default Wagyu sample
    @State private var scannedReceipt: ScannedReceipt? = ReceiptDemoSample.samples[1].receipt
    @State private var laserOffset: CGFloat = -90
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var isProcessingOCR = false

    private var projectedSpentAmount: Decimal {
        let added = scannedReceipt?.convertedAmount ?? 0
        return dayPlan.spentAmount + added
    }

    private var projectedRemainingAmount: Decimal {
        dayPlan.budgetLimit - projectedSpentAmount
    }

    var body: some View {
        ZStack {
            WayPointTheme.obsidian.ignoresSafeArea()

            VStack(spacing: 16) {
                // Header
                headerSection

                // Camera Viewfinder & Scanner Reticle Area
                if cameraAuthStatus == .denied || cameraAuthStatus == .restricted {
                    CameraPermissionRecoveryCard(selectedPhotoItem: $selectedPhotoItem)
                        .padding(.vertical, 10)
                } else {
                    viewfinderSection
                }

                // Photo Library Picker & Demo Test Chips
                actionControlsSection

                // Budget Ledger Summary Card & Projection
                if let receipt = scannedReceipt {
                    budgetSummaryCard(receipt: receipt)
                }

                Spacer(minLength: 8)

                // Log Expense CTA Button
                logExpenseCTAButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            checkCameraPermission()
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                laserOffset = 90
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data),
                   let cgImage = uiImage.cgImage {
                    await performVisionOCR(on: cgImage)
                }
            }
        }
    }

    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        self.cameraAuthStatus = status
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraAuthStatus = granted ? .authorized : .denied
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(WayPointTheme.cyanGlow)

                    Text("CAMERA LENS FX SCANNER")
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .tracking(1.5)
                        .foregroundStyle(WayPointTheme.cyanGlow)
                }

                Text("Apple VisionKit OCR Engine")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(WayPointTheme.textPrimary)
            }

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(WayPointTheme.textSecondary)
                    .padding(8)
                    .background(WayPointTheme.obsidianElevated, in: Circle())
                    .overlay(Circle().strokeBorder(WayPointTheme.glassBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Viewfinder Section

    private var viewfinderSection: some View {
        ZStack {
            // Live Camera Feed with Simulator Fallback
            if isCameraAvailable {
                CameraPreviewView(isCameraAvailable: $isCameraAvailable)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                simulatorCameraFallback
            }

            // Glass Reticle & Laser Line Overlay
            ZStack {
                // Reticle Box Frame
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [WayPointTheme.cyanGlow.opacity(0.8), WayPointTheme.violetGlow.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 260, height: 180)

                    // Laser Scanning Line
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    WayPointTheme.cyanGlow.opacity(0.0),
                                    WayPointTheme.cyanGlow,
                                    WayPointTheme.cyanGlow.opacity(0.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 240, height: 3)
                        .shadow(color: WayPointTheme.cyanGlow, radius: 8, x: 0, y: 0)
                        .offset(y: laserOffset)

                    // Status Pill Overlay inside reticle
                    VStack {
                        Spacer()
                        HStack(spacing: 4) {
                            if isProcessingOCR {
                                ProgressView()
                                    .tint(WayPointTheme.cyanGlow)
                                    .scaleEffect(0.7)
                            } else {
                                Circle()
                                    .fill(WayPointTheme.cyanGlow)
                                    .frame(width: 6, height: 6)
                            }
                            Text(isProcessingOCR ? "VISION OCR PROCESSING..." : "LIVE VISION OCR · 151.8 JPY/USD")
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundStyle(WayPointTheme.textPrimary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(WayPointTheme.obsidian.opacity(0.85), in: Capsule())
                        .overlay(Capsule().strokeBorder(WayPointTheme.cyanGlow.opacity(0.4), lineWidth: 1))
                        .padding(.bottom, 12)
                    }
                }
                .frame(width: 260, height: 180)
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(WayPointTheme.glassBorder, lineWidth: 1)
        )
    }

    private var simulatorCameraFallback: some View {
        ZStack {
            WayPointTheme.obsidianElevated.ignoresSafeArea()

            VStack(spacing: 8) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 32))
                    .foregroundStyle(WayPointTheme.cyanGlow.opacity(0.8))

                Text("Simulated Camera Viewfinder")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(WayPointTheme.textSecondary)

                Text("Pick a photo or select a test chip below for instant Vision OCR")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(WayPointTheme.textTertiary)
            }
        }
    }

    // MARK: - Action Controls Section (PhotosPicker + Test Chips)

    private var actionControlsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SCAN OPTIONS & DEMO PRESETS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(WayPointTheme.textSecondary)

                Spacer()

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack(spacing: 4) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Pick Photo")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(WayPointTheme.cyanGlow)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(WayPointTheme.cyanGlow.opacity(0.15), in: Capsule())
                    .overlay(Capsule().strokeBorder(WayPointTheme.cyanGlow.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<ReceiptDemoSample.samples.count, id: \.self) { index in
                        let sample = ReceiptDemoSample.samples[index]
                        let isSelected = selectedSampleIndex == index

                        Button(action: {
                            #if canImport(UIKit)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                            withAnimation(.spring(response: 0.35)) {
                                selectedSampleIndex = index
                                scannedReceipt = sample.receipt
                            }
                        }) {
                            HStack(spacing: 6) {
                                Text(sample.icon)
                                    .font(.system(size: 13))

                                Text(sample.title)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(isSelected ? WayPointTheme.cyanGlow : WayPointTheme.textPrimary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                isSelected ? WayPointTheme.cyanGlow.opacity(0.18) : WayPointTheme.obsidianElevated,
                                in: Capsule()
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        isSelected ? WayPointTheme.cyanGlow : WayPointTheme.glassBorder,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Budget Ledger Summary Card

    private func budgetSummaryCard(receipt: ScannedReceipt) -> some View {
        GlassCardView(glowColor: WayPointTheme.cyanGlow) {
            VStack(alignment: .leading, spacing: 14) {
                // Receipt Merchant & Category Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(receipt.merchantName)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(WayPointTheme.textPrimary)

                        HStack(spacing: 4) {
                            Text(receipt.category.emoji)
                                .font(.system(size: 11))
                            Text(receipt.category.displayName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(WayPointTheme.textSecondary)
                        }
                    }

                    Spacer()

                    // Converted Tag
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(receipt.formattedOriginal)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(WayPointTheme.textSecondary)

                        Text(receipt.formattedConverted)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(WayPointTheme.cyanGlow)
                    }
                }

                Divider()
                    .overlay(WayPointTheme.glassBorder)

                // Updated Daily Budget Projection
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("UPDATED DAILY BUDGET PROJECTION")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .tracking(1.0)
                            .foregroundStyle(WayPointTheme.textSecondary)
                        Spacer()
                    }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Spent Pace")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(WayPointTheme.textTertiary)

                            HStack(spacing: 4) {
                                Text(dayPlan.formatCurrency(dayPlan.spentAmount))
                                    .foregroundStyle(WayPointTheme.textSecondary)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(WayPointTheme.cyanGlow)
                                Text(dayPlan.formatCurrency(projectedSpentAmount))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(WayPointTheme.cyanGlow)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Remaining Budget")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(WayPointTheme.textTertiary)

                            HStack(spacing: 4) {
                                Text(dayPlan.formatCurrency(dayPlan.remainingBudget))
                                    .foregroundStyle(WayPointTheme.textSecondary)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(WayPointTheme.textPrimary)
                                Text(dayPlan.formatCurrency(projectedRemainingAmount))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(projectedRemainingAmount >= 0 ? WayPointTheme.textPrimary : WayPointTheme.budgetOver)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Log Expense CTA Button

    private var logExpenseCTAButton: some View {
        Button(action: commitLoggedExpense) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16, weight: .bold))

                if let receipt = scannedReceipt {
                    Text("Log \(receipt.formattedConverted) to Daily Ledger")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                } else {
                    Text("Log Expense to Daily Ledger")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(WayPointTheme.cyanGlow, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: WayPointTheme.cyanGlow.opacity(0.4), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - VisionKit OCR Engine

    @MainActor
    private func performVisionOCR(on cgImage: CGImage) async {
        isProcessingOCR = true
        selectedSampleIndex = nil

        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    self.isProcessingOCR = false
                }
                return
            }

            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            let fullText = recognizedStrings.joined(separator: "\n")

            DispatchQueue.main.async {
                let parsed = ReceiptOCRParser.parseText(fullText, baseCurrency: baseCurrencyCode)
                withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                    self.scannedReceipt = parsed
                    self.isProcessingOCR = false
                }
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }

    // MARK: - Actions

    private func commitLoggedExpense() {
        guard let receipt = scannedReceipt else { return }

        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif

        withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
            tripStore.logExpense(receipt, to: dayPlan.id)
        }

        dismiss()
    }
}
