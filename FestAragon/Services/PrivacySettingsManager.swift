//
//  PrivacySettingsManager.swift
//  FestAragon
//
//  Single source of truth for privacy & permission settings across the app.
//  All ViewModels should observe this manager for permission state.
//

import Foundation
import Combine
import AVFoundation
import CoreLocation
import UIKit

/// Centralized manager for privacy and permission settings
/// Provides reactive state that syncs across Profile, Maps, and Event views
///
/// **Usage:**
/// ```swift
/// // Observe settings changes
/// PrivacySettingsManager.shared.$locationPermissionGranted
///     .sink { granted in ... }
///     .store(in: &cancellables)
///
/// // Check/request permissions
/// await PrivacySettingsManager.shared.requestLocationPermission()
/// await PrivacySettingsManager.shared.requestCameraPermission()
///
/// // Check if sharing is enabled
/// if PrivacySettingsManager.shared.shareEventsEnabled { ... }
/// ```
@MainActor
final class PrivacySettingsManager: NSObject, ObservableObject {
    static let shared = PrivacySettingsManager()
    
    // MARK: - Published Properties (Reactive State)
    
    /// Whether location permission is granted
    @Published private(set) var locationPermissionGranted: Bool = false
    
    /// Whether camera permission is granted
    @Published private(set) var cameraPermissionGranted: Bool = false
    
    /// Whether share events feature is enabled (user preference)
    @Published private(set) var shareEventsEnabled: Bool = true
    
    /// Current location authorization status
    @Published private(set) var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    
    /// Current camera authorization status
    @Published private(set) var cameraAuthorizationStatus: AVAuthorizationStatus = .notDetermined
    
    // MARK: - UserDefaults Keys
    
    private enum Keys {
        static let shareEventsEnabled = "privacy_share_events_enabled"
    }
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()
    
    // MARK: - Init
    
    private override init() {
        super.init()
        loadSettings()
        refreshAllPermissionStates()
    }
    
    // MARK: - Public Methods
    
    /// Refresh all permission states from system
    func refreshAllPermissionStates() {
        refreshLocationPermissionState()
        refreshCameraPermissionState()
    }
    
    // MARK: - Location Permission
    
    /// Refresh location permission state from system
    func refreshLocationPermissionState() {
        let status = locationManager.authorizationStatus
        locationAuthorizationStatus = status
        locationPermissionGranted = (status == .authorizedWhenInUse || status == .authorizedAlways)
    }
    
    /// Request location permission
    /// - Returns: True if permission is granted
    @discardableResult
    func requestLocationPermission() async -> Bool {
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            // Wait briefly for authorization callback
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            refreshLocationPermissionState()
            return locationPermissionGranted
            
        case .authorizedWhenInUse, .authorizedAlways:
            locationPermissionGranted = true
            return true
            
        case .denied, .restricted:
            locationPermissionGranted = false
            return false
            
        @unknown default:
            return false
        }
    }
    
    // MARK: - Camera Permission
    
    /// Refresh camera permission state from system
    func refreshCameraPermissionState() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        cameraAuthorizationStatus = status
        cameraPermissionGranted = (status == .authorized)
    }
    
    /// Request camera permission
    /// - Returns: True if permission is granted
    @discardableResult
    func requestCameraPermission() async -> Bool {
        // Check if camera is available
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            cameraPermissionGranted = false
            return false
        }
        
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            cameraPermissionGranted = granted
            cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
            return granted
            
        case .authorized:
            cameraPermissionGranted = true
            return true
            
        case .denied, .restricted:
            cameraPermissionGranted = false
            return false
            
        @unknown default:
            return false
        }
    }
    
    // MARK: - Share Events Preference
    
    /// Set whether sharing events is enabled
    func setShareEventsEnabled(_ enabled: Bool) {
        shareEventsEnabled = enabled
        userDefaults.set(enabled, forKey: Keys.shareEventsEnabled)
    }
    
    // MARK: - Helper Methods
    
    /// Check if can share (user preference enabled)
    var canShare: Bool {
        shareEventsEnabled
    }
    
    /// Check if location services are available
    var isLocationServicesEnabled: Bool {
        CLLocationManager.locationServicesEnabled()
    }
    
    /// Check if camera is available on device
    var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    /// Open app settings
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadSettings() {
        // Default to true if not set
        if userDefaults.object(forKey: Keys.shareEventsEnabled) == nil {
            shareEventsEnabled = true
            userDefaults.set(true, forKey: Keys.shareEventsEnabled)
        } else {
            shareEventsEnabled = userDefaults.bool(forKey: Keys.shareEventsEnabled)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension PrivacySettingsManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.refreshLocationPermissionState()
        }
    }
}
