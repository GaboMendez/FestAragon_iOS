import Foundation
import SwiftUI
import Combine
import CoreLocation
import MapKit

@MainActor
class MapsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var events: [Event] = []
    @Published var filteredEvents: [Event] = []
    @Published var searchText: String = ""
    @Published var selectedCategories: Set<EventCategory> = []
    @Published var showListView: Bool = false
    @Published var selectedEvent: Event?
    @Published var selectedLocality: String?
    @Published var locationPermissionGranted: Bool = false
    
    // User location (simulated for demo - Plaza del Pilar)
    let userLocation = CLLocation(latitude: 41.6561, longitude: -0.8779)
    
    private var cancellables = Set<AnyCancellable>()
    private let favoritesManager = FavoritesManager.shared
    private let privacySettings = PrivacySettingsManager.shared
    
    // MARK: - Computed Properties
    
    /// Events to display on the map (filtered by category if any selected)
    var mapEvents: [Event] {
        filteredEvents
    }
    
    /// Todas las localidades únicas disponibles
    var availableLocalities: [(name: String, center: CLLocationCoordinate2D)] {
        let uniqueLocalities = Set(filteredEvents.map { $0.location })
        return uniqueLocalities.sorted().map { locality in
            let eventsInLocality = filteredEvents.filter { $0.location == locality }

            guard !eventsInLocality.isEmpty else {
                return (name: locality, center: userLocation.coordinate)
            }
            
            // Calcular centro de la localidad basado en el promedio de coordenadas de sus eventos
            let avgLat = eventsInLocality.map { $0.latitude }.reduce(0, +) / Double(eventsInLocality.count)
            let avgLng = eventsInLocality.map { $0.longitude }.reduce(0, +) / Double(eventsInLocality.count)
            
            return (name: locality, center: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLng))
        }
    }
    
    /// Eventos de la localidad seleccionada
    var eventsInSelectedLocality: [Event] {
        guard let locality = selectedLocality else { return [] }
        return filteredEvents.filter { $0.location == locality }
    }
    
    /// Events sorted by distance from user
    var nearbyEvents: [Event] {
        filteredEvents.sorted { event1, event2 in
            distanceFrom(event: event1) < distanceFrom(event: event2)
        }
    }
    
    // MARK: - Init
    init() {
        loadEvents()
        setupSubscriptions()
        setupAdminChangeObserver()
    }
    
    // MARK: - Private Methods
    
    private func setupAdminChangeObserver() {
        NotificationCenter.default.publisher(for: .adminEventDataChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadEvents()
            }
            .store(in: &cancellables)
    }

    private func syncFavoriteStatus() {
        for index in events.indices {
            events[index].isFavorite = favoritesManager.isFavorite(eventId: events[index].jsonId)
        }
        for index in filteredEvents.indices {
            filteredEvents[index].isFavorite = favoritesManager.isFavorite(eventId: filteredEvents[index].jsonId)
        }
        if let eventId = selectedEvent?.jsonId {
            selectedEvent?.isFavorite = favoritesManager.isFavorite(eventId: eventId)
        }
    }
    
    private func setupSubscriptions() {
        // Observe favorites changes
        favoritesManager.$favoriteIds
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncFavoriteStatus()
            }
            .store(in: &cancellables)
        
        // Observe location permission changes from centralized manager
        privacySettings.$locationPermissionGranted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] granted in
                self?.locationPermissionGranted = granted
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest($searchText, $selectedCategories)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _ in
                self?.filterEvents()
            }
            .store(in: &cancellables)
    }
    
    private func filterEvents() {
        var result = events
        
        // Filter only future events (from demo date)
        result = result.filter { $0.date >= AppConfiguration.startOfDemoDay }
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { event in
                event.title.localizedCaseInsensitiveContains(searchText) ||
                event.location.localizedCaseInsensitiveContains(searchText) ||
                event.address.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by categories
        if !selectedCategories.isEmpty {
            result = result.filter { selectedCategories.contains($0.category) }
        }
        
        filteredEvents = result

        if let selectedLocality,
           !filteredEvents.contains(where: { $0.location == selectedLocality }) {
            self.selectedLocality = nil
        }
    }
    
    private func loadEvents() {
        events = EventDataService.shared.loadEvents()
        filterEvents()
    }
    
    // MARK: - Public Methods
    
    /// Toggle a category filter
    func toggleCategory(_ category: EventCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
    
    /// Check if a category is selected
    func isCategorySelected(_ category: EventCategory) -> Bool {
        selectedCategories.contains(category)
    }
    
    /// Clear all category filters
    func clearFilters() {
        selectedCategories.removeAll()
        searchText = ""
    }
    
    /// Calculate distance from user to event
    func distanceFrom(event: Event) -> CLLocationDistance {
        let eventLocation = CLLocation(latitude: event.latitude, longitude: event.longitude)
        return userLocation.distance(from: eventLocation)
    }
    
    /// Format distance for display
    func formattedDistance(for event: Event) -> String {
        let distance = distanceFrom(event: event)
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
    
    /// Toggle favorite for an event
    func toggleFavorite(event: Event) {
        favoritesManager.toggleFavorite(eventId: event.jsonId)
    }
    
    /// Get icon name for category
    func iconName(for category: EventCategory) -> String {
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
    
    /// Get display name for category (Spanish)
    func displayName(for category: EventCategory) -> String {
        switch category {
        case .music:
            return "Conciertos"
        case .cultural:
            return "Culturales"
        case .infantil:
            return "Infantiles"
        case .traditional:
            return "Tradicionales"
        }
    }
    
    /// Get color for category
    func color(for category: EventCategory) -> String {
        switch category {
        case .music:
            return "MusicColor"
        case .cultural:
            return "CulturalColor"
        case .infantil:
            return "InfantilColor"
        case .traditional:
            return "TradicionalColor"
        }
    }
    
    /// Obtener el conteo de eventos en una localidad
    func eventCountInLocality(_ locality: String) -> Int {
        filteredEvents.filter { $0.location == locality }.count
    }
    
    /// Seleccionar una localidad
    func selectLocality(_ locality: String) {
        selectedLocality = locality
        selectedEvent = nil
    }
    
    /// Deseleccionar la localidad actual
    func deselectLocality() {
        selectedLocality = nil
    }
}
