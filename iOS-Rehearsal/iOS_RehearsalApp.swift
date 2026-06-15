//
//  iOS_RehersalApp.swift
//  iOS-Rehersal
//
//  Created by Rubén Suárez on 14/06/26.
//

import SwiftUI
import CoreData

@main
struct iOS_RehersalApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
