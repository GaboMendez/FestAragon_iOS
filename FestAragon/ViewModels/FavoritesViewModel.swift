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
    
    private func syncFavorites(with favoriteIds: Set<String>) {
        let allEvents = eventDataService.loadEventsFromJSON()
        
        let favorites = allEvents.filter { event in
            favoriteIds.contains(event.jsonId)
        }.map { event in
            var updatedEvent = event
            updatedEvent.isFavorite = true
            return updatedEvent
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
            scheduleNotificationsForFavorites()
        } else {
            cancelAllNotifications()
        }
    }
    
    func setNoticeTime(_ minutes: Int) {
        guard minutes > 0 else { return }
        noticeTimeMinutes = minutes
        userDefaults.set(minutes, forKey: noticeTimeMinutesKey)
        
        if notificationsEnabled {
            scheduleNotificationsForFavorites()
        }
    }
    
    func clearAllFavorites() {
        favoritesManager.clearAllFavorites()
        favoriteEvents = []
    }
    
    // MARK: - Private Methods
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    private func scheduleNotificationsForFavorites() {
        cancelAllNotifications()
        
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            
            if settings.authorizationStatus == .notDetermined {
                self.requestNotificationPermissions()
            }
            
            for event in self.favoriteEvents {
                self.scheduleNotificationForEvent(event)
            }
        }
    }
    
    private func scheduleNotificationForEvent(_ event: Event) {
        let notificationTime = event.date.addingTimeInterval(-Double(noticeTimeMinutes * 60))
        
        guard notificationTime > Date() else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Próximo evento"
        content.body = "En \(noticeTimeMinutes) minutos comienza: \(event.title)"
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        content.userInfo = [
            "eventId": event.jsonId,
            "eventTitle": event.title,
            "eventLocation": event.location,
            "eventTime": event.date.timeIntervalSince1970
        ]
        
        let timeInterval = notificationTime.timeIntervalSinceNow
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(timeInterval, 1), repeats: false)
        
        let requestId = "notification_\(event.jsonId)_\(noticeTimeMinutes)"
        let request = UNNotificationRequest(identifier: requestId, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

