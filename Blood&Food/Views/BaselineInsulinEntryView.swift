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

    var body: some View {
        NavigationView {
            Form {
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBaselineInsulin()
                    }
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    .disabled(!isValidInput())
                }
            }
        }
    }

    private func isValidInput() -> Bool {
        return !breakfastShortActing.isEmpty ||
               !lunchShortActing.isEmpty ||
               !dinnerShortActing.isEmpty ||
               !bedtimeLongActing.isEmpty
    }

    private func saveBaselineInsulin() {
        // Deactivate current baseline
        let descriptor = FetchDescriptor<BaselineInsulin>(
            predicate: #Predicate { $0.isActive == true }
        )

        do {
            let activeBaselines = try modelContext.fetch(descriptor)
            for baseline in activeBaselines {
                baseline.isActive = false
            }
        } catch {
            print("Error deactivating previous baselines: \(error)")
        }

        // Create new baseline
        let newBaseline = BaselineInsulin(
            breakfastShortActing: Double(breakfastShortActing) ?? 0.0,
            lunchShortActing: Double(lunchShortActing) ?? 0.0,
            dinnerShortActing: Double(dinnerShortActing) ?? 0.0,
            bedtimeLongActing: Double(bedtimeLongActing) ?? 0.0,
            notes: notes,
            isActive: true
        )

        modelContext.insert(newBaseline)

        do {
            try modelContext.save()
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