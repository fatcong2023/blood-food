//
//  DateFilterView.swift
//  Blood&Food
//
//  Created by Frank Jin on 2025-09-27.
//  Copyright © 2025 Frank Jin. All rights reserved.
//

import SwiftUI

struct DateFilterView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var selectedDate: Date?
    @Binding var showAllMeals: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var calendarDate = Date()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Filter Options")
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)

                        Button(action: {
                            showAllMeals = true
                            selectedDate = nil
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: showAllMeals ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(showAllMeals ? themeManager.currentTheme.negativeChangeColor : themeManager.currentTheme.secondaryTextColor)
                                Text("Show All Meals")
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                Spacer()
                                Text("(Most recent first)")
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                            .padding()
                            .background(themeManager.currentTheme.cardBackgroundColor)
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: {
                            showAllMeals = false
                            selectedDate = Calendar.current.startOfDay(for: Date())
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: (!showAllMeals && Calendar.current.isDateInToday(selectedDate ?? Date())) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor((!showAllMeals && Calendar.current.isDateInToday(selectedDate ?? Date())) ? themeManager.currentTheme.negativeChangeColor : themeManager.currentTheme.secondaryTextColor)
                                Text("Today Only")
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                Spacer()
                                Text("(\(Date(), format: .dateTime.month().day()))")
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                            .padding()
                            .background(themeManager.currentTheme.cardBackgroundColor)
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding()
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Specific Date")
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)

                        CalendarView(
                            selectedDate: $selectedDate,
                            showAllMeals: $showAllMeals,
                            calendarDate: $calendarDate
                        )
                        .environmentObject(themeManager)
                    }
                    .padding()
                }

                Spacer()
            }
            .background(themeManager.currentTheme.backgroundColor)
            .navigationTitle("Filter Meals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                }
            }
        }
    }
}

struct CalendarView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var selectedDate: Date?
    @Binding var showAllMeals: Bool
    @Binding var calendarDate: Date
    @Environment(\.dismiss) private var dismiss

    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    var body: some View {
        VStack(spacing: 16) {
            // Month/Year header with navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        .padding(8)
                }

                Spacer()

                Text(dateFormatter.string(from: calendarDate))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        .padding(8)
                }
            }

            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                // Weekday headers
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .frame(height: 30)
                }

                // Calendar days
                ForEach(calendarDays, id: \.self) { date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate ?? Date.distantPast),
                            isToday: calendar.isDateInToday(date),
                            isCurrentMonth: calendar.isDate(date, equalTo: calendarDate, toGranularity: .month)
                        ) {
                            selectDate(date)
                        }
                        .environmentObject(themeManager)
                    } else {
                        Text("")
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(16)
    }

    private var calendarDays: [Date?] {
        let startOfMonth = calendar.dateInterval(of: .month, for: calendarDate)?.start ?? calendarDate
        let startOfCalendar = calendar.dateInterval(of: .weekOfYear, for: startOfMonth)?.start ?? startOfMonth

        var days: [Date?] = []
        let endDate = calendar.date(byAdding: .day, value: 42, to: startOfCalendar) ?? startOfCalendar

        var currentDate = startOfCalendar
        while currentDate < endDate {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return days
    }

    private func previousMonth() {
        calendarDate = calendar.date(byAdding: .month, value: -1, to: calendarDate) ?? calendarDate
    }

    private func nextMonth() {
        calendarDate = calendar.date(byAdding: .month, value: 1, to: calendarDate) ?? calendarDate
    }

    private func selectDate(_ date: Date) {
        selectedDate = calendar.startOfDay(for: date)
        showAllMeals = false
        dismiss()
    }
}

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let action: () -> Void

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .foregroundColor(textColor)
                .frame(width: 40, height: 40)
                .background(backgroundColor)
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
                )
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return themeManager.currentTheme.negativeChangeColor
        } else if isCurrentMonth {
            return themeManager.currentTheme.primaryTextColor
        } else {
            return themeManager.currentTheme.secondaryTextColor.opacity(0.5)
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return themeManager.currentTheme.negativeChangeColor
        } else {
            return Color.clear
        }
    }

    private var borderColor: Color {
        isSelected ? themeManager.currentTheme.negativeChangeColor : Color.clear
    }
}

#Preview {
    DateFilterView(selectedDate: .constant(Date()), showAllMeals: .constant(true))
        .environmentObject(ThemeManager())
}