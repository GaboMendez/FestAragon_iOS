//
//  EventView.swift
//  FestAragon
//
//  Created by Gabriel Mendez Reyes on 14/1/26.
//

import SwiftUI
import MapKit

struct EventView: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss
    @State private var isFavorite: Bool = false
    
    init(event: Event) {
        self.event = event
        self._isFavorite = State(initialValue: FavoritesManager.shared.isFavorite(eventId: event.jsonId))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Event Image
                ZStack(alignment: .topLeading) {
                    if let imageURL = event.imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure(_):
                                imagePlaceholder
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 250)
                            @unknown default:
                                imagePlaceholder
                            }
                        }
                    } else {
                        imagePlaceholder
                    }
                }
                .frame(height: 250)
                .clipped()
                
                VStack(alignment: .leading, spacing: 16) {
                    // Category badge
                    HStack {
                        Text(event.category.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(categoryColor.opacity(0.2))
                            .foregroundColor(categoryColor)
                            .cornerRadius(16)
                        
                        Spacer()
                        
                        // Favorite button
                        Button {
                            isFavorite.toggle()
                            FavoritesManager.shared.toggleFavorite(eventId: event.jsonId)
                        } label: {
                            Image(systemName: isFavorite ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundColor(isFavorite ? .yellow : .gray)
                        }
                    }
                    
                    // Title
                    Text(event.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Date and Time
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .foregroundColor(.secondary)
                            Text(formattedDate)
                                .font(.subheadline)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .foregroundColor(.secondary)
                            Text(event.timeRange)
                                .font(.subheadline)
                        }
                    }
                    
                    Divider()
                    
                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ubicación")
                            .font(.headline)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.location)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(event.address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Mini Map - Static snapshot to avoid Metal crashes
                        StaticMapView(coordinate: event.coordinate)
                            .frame(height: 150)
                            .cornerRadius(12)
                        
                        // Open in Maps button
                        Button {
                            openInMaps()
                        } label: {
                            HStack {
                                Image(systemName: "map.fill")
                                Text("Abrir en Mapas")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(red: 166/255, green: 47/255, blue: 54/255))
                            .cornerRadius(10)
                        }
                    }
                    
                    Divider()
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Descripción")
                            .font(.headline)
                        
                        Text(event.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    
                    // Price info
                    if event.price > 0 {
                        Divider()
                        
                        HStack {
                            Text("Precio")
                                .font(.headline)
                            Spacer()
                            Text(String(format: "%.2f €", event.price))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(categoryColor)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Detalle del Evento")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Helper Properties
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: event.date)
    }
    
    private var categoryColor: Color {
        switch event.category {
        case .music:
            return Color(red: 0.2, green: 0.4, blue: 0.8)
        case .cultural:
            return Color(red: 0.6, green: 0.3, blue: 0.7)
        case .infantil:
            return Color(red: 0.2, green: 0.7, blue: 0.5)
        case .traditional:
            return Color(red: 0.9, green: 0.5, blue: 0.2)
        }
    }
    
    private var imagePlaceholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(height: 250)
            .overlay(
                VStack {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Imagen no disponible")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            )
    }
    
    // MARK: - Actions
    
    private func openInMaps() {
        let coordinate = event.coordinate
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = event.location
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - Static Map View (prevents Metal crashes in Simulator)
struct StaticMapView: View {
    let coordinate: CLLocationCoordinate2D
    @State private var mapImage: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if let image = mapImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        ProgressView()
                    )
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        VStack {
                            Image(systemName: "map")
                                .font(.title)
                                .foregroundColor(.secondary)
                            Text("Mapa no disponible")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
            }
            
            // Pin overlay
            if mapImage != nil {
                Image(systemName: "mappin.circle.fill")
                    .font(.title)
                    .foregroundColor(.red)
                    .background(
                        Circle()
                            .fill(.white)
                            .frame(width: 20, height: 20)
                    )
            }
        }
        .onAppear {
            generateSnapshot()
        }
    }
    
    private func generateSnapshot() {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        options.size = CGSize(width: 400, height: 200)
        options.scale = UIScreen.main.scale
        
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { snapshot, error in
            DispatchQueue.main.async {
                isLoading = false
                if let snapshot = snapshot {
                    mapImage = snapshot.image
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EventView(event: Event(
            jsonId: "preview",
            title: "Concierto de Año Nuevo",
            description: "Un maravilloso concierto para celebrar el nuevo año con la mejor música clásica.",
            date: Date(),
            endDate: Date().addingTimeInterval(7200),
            category: .music,
            location: "Auditorio de Zaragoza",
            address: "Eduardo Ibarra, 3",
            latitude: 41.6436,
            longitude: -0.8926,
            imageURL: nil,
            price: 25.0
        ))
    }
}
