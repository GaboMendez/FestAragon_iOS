//
//  EventResponse.swift
//  FestAragon
//
//  Created by Gabriel Mendez Reyes on 14/1/26.
//

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
    func toEvent() -> Event? {
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
        
        // Determinar si el evento es pasado basado en la fecha de demo (21 enero 2026)
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 21
        components.hour = 0
        components.minute = 0
        let demoDate = Calendar.current.date(from: components) ?? Date()
        let isPast = eventDate < demoDate
        
        return Event(
            id: UUID(),
            title: titulo,
            description: descripcion,
            date: eventDate,
            category: category,
            location: lugar.nombre,
            imageURL: multimedia.first?.recurso,
            price: 0.0,
            isPast: isPast,
            isFavorite: false
        )
    }
}
