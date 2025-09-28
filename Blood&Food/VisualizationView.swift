import SwiftUI
import SwiftData
import Charts

struct VisualizationView: View {
    @Query(sort: \MealEntry.timestamp, order: .forward) private var mealEntries: [MealEntry]

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
    }
}

struct EmptyVisualizationView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Data Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add some meal entries with blood sugar readings to see your patterns here.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

struct BloodSugarTrendChart: View {
    let entries: [MealEntry]

    var body: some View {
        Card(title: "Blood Sugar Trends") {
            Chart {
                ForEach(entries.suffix(10), id: \.id) { entry in
                    LineMark(
                        x: .value("Time", entry.timestamp),
                        y: .value("Before Meal", entry.bloodSugarBefore ?? 0)
                    )
                    .foregroundStyle(.blue)
                    .symbol(.circle)

                    LineMark(
                        x: .value("Time", entry.timestamp.addingTimeInterval(3600)),
                        y: .value("After Meal", entry.bloodSugarAfter ?? 0)
                    )
                    .foregroundStyle(.red)
                    .symbol(.square)
                }
            }
            .frame(height: 200)
            .chartYScale(domain: 60...300)
            .chartLegend {
                HStack {
                    Label("Before Meal", systemImage: "circle.fill")
                        .foregroundColor(.blue)
                    Label("After Meal", systemImage: "square.fill")
                        .foregroundColor(.red)
                }
                .font(.caption)
            }
        }
    }
}

struct BloodSugarChangeChart: View {
    let entries: [MealEntry]

    private var changes: [(Date, Double)] {
        entries.compactMap { entry in
            guard let before = entry.bloodSugarBefore,
                  let after = entry.bloodSugarAfter else { return nil }
            return (entry.timestamp, after - before)
        }
    }

    var body: some View {
        Card(title: "Blood Sugar Changes") {
            Chart {
                ForEach(changes.suffix(10), id: \.0) { timestamp, change in
                    BarMark(
                        x: .value("Date", timestamp),
                        y: .value("Change", change)
                    )
                    .foregroundStyle(change > 0 ? .red : .green)
                }

                RuleMark(y: .value("Baseline", 0))
                    .foregroundStyle(.gray)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
            }
            .frame(height: 150)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Double.self) {
                            Text("\(intValue > 0 ? "+" : "")\(Int(intValue))")
                        }
                    }
                }
            }
        }
    }
}

struct SummaryStatsView: View {
    let entries: [MealEntry]

    private var averageIncrease: Double {
        let increases = entries.compactMap { entry in
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
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                StatCard(title: "Avg Before", value: "\(Int(averageBeforeMeal))", unit: "mg/dL", color: .blue)
                StatCard(title: "Avg After", value: "\(Int(averageAfterMeal))", unit: "mg/dL", color: .red)
                StatCard(title: "Avg Change", value: "\(averageIncrease > 0 ? "+" : "")\(Int(averageIncrease))", unit: "mg/dL", color: averageIncrease > 0 ? .red : .green)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationView {
        VisualizationView()
    }
    .modelContainer(for: MealEntry.self, inMemory: true)
}