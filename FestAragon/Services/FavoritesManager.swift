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
/// Los favoritos se guardan automáticamente en UserDefaults y persisten entre sesiones de la app.
/// Notificaciones se programan/cancelan automáticamente via NotificationSettingsManager.
class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    
    private let favoritesKey = "user_favorites"
    private let userDefaults = UserDefaults.standard
    
    /// Published set of favorite event IDs - ViewModels can observe this via Combine
    @Published private(set) var favoriteIds: Set<String> = []
    
    private init() {
        // Load favorites from UserDefaults on init
        let saved = userDefaults.stringArray(forKey: favoritesKey) ?? []
        favoriteIds = Set(saved)
    }
    
    // MARK: - Event Lookup Helper
    
    /// Get event by ID for notification scheduling
    private func getEvent(by eventId: String) -> Event? {
        let allEvents = EventDataService.shared.loadEventsFromJSON()
        return allEvents.first { $0.jsonId == eventId }
    }
    
    // MARK: - Public Methods
    
    /// Verifica si un evento está marcado como favorito
    func isFavorite(eventId: String) -> Bool {
        favoriteIds.contains(eventId)
    }
    
    /// Alterna el estado de favorito de un evento (marcar/desmarcar)
    @discardableResult
    func toggleFavorite(eventId: String) -> Bool {
        if favoriteIds.contains(eventId) {
            favoriteIds.remove(eventId)
            saveFavorites()
            // Cancel notification for removed favorite
            Task { @MainActor in
                NotificationSettingsManager.shared.onFavoriteRemoved(eventId: eventId)
            }
            return false
        } else {
            favoriteIds.insert(eventId)
            saveFavorites()
            // Schedule notification for new favorite
            if let event = getEvent(by: eventId) {
                Task { @MainActor in
                    NotificationSettingsManager.shared.onFavoriteAdded(event)
                }
            }
            return true
        }
    }
    
    /// Agrega un evento a favoritos
    func addFavorite(eventId: String) {
        guard !favoriteIds.contains(eventId) else { return }
        favoriteIds.insert(eventId)
        saveFavorites()
        // Schedule notification for new favorite
        if let event = getEvent(by: eventId) {
            Task { @MainActor in
                NotificationSettingsManager.shared.onFavoriteAdded(event)
            }
        }
    }
    
    /// Remueve un evento de favoritos
    func removeFavorite(eventId: String) {
        favoriteIds.remove(eventId)
        saveFavorites()
        // Cancel notification for removed favorite
        Task { @MainActor in
            NotificationSettingsManager.shared.onFavoriteRemoved(eventId: eventId)
        }
    }
    
    /// Limpia todos los favoritos
    func clearAllFavorites() {
        favoriteIds.removeAll()
        userDefaults.removeObject(forKey: favoritesKey)
        // Cancel all notifications when clearing favorites
        NotificationManager.shared.cancelAllNotifications()
    }
    
    /// Obtiene todos los IDs de eventos marcados como favoritos
    func getFavorites() -> [String] {
        Array(favoriteIds)
    }
    
    // MARK: - Private Methods
    
    private func saveFavorites() {
        userDefaults.set(Array(favoriteIds), forKey: favoritesKey)
    }
}

