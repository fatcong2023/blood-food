//
//  Blood_FoodApp.swift
//  Blood&Food
//
//  Created by Frank Jin on 2025-09-27.
//

import SwiftUI
import SwiftData

@main
struct Blood_FoodApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MealEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
