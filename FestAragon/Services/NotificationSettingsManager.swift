//
//  NotificationSettingsManager.swift
//  FestAragon
//
//  Single source of truth for notification settings across the app.
//  All ViewModels should observe this manager for notification state.
//

import Foundation
import Combine
import UserNotifications

/// Centralized manager for notification settings
/// Provides reactive state that syncs across Profile, Favorites, and Event views
///
/// **Usage:**
/// ```swift
/// // Observe settings changes
/// NotificationSettingsManager.shared.$isEnabled
///     .sink { enabled in ... }
///     .store(in: &cancellables)
///
/// // Update settings (will auto-sync everywhere)
/// await NotificationSettingsManager.shared.setNotificationsEnabled(true)
/// NotificationSettingsManager.shared.setNoticeTime(30)
/// ```
@MainActor
final class NotificationSettingsManager: ObservableObject {
    static let shared = NotificationSettingsManager()
    
    // MARK: - Published Properties (Reactive State)
    
    /// Whether event reminders are enabled
    @Published private(set) var isEnabled: Bool = false
    
    /// Minutes before event to send notification
    @Published private(set) var noticeTimeMinutes: Int = 15
    
    /// Current authorization status from system
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    // MARK: - UserDefaults Keys (Single Source)
    
    private enum Keys {
        static let notificationsEnabled = "notification_settings_enabled"
        static let noticeTimeMinutes = "notification_settings_notice_time"
    }
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Init
    
    private init() {
        loadSettings()
        Task {
            await refreshAuthorizationStatus()
        }
    }
    
    // MARK: - Public Methods
    
    /// Enable or disable notifications
    /// - Parameter enabled: Whether to enable notifications
    /// - Returns: True if successfully enabled (with permissions granted)
    @discardableResult
    func setNotificationsEnabled(_ enabled: Bool) async -> Bool {
        if enabled {
            // Request authorization if enabling
            let granted = await requestAuthorization()
            
            if granted {
                isEnabled = true
                userDefaults.set(true, forKey: Keys.notificationsEnabled)
                rescheduleAllFavoriteNotifications()
                return true
            } else {
                // Permission denied - keep disabled
                isEnabled = false
                userDefaults.set(false, forKey: Keys.notificationsEnabled)
                return false
            }
        } else {
            // Disabling
            isEnabled = false
            userDefaults.set(false, forKey: Keys.notificationsEnabled)
            NotificationManager.shared.cancelAllNotifications()
            return true
        }
    }
    
    /// Set the notice time (minutes before event)
    /// - Parameter minutes: Minutes before event to notify (must be > 0)
    func setNoticeTime(_ minutes: Int) {
        guard minutes > 0 else { return }
        
        noticeTimeMinutes = minutes
        userDefaults.set(minutes, forKey: Keys.noticeTimeMinutes)
        
        // Reschedule notifications if enabled
        if isEnabled {
            rescheduleAllFavoriteNotifications()
        }
    }
    
    /// Request notification authorization
    /// - Returns: True if permission granted
    func requestAuthorization() async -> Bool {
        let granted = await NotificationManager.shared.requestAuthorization()
        await refreshAuthorizationStatus()
        return granted
    }
    
    /// Refresh the current authorization status from the system
    func refreshAuthorizationStatus() async {
        authorizationStatus = await NotificationManager.shared.checkAuthorizationStatus()
        
        // If authorization was revoked externally, update enabled state
        if authorizationStatus == .denied && isEnabled {
            isEnabled = false
            userDefaults.set(false, forKey: Keys.notificationsEnabled)
        }
    }
    
    /// Schedule notification for a specific event (when user taps reminder button)
    /// - Parameter event: The event to schedule a reminder for
    /// - Returns: True if scheduled successfully
    @discardableResult
    func scheduleReminderForEvent(_ event: Event) async -> Bool {
        // Check/request authorization
        let status = await NotificationManager.shared.checkAuthorizationStatus()
        
        switch status {
        case .notDetermined:
            let granted = await requestAuthorization()
            guard granted else { return false }
            
        case .denied:
            return false
            
        case .authorized, .provisional, .ephemeral:
            break
            
        @unknown default:
            break
        }
        
        // Schedule the notification
        NotificationManager.shared.scheduleEventNotification(
            event: event,
            minutesBefore: noticeTimeMinutes
        )
        
        return true
    }
    
    /// Reschedule all favorite notifications (called when settings change)
    func rescheduleAllFavoriteNotifications() {
        guard isEnabled else { return }
        NotificationManager.shared.rescheduleAllFavoriteNotifications(minutesBefore: noticeTimeMinutes)
    }
    
    /// Called when a favorite is added - schedules notification if enabled
    func onFavoriteAdded(_ event: Event) {
        guard isEnabled else { return }
        NotificationManager.shared.scheduleEventNotification(
            event: event,
            minutesBefore: noticeTimeMinutes
        )
    }
    
    /// Called when a favorite is removed - cancels its notification
    func onFavoriteRemoved(eventId: String) {
        NotificationManager.shared.cancelNotification(for: eventId)
    }
    
    // MARK: - Formatted Display
    
    /// Human-readable notice time
    var noticeTimeFormatted: String {
        if noticeTimeMinutes >= 1440 {
            let days = noticeTimeMinutes / 1440
            return "\(days) día\(days > 1 ? "s" : "")"
        } else if noticeTimeMinutes >= 60 {
            let hours = noticeTimeMinutes / 60
            return "\(hours) hora\(hours > 1 ? "s" : "")"
        } else {
            return "\(noticeTimeMinutes) min"
        }
    }
    
    // MARK: - Private Methods
    
    private func loadSettings() {
        isEnabled = userDefaults.bool(forKey: Keys.notificationsEnabled)
        
        let savedTime = userDefaults.integer(forKey: Keys.noticeTimeMinutes)
        noticeTimeMinutes = savedTime > 0 ? savedTime : 15
    }
}
