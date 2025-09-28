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

    init(timestamp: Date = Date(), bloodSugarBefore: Double? = nil, bloodSugarAfter: Double? = nil, mealDescription: String = "", notes: String = "") {
        self.id = UUID()
        self.timestamp = timestamp
        self.bloodSugarBefore = bloodSugarBefore
        self.bloodSugarAfter = bloodSugarAfter
        self.mealDescription = mealDescription
        self.notes = notes
    }

    var isComplete: Bool {
        return bloodSugarBefore != nil && bloodSugarAfter != nil && !mealDescription.isEmpty
    }
}
