import SwiftUI
import AVFoundation
import Photos
import UserNotifications
import CoreLocation
import Combine

enum ProfileEditField {
    case name
    case email
    case phone
    case location
}

@MainActor
class ProfileViewModel: NSObject, ObservableObject {
    @Published var profileImage: UIImage?
    @Published var userName: String = "María García López"
    @Published var userEmail: String = "maria.garcia@email.com"
    @Published var userPhone: String = "+34 612 345 678"
    @Published var userLocation: String = "Aragón, España"
    
    // Notification settings (observed from centralized manager)
    @Published var eventRemindersEnabled: Bool = false
    @Published var noticeTimeMinutes: Int = 15
    @Published var darkModeEnabled: Bool = false
    
    // Privacy settings (observed from centralized manager)
    @Published var locationPermissionGranted: Bool = false
    @Published var cameraPermissionGranted: Bool = false
    @Published var shareEventsEnabled: Bool = true
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let notificationSettings = NotificationManager.shared
    private let privacySettings = PrivacySettingsManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private let profileImageKey = "user_image_path"
    private let userNameKey = "user_name"
    private let userEmailKey = "user_email"
    private let userPhoneKey = "user_phone"
    private let userLocationKey = "user_location"
    private let darkModeEnabledKey = "is_dark_mode_enabled"
    
    override init() {
        super.init()
        loadUserData()
        setupSettingsObservers()
    }
    
    // MARK: - Settings Observers
    
    private func setupSettingsObservers() {
        // Observe notification settings from centralized manager
        notificationSettings.$isEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.eventRemindersEnabled = enabled
            }
            .store(in: &cancellables)
        
        notificationSettings.$noticeTimeMinutes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] minutes in
                self?.noticeTimeMinutes = minutes
            }
            .store(in: &cancellables)
        
        // Observe privacy settings from centralized manager
        privacySettings.$locationPermissionGranted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] granted in
                self?.locationPermissionGranted = granted
            }
            .store(in: &cancellables)
        
        privacySettings.$cameraPermissionGranted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] granted in
                self?.cameraPermissionGranted = granted
            }
            .store(in: &cancellables)
        
        privacySettings.$shareEventsEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.shareEventsEnabled = enabled
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Persistence
    
    func loadUserData() {
        userName = userDefaults.string(forKey: userNameKey) ?? "María García López"
        userEmail = userDefaults.string(forKey: userEmailKey) ?? "maria.garcia@email.com"
        userPhone = userDefaults.string(forKey: userPhoneKey) ?? "+34 612 345 678"
        userLocation = userDefaults.string(forKey: userLocationKey) ?? "Aragón, España"
        
        // Sync settings from centralized managers
        eventRemindersEnabled = notificationSettings.isEnabled
        noticeTimeMinutes = notificationSettings.noticeTimeMinutes
        locationPermissionGranted = privacySettings.locationPermissionGranted
        cameraPermissionGranted = privacySettings.cameraPermissionGranted
        shareEventsEnabled = privacySettings.shareEventsEnabled
        darkModeEnabled = userDefaults.bool(forKey: darkModeEnabledKey)
        
        // Load profile image
        if let imagePath = userDefaults.string(forKey: profileImageKey),
           let image = UIImage(contentsOfFile: imagePath) {
            self.profileImage = image
        }
    }
    
    func updateUserInfo(field: ProfileEditField, value: String) {
        switch field {
        case .name:
            userName = value
            userDefaults.set(value, forKey: userNameKey)
        case .email:
            userEmail = value
            userDefaults.set(value, forKey: userEmailKey)
        case .phone:
            userPhone = value
            userDefaults.set(value, forKey: userPhoneKey)
        case .location:
            userLocation = value
            userDefaults.set(value, forKey: userLocationKey)
        }
    }
    
    func saveShareEventsPreference(_ enabled: Bool) {
        privacySettings.setShareEventsEnabled(enabled)
    }

    func setDarkModeEnabled(_ enabled: Bool) {
        darkModeEnabled = enabled
        userDefaults.set(enabled, forKey: darkModeEnabledKey)
    }
    
    /// Set notice time in minutes (delegates to centralized manager)
    func setNoticeTime(_ minutes: Int) {
        notificationSettings.setNoticeTime(minutes)
    }
    
    /// Toggle event reminders enabled state (delegates to centralized manager)
    func setEventRemindersEnabled(_ enabled: Bool) {
        Task {
            await notificationSettings.setNotificationsEnabled(enabled)
        }
    }
    
    // Método helper para formatear el tiempo de aviso
    var noticeTimeFormatted: String {
        notificationSettings.noticeTimeFormatted
    }
    
    // MARK: - Image Handling
    
    func saveProfileImage(_ image: UIImage) {
        self.profileImage = image
        
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsDirectory.appendingPathComponent("profile_image.jpg")
            if let data = image.jpegData(compressionQuality: 1.0) {
                try? data.write(to: fileURL)
                userDefaults.set(fileURL.path, forKey: profileImageKey)
            }
        }
    }
    
    // MARK: - Permissions (delegated to centralized manager)
    
    func updatePermissionStates() {
        privacySettings.refreshAllPermissionStates()
    }
    
    func checkAndRequestLocationPermission() {
        Task {
            await privacySettings.requestLocationPermission()
        }
    }
    
    func checkAndRequestCameraPermission() {
        Task {
            await privacySettings.requestCameraPermission()
        }
    }
    
    func checkAndRequestNotificationPermission() {
        Task {
            await notificationSettings.setNotificationsEnabled(true)
        }
    }
}
