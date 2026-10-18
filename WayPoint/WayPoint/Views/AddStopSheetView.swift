//
//  AddStopSheetView.swift
//  WayPoint
//
//  Phase 2: Manual Stop Creation Modal
//

import SwiftUI

public struct AddStopSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    let dayIndex: Int
    
    @State private var title: String = ""
    @State private var selectedType: StopType = .activity
    @State private var scheduledTime: Date = Date()
    @State private var durationMinutes: Int = 60
    @State private var estimatedCost: Double = 0.0
    @State private var isHardReservation: Bool = false
    @State private var bookingReference: String = ""
    @State private var notes: String = ""

    public init(dayIndex: Int = 0) {
        self.dayIndex = dayIndex
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                WayPointTheme.oledBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // MARK: - Title Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("STOP TITLE")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(WayPointTheme.textTertiary)
                            
                            TextField("e.g. Tsukiji Outer Market Breakfast", text: $title)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(WayPointTheme.textPrimary)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(WayPointTheme.obsidianSurface)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(WayPointTheme.glassBorder, lineWidth: 1))
                                )
                        }
                        
                        // MARK: - Stop Type Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CATEGORY & TYPE")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(WayPointTheme.textTertiary)
                            
                            Picker("Stop Type", selection: $selectedType) {
                                Text("Activity").tag(StopType.activity)
                                Text("Dining").tag(StopType.dining)
                                Text("Hotel").tag(StopType.hotel)
                                Text("Transit").tag(StopType.transit)
                                Text("Flight").tag(StopType.flight)
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        // MARK: - Date & Duration
                        VStack(alignment: .leading, spacing: 14) {
                            Text("SCHEDULE & DURATION")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(WayPointTheme.textTertiary)
                            
                            DatePicker("Scheduled Time", selection: $scheduledTime, displayedComponents: [.hourAndMinute])
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(WayPointTheme.textPrimary)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 10).fill(WayPointTheme.obsidianSurface))
                            
                            HStack {
                                Text("Duration")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(WayPointTheme.textPrimary)
                                
                                Spacer()
                                
                                Stepper("\(durationMinutes) mins", value: $durationMinutes, in: 15...480, step: 15)
                                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                                    .foregroundStyle(WayPointTheme.cyanGlow)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(WayPointTheme.obsidianSurface))
                        }
                        
                        // MARK: - Cost & Booking Ref
                        VStack(alignment: .leading, spacing: 14) {
                            Text("ESTIMATED COST & RESERVATION")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(WayPointTheme.textTertiary)
                            
                            HStack {
                                Text("Estimated Cost ($)")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(WayPointTheme.textPrimary)
                                
                                Spacer()
                                
                                TextField("0.00", value: $estimatedCost, format: .currency(code: "USD"))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundStyle(WayPointTheme.cyanGlow)
                                    .frame(width: 120)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(WayPointTheme.obsidianSurface))
                            
                            Toggle("Hard Reservation (Firm Time)", isOn: $isHardReservation)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(WayPointTheme.textPrimary)
                                .tint(WayPointTheme.cyanGlow)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 10).fill(WayPointTheme.obsidianSurface))
                            
                            if isHardReservation {
                                TextField("Booking Reference # (Optional)", text: $bookingReference)
                                    .font(.system(size: 14))
                                    .foregroundStyle(WayPointTheme.textPrimary)
                                    .padding(12)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(WayPointTheme.obsidianSurface))
                            }
                        }
                        
                        // MARK: - Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOTES & DETAILS")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(WayPointTheme.textTertiary)
                            
                            TextField("Special instructions, confirmation notes...", text: $notes, axis: .vertical)
                                .lineLimit(3...5)
                                .font(.system(size: 14))
                                .foregroundStyle(WayPointTheme.textPrimary)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 10).fill(WayPointTheme.obsidianSurface))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add New Stop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(WayPointTheme.textSecondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Stop") {
                        saveStop()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(title.trimmingCharacters(in: .whitespaces).isEmpty ? WayPointTheme.textTertiary : WayPointTheme.cyanGlow)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func saveStop() {
        let stop = TripStop(
            title: title,
            type: selectedType,
            scheduledTime: scheduledTime,
            durationMinutes: durationMinutes,
            estimatedCost: estimatedCost,
            isHardReservation: isHardReservation,
            bookingReference: bookingReference.isEmpty ? nil : bookingReference,
            notes: notes.isEmpty ? nil : notes
        )
        
        TripStore.shared.addStop(to: dayIndex, stop: stop)
        dismiss()
    }
}

#Preview {
    AddStopSheetView(dayIndex: 0)
}
