//
//  MapsView.swift
//  FestAragon
//
//  Created by Gabriel Mendez Reyes on 14/1/26.
//

import SwiftUI

struct MapsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "map.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                    .padding()
                
                Text("Maps")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Explore event locations")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Maps")
        }
    }
}

#Preview {
    MapsView()
}
