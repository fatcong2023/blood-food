//
//  ContentView.swift
//  Blood&Food
//
//  Created by Frank Jin on 2025-09-27.
//

import SwiftUI
import SwiftData

struct ContentView: View {
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
    }
}

struct MealListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealEntry.timestamp, order: .reverse) private var mealEntries: [MealEntry]
    @State private var showingAddMeal = false

    var body: some View {
        NavigationView {
            List {
                ForEach(mealEntries) { entry in
                    NavigationLink {
                        MealDetailView(mealEntry: entry)
                    } label: {
                        MealRowView(mealEntry: entry)
                    }
                }
                .onDelete(perform: deleteMealEntries)
            }
            .navigationTitle("Blood & Food")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddMeal = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMeal) {
                AddMealView()
            }
        }
    }

    private func deleteMealEntries(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(mealEntries[index])
            }
        }
    }
}

struct MealRowView: View {
    let mealEntry: MealEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(mealEntry.timestamp, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                    .font(.headline)
                Spacer()
                if mealEntry.isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.orange)
                }
            }

            Text(mealEntry.mealDescription.isEmpty ? "No description" : mealEntry.mealDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                if let before = mealEntry.bloodSugarBefore {
                    Text("Before: \(Int(before)) mg/dL")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }

                if let after = mealEntry.bloodSugarAfter {
                    Text("After: \(Int(after)) mg/dL")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.2))
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
