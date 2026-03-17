//
//  NotificationManager.swift
//  FestAragon
//
//  Unified notification manager — single source of truth for
//  both notification scheduling and notification settings.
//

import Foundation
import UserNotifications
import Combine

/// Unified manager for local notifications and notification settings.
///
/// Single source of truth for:
/// - User notification preferences (enabled, notice time)
/// - System authorization state
/// - Scheduling and cancelling event reminders
///
/// **Usage from ViewModels:**
/// ```swift
/// // Enable/disable
/// await NotificationManager.shared.setNotificationsEnabled(true)
///
/// // Change notice time (reschedules automatically)
/// NotificationManager.shared.setNoticeTime(30)
///
/// // When a favorite is added/removed (FavoritesManager calls this automatically)
/// NotificationManager.shared.onFavoriteAdded(event)
/// NotificationManager.shared.onFavoriteRemoved(eventId: event.jsonId)
///
/// // Schedule reminder from event detail
/// await NotificationManager.shared.scheduleReminderForEvent(event)
/// ```
@MainActor
final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    // MARK: - Published State

    /// Whether event reminders are enabled
    @Published private(set) var isEnabled: Bool = false

    /// Minutes before event to send notification
    @Published private(set) var noticeTimeMinutes: Int = 15

    /// Current system authorization status
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    // MARK: - UserDefaults Keys (single source — no duplication)

    private enum Keys {
        static let notificationsEnabled = "notification_settings_enabled"
        static let noticeTimeMinutes    = "notification_settings_notice_time"
    }

    private let center = UNUserNotificationCenter.current()

    override private init() {
        super.init()
        center.delegate = self
        loadSettings()
        Task { await refreshAuthorizationStatus() }
    }

    // MARK: - Settings

    /// Enable or disable event reminders. Requests system permission if enabling.
    /// - Returns: `true` if the new state was applied successfully.
    @discardableResult
    func setNotificationsEnabled(_ enabled: Bool) async -> Bool {
        if enabled {
            let granted = await requestAuthorization()
            isEnabled = granted
            UserDefaults.standard.set(granted, forKey: Keys.notificationsEnabled)
            if granted { rescheduleAllFavoriteNotifications() }
            return granted
        } else {
            isEnabled = false
            UserDefaults.standard.set(false, forKey: Keys.notificationsEnabled)
            cancelAllNotifications()
            return true
        }
    }

    /// Update notice time. Automatically reschedules all favorites if enabled.
    func setNoticeTime(_ minutes: Int) {
        guard minutes > 0 else { return }
        noticeTimeMinutes = minutes
        UserDefaults.standard.set(minutes, forKey: Keys.noticeTimeMinutes)
        if isEnabled { rescheduleAllFavoriteNotifications() }
    }

    // MARK: - Authorization

    /// Request system notification permission.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge, .provisional]
            let granted = try await center.requestAuthorization(options: options)
            await refreshAuthorizationStatus()
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }

    /// Refresh `authorizationStatus` from the system. Disables if revoked externally.
    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        if authorizationStatus == .denied && isEnabled {
            isEnabled = false
            UserDefaults.standard.set(false, forKey: Keys.notificationsEnabled)
        }
    }

    // MARK: - Scheduling

    /// Schedule a notification for an event at `minutesBefore` minutes before it starts.
    func scheduleEventNotification(event: Event, minutesBefore: Int) {
        guard event.date > AppConfiguration.demoDate else { return }
        guard let notificationDate = Calendar.current.date(
            byAdding: .minute, value: -minutesBefore, to: event.date
        ) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Recordatorio de evento"
        content.body  = "\(event.title) - Comienza \(formatTimeText(minutesBefore))"
        content.sound = .default
        content.badge = 1

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        content.subtitle = "Hora de inicio: \(timeFormatter.string(from: event.date)) - \(event.location)"

        content.userInfo = [
            "eventId":   event.jsonId,
            "eventTitle": event.title,
            "eventDate":  ISO8601DateFormatter().string(from: event.date),
            "location":   event.location
        ]

        let trigger = makeTrigger(for: notificationDate)
        let request = UNNotificationRequest(
            identifier: notificationId(for: event.jsonId),
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error { print("Error scheduling notification: \(error)") }
        }
    }

    /// Cancel the pending notification for a specific event.
    func cancelNotification(for eventId: String) {
        center.removePendingNotificationRequests(withIdentifiers: [notificationId(for: eventId)])
    }

    /// Cancel all pending notifications.
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Batch

    /// Cancel and reschedule notifications for all favorited events.
    func rescheduleAllFavoriteNotifications() {
        guard isEnabled else { return }
        cancelAllNotifications()
        let allEvents    = EventDataService.shared.loadEventsFromJSON()
        let favoriteIds  = FavoritesManager.shared.getFavorites()
        allEvents
            .filter { favoriteIds.contains($0.jsonId) }
            .forEach { scheduleEventNotification(event: $0, minutesBefore: noticeTimeMinutes) }
    }

    // MARK: - Favorites convenience API (called by FavoritesManager)

    /// Schedule a notification when a favorite is added (no-op if disabled).
    func onFavoriteAdded(_ event: Event) {
        guard isEnabled else { return }
        scheduleEventNotification(event: event, minutesBefore: noticeTimeMinutes)
    }

    /// Cancel the notification when a favorite is removed.
    func onFavoriteRemoved(eventId: String) {
        cancelNotification(for: eventId)
    }

    // MARK: - Event detail reminder

    /// Schedule a reminder from the event detail screen.
    /// Handles authorization flow automatically.
    /// - Returns: `true` if the notification was scheduled.
    @discardableResult
    func scheduleReminderForEvent(_ event: Event) async -> Bool {
        await refreshAuthorizationStatus()
        switch authorizationStatus {
        case .denied:
            return false
        case .notDetermined:
            let granted = await requestAuthorization()
            guard granted else { return false }
            scheduleEventNotification(event: event, minutesBefore: noticeTimeMinutes)
            return true
        default:
            scheduleEventNotification(event: event, minutesBefore: noticeTimeMinutes)
            return true
        }
    }

    // MARK: - Display Helpers

    /// Human-readable notice time (e.g. "30 min", "2 horas", "1 día").
    var noticeTimeFormatted: String {
        formatTimeText(noticeTimeMinutes)
    }

    // MARK: - Debug

    func getPendingNotifications() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }

    // MARK: - Private Helpers

    private func loadSettings() {
        isEnabled = UserDefaults.standard.bool(forKey: Keys.notificationsEnabled)
        let saved = UserDefaults.standard.integer(forKey: Keys.noticeTimeMinutes)
        noticeTimeMinutes = saved > 0 ? saved : 15
    }

    private func notificationId(for eventId: String) -> String {
        "event_\(eventId)"
    }

    private func makeTrigger(for notificationDate: Date) -> UNNotificationTrigger {
        if notificationDate < AppConfiguration.demoDate {
            return UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        }
        let interval = notificationDate.timeIntervalSince(AppConfiguration.demoDate)
        return UNTimeIntervalNotificationTrigger(timeInterval: max(interval, 10), repeats: false)
    }

    private func formatTimeText(_ minutes: Int) -> String {
        if minutes >= 1440 {
            let days = minutes / 1440
            return days == 1 ? "mañana" : "en \(days) días"
        } else if minutes >= 60 {
            let hours = minutes / 60
            return "en \(hours) hora\(hours > 1 ? "s" : "")"
        } else {
            return "en \(minutes) minutos"
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {

    /// Show notification banner even when the app is in the foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.list, .sound, .badge])
    }

    /// Handle tap on a notification — broadcasts `openEventDetails` so any listener can navigate.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let eventId = userInfo["eventId"] as? String {
            NotificationCenter.default.post(
                name: .openEventDetails,
                object: nil,
                userInfo: ["eventId": eventId]
            )
        }
        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openEventDetails = Notification.Name("OpenEventDetails")
}
