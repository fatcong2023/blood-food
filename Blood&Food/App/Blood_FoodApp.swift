//
//  Blood_FoodApp.swift
//  Blood&Food
//
//  Created by Frank Jin on 2025-09-27.
//  Copyright © 2025 Frank Jin. All rights reserved.
//

import SwiftUI
import SwiftData

@main
struct Blood_FoodApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MealEntry.self,
            BaselineInsulin.self,
        ])

        do {
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("⚠️ ModelContainer creation failed: \(error)")
            print("This often happens when adding new models to existing data.")
            print("Quick fix: Reset simulator (Device -> Erase All Content and Settings)")

            // For development, you can use in-memory storage as fallback
            do {
                print("Using in-memory storage as fallback...")
                let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                return try ModelContainer(for: schema, configurations: [fallbackConfiguration])
            } catch {
                fatalError("Could not create fallback ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
