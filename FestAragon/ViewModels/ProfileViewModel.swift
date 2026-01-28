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
    
    // Other settings (local to profile)
    @Published var emailNotificationsEnabled: Bool = false
    @Published var pushNotificationsEnabled: Bool = true
    
    @Published var locationPermissionGranted: Bool = false
    @Published var cameraPermissionGranted: Bool = false
    @Published var shareEventsEnabled: Bool = true
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let notificationSettings = NotificationSettingsManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private let profileImageKey = "user_image_path"
    private let userNameKey = "user_name"
    private let userEmailKey = "user_email"
    private let userPhoneKey = "user_phone"
    private let userLocationKey = "user_location"
    private let emailNotifKey = "email_notifications_enabled"
    private let pushNotifKey = "push_notifications_enabled"
    private let shareEventsKey = "share_events_enabled"
    
    override init() {
        super.init()
        loadUserData()
        updatePermissionStates()
        setupNotificationSettingsObserver()
    }
    
    // MARK: - Notification Settings Observer
    
    private func setupNotificationSettingsObserver() {
        // Observe isEnabled changes from centralized manager
        notificationSettings.$isEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.eventRemindersEnabled = enabled
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
    
    // MARK: - Data Persistence
    
    func loadUserData() {
        userName = userDefaults.string(forKey: userNameKey) ?? "María García López"
        userEmail = userDefaults.string(forKey: userEmailKey) ?? "maria.garcia@email.com"
        userPhone = userDefaults.string(forKey: userPhoneKey) ?? "+34 612 345 678"
        userLocation = userDefaults.string(forKey: userLocationKey) ?? "Aragón, España"
        emailNotificationsEnabled = userDefaults.bool(forKey: emailNotifKey)
        pushNotificationsEnabled = userDefaults.bool(forKey: pushNotifKey)
        
        // Sync notification settings from centralized manager
        eventRemindersEnabled = notificationSettings.isEnabled
        noticeTimeMinutes = notificationSettings.noticeTimeMinutes
        shareEventsEnabled = userDefaults.bool(forKey: shareEventsKey)
        
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
    
    func saveEmailNotificationPreference(_ enabled: Bool) {
        do {
            userDefaults.set(enabled, forKey: emailNotifKey)
            userDefaults.synchronize()
        } catch {
            print("Error saving email notification preference: \(error.localizedDescription)")
        }
    }
    
    func savePushNotificationPreference(_ enabled: Bool) {
        do {
            userDefaults.set(enabled, forKey: pushNotifKey)
            userDefaults.synchronize()
        } catch {
            print("Error saving push notification preference: \(error.localizedDescription)")
        }
    }
    
    func saveShareEventsPreference(_ enabled: Bool) {
        do {
            userDefaults.set(enabled, forKey: shareEventsKey)
            userDefaults.synchronize()
        } catch {
            print("Error saving share events preference: \(error.localizedDescription)")
        }
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
    
    // MARK: - Permissions
    
    func updatePermissionStates() {
        locationPermissionGranted = checkLocationPermission()
        cameraPermissionGranted = checkCameraPermission()
    }
    
    func checkLocationPermission() -> Bool {
        let locationStatus = CLLocationManager().authorizationStatus
        return locationStatus == .authorizedWhenInUse || locationStatus == .authorizedAlways
    }
    
    func checkCameraPermission() -> Bool {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        return cameraStatus == .authorized
    }
    
    private func isCameraAvailable() -> Bool {
        // Check if device has a camera
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    func checkAndRequestLocationPermission() {
        let locationManager = CLLocationManager()
        let status = locationManager.authorizationStatus
        
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            // Delay permission check to allow time for the user to respond
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.locationPermissionGranted = self?.checkLocationPermission() ?? false
            }
        } else if status == .denied || status == .restricted {
            DispatchQueue.main.async { [weak self] in
                self?.locationPermissionGranted = false
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.locationPermissionGranted = true
            }
        }
    }
    
    func checkAndRequestCameraPermission() {
        // First check if camera is available on device
        guard isCameraAvailable() else {
            DispatchQueue.main.async {
                self.cameraPermissionGranted = false
            }
            return
        }
        
        // Then request permission
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.cameraPermissionGranted = granted
            }
        }
    }
    
    func checkAndRequestNotificationPermission() {
        Task {
            await notificationSettings.setNotificationsEnabled(true)
        }
    }
}
