//
//  MultrixApp.swift
//  Multrix
//
//  Created by Mike Schwab on 1/13/26.
//

import SwiftUI
import SwiftData

@main
struct MultrixApp: App {
    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([ArithmeticHistoryEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create SwiftData container: \\(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .modelContainer(sharedModelContainer)
        }
    }
}
