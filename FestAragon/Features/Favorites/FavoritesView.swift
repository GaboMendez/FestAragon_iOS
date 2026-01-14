//
//  FavoritesView.swift
//  FestAragon
//
//  Created by Gabriel Mendez Reyes on 14/1/26.
//

import SwiftUI

struct FavoritesView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.red)
                    .padding()
                
                Text("Favorites")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your saved events")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Favorites")
        }
    }
}

#Preview {
    FavoritesView()
}
