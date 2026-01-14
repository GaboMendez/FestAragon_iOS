//
//  EventView.swift
//  FestAragon
//
//  Created by Gabriel Mendez Reyes on 14/1/26.
//

import SwiftUI

struct EventView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "calendar")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)
                    .padding()
                
                Text("Event Details")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("View event information")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Event")
        }
    }
}

#Preview {
    EventView()
}
