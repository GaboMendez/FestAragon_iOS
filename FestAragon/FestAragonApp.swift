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
    @AppStorage("is_dark_mode_enabled") private var isDarkModeEnabled = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
        }
        .modelContainer(EventDataService.shared.modelContainer)
    }
}
