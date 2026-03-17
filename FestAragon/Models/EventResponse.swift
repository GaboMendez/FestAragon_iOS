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

// MARK: - JSON Parsing Helpers
extension EventoJSON {
    var parsedStartDate: Date? {
        parseDate(inicio)
    }

    var parsedEndDate: Date? {
        parseDate(fin)
    }

    var eventCategory: EventCategory {
        EventCategory.fromStorageIdentifier(categoriaId)
    }

    private func parseDate(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        var parsedDate: Date?
        
        // Formato 1: ISO8601 con fracciones de segundo
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        parsedDate = formatter.date(from: value)
        
        // Formato 2: ISO8601 sin fracciones de segundo
        if parsedDate == nil {
            formatter.formatOptions = [.withInternetDateTime]
            parsedDate = formatter.date(from: value)
        }
        
        // Formato 3: Formato simple "yyyy-MM-dd'T'HH:mm:ss"
        if parsedDate == nil {
            let simpleDateFormatter = DateFormatter()
            simpleDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            simpleDateFormatter.locale = Locale(identifier: "en_US_POSIX")
            simpleDateFormatter.timeZone = TimeZone(identifier: "Europe/Madrid")
            parsedDate = simpleDateFormatter.date(from: value)
        }

        if parsedDate == nil {
            print("❌ Error parseando fecha: \(value)")
        }

        return parsedDate
    }
}
