//
//  EventViewModel.swift
//  FestAragon
//
//  Created by Gabriel Mendez Reyes on 27/1/26.
//

import Foundation
import SwiftUI
import MapKit
import EventKit
import UserNotifications
import Combine

@MainActor
class EventViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var event: Event
    @Published var isFavorite: Bool = false
    @Published var showingAlert: Bool = false
    @Published var showingContactAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var showSettingsButton: Bool = false
    @Published var selectedMediaItem: MediaItem? = nil
    @Published var showingMediaViewer: Bool = false
    
    // MARK: - Private Properties
    private let favoritesManager = FavoritesManager.shared
    private let eventStore = EKEventStore()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Organizer Info (from event data)
    var organizadorNombre: String {
        event.organizadorNombre.isEmpty ? "Organizador" : event.organizadorNombre
    }
    let organizadorSubtitulo = "Organizador oficial"
    var organizadorEmail: String {
        event.organizadorEmail
    }
    
    // MARK: - Init
    init(event: Event) {
        self.event = event
        self.isFavorite = favoritesManager.isFavorite(eventId: event.jsonId)
        setupFavoritesObserver()
    }
    
    // MARK: - Private Methods
    
    private func setupFavoritesObserver() {
        favoritesManager.$favoriteIds
            .receive(on: DispatchQueue.main)
            .sink { [weak self] favoriteIds in
                guard let self = self else { return }
                self.isFavorite = favoriteIds.contains(self.event.jsonId)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Computed Properties
    
    var formattedFullDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d 'de' MMMM yyyy"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: event.date).capitalized
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: event.date)
    }
    
    var categoryIcon: String {
        switch event.category {
        case .music:
            return "music.note"
        case .cultural:
            return "theatermasks"
        case .infantil:
            return "figure.2.and.child.holdinghands"
        case .traditional:
            return "flag.fill"
        }
    }
    
    var categoryColor: Color {
        switch event.category {
        case .music:
            return Color(red: 0.2, green: 0.4, blue: 0.8)
        case .cultural:
            return Color(red: 0.6, green: 0.3, blue: 0.7)
        case .infantil:
            return Color(red: 0.2, green: 0.7, blue: 0.5)
        case .traditional:
            return Color(red: 0.9, green: 0.5, blue: 0.2)
        }
    }
    
    var shareText: String {
        """
        🎉 \(event.title)
        📅 \(formattedFullDate) - \(event.timeRange)
        📍 \(event.location)
        
        \(event.description)
        """
    }
    
    // MARK: - Multimedia Properties
    
    var hasMultimedia: Bool {
        !event.multimedia.isEmpty
    }
    
    var imageItems: [MediaItem] {
        event.multimedia.filter { $0.type == .image }
    }
    
    var videoItems: [MediaItem] {
        event.multimedia.filter { $0.type == .video }
    }
    
    var hasVideos: Bool {
        !videoItems.isEmpty
    }
    
    // MARK: - Public Methods
    
    func selectMedia(_ item: MediaItem) {
        selectedMediaItem = item
        showingMediaViewer = true
    }
    
    func toggleFavorite() {
        favoritesManager.toggleFavorite(eventId: event.jsonId)
    }
    
    func openInMaps() {
        let coordinate = event.coordinate
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = event.location
        mapItem.openInMaps()
    }
    
    func openDirections() {
        let coordinate = event.coordinate
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = event.location
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    // MARK: - Contact Organizer
    
    func contactOrganizer() {
        guard !organizadorEmail.isEmpty else {
            showAlert(title: "Sin contacto", message: "No hay información de contacto disponible para este organizador.")
            return
        }
        
        let subject = "Consulta sobre: \(event.title)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let emailURL = URL(string: "mailto:\(organizadorEmail)?subject=\(subject)") {
            if UIApplication.shared.canOpenURL(emailURL) {
                UIApplication.shared.open(emailURL)
            } else {
                alertMessage = "Puedes contactar al organizador en: \(organizadorEmail)"
                showingContactAlert = true
            }
        }
    }
    
    // MARK: - Reminder (Notifications)
    
    func scheduleReminder() {
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            
            switch settings.authorizationStatus {
            case .denied:
                // Permission was denied - guide to settings
                Task { @MainActor in
                    self.showAlert(
                        title: "Notificaciones desactivadas",
                        message: "Para recibir recordatorios, activa las notificaciones en Ajustes.",
                        showSettings: true
                    )
                }
                
            case .authorized, .provisional, .ephemeral:
                // Already authorized - schedule directly
                self.createNotification()
                
            case .notDetermined:
                // First time - request permission, then schedule if granted
                center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
                    guard let self = self else { return }
                    if granted {
                        self.createNotification()
                    } else {
                        Task { @MainActor in
                            self.showAlert(
                                title: "Permiso denegado",
                                message: "No podrás recibir recordatorios sin activar las notificaciones.",
                                showSettings: true
                            )
                        }
                    }
                }
                
            @unknown default:
                self.createNotification()
            }
        }
    }
    
    private func createNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🎉 \(event.title)"
        content.body = "Comienza en 15 minutos en \(event.location)"
        content.sound = .default
        
        // Schedule 15 minutes before event
        let triggerDate = event.date.addingTimeInterval(-15 * 60)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: event.jsonId, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { [weak self] error in
            Task { @MainActor in
                guard let self = self else { return }
                if error == nil {
                    self.showAlert(
                        title: "Recordatorio programado",
                        message: "✅ Recibirás una notificación 15 minutos antes del evento."
                    )
                } else {
                    self.showAlert(
                        title: "Error",
                        message: "No se pudo programar el recordatorio. Inténtalo de nuevo."
                    )
                }
            }
        }
    }
    
    // MARK: - Calendar
    
    func addToCalendar() {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .denied, .restricted:
            // Permission denied - guide to settings
            showAlert(
                title: "Acceso al calendario desactivado",
                message: "Para añadir eventos, activa el acceso al calendario en Ajustes.",
                showSettings: true
            )
            
        case .authorized, .fullAccess, .writeOnly:
            // Already authorized - add directly
            createCalendarEvent()
            
        case .notDetermined:
            // First time - request permission
            requestCalendarAccess()
            
        @unknown default:
            requestCalendarAccess()
        }
    }
    
    private func requestCalendarAccess() {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, _ in
                self?.handleCalendarPermissionResult(granted: granted)
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, _ in
                self?.handleCalendarPermissionResult(granted: granted)
            }
        }
    }
    
    private func handleCalendarPermissionResult(granted: Bool) {
        if granted {
            createCalendarEvent()
        } else {
            Task { @MainActor in
                self.showAlert(
                    title: "Permiso denegado",
                    message: "No podrás añadir eventos al calendario sin activar el acceso.",
                    showSettings: true
                )
            }
        }
    }
    
    private func createCalendarEvent() {
        let calendarEvent = EKEvent(eventStore: eventStore)
        calendarEvent.title = event.title
        calendarEvent.startDate = event.date
        calendarEvent.endDate = event.endDate ?? event.date.addingTimeInterval(3600)
        calendarEvent.location = event.location
        calendarEvent.notes = event.description
        calendarEvent.calendar = eventStore.defaultCalendarForNewEvents
        
        // Add an alert 15 minutes before
        calendarEvent.addAlarm(EKAlarm(relativeOffset: -15 * 60))
        
        do {
            try eventStore.save(calendarEvent, span: .thisEvent)
            Task { @MainActor in
                self.showAlert(
                    title: "Evento añadido",
                    message: "✅ El evento se ha añadido a tu calendario."
                )
            }
        } catch {
            Task { @MainActor in
                self.showAlert(
                    title: "Error",
                    message: "No se pudo añadir el evento al calendario."
                )
            }
        }
    }
    
    // MARK: - Alert Helper
    
    private func showAlert(title: String, message: String, showSettings: Bool = false) {
        alertTitle = title
        alertMessage = message
        showSettingsButton = showSettings
        showingAlert = true
    }
    
    func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    func shareEvent() {
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}
