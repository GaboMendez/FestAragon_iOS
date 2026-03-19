import Foundation
import SwiftData

@Model
final class TownEntity {
    @Attribute(.unique) var identifier: String
    var name: String
    var province: String
    var region: String
    var latitude: Double
    var longitude: Double
    var festivalStart: String
    var festivalEnd: String

    init(
        identifier: String = "festival_town",
        name: String,
        province: String,
        region: String,
        latitude: Double,
        longitude: Double,
        festivalStart: String,
        festivalEnd: String
    ) {
        self.identifier = identifier
        self.name = name
        self.province = province
        self.region = region
        self.latitude = latitude
        self.longitude = longitude
        self.festivalStart = festivalStart
        self.festivalEnd = festivalEnd
    }
}

@Model
final class LocalityEntity {
    @Attribute(.unique) var name: String

    init(name: String) {
        self.name = name
    }
}

@Model
final class CategoryEntity {
    @Attribute(.unique) var identifier: String
    var name: String
    var iconName: String

    init(identifier: String, name: String, iconName: String) {
        self.identifier = identifier
        self.name = name
        self.iconName = iconName
    }
}

@Model
final class OrganizerEntity {
    @Attribute(.unique) var identifier: String
    var name: String
    var contact: String

    init(identifier: String, name: String, contact: String) {
        self.identifier = identifier
        self.name = name
        self.contact = contact
    }
}

@Model
final class EventEntity {
    @Attribute(.unique) var jsonId: String
    var title: String
    var eventDescription: String
    var date: Date
    var endDate: Date?
    var categoryIdentifier: String
    var location: String
    var address: String
    var latitude: Double
    var longitude: Double
    var imageURL: String?
    var price: Double
    var isFavorite: Bool
    var organizerIdentifier: String
    var organizerName: String
    var organizerEmail: String
    var mediaItems: [MediaItemEntity]

    init(
        jsonId: String,
        title: String,
        eventDescription: String,
        date: Date,
        endDate: Date?,
        categoryIdentifier: String,
        location: String,
        address: String,
        latitude: Double,
        longitude: Double,
        imageURL: String?,
        price: Double,
        isFavorite: Bool,
        organizerIdentifier: String,
        organizerName: String,
        organizerEmail: String,
        mediaItems: [MediaItemEntity] = []
    ) {
        self.jsonId = jsonId
        self.title = title
        self.eventDescription = eventDescription
        self.date = date
        self.endDate = endDate
        self.categoryIdentifier = categoryIdentifier
        self.location = location
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.imageURL = imageURL
        self.price = price
        self.isFavorite = isFavorite
        self.organizerIdentifier = organizerIdentifier
        self.organizerName = organizerName
        self.organizerEmail = organizerEmail
        self.mediaItems = mediaItems
    }

    func toDomain() -> Event {
        Event(
            jsonId: jsonId,
            title: title,
            description: eventDescription,
            date: date,
            endDate: endDate,
            category: EventCategory.fromStorageIdentifier(categoryIdentifier),
            location: location,
            address: address,
            latitude: latitude,
            longitude: longitude,
            imageURL: imageURL,
            multimedia: mediaItems.map { $0.toDomain() },
            price: price,
            isPast: AppConfiguration.isPastDate(date),
            isFavorite: isFavorite,
            organizadorNombre: organizerName,
            organizadorEmail: organizerEmail
        )
    }
}

@Model
final class MediaItemEntity {
    var id: UUID
    var typeRawValue: String
    var url: String

    init(id: UUID = UUID(), typeRawValue: String, url: String) {
        self.id = id
        self.typeRawValue = typeRawValue
        self.url = url
    }

    func toDomain() -> MediaItem {
        MediaItem(
            id: id,
            type: MediaType(rawValue: typeRawValue) ?? .image,
            url: url
        )
    }
}
