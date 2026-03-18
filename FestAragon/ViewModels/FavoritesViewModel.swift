import Foundation
import UserNotifications
import SwiftUI
import Combine

@MainActor
class FavoritesViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var favoriteEvents: [Event] = []
    @Published var isLoading: Bool = false
    
    // MARK: - Notification Settings (observed from centralized manager)
    @Published var notificationsEnabled: Bool = false
    @Published var noticeTimeMinutes: Int = 15
    
    // MARK: - Private Properties
    private let favoritesManager = FavoritesManager.shared
    private let eventDataService = EventDataService.shared
    private let notificationSettings = NotificationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    init() {
        // Sync initial state from centralized settings
        notificationsEnabled = notificationSettings.isEnabled
        noticeTimeMinutes = notificationSettings.noticeTimeMinutes

        // Load favorites
        loadFavorites()
        
        // Observe favorites changes via Combine
        setupFavoritesObserver()
        
        // Observe notification settings changes from centralized manager
        setupNotificationSettingsObserver()

        // Observe admin changes
        setupAdminChangeObserver()
    }
    
    // MARK: - Private Methods
    
    private func setupAdminChangeObserver() {
        NotificationCenter.default.publisher(for: .adminEventDataChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadFavorites()
            }
            .store(in: &cancellables)
    }

    private func setupFavoritesObserver() {
        favoritesManager.$favoriteIds
            .dropFirst() // Skip initial value since we already loaded
            .receive(on: DispatchQueue.main)
            .sink { [weak self] favoriteIds in
                self?.syncFavorites(with: favoriteIds)
            }
            .store(in: &cancellables)
    }
    
    private func setupNotificationSettingsObserver() {
        // Observe isEnabled changes from centralized manager
        notificationSettings.$isEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.notificationsEnabled = enabled
            }
            .store(in: &cancellables)
        
        // Observe noticeTimeMinutes changes from centralized manager
        notificationSettings.$noticeTimeMinutes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] minutes in
                self?.noticeTimeMinutes = minutes
            }
            .store(in: &cancellables)
    }
    
    private func syncFavorites(with favoriteIds: Set<String>) {
        // Use eventsWithFavorites to get fresh favorite status
        let allEvents = eventDataService.eventsWithFavorites
        
        let favorites = allEvents.filter { event in
            favoriteIds.contains(event.jsonId)
        }
        
        // Sort from most recent to oldest
        favoriteEvents = favorites.sorted { $0.date > $1.date }
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
    
    /// Toggle notifications enabled state (delegates to centralized manager)
    func setNotificationsEnabled(_ enabled: Bool) {
        Task {
            let success = await notificationSettings.setNotificationsEnabled(enabled)
            if !success && enabled {
                // Permission was denied, the centralized manager already updated state
                // UI will update via the observer
            }
        }
    }
    
    /// Set notice time in minutes (delegates to centralized manager)
    func setNoticeTime(_ minutes: Int) {
        notificationSettings.setNoticeTime(minutes)
    }
    
    func clearAllFavorites() {
        favoritesManager.clearAllFavorites()
        favoriteEvents = []
    }
}

