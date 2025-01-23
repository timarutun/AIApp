//
//  AIAppApp.swift
//  AIApp
//
//  Created by Timur on 1/22/25.
//

import SwiftUI

@main
struct AIAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
