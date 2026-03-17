import Foundation
import Combine

/// Gestor de favoritos que persiste los IDs de eventos favoritos
///
/// **Cómo usar:**
/// ```swift
/// // Marcar/desmarcar favorito
/// FavoritesManager.shared.toggleFavorite(eventId: "evt_001")
///
/// // Verificar si es favorito
/// if FavoritesManager.shared.isFavorite(eventId: "evt_001") {
///     print("Es favorito")
/// }
///
/// // Observar cambios (en ViewModels con Combine)
/// FavoritesManager.shared.$favoriteIds
///     .sink { ids in ... }
///     .store(in: &cancellables)
/// ```
///
/// Los favoritos se guardan automáticamente en SwiftData y persisten entre sesiones de la app.
/// Notificaciones se programan/cancelan automáticamente via NotificationManager.
@MainActor
final class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    
    private let eventDataService = EventDataService.shared
    
    /// Published set of favorite event IDs - ViewModels can observe this via Combine
    @Published private(set) var favoriteIds: Set<String> = []
    
    private init() {
        refreshFavoriteIds()
    }
    
    // MARK: - Event Lookup Helper
    
    /// Get event by ID for notification scheduling
    private func getEvent(by eventId: String) -> Event? {
        eventDataService.event(by: eventId)
    }
    
    // MARK: - Public Methods
    
    /// Verifica si un evento está marcado como favorito
    func isFavorite(eventId: String) -> Bool {
        favoriteIds.contains(eventId)
    }
    
    /// Alterna el estado de favorito de un evento (marcar/desmarcar)
    @discardableResult
    func toggleFavorite(eventId: String) -> Bool {
        let isFavorite = eventDataService.toggleFavorite(eventId: eventId)
        refreshFavoriteIds()

        if isFavorite {
            if let event = getEvent(by: eventId) {
                NotificationManager.shared.onFavoriteAdded(event)
            }
        } else {
            // Cancel notification for removed favorite
            NotificationManager.shared.onFavoriteRemoved(eventId: eventId)
        }

        return isFavorite
    }
    
    /// Agrega un evento a favoritos
    func addFavorite(eventId: String) {
        guard !favoriteIds.contains(eventId) else { return }
        eventDataService.addFavorite(eventId: eventId)
        refreshFavoriteIds()
        // Schedule notification for new favorite
        if let event = getEvent(by: eventId) {
            NotificationManager.shared.onFavoriteAdded(event)
        }
    }
    
    /// Remueve un evento de favoritos
    func removeFavorite(eventId: String) {
        guard favoriteIds.contains(eventId) else { return }
        eventDataService.removeFavorite(eventId: eventId)
        refreshFavoriteIds()
        // Cancel notification for removed favorite
        NotificationManager.shared.onFavoriteRemoved(eventId: eventId)
    }
    
    /// Limpia todos los favoritos
    func clearAllFavorites() {
        eventDataService.clearAllFavorites()
        refreshFavoriteIds()
        // Cancel all notifications when clearing favorites
        NotificationManager.shared.cancelAllNotifications()
    }
    
    /// Obtiene todos los IDs de eventos marcados como favoritos
    func getFavorites() -> [String] {
        Array(favoriteIds)
    }
    
    // MARK: - Private Methods

    private func refreshFavoriteIds() {
        favoriteIds = Set(eventDataService.favoriteEventIds())
    }
}

