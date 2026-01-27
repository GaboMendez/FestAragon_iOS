import Foundation
import UserNotifications
import SwiftUI
import Combine

@MainActor
class FavoritesViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var favoriteEvents: [Event] = []
    @Published var notificationsEnabled: Bool = false
    @Published var noticeTimeMinutes: Int = 15
    @Published var isLoading: Bool = false
    
    // MARK: - Private Properties
    private let favoritesManager = FavoritesManager.shared
    private let eventDataService = EventDataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - User Defaults
    private let userDefaults = UserDefaults.standard
    private let notificationsEnabledKey = "favorites_notifications_enabled"
    private let noticeTimeMinutesKey = "favorites_notice_time_minutes"
    
    // MARK: - Init
    init() {
        // Load notification settings
        notificationsEnabled = userDefaults.bool(forKey: notificationsEnabledKey)
        noticeTimeMinutes = userDefaults.integer(forKey: noticeTimeMinutesKey) > 0 ? 
            userDefaults.integer(forKey: noticeTimeMinutesKey) : 15
        
        // Request notification permissions if enabled
        if notificationsEnabled {
            requestNotificationPermissions()
        }

        // Load favorites
        loadFavorites()
        
        // Observe favorites changes via Combine
        setupFavoritesObserver()
        
        // Observe changes in noticeTimeMinutes from other screens (like Profile)
        setupNoticeTimeObserver()
    }
    
    // MARK: - Private Methods
    
    private func setupFavoritesObserver() {
        favoritesManager.$favoriteIds
            .dropFirst() // Skip initial value since we already loaded
            .receive(on: DispatchQueue.main)
            .sink { [weak self] favoriteIds in
                self?.syncFavorites(with: favoriteIds)
            }
            .store(in: &cancellables)
    }
    
    private func setupNoticeTimeObserver() {
        // Observar cambios en UserDefaults para sincronizar entre pantallas
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                let newValue = self.userDefaults.integer(forKey: self.noticeTimeMinutesKey)
                if newValue > 0 && newValue != self.noticeTimeMinutes {
                    self.noticeTimeMinutes = newValue
                    // Si las notificaciones están activas, reprogramar
                    if self.notificationsEnabled {
                        self.scheduleNotificationsForFavorites()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func syncFavorites(with favoriteIds: Set<String>) {
        // Use eventsWithFavorites to get fresh favorite status
        let allEvents = eventDataService.eventsWithFavorites
        
        let favorites = allEvents.filter { event in
            favoriteIds.contains(event.jsonId)
        }
        
        favoriteEvents = favorites.sorted { $0.date < $1.date }
        
        // Reschedule notifications if enabled
        if notificationsEnabled {
            scheduleNotificationsForFavorites()
        }
    }
    
    // MARK: - Public Methods
    
    func loadFavorites() {
        isLoading = true
        syncFavorites(with: favoritesManager.favoriteIds)
        isLoading = false
    }
    
    func removeFavorite(_ event: Event) {
        favoritesManager.removeFavorite(eventId: event.jsonId)
    }
    
    func setNotificationsEnabled(_ enabled: Bool) {
        notificationsEnabled = enabled
        userDefaults.set(enabled, forKey: notificationsEnabledKey)
        
        if enabled {
            // Solicitar permisos y programar notificaciones
            Task {
                let granted = await NotificationManager.shared.requestAuthorization()
                if granted {
                    NotificationManager.shared.rescheduleAllFavoriteNotifications(minutesBefore: noticeTimeMinutes)
                } else {
                    // Si se deniegan los permisos, desactivar el toggle
                    await MainActor.run {
                        self.notificationsEnabled = false
                        self.userDefaults.set(false, forKey: self.notificationsEnabledKey)
                    }
                }
            }
        } else {
            NotificationManager.shared.cancelAllNotifications()
        }
    }
    
    func setNoticeTime(_ minutes: Int) {
        guard minutes > 0 else { return }
        noticeTimeMinutes = minutes
        userDefaults.set(minutes, forKey: noticeTimeMinutesKey)
        
        // Guardar también en la clave global para que otras pantallas lo usen
        userDefaults.set(minutes, forKey: "noticeTimeMinutes")
        
        if notificationsEnabled {
            // Reprogramar todas las notificaciones con el nuevo tiempo
            NotificationManager.shared.rescheduleAllFavoriteNotifications(minutesBefore: minutes)
        }
    }
    
    func clearAllFavorites() {
        favoritesManager.clearAllFavorites()
        favoriteEvents = []
        // Cancelar todas las notificaciones al limpiar favoritos
        if notificationsEnabled {
            NotificationManager.shared.cancelAllNotifications()
        }
    }
    
    // MARK: - Private Notification Methods
    
    private func requestNotificationPermissions() {
        Task {
            await NotificationManager.shared.requestAuthorization()
        }
    }
    
    private func scheduleNotificationsForFavorites() {
        NotificationManager.shared.rescheduleAllFavoriteNotifications(minutesBefore: noticeTimeMinutes)
    }
}

