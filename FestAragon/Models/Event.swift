import Foundation
import CoreLocation

// MARK: - MediaItem
struct MediaItem: Identifiable, Codable {
    let id: UUID
    let type: MediaType
    let url: String
    
    init(id: UUID = UUID(), type: MediaType, url: String) {
        self.id = id
        self.type = type
        self.url = url
    }
}

enum MediaType: String, Codable {
    case image = "imagen"
    case video = "video"
    
    var iconName: String {
        switch self {
        case .image:
            return "photo"
        case .video:
            return "play.fill"
        }
    }
}

struct Event: Identifiable, Codable {
    let id: UUID
    let jsonId: String
    let title: String
    let description: String
    let date: Date
    let endDate: Date?
    let category: EventCategory
    let location: String
    let address: String
    let latitude: Double
    let longitude: Double
    let imageURL: String?
    let multimedia: [MediaItem]
    let price: Double
    let isPast: Bool
    var isFavorite: Bool
    let organizadorNombre: String
    let organizadorEmail: String
    
    // Computed property for CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // Formatted time range for display
    var timeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let start = formatter.string(from: date)
        if let end = endDate {
            let endStr = formatter.string(from: end)
            return "\(start) - \(endStr)"
        }
        return start
    }
    
    init(
        id: UUID = UUID(),
        jsonId: String = "",
        title: String,
        description: String,
        date: Date,
        endDate: Date? = nil,
        category: EventCategory,
        location: String,
        address: String = "",
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        imageURL: String? = nil,
        multimedia: [MediaItem] = [],
        price: Double = 0.0,
        isPast: Bool = false,
        isFavorite: Bool = false,
        organizadorNombre: String = "",
        organizadorEmail: String = ""
    ) {
        self.id = id
        self.jsonId = jsonId
        self.title = title
        self.description = description
        self.date = date
        self.endDate = endDate
        self.category = category
        self.location = location
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.imageURL = imageURL
        self.multimedia = multimedia
        self.price = price
        self.isPast = isPast
        self.isFavorite = isFavorite
        self.organizadorNombre = organizadorNombre
        self.organizadorEmail = organizadorEmail
    }
}

enum EventCategory: String, Codable, CaseIterable {
    case music = "MÚSICA"
    case cultural = "CULTURAL"
    case infantil = "INFANTIL"
    case traditional = "TRADICIONAL"
    
    var displayName: String {
        self.rawValue
    }

    var storageIdentifier: String {
        switch self {
        case .music:
            return "musica"
        case .cultural:
            return "cultural"
        case .infantil:
            return "infantil"
        case .traditional:
            return "tradicional"
        }
    }

    static func fromStorageIdentifier(_ identifier: String) -> EventCategory {
        switch identifier {
        case "musica":
            return .music
        case "cultural":
            return .cultural
        case "infantil":
            return .infantil
        case "tradicional":
            return .traditional
        default:
            return .music
        }
    }
}
