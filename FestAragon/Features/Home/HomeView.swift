//
//  HomeView.swift
//  FestAragon
//
//  Created by Gabriel Mendez Reyes on 14/1/26.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "house.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                    .padding()
                
                Text("Home")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Welcome to FestAragon")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeView()
}
