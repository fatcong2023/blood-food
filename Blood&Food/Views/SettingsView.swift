//
//  SettingsView.swift
//  Blood&Food
//
//  Created by Frank Jin on 2025-09-27.
//  Copyright © 2025 Frank Jin. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        NavigationView {
            Form {
                Section {
                    ForEach(AppTheme.allCases) { theme in
                        HStack {
                            ThemePreviewCard(theme: theme)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(theme.displayName)
                                    .font(.headline)
                                    .foregroundColor(themeTitleColor(for: theme))

                                Text(themeDescription(for: theme))
                                    .font(.caption)
                                    .foregroundColor(themeSubtitleColor(for: theme))
                            }

                            Spacer()

                            if themeManager.currentTheme == theme {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .contentShape(Rectangle())
                        .listRowBackground(themeManager.currentTheme.cardBackgroundColor)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                themeManager.currentTheme = theme
                            }
                        }
                    }
                } header: {
                    Text("Theme")
                        .foregroundColor(sectionHeaderColor)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .background(themeManager.currentTheme.backgroundColor)
        }
    }

    private func themeDescription(for theme: AppTheme) -> String {
        switch theme {
        case .dark:
            return "High contrast with black background"
        case .lightBlue:
            return "Calming blue tones for easy viewing"
        case .lightPink:
            return "Soft pink aesthetics for comfort"
        }
    }

    private var sectionHeaderColor: Color {
        themeManager.currentTheme == .dark ? .white : themeManager.currentTheme.secondaryTextColor
    }

    private func themeTitleColor(for theme: AppTheme) -> Color {
        guard themeManager.currentTheme == .dark else {
            return theme.primaryTextColor
        }

        switch theme {
        case .dark:
            return .white
        case .lightBlue:
            return Color(red: 0.56, green: 0.80, blue: 1.0)
        case .lightPink:
            return Color(red: 1.0, green: 0.72, blue: 0.86)
        }
    }

    private func themeSubtitleColor(for theme: AppTheme) -> Color {
        guard themeManager.currentTheme == .dark else {
            return theme.secondaryTextColor
        }

        switch theme {
        case .dark:
            return Color(white: 0.75)
        case .lightBlue:
            return Color(red: 0.46, green: 0.70, blue: 0.96)
        case .lightPink:
            return Color(red: 0.95, green: 0.58, blue: 0.79)
        }
    }
}

struct ThemePreviewCard: View {
    let theme: AppTheme

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                Rectangle()
                    .fill(theme.chartBeforeColor)
                    .frame(width: 8, height: 8)
                Rectangle()
                    .fill(theme.chartAfterColor)
                    .frame(width: 8, height: 8)
            }

            Rectangle()
                .fill(theme.primaryTextColor)
                .frame(width: 16, height: 2)

            Rectangle()
                .fill(theme.secondaryTextColor)
                .frame(width: 12, height: 1)
        }
        .padding(6)
        .background(theme.backgroundColor)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(theme.primaryTextColor.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
}
