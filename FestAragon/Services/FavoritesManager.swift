import Foundation

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
/// // Obtener todos los IDs favoritos
/// let favoriteIds = FavoritesManager.shared.getFavorites()
/// ```
///
/// Los favoritos se guardan automáticamente en UserDefaults y persisten entre sesiones de la app.
class FavoritesManager {
    static let shared = FavoritesManager()
    
    private let favoritesKey = "user_favorites"
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Obtiene todos los IDs de eventos marcados como favoritos
    /// - Returns: Array de IDs de eventos favoritos
    func getFavorites() -> [String] {
        return userDefaults.stringArray(forKey: favoritesKey) ?? []
    }
    
    /// Verifica si un evento está marcado como favorito
    /// - Parameter eventId: ID del evento a verificar
    /// - Returns: true si está en favoritos, false si no
    func isFavorite(eventId: String) -> Bool {
        let favorites = getFavorites()
        return favorites.contains(eventId)
    }
    
    /// Alterna el estado de favorito de un evento (marcar/desmarcar)
    /// - Parameter eventId: ID del evento
    /// - Returns: true si ahora es favorito, false si se removió
    @discardableResult
    func toggleFavorite(eventId: String) -> Bool {
        var favorites = getFavorites()
        
        if let index = favorites.firstIndex(of: eventId) {
            // Ya es favorito, lo removemos
            favorites.remove(at: index)
            saveFavorites(favorites)
            return false
        } else {
            // No es favorito, lo agregamos
            favorites.append(eventId)
            saveFavorites(favorites)
            return true
        }
    }
    
    /// Agrega un evento a favoritos
    /// - Parameter eventId: ID del evento a agregar
    func addFavorite(eventId: String) {
        var favorites = getFavorites()
        guard !favorites.contains(eventId) else { return }
        favorites.append(eventId)
        saveFavorites(favorites)
    }
    
    /// Remueve un evento de favoritos
    /// - Parameter eventId: ID del evento a remover
    func removeFavorite(eventId: String) {
        var favorites = getFavorites()
        favorites.removeAll { $0 == eventId }
        saveFavorites(favorites)
    }
    
    /// Limpia todos los favoritos
    func clearAllFavorites() {
        userDefaults.removeObject(forKey: favoritesKey)
    }
    
    // MARK: - Private Methods
    
    private func saveFavorites(_ favorites: [String]) {
        userDefaults.set(favorites, forKey: favoritesKey)
    }
}
