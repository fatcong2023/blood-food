//
//  MealDetailView.swift
//  Blood&Food
//
//  Created by Frank Jin on 2025-09-27.
//  Copyright © 2025 Frank Jin. All rights reserved.
//

import SwiftUI
import SwiftData

struct MealDetailView: View {
    @Bindable var mealEntry: MealEntry
    @State private var isEditing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if isEditing {
                    EditableMealView(mealEntry: mealEntry, isEditing: $isEditing)
                } else {
                    ReadOnlyMealView(mealEntry: mealEntry)
                }
            }
            .padding()
        }
        .navigationTitle("Meal Details")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    isEditing.toggle()
                }
            }
        }
    }
}

struct ReadOnlyMealView: View {
    let mealEntry: MealEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Card(title: "Meal Time") {
                Text(mealEntry.timestamp, format: Date.FormatStyle(date: .complete, time: .shortened))
                    .font(.title2)
            }

            Card(title: "What You Ate") {
                Text(mealEntry.mealDescription.isEmpty ? "No description" : mealEntry.mealDescription)
                    .font(.body)
            }

            HStack(spacing: 16) {
                Card(title: "Before Meal") {
                    if let before = mealEntry.bloodSugarBefore {
                        VStack {
                            Text("\(Int(before))")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("mg/dL")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Not recorded")
                            .foregroundColor(.secondary)
                    }
                }

                Card(title: "1hr After") {
                    if let after = mealEntry.bloodSugarAfter {
                        VStack {
                            Text("\(Int(after))")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            Text("mg/dL")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Not recorded")
                            .foregroundColor(.secondary)
                    }
                }
            }

            if let before = mealEntry.bloodSugarBefore,
               let after = mealEntry.bloodSugarAfter {
                let change = after - before
                Card(title: "Blood Sugar Change") {
                    HStack {
                        Text("\(change > 0 ? "+" : "")\(Int(change)) mg/dL")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(change > 0 ? .red : .green)

                        Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                            .foregroundColor(change > 0 ? .red : .green)
                    }
                }
            }

            if !mealEntry.notes.isEmpty {
                Card(title: "Notes") {
                    Text(mealEntry.notes)
                        .font(.body)
                }
            }
        }
    }
}

struct EditableMealView: View {
    @Bindable var mealEntry: MealEntry
    @Binding var isEditing: Bool

    @State private var bloodSugarBeforeText: String
    @State private var bloodSugarAfterText: String

    init(mealEntry: MealEntry, isEditing: Binding<Bool>) {
        self.mealEntry = mealEntry
        self._isEditing = isEditing
        self._bloodSugarBeforeText = State(initialValue: mealEntry.bloodSugarBefore?.formatted() ?? "")
        self._bloodSugarAfterText = State(initialValue: mealEntry.bloodSugarAfter?.formatted() ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Card(title: "Meal Time") {
                DatePicker("", selection: $mealEntry.timestamp, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
            }

            Card(title: "What You Ate") {
                TextField("Describe your meal", text: $mealEntry.mealDescription, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            HStack(spacing: 16) {
                Card(title: "Before Meal (mg/dL)") {
                    TextField("mg/dL", text: $bloodSugarBeforeText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: bloodSugarBeforeText) { _, newValue in
                            mealEntry.bloodSugarBefore = Double(newValue)
                        }
                }

                Card(title: "1hr After (mg/dL)") {
                    TextField("mg/dL", text: $bloodSugarAfterText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: bloodSugarAfterText) { _, newValue in
                            mealEntry.bloodSugarAfter = Double(newValue)
                        }
                }
            }

            Card(title: "Notes") {
                TextField("Additional notes", text: $mealEntry.notes, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
}

struct Card<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationView {
        MealDetailView(mealEntry: MealEntry(
            timestamp: Date(),
            bloodSugarBefore: 120,
            bloodSugarAfter: 180,
            mealDescription: "Pasta with tomato sauce and a side salad",
            notes: "Felt a bit tired after eating"
        ))
    }
    .modelContainer(for: MealEntry.self, inMemory: true)
}