//
//  MealDetailView.swift
//  Blood&Food
//
//  Created by Frank Jin on 2025-09-27.
//  Copyright © 2025 Frank Jin. All rights reserved.
//

import SwiftUI
import SwiftData

struct MealDetailThemeStyle {
    let pageBackgroundColor: Color
    let cardBackgroundColor: Color
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let beforeValueColor: Color
    let afterValueColor: Color
    let increaseColor: Color
    let decreaseColor: Color

    init(theme: AppTheme) {
        pageBackgroundColor = theme.backgroundColor
        cardBackgroundColor = theme.cardBackgroundColor
        primaryTextColor = theme.primaryTextColor
        secondaryTextColor = theme.secondaryTextColor
        beforeValueColor = theme.chartBeforeColor
        afterValueColor = theme.chartAfterColor
        increaseColor = theme.positiveChangeColor
        decreaseColor = theme.negativeChangeColor
    }
}

struct MealDetailView: View {
    @Bindable var mealEntry: MealEntry
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isEditing = false

    private var style: MealDetailThemeStyle {
        MealDetailThemeStyle(theme: themeManager.currentTheme)
    }

    var body: some View {
        ZStack {
            style.pageBackgroundColor.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if isEditing {
                        EditableMealView(mealEntry: mealEntry, isEditing: $isEditing, style: style)
                    } else {
                        ReadOnlyMealView(mealEntry: mealEntry, style: style)
                    }
                }
                .padding()
            }
        }
        .toolbarBackground(style.pageBackgroundColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(themeManager.currentTheme == .dark ? .dark : .light, for: .navigationBar)
        .navigationTitle("Meal Details")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    isEditing.toggle()
                }
                .foregroundColor(style.primaryTextColor)
            }
        }
    }
}

struct ReadOnlyMealView: View {
    let mealEntry: MealEntry
    let style: MealDetailThemeStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Card(title: "Meal Time", style: style) {
                Text(mealEntry.timestamp, format: Date.FormatStyle(date: .complete, time: .shortened))
                    .font(.title2)
                    .foregroundColor(style.primaryTextColor)
            }

            Card(title: "What You Ate", style: style) {
                Text(mealEntry.mealDescription.isEmpty ? "No description" : mealEntry.mealDescription)
                    .font(.body)
                    .foregroundColor(style.primaryTextColor)
            }

            HStack(spacing: 16) {
                Card(title: "Before Meal", style: style) {
                    if let before = mealEntry.bloodSugarBefore {
                        VStack {
                            Text("\(Int(before))")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(style.beforeValueColor)
                            Text("mg/dL")
                                .font(.caption)
                                .foregroundColor(style.secondaryTextColor)
                        }
                    } else {
                        Text("Not recorded")
                            .foregroundColor(style.secondaryTextColor)
                    }
                }

                Card(title: "1hr After", style: style) {
                    if let after = mealEntry.bloodSugarAfter {
                        VStack {
                            Text("\(Int(after))")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(style.afterValueColor)
                            Text("mg/dL")
                                .font(.caption)
                                .foregroundColor(style.secondaryTextColor)
                        }
                    } else {
                        Text("Not recorded")
                            .foregroundColor(style.secondaryTextColor)
                    }
                }
            }

            if let before = mealEntry.bloodSugarBefore,
               let after = mealEntry.bloodSugarAfter {
                let change = after - before
                Card(title: "Blood Sugar Change", style: style) {
                    HStack {
                        Text("\(change > 0 ? "+" : "")\(Int(change)) mg/dL")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(change > 0 ? style.increaseColor : style.decreaseColor)

                        Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                            .foregroundColor(change > 0 ? style.increaseColor : style.decreaseColor)
                    }
                }
            }

            if !mealEntry.notes.isEmpty {
                Card(title: "Notes", style: style) {
                    Text(mealEntry.notes)
                        .font(.body)
                        .foregroundColor(style.primaryTextColor)
                }
            }
        }
    }
}

struct EditableMealView: View {
    @Bindable var mealEntry: MealEntry
    @Binding var isEditing: Bool
    let style: MealDetailThemeStyle

    @State private var bloodSugarBeforeText: String
    @State private var bloodSugarAfterText: String

    init(mealEntry: MealEntry, isEditing: Binding<Bool>, style: MealDetailThemeStyle) {
        self.mealEntry = mealEntry
        self._isEditing = isEditing
        self.style = style
        self._bloodSugarBeforeText = State(initialValue: mealEntry.bloodSugarBefore?.formatted() ?? "")
        self._bloodSugarAfterText = State(initialValue: mealEntry.bloodSugarAfter?.formatted() ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Card(title: "Meal Time", style: style) {
                DatePicker("", selection: $mealEntry.timestamp, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
            }

            Card(title: "What You Ate", style: style) {
                TextField("Describe your meal", text: $mealEntry.mealDescription, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            HStack(spacing: 16) {
                Card(title: "Before Meal (mg/dL)", style: style) {
                    TextField("mg/dL", text: $bloodSugarBeforeText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: bloodSugarBeforeText) { _, newValue in
                            mealEntry.bloodSugarBefore = Double(newValue)
                        }
                }

                Card(title: "1hr After (mg/dL)", style: style) {
                    TextField("mg/dL", text: $bloodSugarAfterText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: bloodSugarAfterText) { _, newValue in
                            mealEntry.bloodSugarAfter = Double(newValue)
                        }
                }
            }

            Card(title: "Notes", style: style) {
                TextField("Additional notes", text: $mealEntry.notes, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
}

struct Card<Content: View>: View {
    let title: String
    let style: MealDetailThemeStyle
    let content: Content

    init(title: String, style: MealDetailThemeStyle, @ViewBuilder content: () -> Content) {
        self.title = title
        self.style = style
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(style.primaryTextColor)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(style.cardBackgroundColor)
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
    .environmentObject(ThemeManager())
}
