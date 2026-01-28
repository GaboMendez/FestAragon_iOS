import Foundation

// MARK: - Respuesta completa del JSON
struct EventResponse: Codable {
    let meta: Meta
    let pueblo: Pueblo
    let categorias: [Categoria]
    let organizadores: [Organizador]
    let eventos: [EventoJSON]
}

// MARK: - Meta
struct Meta: Codable {
    let version: String
    let timezone: String
    let ultimaActualizacion: String
}

// MARK: - Pueblo
struct Pueblo: Codable {
    let nombre: String
    let provincia: String
    let comunidad: String
    let coordenadas: Coordenadas
    let fechasFiestas: FechasFiestas
}

struct Coordenadas: Codable {
    let lat: Double
    let lng: Double
}

struct FechasFiestas: Codable {
    let inicio: String
    let fin: String
}

// MARK: - Categoria
struct Categoria: Codable {
    let id: String
    let nombre: String
    let icono: String
}

// MARK: - Organizador
struct Organizador: Codable {
    let id: String
    let nombre: String
    let contacto: String
}

// MARK: - EventoJSON (del JSON)
struct EventoJSON: Codable {
    let id: String
    let titulo: String
    let descripcion: String
    let categoriaId: String
    let organizadorId: String
    let inicio: String
    let fin: String
    let lugar: Lugar
    let multimedia: [Multimedia]
    let tags: [String]
}

struct Lugar: Codable {
    let nombre: String
    let direccion: String
    let coordenadas: Coordenadas
}

struct Multimedia: Codable {
    let tipo: String
    let recurso: String
}

// MARK: - Extension para convertir EventoJSON a Event
extension EventoJSON {
    func toEvent(organizadores: [Organizador]) -> Event? {
        // Probar múltiples formatos de fecha
        let formatter = ISO8601DateFormatter()
        var startDate: Date?
        
        // Formato 1: ISO8601 con fracciones de segundo
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        startDate = formatter.date(from: inicio)
        
        // Formato 2: ISO8601 sin fracciones de segundo
        if startDate == nil {
            formatter.formatOptions = [.withInternetDateTime]
            startDate = formatter.date(from: inicio)
        }
        
        // Formato 3: Formato simple "yyyy-MM-dd'T'HH:mm:ss"
        if startDate == nil {
            let simpleDateFormatter = DateFormatter()
            simpleDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            simpleDateFormatter.locale = Locale(identifier: "en_US_POSIX")
            simpleDateFormatter.timeZone = TimeZone(identifier: "Europe/Madrid")
            startDate = simpleDateFormatter.date(from: inicio)
        }
        
        guard let eventDate = startDate else {
            print("❌ Error parseando fecha: \(inicio)")
            return nil
        }
        
        // Parsear fecha de fin
        var endDate: Date?
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        endDate = formatter.date(from: fin)
        if endDate == nil {
            formatter.formatOptions = [.withInternetDateTime]
            endDate = formatter.date(from: fin)
        }
        if endDate == nil {
            let simpleDateFormatter = DateFormatter()
            simpleDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            simpleDateFormatter.locale = Locale(identifier: "en_US_POSIX")
            simpleDateFormatter.timeZone = TimeZone(identifier: "Europe/Madrid")
            endDate = simpleDateFormatter.date(from: fin)
        }
        
        // Mapear categoría del JSON a EventCategory
        let category: EventCategory
        switch categoriaId {
        case "musica":
            category = .music
        case "cultural":
            category = .cultural
        case "infantil":
            category = .infantil
        case "tradicional":
            category = .traditional
        default:
            category = .music
        }
        
        // Determinar si el evento es pasado basado en la fecha de demo
        let isPast = AppConfiguration.isPastDate(eventDate)
        
        // Verificar si está en favoritos
        let isFavorite = FavoritesManager.shared.isFavorite(eventId: id)
        
        // Convertir multimedia del JSON a MediaItem
        let mediaItems = multimedia.map { media in
            MediaItem(
                type: MediaType(rawValue: media.tipo) ?? .image,
                url: media.recurso
            )
        }
        
        // Buscar organizador por ID
        let organizador = organizadores.first { $0.id == organizadorId }
        
        return Event(
            id: UUID(),
            jsonId: id,
            title: titulo,
            description: descripcion,
            date: eventDate,
            endDate: endDate,
            category: category,
            location: lugar.nombre,
            address: lugar.direccion,
            latitude: lugar.coordenadas.lat,
            longitude: lugar.coordenadas.lng,
            imageURL: multimedia.first?.recurso,
            multimedia: mediaItems,
            price: 0.0,
            isPast: isPast,
            isFavorite: isFavorite,
            organizadorNombre: organizador?.nombre ?? "Organizador",
            organizadorEmail: organizador?.contacto ?? ""
        )
    }
}
