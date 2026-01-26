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
                    Label("Inicio", systemImage: "house.fill")
                }
            
            MapsView()
                .tabItem {
                    Label("Mapa", systemImage: "map.fill")
                }
            
            FavoritesView()
                .tabItem {
                    Label("Favoritos", systemImage: "star.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Perfil", systemImage: "person.fill")
                }
        }
        .tint(Color(red: 166/255, green: 47/255, blue: 54/255))
    }
}

#Preview {
    ContentView()
}
