//
//  FestAragonApp.swift
//  FestAragon
//
//  Created by Gabriel Mendez Reyes on 14/1/26.
//

import SwiftUI
import SwiftData

@main
struct FestAragonApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(EventDataService.shared.modelContainer)
    }
}
