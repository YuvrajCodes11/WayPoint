//
//  TripGenesisView.swift
//  WayPoint
//
//  Step 3: Dynamic 4-Step Progressive Disclosure Trip Setup Wizard
//

import SwiftUI
import CoreLocation

public struct TripGenesisView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Step State
    @State private var currentStep: Int = 1
    
    // Form Inputs
    @State private var origin: String = ""
    @State private var destination: String = ""
    @State private var selectedType: TripType = .roundTrip
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    @State private var currencyCode: String = "USD"
    @State private var totalBudget: Double = 500.0
    
    // Location Helper State
    @State private var isLocating: Bool = false
    @State private var locationManager = CLLocationManager()
    
    private let availableCurrencies = ["USD", "EUR", "JPY", "GBP", "INR"]
    private let destinationChips = ["Tokyo", "Kyoto", "Osaka", "New York", "London"]

    public init() {}

    public var body: some View {
        ZStack {
            WayPointTheme.oledBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Header & Step Indicator
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                
                progressBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                
                // MARK: - Step Contents
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        Group {
                            switch currentStep {
                            case 1:
                                step1OriginView
                            case 2:
                                step2DestinationView
                            case 3:
                                step3ModalityDatesView
                            case 4:
                                step4BudgetEnvelopeView
                            default:
                                EmptyView()
                            }
                        }
                        .id(currentStep)
                        .transition(.opacity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
                
                Spacer(minLength: 0)
                
                // MARK: - Bottom Navigation Bar
                bottomNavigationBar
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(WayPointTheme.obsidianElevated.ignoresSafeArea(edges: .bottom))
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Plan Your Trip")
                    .font(.caption.weight(.bold))
                    .tracking(1.5)
                    .foregroundStyle(WayPointTheme.cyanGlow)
                
                Text(stepTitle)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(WayPointTheme.textPrimary)
            }
            
            Spacer()
            
            Text("Step \(currentStep) of 4")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(WayPointTheme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(WayPointTheme.glassBorder))
        }
    }

    private var stepTitle: String {
        switch currentStep {
        case 1: return "Origin"
        case 2: return "Destination"
        case 3: return "Schedule & Type"
        case 4: return "Budget Allocation"
        default: return ""
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(WayPointTheme.glassBorder)
                    .frame(height: 4)
                
                Capsule()
                    .fill(WayPointTheme.accentGradient)
                    .frame(width: geo.size.width * (CGFloat(currentStep) / 4.0), height: 4)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Step 1: Origin View

    private var step1OriginView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Where are you starting your journey from?")
                .font(.subheadline)
                .foregroundStyle(WayPointTheme.textSecondary)
            
            HStack(spacing: 12) {
                Image(systemName: "location.north.circle.fill")
                    .font(.title3)
                    .foregroundStyle(WayPointTheme.cyanGlow)
                
                TextField("Starting location (e.g. San Francisco, CA)", text: $origin)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(WayPointTheme.textPrimary)
                    .autocorrectionDisabled()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(WayPointTheme.obsidianSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(WayPointTheme.glassBorder, lineWidth: 1)
                    )
            )
            
            Button(action: requestCurrentLocation) {
                HStack(spacing: 8) {
                    if isLocating {
                        ProgressView()
                            .tint(WayPointTheme.cyanGlow)
                    } else {
                        Image(systemName: "location.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text("Use Current Location")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                .foregroundStyle(WayPointTheme.cyanGlow)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(WayPointTheme.cyanGlow.opacity(0.12))
                        .overlay(
                            Capsule()
                                .stroke(WayPointTheme.cyanGlow.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .disabled(isLocating)
        }
    }

    // MARK: - Step 2: Destination View

    private var step2DestinationView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Where are you heading?")
                .font(.subheadline)
                .foregroundStyle(WayPointTheme.textSecondary)
            
            HStack(spacing: 12) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.title3)
                    .foregroundStyle(WayPointTheme.violetGlow)
                
                TextField("Destination city or country (e.g. Tokyo)", text: $destination)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(WayPointTheme.textPrimary)
                    .autocorrectionDisabled()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(WayPointTheme.obsidianSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(WayPointTheme.glassBorder, lineWidth: 1)
                    )
            )
            
            VStack(alignment: .leading, spacing: 10) {
                Text("POPULAR DESTINATIONS")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WayPointTheme.textTertiary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(destinationChips, id: \.self) { chip in
                            Button(action: { destination = chip }) {
                                Text(chip)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(destination == chip ? .black : WayPointTheme.textPrimary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(destination == chip ? WayPointTheme.cyanGlow : WayPointTheme.obsidianSurface)
                                    )
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Step 3: Modality & Dates View

    private var step3ModalityDatesView: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text("TRIP TYPE")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WayPointTheme.textTertiary)
                
                Picker("Trip Type", selection: $selectedType) {
                    ForEach(TripType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("TRAVEL DATES")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WayPointTheme.textTertiary)
                
                DatePicker("Departure Date", selection: $startDate, in: Date()..., displayedComponents: .date)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(WayPointTheme.textPrimary)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(WayPointTheme.obsidianSurface))
                
                if selectedType == .roundTrip || selectedType == .multiDay {
                    DatePicker("Return Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(WayPointTheme.textPrimary)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(WayPointTheme.obsidianSurface))
                }
            }
        }
    }

    // MARK: - Step 4: Budget Envelope View

    private var step4BudgetEnvelopeView: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Text("CURRENCY & TOTAL BUDGET")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WayPointTheme.textTertiary)
                
                HStack(spacing: 12) {
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(availableCurrencies, id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(WayPointTheme.cyanGlow)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(WayPointTheme.obsidianSurface))
                    
                    Spacer()
                    
                    Text(formatCurrency(totalBudget))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(WayPointTheme.cyanGlow)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Slider(value: $totalBudget, in: 50...10000, step: 50)
                    .tint(WayPointTheme.cyanGlow)
                
                HStack {
                    Text("\(currencyCode) 50")
                        .font(.caption)
                        .foregroundStyle(WayPointTheme.textTertiary)
                    Spacer()
                    Text("\(currencyCode) 10,000")
                        .font(.caption)
                        .foregroundStyle(WayPointTheme.textTertiary)
                }
            }
            
            Text("AUTOMATIC ENVELOPE ALLOCATION")
                .font(.caption.weight(.bold))
                .foregroundStyle(WayPointTheme.textTertiary)
                .padding(.top, 8)
            
            VStack(spacing: 10) {
                budgetBreakdownRow(title: "Transit & Flights (25%)", amount: totalBudget * 0.25, icon: "airplane", color: WayPointTheme.sapphireAccent)
                budgetBreakdownRow(title: "Accommodation & Stay (45%)", amount: totalBudget * 0.45, icon: "bed.double.fill", color: WayPointTheme.violetGlow)
                budgetBreakdownRow(title: "Daily Food & Activities (20%)", amount: totalBudget * 0.20, icon: "fork.knife", color: WayPointTheme.emeraldRecovery)
                budgetBreakdownRow(title: "Reserve Buffer (10%)", amount: totalBudget * 0.10, icon: "shield.fill", color: WayPointTheme.imperialGold)
            }
        }
    }

    private func budgetBreakdownRow(title: String, amount: Double, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(Circle().fill(color.opacity(0.15)))
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(WayPointTheme.textPrimary)
            
            Spacer()
            
            Text(formatCurrency(amount))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(WayPointTheme.textPrimary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(WayPointTheme.obsidianSurface)
        )
    }

    // MARK: - Bottom Navigation Bar

    private var bottomNavigationBar: some View {
        HStack(spacing: 14) {
            if currentStep > 1 {
                Button(action: {
                    withAnimation { currentStep = max(1, currentStep - 1) }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(WayPointTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(WayPointTheme.obsidianSurface))
                }
            }
            
            Button(action: handleContinue) {
                HStack {
                    Text(currentStep == 4 ? "Generate Trip Itinerary" : "Continue")
                    if currentStep < 4 {
                        Image(systemName: "chevron.right")
                    }
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isStepValid ? WayPointTheme.cyanGlow : WayPointTheme.textTertiary)
                )
            }
            .disabled(!isStepValid)
        }
    }

    private var isStepValid: Bool {
        switch currentStep {
        case 1: return !origin.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return !destination.trimmingCharacters(in: .whitespaces).isEmpty
        case 3: return true
        case 4: return totalBudget >= 50
        default: return false
        }
    }

    private func handleContinue() {
        if currentStep < 4 {
            withAnimation { currentStep += 1 }
        } else {
            let budget = BudgetAllocation(total: totalBudget, currencyCode: currencyCode)
            TripStore.shared.createTrip(
                origin: origin,
                destination: destination,
                type: selectedType,
                startDate: startDate,
                endDate: endDate,
                budget: budget
            )
            dismiss()
        }
    }

    // MARK: - Location & Currency Helpers

    private func requestCurrentLocation() {
        isLocating = true
        locationManager.requestWhenInUseAuthorization()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if let loc = locationManager.location {
                CLGeocoder().reverseGeocodeLocation(loc) { placemarks, error in
                    isLocating = false
                    if let city = placemarks?.first?.locality ?? placemarks?.first?.administrativeArea {
                        origin = city
                    } else {
                        origin = "Current Location (\(String(format: "%.2f", loc.coordinate.latitude)), \(String(format: "%.2f", loc.coordinate.longitude)))"
                    }
                }
            } else {
                isLocating = false
                if origin.isEmpty {
                    origin = "San Francisco, CA"
                }
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currencyCode) \(Int(amount))"
    }
}

#Preview {
    TripGenesisView()
}
