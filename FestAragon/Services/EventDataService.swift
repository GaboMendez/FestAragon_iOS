import Foundation

class EventDataService {
    static let shared = EventDataService()
    
    private(set) var events: [Event] = []
    private let favoritesManager = FavoritesManager.shared
    
    private init() {
        loadAllEvents()
    }
    
    // MARK: - Public Methods
    
    /// Loads events and returns them with favorite status
    func loadEventsFromJSON() -> [Event] {
        return events
    }
    
    /// Reloads events from JSON and syncs favorite status
    func reloadEvents() {
        loadAllEvents()
    }
    
    /// Gets events with updated favorite status
    var eventsWithFavorites: [Event] {
        events.map { event in
            var updatedEvent = event
            updatedEvent.isFavorite = favoritesManager.isFavorite(eventId: event.jsonId)
            return updatedEvent
        }
    }
    
    // MARK: - Private Methods
    
    private func loadAllEvents() {
        guard let url = Bundle.main.url(forResource: "eventos", withExtension: "json") else {
            print("Error: No se encontró el archivo eventos.json")
            events = []
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let response = try decoder.decode(EventResponse.self, from: data)
            
            // Convertir EventoJSON a Event y sincronizar con FavoritesManager
            var loadedEvents = response.eventos.compactMap { $0.toEvent() }
            
            // Sincronizar estado de favoritos
            loadedEvents = loadedEvents.map { event in
                var updatedEvent = event
                updatedEvent.isFavorite = favoritesManager.isFavorite(eventId: event.jsonId)
                return updatedEvent
            }
            
            events = loadedEvents
            print("✅ Cargados \(events.count) eventos desde JSON")
            
        } catch {
            print("❌ Error al cargar eventos: \(error)")
            events = []
        }
    }
}
