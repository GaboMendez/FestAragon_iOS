import Foundation
import SwiftData

enum AdminError: LocalizedError {
    case eventNotFound
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .eventNotFound:
            return "No se encontró el evento"
        case .deleteFailed(let reason):
            return "Error al eliminar: \(reason)"
        }
    }
}

@MainActor
final class EventDataService {
    static let shared = EventDataService()

    let modelContainer: ModelContainer

    private var modelContext: ModelContext {
        modelContainer.mainContext
    }

    private init() {
        do {
            let storeURL = URL.applicationSupportDirectory.appending(path: "fest_aragon.store")
            let configuration = ModelConfiguration(url: storeURL)

            modelContainer = try ModelContainer(
                for:
                TownEntity.self,
                CategoryEntity.self,
                OrganizerEntity.self,
                EventEntity.self,
                MediaItemEntity.self,
                configurations: configuration
            )
            seedIfNeeded()
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
    }

    // MARK: - Public Methods

    /// Loads events from SwiftData.
    func loadEvents() -> [Event] {
        fetchEventEntities().map { $0.toDomain() }
    }

    /// Backward-compatible wrapper. Data now comes from SwiftData, not JSON.
    func loadEventsFromJSON() -> [Event] {
        loadEvents()
    }

    /// Syncs bundled seed JSON into SwiftData, preserving persisted favorites.
    func reloadEvents() {
        // No longer re-imports from JSON to preserve admin changes.
        // Data is already in SwiftData; just trigger a re-read via loadEvents().
    }

    // MARK: - Seed Control

    private static let seedImportedKey = "seed_data_imported"

    /// Import seed data only once. Subsequent launches preserve admin changes.
    private func seedIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Self.seedImportedKey) else { return }
        syncSeedDataFromBundle()
        UserDefaults.standard.set(true, forKey: Self.seedImportedKey)
    }

    /// Force re-import seed data (overwrites all admin changes — use with caution).
    func forceReseed() {
        syncSeedDataFromBundle()
    }

    /// Gets events with current persisted favorite status.
    var eventsWithFavorites: [Event] {
        loadEvents()
    }

    func event(by eventId: String) -> Event? {
        fetchEventEntity(by: eventId)?.toDomain()
    }

    func favoriteEventIds() -> [String] {
        fetchEventEntities()
            .filter(\.isFavorite)
            .map(\.jsonId)
    }

    @discardableResult
    func toggleFavorite(eventId: String) -> Bool {
        guard let entity = fetchEventEntity(by: eventId) else { return false }
        entity.isFavorite.toggle()
        saveContext()
        return entity.isFavorite
    }

    func addFavorite(eventId: String) {
        guard let entity = fetchEventEntity(by: eventId) else { return }
        guard !entity.isFavorite else { return }
        entity.isFavorite = true
        saveContext()
    }

    func removeFavorite(eventId: String) {
        guard let entity = fetchEventEntity(by: eventId) else { return }
        guard entity.isFavorite else { return }
        entity.isFavorite = false
        saveContext()
    }

    func clearAllFavorites() {
        let favorites = fetchEventEntities().filter(\.isFavorite)
        for event in favorites {
            event.isFavorite = false
        }
        saveContext()
    }

    // MARK: - Admin CRUD Methods

    @discardableResult
    func createEvent(
        title: String,
        description: String,
        date: Date,
        endDate: Date?,
        categoryIdentifier: String,
        location: String,
        address: String,
        latitude: Double,
        longitude: Double,
        imageURL: String?,
        price: Double,
        organizerName: String,
        organizerEmail: String
    ) -> String {
        let newId = UUID().uuidString
        let entity = EventEntity(
            jsonId: newId,
            title: title,
            eventDescription: description,
            date: date,
            endDate: endDate,
            categoryIdentifier: categoryIdentifier,
            location: location,
            address: address,
            latitude: latitude,
            longitude: longitude,
            imageURL: imageURL,
            price: price,
            isFavorite: false,
            organizerIdentifier: newId,
            organizerName: organizerName,
            organizerEmail: organizerEmail
        )
        modelContext.insert(entity)
        saveContext()
        return newId
    }

    func updateEvent(
        jsonId: String,
        title: String,
        description: String,
        date: Date,
        endDate: Date?,
        categoryIdentifier: String,
        location: String,
        address: String,
        latitude: Double,
        longitude: Double,
        imageURL: String?,
        price: Double,
        organizerName: String,
        organizerEmail: String
    ) throws {
        guard let entity = fetchEventEntity(by: jsonId) else {
            throw AdminError.eventNotFound
        }
        entity.title = title
        entity.eventDescription = description
        entity.date = date
        entity.endDate = endDate
        entity.categoryIdentifier = categoryIdentifier
        entity.location = location
        entity.address = address
        entity.latitude = latitude
        entity.longitude = longitude
        entity.imageURL = imageURL
        entity.price = price
        entity.organizerName = organizerName
        entity.organizerEmail = organizerEmail
        saveContext()
    }

    func deleteEvent(jsonId: String) throws {
        guard let entity = fetchEventEntity(by: jsonId) else {
            throw AdminError.eventNotFound
        }
        let wasFavorite = entity.isFavorite
        // Cascade: delete media items first
        for item in entity.mediaItems {
            modelContext.delete(item)
        }
        modelContext.delete(entity)
        saveContext()

        if wasFavorite {
            NotificationManager.shared.cancelNotification(for: jsonId)
        }
    }

    func deleteEventsByLocation(_ location: String) throws -> Int {
        let predicate = #Predicate<EventEntity> { entity in
            entity.location == location
        }
        let descriptor = FetchDescriptor<EventEntity>(predicate: predicate)

        let entities: [EventEntity]
        do {
            entities = try modelContext.fetch(descriptor)
        } catch {
            throw AdminError.deleteFailed(error.localizedDescription)
        }

        guard !entities.isEmpty else { return 0 }

        let count = entities.count
        for entity in entities {
            if entity.isFavorite {
                NotificationManager.shared.cancelNotification(for: entity.jsonId)
            }
            // Cascade: delete media items first
            for item in entity.mediaItems {
                modelContext.delete(item)
            }
            modelContext.delete(entity)
        }
        saveContext()
        return count
    }

    func allLocations() -> [(name: String, count: Int)] {
        let entities = fetchEventEntities()
        var locationCounts: [String: Int] = [:]
        for entity in entities {
            locationCounts[entity.location, default: 0] += 1
        }
        return locationCounts
            .map { (name: $0.key, count: $0.value) }
            .sorted { $0.name < $1.name }
    }

    // MARK: - Private Methods

    private func fetchEventEntities() -> [EventEntity] {
        let descriptor = FetchDescriptor<EventEntity>(
            sortBy: [SortDescriptor(\EventEntity.date, order: .forward)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("❌ Error fetching events from SwiftData: \(error)")
            return []
        }
    }

    private func fetchEventEntity(by eventId: String) -> EventEntity? {
        let predicate = #Predicate<EventEntity> { entity in
            entity.jsonId == eventId
        }
        let descriptor = FetchDescriptor<EventEntity>(predicate: predicate)

        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("❌ Error fetching event \(eventId): \(error)")
            return nil
        }
    }

    private func syncSeedDataFromBundle() {
        guard let response = loadSeedResponse() else { return }

        upsertTown(response.pueblo)

        let categoriesById = upsertCategories(response.categorias)
        let organizersById = upsertOrganizers(response.organizadores)
        upsertEvents(response.eventos, categoriesById: categoriesById, organizersById: organizersById)

        saveContext()
    }

    private func loadSeedResponse() -> EventResponse? {
        guard let url = Bundle.main.url(forResource: "eventos", withExtension: "json") else {
            print("❌ No se encontró el archivo eventos.json")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(EventResponse.self, from: data)
        } catch {
            print("❌ Error al cargar seed JSON: \(error)")
            return nil
        }
    }

    private func upsertTown(_ pueblo: Pueblo) {
        let descriptor = FetchDescriptor<TownEntity>()
        let entity = (try? modelContext.fetch(descriptor).first) ?? TownEntity(
            name: pueblo.nombre,
            province: pueblo.provincia,
            region: pueblo.comunidad,
            latitude: pueblo.coordenadas.lat,
            longitude: pueblo.coordenadas.lng,
            festivalStart: pueblo.fechasFiestas.inicio,
            festivalEnd: pueblo.fechasFiestas.fin
        )

        entity.name = pueblo.nombre
        entity.province = pueblo.provincia
        entity.region = pueblo.comunidad
        entity.latitude = pueblo.coordenadas.lat
        entity.longitude = pueblo.coordenadas.lng
        entity.festivalStart = pueblo.fechasFiestas.inicio
        entity.festivalEnd = pueblo.fechasFiestas.fin

        if entity.modelContext == nil {
            modelContext.insert(entity)
        }
    }

    private func upsertCategories(_ categories: [Categoria]) -> [String: CategoryEntity] {
        let existing = fetchDictionary(for: FetchDescriptor<CategoryEntity>(), keyPath: \.identifier)
        let incomingIds = Set(categories.map(\.id))

        for category in categories {
            let entity = existing[category.id] ?? CategoryEntity(
                identifier: category.id,
                name: category.nombre,
                iconName: category.icono
            )

            entity.name = category.nombre
            entity.iconName = category.icono

            if entity.modelContext == nil {
                modelContext.insert(entity)
            }
        }

        deleteStaleEntities(existing.values.filter { !incomingIds.contains($0.identifier) })
        return fetchDictionary(for: FetchDescriptor<CategoryEntity>(), keyPath: \.identifier)
    }

    private func upsertOrganizers(_ organizers: [Organizador]) -> [String: OrganizerEntity] {
        let existing = fetchDictionary(for: FetchDescriptor<OrganizerEntity>(), keyPath: \.identifier)
        let incomingIds = Set(organizers.map(\.id))

        for organizer in organizers {
            let entity = existing[organizer.id] ?? OrganizerEntity(
                identifier: organizer.id,
                name: organizer.nombre,
                contact: organizer.contacto
            )

            entity.name = organizer.nombre
            entity.contact = organizer.contacto

            if entity.modelContext == nil {
                modelContext.insert(entity)
            }
        }

        deleteStaleEntities(existing.values.filter { !incomingIds.contains($0.identifier) })
        return fetchDictionary(for: FetchDescriptor<OrganizerEntity>(), keyPath: \.identifier)
    }

    private func upsertEvents(
        _ events: [EventoJSON],
        categoriesById: [String: CategoryEntity],
        organizersById: [String: OrganizerEntity]
    ) {
        let existing = fetchDictionary(for: FetchDescriptor<EventEntity>(), keyPath: \.jsonId)
        let incomingIds = Set(events.map(\.id))

        for event in events {
            guard let startDate = event.parsedStartDate else { continue }
            let entity = existing[event.id] ?? EventEntity(
                jsonId: event.id,
                title: event.titulo,
                eventDescription: event.descripcion,
                date: startDate,
                endDate: event.parsedEndDate,
                categoryIdentifier: event.categoriaId,
                location: event.lugar.nombre,
                address: event.lugar.direccion,
                latitude: event.lugar.coordenadas.lat,
                longitude: event.lugar.coordenadas.lng,
                imageURL: nil,
                price: 0.0,
                isFavorite: false,
                organizerIdentifier: event.organizadorId,
                organizerName: organizersById[event.organizadorId]?.name ?? "Organizador",
                organizerEmail: organizersById[event.organizadorId]?.contact ?? ""
            )

            entity.title = event.titulo
            entity.eventDescription = event.descripcion
            entity.date = startDate
            entity.endDate = event.parsedEndDate
            entity.categoryIdentifier = categoriesById[event.categoriaId]?.identifier ?? event.eventCategory.storageIdentifier
            entity.location = event.lugar.nombre
            entity.address = event.lugar.direccion
            entity.latitude = event.lugar.coordenadas.lat
            entity.longitude = event.lugar.coordenadas.lng
            entity.organizerIdentifier = event.organizadorId
            entity.organizerName = organizersById[event.organizadorId]?.name ?? "Organizador"
            entity.organizerEmail = organizersById[event.organizadorId]?.contact ?? ""
            replaceMediaItems(for: entity, with: event.multimedia)

            if entity.modelContext == nil {
                modelContext.insert(entity)
            }
        }

        deleteStaleEntities(existing.values.filter { !incomingIds.contains($0.jsonId) })
    }

    private func replaceMediaItems(for event: EventEntity, with mediaItems: [Multimedia]) {
        for item in event.mediaItems {
            modelContext.delete(item)
        }

        event.mediaItems.removeAll()
        event.mediaItems = mediaItems.map { media in
            let entity = MediaItemEntity(typeRawValue: media.tipo, url: media.recurso)
            modelContext.insert(entity)
            return entity
        }
        event.imageURL = mediaItems.first(where: { MediaType(rawValue: $0.tipo) == .image })?.recurso ?? mediaItems.first?.recurso
    }

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("❌ Error saving SwiftData context: \(error)")
        }
    }

    private func fetchDictionary<T: PersistentModel>(
        for descriptor: FetchDescriptor<T>,
        keyPath: KeyPath<T, String>
    ) -> [String: T] {
        do {
            let models = try modelContext.fetch(descriptor)
            return Dictionary(uniqueKeysWithValues: models.map { ($0[keyPath: keyPath], $0) })
        } catch {
            print("❌ Error fetching SwiftData models: \(error)")
            return [:]
        }
    }

    private func deleteStaleEntities<T: PersistentModel>(_ entities: [T]) {
        for entity in entities {
            modelContext.delete(entity)
        }
    }
}
