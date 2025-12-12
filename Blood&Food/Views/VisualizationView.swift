//
//  VisualizationView.swift
//  Blood&Food
//
//  Created by Frank Jin on 2025-09-27.
//  Copyright © 2025 Frank Jin. All rights reserved.
//

import SwiftUI
import SwiftData
import Charts

struct VisualizationView: View {
    @Query(sort: \MealEntry.timestamp, order: .forward) private var mealEntries: [MealEntry]
    @EnvironmentObject var themeManager: ThemeManager

    private var completedEntries: [MealEntry] {
        mealEntries.filter { $0.isComplete }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if completedEntries.isEmpty {
                    EmptyVisualizationView()
                } else {
                    BloodSugarTrendChart(entries: completedEntries)
                    BloodSugarChangeChart(entries: completedEntries)
                    SummaryStatsView(entries: completedEntries)
                }
            }
            .padding()
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.large)
        .background(themeManager.currentTheme.backgroundColor)
    }
}

struct EmptyVisualizationView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)

            Text("No Data Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)

            Text("Add some meal entries with blood sugar readings to see your patterns here.")
                .font(.body)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

struct BloodSugarTrendChart: View {
    let entries: [MealEntry]
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ThemedCard(title: "Blood Sugar Trends") {
            Chart {
                ForEach(entries.suffix(10), id: \.id) { entry in
                    LineMark(
                        x: .value("Time", entry.timestamp),
                        y: .value("Before Meal", entry.bloodSugarBefore ?? 0)
                    )
                    .foregroundStyle(themeManager.currentTheme.chartBeforeColor)
                    .symbol(.circle)

                    LineMark(
                        x: .value("Time", entry.timestamp.addingTimeInterval(3600)),
                        y: .value("After Meal", entry.bloodSugarAfter ?? 0)
                    )
                    .foregroundStyle(themeManager.currentTheme.chartAfterColor)
                    .symbol(.square)
                }
            }
            .frame(height: 200)
            .chartYScale(domain: 60...300)
            .chartLegend {
                HStack {
                    Label("Before Meal", systemImage: "circle.fill")
                        .foregroundColor(themeManager.currentTheme.chartBeforeColor)
                    Label("After Meal", systemImage: "square.fill")
                        .foregroundColor(themeManager.currentTheme.chartAfterColor)
                }
                .font(.caption)
            }
        }
    }
}

struct BloodSugarChangeChart: View {
    let entries: [MealEntry]
    @EnvironmentObject var themeManager: ThemeManager

    private var changes: [(Date, Double)] {
        entries.compactMap { entry in
            guard let before = entry.bloodSugarBefore,
                  let after = entry.bloodSugarAfter else { return nil }
            return (entry.timestamp, after - before)
        }
    }

    var body: some View {
        ThemedCard(title: "Blood Sugar Changes") {
            Chart {
                ForEach(changes.suffix(10), id: \.0) { timestamp, change in
                    BarMark(
                        x: .value("Date", timestamp),
                        y: .value("Change", change)
                    )
                    .foregroundStyle(change > 0 ? themeManager.currentTheme.positiveChangeColor : themeManager.currentTheme.negativeChangeColor)
                }

                RuleMark(y: .value("Baseline", 0))
                    .foregroundStyle(themeManager.currentTheme.secondaryTextColor)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
            }
            .frame(height: 150)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Double.self) {
                            Text("\(intValue > 0 ? "+" : "")\(Int(intValue))")
                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        }
                    }
                }
            }
        }
    }
}

struct SummaryStatsView: View {
    let entries: [MealEntry]
    @EnvironmentObject var themeManager: ThemeManager

    private var averageIncrease: Double {
        let increases = entries.compactMap { entry -> Double? in
            guard let before = entry.bloodSugarBefore,
                  let after = entry.bloodSugarAfter else { return nil }
            return after - before
        }
        return increases.isEmpty ? 0 : increases.reduce(0, +) / Double(increases.count)
    }

    private var averageBeforeMeal: Double {
        let beforeReadings = entries.compactMap { $0.bloodSugarBefore }
        return beforeReadings.isEmpty ? 0 : beforeReadings.reduce(0, +) / Double(beforeReadings.count)
    }

    private var averageAfterMeal: Double {
        let afterReadings = entries.compactMap { $0.bloodSugarAfter }
        return afterReadings.isEmpty ? 0 : afterReadings.reduce(0, +) / Double(afterReadings.count)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Summary Statistics")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                ThemedStatCard(title: "Avg Before", value: "\(Int(averageBeforeMeal))", unit: "mg/dL", color: themeManager.currentTheme.chartBeforeColor)
                ThemedStatCard(title: "Avg After", value: "\(Int(averageAfterMeal))", unit: "mg/dL", color: themeManager.currentTheme.chartAfterColor)
                ThemedStatCard(title: "Avg Change", value: "\(averageIncrease > 0 ? "+" : "")\(Int(averageIncrease))", unit: "mg/dL", color: averageIncrease > 0 ? themeManager.currentTheme.positiveChangeColor : themeManager.currentTheme.negativeChangeColor)
            }
        }
    }
}

struct ThemedStatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(unit)
                .font(.caption2)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(themeManager.currentTheme.statCardBackgroundColor)
        .cornerRadius(8)
    }
}

struct ThemedCard<Content: View>: View {
    let title: String
    let content: Content
    @EnvironmentObject var themeManager: ThemeManager

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(12)
    }
}

#Preview {
    NavigationView {
        VisualizationView()
    }
    .modelContainer(for: MealEntry.self, inMemory: true)
    .environmentObject(ThemeManager())
}