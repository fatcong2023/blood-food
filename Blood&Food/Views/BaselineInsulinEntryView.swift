//
//  BaselineInsulinEntryView.swift
//  Blood&Food
//
//  Created by Frank Jin on 2025-09-27.
//  Copyright © 2025 Frank Jin. All rights reserved.
//

import SwiftUI
import SwiftData

struct BaselineInsulinEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    @State private var breakfastShortActing: String = ""
    @State private var lunchShortActing: String = ""
    @State private var dinnerShortActing: String = ""
    @State private var bedtimeLongActing: String = ""
    @State private var notes: String = ""
    @State private var currentBaseline: BaselineInsulin?
    @State private var hasLoaded = false
    @State private var showingError = false

    var body: some View {
        NavigationView {
            Form {
                if let baseline = currentBaseline {
                    Section(header: Text("Current Baseline Insulin")) {
                        HStack {
                            Text("Set on:")
                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                            Spacer()
                            Text(baseline.dateCreated, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Breakfast:")
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                Spacer()
                                Text("\(String(format: "%.1f", baseline.breakfastShortActing)) units")
                                    .foregroundColor(themeManager.currentTheme.chartAfterColor)
                                    .fontWeight(.medium)
                            }

                            HStack {
                                Text("Lunch:")
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                Spacer()
                                Text("\(String(format: "%.1f", baseline.lunchShortActing)) units")
                                    .foregroundColor(themeManager.currentTheme.chartAfterColor)
                                    .fontWeight(.medium)
                            }

                            HStack {
                                Text("Dinner:")
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                Spacer()
                                Text("\(String(format: "%.1f", baseline.dinnerShortActing)) units")
                                    .foregroundColor(themeManager.currentTheme.chartAfterColor)
                                    .fontWeight(.medium)
                            }

                            HStack {
                                Text("Bedtime:")
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                Spacer()
                                Text("\(String(format: "%.1f", baseline.bedtimeLongActing)) units")
                                    .foregroundColor(themeManager.currentTheme.chartAfterColor)
                                    .fontWeight(.medium)
                            }
                        }

                        if !baseline.notes.isEmpty {
                            Text("Notes: \(baseline.notes)")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                .padding(.top, 4)
                        }
                    }
                    .listRowBackground(themeManager.currentTheme.cardBackgroundColor)
                }
                Section(header: Text("Short Acting Insulin (Meals)")) {
                    HStack {
                        Text("Breakfast")
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        Spacer()
                        TextField("Units", text: $breakfastShortActing)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }

                    HStack {
                        Text("Lunch")
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        Spacer()
                        TextField("Units", text: $lunchShortActing)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }

                    HStack {
                        Text("Dinner")
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        Spacer()
                        TextField("Units", text: $dinnerShortActing)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                }
                .listRowBackground(themeManager.currentTheme.cardBackgroundColor)

                Section(header: Text("Long Acting Insulin")) {
                    HStack {
                        Text("Bedtime")
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        Spacer()
                        TextField("Units", text: $bedtimeLongActing)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                }
                .listRowBackground(themeManager.currentTheme.cardBackgroundColor)

                Section(header: Text("Notes from Diabetes Help Center")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                }
                .listRowBackground(themeManager.currentTheme.cardBackgroundColor)

                Section {
                    Text("This will replace your current baseline insulin prescription. Your healthcare provider should review your data from the last 3 days before setting these values.")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .padding()
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.currentTheme.backgroundColor)
            .navigationTitle("Baseline Insulin")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Missing Information", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter at least one insulin value.")
            }
            .onAppear {
                loadCurrentBaseline()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button("Clear") {
                            clearAllFields()
                        }
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)

                        Button("Save") {
                            saveBaselineInsulin()
                        }
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    }
                }
            }
        }
    }

    private func loadCurrentBaseline() {
        guard !hasLoaded else { return }
        hasLoaded = true

        currentBaseline = BaselineInsulin.getCurrentActive(from: modelContext)

        if let baseline = currentBaseline {
            breakfastShortActing = baseline.breakfastShortActing > 0 ? String(format: "%.1f", baseline.breakfastShortActing) : ""
            lunchShortActing = baseline.lunchShortActing > 0 ? String(format: "%.1f", baseline.lunchShortActing) : ""
            dinnerShortActing = baseline.dinnerShortActing > 0 ? String(format: "%.1f", baseline.dinnerShortActing) : ""
            bedtimeLongActing = baseline.bedtimeLongActing > 0 ? String(format: "%.1f", baseline.bedtimeLongActing) : ""
            notes = baseline.notes
        }
    }

    private func clearAllFields() {
        breakfastShortActing = ""
        lunchShortActing = ""
        dinnerShortActing = ""
        bedtimeLongActing = ""
        notes = ""
    }

    private func isValidInput() -> Bool {
        return !breakfastShortActing.isEmpty ||
               !lunchShortActing.isEmpty ||
               !dinnerShortActing.isEmpty ||
               !bedtimeLongActing.isEmpty
    }

    private func saveBaselineInsulin() {
        guard isValidInput() else {
            showingError = true
            return
        }
        print("DEBUG: Saving baseline insulin...")
        print("DEBUG: Values - Breakfast: \(breakfastShortActing), Lunch: \(lunchShortActing), Dinner: \(dinnerShortActing), Bedtime: \(bedtimeLongActing)")

        // Deactivate current baseline
        let descriptor = FetchDescriptor<BaselineInsulin>(
            predicate: #Predicate { $0.isActive == true }
        )

        do {
            let activeBaselines = try modelContext.fetch(descriptor)
            print("DEBUG: Found \(activeBaselines.count) active baselines to deactivate")
            for baseline in activeBaselines {
                baseline.isActive = false
            }
        } catch {
            print("Error deactivating previous baselines: \(error)")
        }

        // Create new baseline
        let breakfastValue = Double(breakfastShortActing) ?? 0.0
        let lunchValue = Double(lunchShortActing) ?? 0.0
        let dinnerValue = Double(dinnerShortActing) ?? 0.0
        let bedtimeValue = Double(bedtimeLongActing) ?? 0.0

        let newBaseline = BaselineInsulin(
            breakfastShortActing: breakfastValue,
            lunchShortActing: lunchValue,
            dinnerShortActing: dinnerValue,
            bedtimeLongActing: bedtimeValue,
            notes: notes,
            isActive: true
        )

        print("DEBUG: Created baseline with values: B:\(breakfastValue), L:\(lunchValue), D:\(dinnerValue), Bed:\(bedtimeValue)")

        modelContext.insert(newBaseline)

        do {
            try modelContext.save()
            print("DEBUG: Successfully saved baseline insulin")
            dismiss()
        } catch {
            print("Error saving baseline insulin: \(error)")
        }
    }
}

#Preview {
    BaselineInsulinEntryView()
        .modelContainer(for: [BaselineInsulin.self], inMemory: true)
        .environmentObject(ThemeManager())
}