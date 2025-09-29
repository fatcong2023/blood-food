//
//  Item.swift
//  Blood&Food
//
//  Created by Frank Jin on 2025-09-27.
//

import Foundation
import SwiftData

@Model
final class MealEntry {
    var id: UUID
    var timestamp: Date
    var bloodSugarBefore: Double?
    var bloodSugarAfter: Double?
    var mealDescription: String
    var notes: String
    var mealTime: String

    init(timestamp: Date = Date(), bloodSugarBefore: Double? = nil, bloodSugarAfter: Double? = nil, mealDescription: String = "", notes: String = "", mealTime: String = "") {
        self.id = UUID()
        self.timestamp = timestamp
        self.bloodSugarBefore = bloodSugarBefore
        self.bloodSugarAfter = bloodSugarAfter
        self.mealDescription = mealDescription
        self.notes = notes

        // Infer meal time if not provided, without using self
        if mealTime.isEmpty {
            let hour = Calendar.current.component(.hour, from: timestamp)
            switch hour {
            case 5..<11:
                self.mealTime = "Breakfast"
            case 11..<15:
                self.mealTime = "Lunch"
            case 15..<20:
                self.mealTime = "Dinner"
            default:
                self.mealTime = "Snack"
            }
        } else {
            self.mealTime = mealTime
        }
    }

    var isComplete: Bool {
        return bloodSugarBefore != nil && bloodSugarAfter != nil && !mealDescription.isEmpty
    }


    func getBaselineInsulin(from context: ModelContext) -> Double {
        guard let activeBaseline = BaselineInsulin.getCurrentActive(from: context) else {
            return 0.0
        }
        return activeBaseline.getInsulinForMealTime(mealTime)
    }
}
