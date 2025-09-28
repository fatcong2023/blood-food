import SwiftUI
import Foundation
import Combine

enum AppTheme: String, CaseIterable, Identifiable {
    case dark = "dark"
    case lightBlue = "lightBlue"
    case lightPink = "lightPink"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dark:
            return "Dark Theme"
        case .lightBlue:
            return "Light Blue Theme"
        case .lightPink:
            return "Light Pink Theme"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .dark:
            return Color.black
        case .lightBlue:
            return Color(red: 0.9, green: 0.95, blue: 1.0)
        case .lightPink:
            return Color(red: 1.0, green: 0.95, blue: 0.97)
        }
    }

    var primaryTextColor: Color {
        switch self {
        case .dark:
            return Color.white
        case .lightBlue:
            return Color(red: 0.1, green: 0.2, blue: 0.4)
        case .lightPink:
            return Color(red: 0.4, green: 0.1, blue: 0.2)
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .dark:
            return Color.gray
        case .lightBlue:
            return Color(red: 0.3, green: 0.4, blue: 0.6)
        case .lightPink:
            return Color(red: 0.6, green: 0.3, blue: 0.4)
        }
    }

    var chartBeforeColor: Color {
        switch self {
        case .dark:
            return Color.cyan
        case .lightBlue:
            return Color.blue
        case .lightPink:
            return Color.purple
        }
    }

    var chartAfterColor: Color {
        switch self {
        case .dark:
            return Color.orange
        case .lightBlue:
            return Color.red
        case .lightPink:
            return Color.pink
        }
    }

    var positiveChangeColor: Color {
        switch self {
        case .dark:
            return Color.red
        case .lightBlue:
            return Color.red
        case .lightPink:
            return Color(red: 0.8, green: 0.2, blue: 0.4)
        }
    }

    var negativeChangeColor: Color {
        switch self {
        case .dark:
            return Color.green
        case .lightBlue:
            return Color.green
        case .lightPink:
            return Color(red: 0.2, green: 0.6, blue: 0.4)
        }
    }

    var cardBackgroundColor: Color {
        switch self {
        case .dark:
            return Color(red: 0.1, green: 0.1, blue: 0.1)
        case .lightBlue:
            return Color.white
        case .lightPink:
            return Color.white
        }
    }

    var statCardBackgroundColor: Color {
        switch self {
        case .dark:
            return Color(red: 0.15, green: 0.15, blue: 0.15)
        case .lightBlue:
            return Color(red: 0.95, green: 0.98, blue: 1.0)
        case .lightPink:
            return Color(red: 1.0, green: 0.98, blue: 0.99)
        }
    }
}

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
        }
    }

    init() {
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? AppTheme.dark.rawValue
        self.currentTheme = AppTheme(rawValue: savedTheme) ?? .dark
    }
}