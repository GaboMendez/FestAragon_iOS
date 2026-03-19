import SwiftUI
import MapKit

struct MapsView: View {
    @StateObject private var viewModel = MapsViewModel()
    @State private var mapPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.6488, longitude: -0.8891),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar - only show in map view
                if !viewModel.showListView && viewModel.selectedLocality == nil {
                    MapSearchBar(searchText: $viewModel.searchText)
                }
                
                // Map Section - hide when in list view or locality selected
                if !viewModel.showListView && viewModel.selectedLocality == nil {
                    ZStack(alignment: .topTrailing) {
                        Map(position: $mapPosition) {
                            // Anotaciones de localidades
                            ForEach(viewModel.availableLocalities, id: \.name) { locality in
                                Annotation("", coordinate: locality.center) {
                                    LocalityMapMarker(
                                        locality: locality.name,
                                        eventCount: viewModel.eventCountInLocality(locality.name),
                                        isSelected: viewModel.selectedLocality == locality.name
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            viewModel.selectLocality(locality.name)
                                        }
                                    }
                                }
                            }
                            
                            // Anotaciones de eventos individuales
                            ForEach(viewModel.mapEvents) { event in
                                Annotation("", coordinate: event.coordinate) {
                                    EventMapMarker(
                                        category: event.category,
                                        isSelected: viewModel.selectedEvent?.id == event.id
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            centerOnEvent(event)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: 280)
                        .onTapGesture {
                            // Dismiss callout when tapping on map background
                            withAnimation(.easeOut(duration: 0.2)) {
                                viewModel.selectedEvent = nil
                            }
                        }
                        
                        // Selected event callout
                        if let selectedEvent = viewModel.selectedEvent {
                            VStack {
                                Spacer()
                                MapEventCallout(
                                    event: selectedEvent,
                                    distance: viewModel.formattedDistance(for: selectedEvent),
                                    onClose: {
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            viewModel.selectedEvent = nil
                                        }
                                    },
                                    onFavoriteToggle: {
                                        viewModel.toggleFavorite(event: selectedEvent)
                                    }
                                )
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .padding(.horizontal, 12)
                                .padding(.bottom, 8)
                            }
                            .frame(height: 280)
                        }
                        
                        // Map controls
                        MapControls(
                            onLocationTap: centerOnUserLocation,
                            onZoomIn: zoomIn,
                            onZoomOut: zoomOut
                        )
                        .padding(.trailing, 12)
                        .padding(.top, 8)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Content section
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Category filters
                        CategoryFiltersSection(
                            categories: EventCategory.allCases,
                            selectedCategories: viewModel.selectedCategories,
                            displayName: viewModel.displayName(for:),
                            iconName: viewModel.iconName(for:),
                            onToggle: viewModel.toggleCategory,
                            onClear: viewModel.clearFilters
                        )
                        
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
                                .foregroundColor(.festPrimary)
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
                                    EventCardWrapper(event: event, overlaySize: .small) {
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
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Map Legend - only show in map view
                        if !viewModel.showListView {
                            MapLegendSection(
                                categories: EventCategory.allCases,
                                iconName: viewModel.iconName(for:),
                                legendTitle: legendTitle(for:)
                            )
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
            .background(Color.festBackground)
            .navigationDestination(isPresented: Binding(
                get: { viewModel.selectedLocality != nil },
                set: { if !$0 { viewModel.deselectLocality() } }
            )) {
                LocalityEventsView(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Helper Methods
    @State private var currentCenter = CLLocationCoordinate2D(latitude: 41.6488, longitude: -0.8891)
    @State private var currentSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    
    private func zoomIn() {
        currentSpan = MKCoordinateSpan(
            latitudeDelta: max(currentSpan.latitudeDelta / 2, 0.002),
            longitudeDelta: max(currentSpan.longitudeDelta / 2, 0.002)
        )
        mapPosition = .region(MKCoordinateRegion(center: currentCenter, span: currentSpan))
        viewModel.selectedEvent = nil
    }
    
    private func zoomOut() {
        currentSpan = MKCoordinateSpan(
            latitudeDelta: min(currentSpan.latitudeDelta * 2, 0.5),
            longitudeDelta: min(currentSpan.longitudeDelta * 2, 0.5)
        )
        mapPosition = .region(MKCoordinateRegion(center: currentCenter, span: currentSpan))
        viewModel.selectedEvent = nil
    }
    
    private func centerOnEvent(_ event: Event) {
        currentCenter = event.coordinate
        currentSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        mapPosition = .region(MKCoordinateRegion(center: currentCenter, span: currentSpan))
        viewModel.selectedEvent = event
    }
    
    private func centerOnUserLocation() {
        currentCenter = viewModel.userLocation.coordinate
        currentSpan = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        mapPosition = .region(MKCoordinateRegion(center: currentCenter, span: currentSpan))
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

#Preview {
    MapsView()
}