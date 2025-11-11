//
//  BaselineInsulin.swift
//  Blood&Food
//
//  Created by Frank Jin on 2025-09-27.
//  Copyright © 2025 Frank Jin. All rights reserved.
//

import Foundation
import SwiftData

@Model
final class BaselineInsulin {
    var id = UUID()
    var dateCreated: Date
    var breakfastShortActing: Double
    var lunchShortActing: Double
    var dinnerShortActing: Double
    var bedtimeLongActing: Double
    var notes: String
    var isActive: Bool

    init(
        breakfastShortActing: Double = 0.0,
        lunchShortActing: Double = 0.0,
        dinnerShortActing: Double = 0.0,
        bedtimeLongActing: Double = 0.0,
        notes: String = "",
        isActive: Bool = true
    ) {
        self.dateCreated = Date()
        self.breakfastShortActing = breakfastShortActing
        self.lunchShortActing = lunchShortActing
        self.dinnerShortActing = dinnerShortActing
        self.bedtimeLongActing = bedtimeLongActing
        self.notes = notes
        self.isActive = isActive
    }
}

extension BaselineInsulin {
    func getInsulinForMealTime(_ mealTime: String) -> Double {
        switch mealTime.lowercased() {
        case "breakfast":
            return breakfastShortActing
        case "lunch":
            return lunchShortActing
        case "dinner":
            return dinnerShortActing
        case "bedtime":
            return bedtimeLongActing
        default:
            return 0.0
        }
    }

    static func getCurrentActive(from context: ModelContext) -> BaselineInsulin? {
        let descriptor = FetchDescriptor<BaselineInsulin>(
            predicate: #Predicate { $0.isActive == true },
            sortBy: [SortDescriptor(\.dateCreated, order: .reverse)]
        )

        do {
            let results = try context.fetch(descriptor)
            return results.first
        } catch {
            print("Error fetching active baseline insulin: \(error)")
            return nil
        }
    }
}