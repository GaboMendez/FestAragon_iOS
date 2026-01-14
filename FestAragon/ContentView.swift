//
//  ContentView.swift
//  FestAragon
//
//  Created by Gabriel Mendez Reyes on 14/1/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            MapsView()
                .tabItem {
                    Label("Maps", systemImage: "map.fill")
                }
            
            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
