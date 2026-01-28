import SwiftUI
import MapKit

struct MapsView: View {
    @StateObject private var viewModel = MapsViewModel()
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.6488, longitude: -0.8891),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar - only show in map view
                if !viewModel.showListView {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(red: 166/255, green: 47/255, blue: 54/255).opacity(0.7))
                        
                        TextField("Buscar ubicación...", text: $viewModel.searchText)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                        
                        if !viewModel.searchText.isEmpty {
                            Button {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    viewModel.searchText = ""
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(red: 166/255, green: 47/255, blue: 54/255).opacity(0.6))
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(red: 166/255, green: 47/255, blue: 54/255).opacity(0.15), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .animation(.easeInOut, value: viewModel.searchText)
                }
                
                // Map Section - hide when in list view
                if !viewModel.showListView {
                    ZStack(alignment: .topTrailing) {
                        Map(coordinateRegion: $mapRegion, annotationItems: viewModel.mapEvents) { event in
                            MapAnnotation(coordinate: event.coordinate) {
                                EventMapMarker(
                                    category: event.category,
                                    isSelected: viewModel.selectedEvent?.id == event.id
                                )
                                .onTapGesture {
                                    centerOnEvent(event)
                                }
                            }
                        }
                        .frame(height: 280)
                        
                        // Map controls
                        VStack(spacing: 8) {
                            // User location button
                            Button {
                                centerOnUserLocation()
                            } label: {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(red: 166/255, green: 47/255, blue: 54/255))
                                    .frame(width: 36, height: 36)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            }
                            
                            // Zoom controls
                            VStack(spacing: 0) {
                                Button {
                                    zoomIn()
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                        .frame(width: 36, height: 36)
                                }
                                
                                Divider()
                                    .frame(width: 36)
                                
                                Button {
                                    zoomOut()
                                } label: {
                                    Image(systemName: "minus")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                        .frame(width: 36, height: 36)
                                }
                            }
                            .frame(width: 36)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                        .padding(.trailing, 12)
                        .padding(.top, 8)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Content section
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Category filters
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Filtrar por categoría")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                if !viewModel.selectedCategories.isEmpty {
                                    Button("Limpiar") {
                                        viewModel.clearFilters()
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(Color(red: 166/255, green: 47/255, blue: 54/255))
                                }
                            }
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(EventCategory.allCases, id: \.self) { category in
                                        CategoryPill(
                                            title: viewModel.displayName(for: category),
                                            icon: viewModel.iconName(for: category),
                                            isSelected: viewModel.isCategorySelected(category)
                                        ) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                viewModel.toggleCategory(category)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Nearby events header
                        HStack {
                            Text("Eventos Cercanos")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.showListView.toggle()
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(viewModel.showListView ? "Vista mapa" : "Vista lista")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                    Image(systemName: viewModel.showListView ? "map" : "list.bullet")
                                        .font(.subheadline)
                                }
                                .foregroundColor(Color(red: 166/255, green: 47/255, blue: 54/255))
                            }
                        }
                        .padding(.horizontal)
                        
                        // Events list
                        if viewModel.nearbyEvents.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "map.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("No hay eventos cercanos")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.nearbyEvents) { event in
                                    NavigationLink(destination: EventView(event: event)) {
                                        NearbyEventCard(
                                            event: event,
                                            distance: viewModel.formattedDistance(for: event),
                                            onFavoriteToggle: {
                                                viewModel.toggleFavorite(event: event)
                                            },
                                            onMapTap: {
                                                viewModel.showListView = false
                                                centerOnEvent(event)
                                            }
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Map Legend - only show in map view
                        if !viewModel.showListView {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Leyenda del Mapa")
                                    .font(.headline)
                                
                                ForEach(EventCategory.allCases, id: \.self) { category in
                                    LegendRow(
                                        icon: viewModel.iconName(for: category),
                                        title: legendTitle(for: category),
                                        category: category
                                    )
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                    .padding(.top, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(viewModel.showListView ? "Lista de Eventos" : "Mapa de Eventos")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color(red: 166/255, green: 47/255, blue: 54/255), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .background(Color(red: 250/255, green: 245/255, blue: 235/255))
        }
    }
    
    // MARK: - Helper Methods
    
    private func zoomIn() {
        mapRegion.span = MKCoordinateSpan(
            latitudeDelta: max(mapRegion.span.latitudeDelta / 2, 0.002),
            longitudeDelta: max(mapRegion.span.longitudeDelta / 2, 0.002)
        )
        viewModel.selectedEvent = nil
    }
    
    private func zoomOut() {
        mapRegion.span = MKCoordinateSpan(
            latitudeDelta: min(mapRegion.span.latitudeDelta * 2, 0.5),
            longitudeDelta: min(mapRegion.span.longitudeDelta * 2, 0.5)
        )
        viewModel.selectedEvent = nil
    }
    
    private func centerOnEvent(_ event: Event) {
        mapRegion = MKCoordinateRegion(
            center: event.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        viewModel.selectedEvent = event
    }
    
    private func centerOnUserLocation() {
        mapRegion = MKCoordinateRegion(
            center: viewModel.userLocation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    }
    
    private func legendTitle(for category: EventCategory) -> String {
        switch category {
        case .music:
            return "Conciertos y Música"
        case .cultural:
            return "Eventos Culturales"
        case .infantil:
            return "Actividades Infantiles"
        case .traditional:
            return "Torneos y Juegos"
        }
    }
}

// MARK: - Event Map Marker
struct EventMapMarker: View {
    let category: EventCategory
    var isSelected: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(markerColor)
                    .frame(width: isSelected ? 40 : 32, height: isSelected ? 40 : 32)
                    .shadow(color: markerColor.opacity(0.4), radius: isSelected ? 6 : 3, x: 0, y: 2)
                
                Image(systemName: iconName)
                    .font(.system(size: isSelected ? 18 : 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Marker point
            Triangle()
                .fill(markerColor)
                .frame(width: 12, height: 8)
                .offset(y: -2)
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
    
    private var markerColor: Color {
        switch category {
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
    
    private var iconName: String {
        switch category {
        case .music:
            return "music.note"
        case .cultural:
            return "theatermasks.fill"
        case .infantil:
            return "figure.and.child.holdinghands"
        case .traditional:
            return "sparkles"
        }
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Category Pill
struct CategoryPill: View {
    let title: String
    let icon: String
    var isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.primary : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - Nearby Event Card
struct NearbyEventCard: View {
    let event: Event
    let distance: String
    let onFavoriteToggle: () -> Void
    let onMapTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Event Image
            ZStack {
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
                                .frame(width: 80, height: 80)
                        @unknown default:
                            imagePlaceholder
                        }
                    }
                } else {
                    imagePlaceholder
                }
            }
            .frame(width: 80, height: 80)
            .cornerRadius(8)
            .clipped()
            
            // Event Info
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption2)
                    Text("\(event.location) - \(distance)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(event.timeRange)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: onFavoriteToggle) {
                    Image(systemName: event.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 18))
                        .foregroundColor(event.isFavorite ? .yellow : .gray)
                }
                
                Button(action: onMapTap) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 166/255, green: 47/255, blue: 54/255))
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var imagePlaceholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .overlay(
                Text("Imagen")
                    .font(.caption)
                    .foregroundColor(.secondary)
            )
    }
}

// MARK: - Legend Row
struct LegendRow: View {
    let icon: String
    let title: String
    let category: EventCategory
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(markerColor)
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    private var markerColor: Color {
        switch category {
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
}

#Preview {
    MapsView()
}

