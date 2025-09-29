import SwiftUI
import SwiftData

struct AddMealView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    @State private var mealDescription = ""
    @State private var bloodSugarBefore = ""
    @State private var bloodSugarAfter = ""
    @State private var notes = ""
    @State private var mealTime = Date()
    @State private var selectedMealType = ""

    private var inferredMealType: String {
        let hour = Calendar.current.component(.hour, from: mealTime)
        switch hour {
        case 5..<11: return "Breakfast"
        case 11..<15: return "Lunch"
        case 15..<20: return "Dinner"
        default: return "Snack"
        }
    }

    private var currentMealType: String {
        selectedMealType.isEmpty ? inferredMealType : selectedMealType
    }

    private var baselineInsulin: Double {
        guard let activeBaseline = BaselineInsulin.getCurrentActive(from: modelContext) else {
            return 0.0
        }
        return activeBaseline.getInsulinForMealTime(currentMealType)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Meal Information") {
                    DatePicker("Meal Time", selection: $mealTime, displayedComponents: [.date, .hourAndMinute])
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)

                    Picker("Meal Type", selection: $selectedMealType) {
                        Text("Auto (\(inferredMealType))").tag("")
                        Text("Breakfast").tag("Breakfast")
                        Text("Lunch").tag("Lunch")
                        Text("Dinner").tag("Dinner")
                        Text("Snack").tag("Snack")
                        Text("Bedtime").tag("Bedtime")
                    }
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)

                    TextField("What did you eat?", text: $mealDescription, axis: .vertical)
                        .lineLimit(3...6)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                }
                .listRowBackground(themeManager.currentTheme.cardBackgroundColor)

                if baselineInsulin > 0 {
                    Section("Baseline Insulin Prescription") {
                        HStack {
                            Image(systemName: "syringe")
                                .foregroundColor(themeManager.currentTheme.chartAfterColor)
                            Text("\(currentMealType): \(String(format: "%.1f", baselineInsulin)) units")
                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                            Spacer()
                            Text("Prescribed")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                    }
                    .listRowBackground(themeManager.currentTheme.cardBackgroundColor)
                }

                Section("Blood Sugar Readings (mg/dL)") {
                    HStack {
                        Text("Before meal:")
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        Spacer()
                        TextField("mg/dL", text: $bloodSugarBefore)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }

                    HStack {
                        Text("1hr after meal:")
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        Spacer()
                        TextField("mg/dL", text: $bloodSugarAfter)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                }
                .listRowBackground(themeManager.currentTheme.cardBackgroundColor)

                Section("Additional Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                }
                .listRowBackground(themeManager.currentTheme.cardBackgroundColor)
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.currentTheme.backgroundColor)
            .navigationTitle("Add Meal")
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
                        saveMeal()
                    }
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    .disabled(mealDescription.isEmpty)
                }
            }
        }
    }

    private func saveMeal() {
        let beforeReading = Double(bloodSugarBefore.trimmingCharacters(in: .whitespacesAndNewlines))
        let afterReading = Double(bloodSugarAfter.trimmingCharacters(in: .whitespacesAndNewlines))

        let newMeal = MealEntry(
            timestamp: mealTime,
            bloodSugarBefore: beforeReading,
            bloodSugarAfter: afterReading,
            mealDescription: mealDescription,
            notes: notes,
            mealTime: currentMealType
        )

        modelContext.insert(newMeal)
        dismiss()
    }
}

#Preview {
    AddMealView()
        .modelContainer(for: [MealEntry.self, BaselineInsulin.self], inMemory: true)
        .environmentObject(ThemeManager())
}