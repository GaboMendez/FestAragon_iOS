import Foundation

class EventDataService {
    static let shared = EventDataService()
    
    private init() {}
    
    func loadEventsFromJSON() -> [Event] {
        guard let url = Bundle.main.url(forResource: "eventos", withExtension: "json") else {
            print("Error: No se encontró el archivo eventos.json")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let response = try decoder.decode(EventResponse.self, from: data)
            
            // Convertir EventoJSON a Event
            let events = response.eventos.compactMap { $0.toEvent() }
            print("✅ Cargados \(events.count) eventos desde JSON")
            return events
            
        } catch {
            print("❌ Error al cargar eventos: \(error)")
            return []
        }
    }
}
