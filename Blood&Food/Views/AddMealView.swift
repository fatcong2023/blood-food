import SwiftUI
import SwiftData

struct AddMealView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var mealDescription = ""
    @State private var bloodSugarBefore = ""
    @State private var bloodSugarAfter = ""
    @State private var notes = ""
    @State private var mealTime = Date()

    var body: some View {
        NavigationView {
            Form {
                Section("Meal Information") {
                    DatePicker("Meal Time", selection: $mealTime, displayedComponents: [.date, .hourAndMinute])

                    TextField("What did you eat?", text: $mealDescription, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Blood Sugar Readings (mg/dL)") {
                    HStack {
                        Text("Before meal:")
                        Spacer()
                        TextField("mg/dL", text: $bloodSugarBefore)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }

                    HStack {
                        Text("1hr after meal:")
                        Spacer()
                        TextField("mg/dL", text: $bloodSugarAfter)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                }

                Section("Additional Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMeal()
                    }
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
            notes: notes
        )

        modelContext.insert(newMeal)
        dismiss()
    }
}

#Preview {
    AddMealView()
        .modelContainer(for: MealEntry.self, inMemory: true)
}