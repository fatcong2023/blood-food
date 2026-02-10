//
//  MealDetailThemeTests.swift
//  Blood&FoodTests
//
//  Created by Codex on 2026-02-10.
//

import SwiftUI
import Testing
import UIKit
@testable import Blood_Food

struct MealDetailThemeTests {
    @Test
    func styleUsesThemeColorsForDetailScreen() throws {
        let style = MealDetailThemeStyle(theme: .lightPink)

        #expect(colorsAreEqual(style.pageBackgroundColor, AppTheme.lightPink.backgroundColor))
        #expect(colorsAreEqual(style.cardBackgroundColor, AppTheme.lightPink.cardBackgroundColor))
        #expect(colorsAreEqual(style.primaryTextColor, AppTheme.lightPink.primaryTextColor))
        #expect(colorsAreEqual(style.secondaryTextColor, AppTheme.lightPink.secondaryTextColor))
    }

    private func colorsAreEqual(_ lhs: Color, _ rhs: Color) -> Bool {
        guard let lhsRGBA = rgbaComponents(of: lhs), let rhsRGBA = rgbaComponents(of: rhs) else {
            return false
        }

        let tolerance: CGFloat = 0.001
        return abs(lhsRGBA.red - rhsRGBA.red) < tolerance &&
            abs(lhsRGBA.green - rhsRGBA.green) < tolerance &&
            abs(lhsRGBA.blue - rhsRGBA.blue) < tolerance &&
            abs(lhsRGBA.alpha - rhsRGBA.alpha) < tolerance
    }

    private func rgbaComponents(of color: Color) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        let uiColor = UIColor(color)

        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }

        return (red, green, blue, alpha)
    }
}
