//
//  ContentView.swift
//  Blood&Food
//
//  Created by Frank Jin on 2025-09-27.
//  Copyright © 2025 Frank Jin. All rights reserved.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var themeManager = ThemeManager()

    var body: some View {
        TabView {
            MealListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Meals")
                }

            VisualizationView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Analytics")
                }
        }
        .environmentObject(themeManager)
        .background(themeManager.currentTheme.backgroundColor)
    }
}

struct MealListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealEntry.timestamp, order: .reverse) private var allMealEntries: [MealEntry]
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingAddMeal = false
    @State private var showingSettings = false
    @State private var showingBaselineInsulinEntry = false
    @State private var showingDateFilter = false
    @State private var selectedDate: Date? = nil
    @State private var showAllMeals = true

    private var filteredMealEntries: [MealEntry] {
        if showAllMeals {
            return allMealEntries
        } else if let selectedDate = selectedDate {
            return allMealEntries.filter { entry in
                Calendar.current.isDate(entry.timestamp, inSameDayAs: selectedDate)
            }
        } else {
            return allMealEntries
        }
    }

    private var displayTitle: String? {
        if showAllMeals {
            return nil
        } else if let selectedDate = selectedDate {
            if Calendar.current.isDateInToday(selectedDate) {
                return "Today's Meals"
            } else {
                return DateFormatter.localizedString(from: selectedDate, dateStyle: .medium, timeStyle: .none)
            }
        } else {
            return nil
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with date filter and meal count
                HStack {
                    Button(action: { showingDateFilter = true }) {
                        HStack {
                            Image(systemName: "calendar")
                            Text(showAllMeals ? "All Meals" : "Filtered")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(themeManager.currentTheme.cardBackgroundColor)
                        .cornerRadius(20)
                    }

                    Spacer()

                    Text("\(filteredMealEntries.count) meals")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                List {
                    ForEach(filteredMealEntries) { entry in
                        NavigationLink {
                            MealDetailView(mealEntry: entry)
                        } label: {
                            MealRowView(mealEntry: entry)
                        }
                        .listRowBackground(themeManager.currentTheme.cardBackgroundColor)
                    }
                    .onDelete(perform: deleteMealEntries)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    floatingActionArea
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.currentTheme.backgroundColor)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(themeManager.currentTheme.backgroundColor, for: .navigationBar)
            .toolbarColorScheme(themeManager.currentTheme == .dark ? .dark : .light, for: .navigationBar)
            .toolbar {
                if let displayTitle {
                    ToolbarItem(placement: .principal) {
                        Text(displayTitle)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    }
                }
            }
            .sheet(isPresented: $showingAddMeal) {
                AddMealView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingBaselineInsulinEntry) {
                BaselineInsulinEntryView()
            }
            .sheet(isPresented: $showingDateFilter) {
                DateFilterView(selectedDate: $selectedDate, showAllMeals: $showAllMeals)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .background(themeManager.currentTheme.backgroundColor)
    }

    private func deleteMealEntries(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredMealEntries[index])
            }
        }
    }

    private var floatingActionBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [
                    themeManager.currentTheme.backgroundColor.opacity(0),
                    themeManager.currentTheme.backgroundColor.opacity(0.75),
                    themeManager.currentTheme.backgroundColor
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 10)

            HStack {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape")
                        .font(.title2)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        .frame(width: 44, height: 44)
                        .background(themeManager.currentTheme.cardBackgroundColor)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }

                Button(action: { showingBaselineInsulinEntry = true }) {
                    Image(systemName: "syringe")
                        .font(.title2)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        .frame(width: 44, height: 44)
                        .background(themeManager.currentTheme.cardBackgroundColor)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }

                Spacer()

                Button(action: { showingAddMeal = true }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        .frame(width: 44, height: 44)
                        .background(themeManager.currentTheme.cardBackgroundColor)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(themeManager.currentTheme.backgroundColor)
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 22,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 22
            )
        )
    }

    private var floatingActionArea: some View {
        VStack(spacing: 0) {
            floatingActionBar
            themeManager.currentTheme.backgroundColor
                .frame(height: 28)
        }
        .background(themeManager.currentTheme.backgroundColor)
    }

}

struct MealRowView: View {
    let mealEntry: MealEntry
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext

    private var baselineInsulin: Double {
        let insulin = mealEntry.getBaselineInsulin(from: modelContext)
        print("DEBUG MealRowView: Meal '\(mealEntry.mealDescription)' (\(mealEntry.mealTime)) -> insulin: \(insulin)")
        return insulin
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(mealEntry.timestamp, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    Text(mealEntry.mealTime)
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                Spacer()
                if mealEntry.isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themeManager.currentTheme.negativeChangeColor)
                } else {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.orange)
                }
            }

            Text(mealEntry.mealDescription.isEmpty ? "No description" : mealEntry.mealDescription)
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .lineLimit(2)

            HStack {
                if let before = mealEntry.bloodSugarBefore {
                    Text("Before: \(Int(before)) mg/dL")
                        .font(.footnote)
                        .foregroundColor(themeManager.currentTheme.chartBeforeColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(themeManager.currentTheme.chartBeforeColor.opacity(0.2))
                        .cornerRadius(8)
                }

                if let after = mealEntry.bloodSugarAfter {
                    Text("After: \(Int(after)) mg/dL")
                        .font(.footnote)
                        .foregroundColor(themeManager.currentTheme.chartAfterColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(themeManager.currentTheme.chartAfterColor.opacity(0.2))
                        .cornerRadius(8)
                }

                if baselineInsulin > 0 {
                    Text("💉 \(String(format: "%.1f", baselineInsulin))u")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(Color.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .cornerRadius(8)
                } else {
                    // Debug: Show when no baseline is available
                    Text("💉 No baseline")
                        .font(.footnote)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(themeManager.currentTheme.secondaryTextColor.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: MealEntry.self, inMemory: true)
}
