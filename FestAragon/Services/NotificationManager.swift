//
//  NotificationManager.swift
//  FestAragon
//
//  Created by Gabriel Mendez Reyes on 14/1/26.
//

import Foundation
import UserNotifications

/// Gestor de notificaciones locales para eventos
/// 
/// **Cómo usar:**
/// ```swift
/// // Solicitar permisos
/// await NotificationManager.shared.requestAuthorization()
///
/// // Programar notificación para un evento
/// NotificationManager.shared.scheduleEventNotification(
///     event: myEvent,
///     minutesBefore: 30
/// )
///
/// // Cancelar notificación de un evento
/// NotificationManager.shared.cancelNotification(for: event.jsonId)
///
/// // Reprogramar todas las notificaciones de favoritos
/// NotificationManager.shared.rescheduleAllFavoriteNotifications(minutesBefore: 15)
/// ```
class NotificationManager: NSObject {
    static let shared = NotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    override private init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    // MARK: - Authorization
    
    /// Solicita permisos de notificación al usuario
    /// - Returns: true si se concedieron los permisos
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            print(granted ? "Permisos de notificación concedidos" : "Permisos de notificación denegados")
            return granted
        } catch {
            print("Error solicitando permisos: \(error)")
            return false
        }
    }
    
    /// Verifica el estado actual de los permisos de notificación
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Schedule Notifications
    
    /// Programa una notificación para un evento
    /// - Parameters:
    ///   - event: El evento para el cual programar la notificación
    ///   - minutesBefore: Minutos antes del evento para enviar la notificación
    func scheduleEventNotification(event: Event, minutesBefore: Int) {
        // Fecha de demo del proyecto: 21 de enero de 2026 a las 12:00
        let demoDate: Date = {
            var components = DateComponents()
            components.year = 2026
            components.month = 1
            components.day = 21
            components.hour = 12
            components.minute = 0
            return Calendar.current.date(from: components) ?? Date()
        }()
        
        // Verificar que el EVENTO sea en el futuro respecto a la fecha de demo
        guard event.date > demoDate else {
            print("El evento ya pasó respecto a la fecha de demo (21/01/2026), no se programa notificación")
            return
        }
        
        // Calcular la fecha de la notificación
        guard let notificationDate = Calendar.current.date(byAdding: .minute, value: -minutesBefore, to: event.date) else {
            print("Error calculando fecha de notificación")
            return
        }
        
        // Configurar el contenido de la notificación
        let content = UNMutableNotificationContent()
        content.title = "Recordatorio de evento"
        
        // Formatear el tiempo de forma legible
        let timeText: String
        if minutesBefore >= 1440 {
            let days = minutesBefore / 1440
            timeText = days == 1 ? "mañana" : "en \(days) días"
        } else if minutesBefore >= 60 {
            let hours = minutesBefore / 60
            timeText = "en \(hours) hora\(hours > 1 ? "s" : "")"
        } else {
            timeText = "en \(minutesBefore) minutos"
        }
        
        content.body = "\(event.title) - Comienza \(timeText)"
        content.sound = .default
        content.badge = 1
        
        // Información adicional
        content.userInfo = [
            "eventId": event.jsonId,
            "eventTitle": event.title,
            "eventDate": ISO8601DateFormatter().string(from: event.date),
            "location": event.location
        ]
        
        // Formatear hora de inicio para mostrar en la notificación
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let startTime = timeFormatter.string(from: event.date)
        
        content.subtitle = "Hora de inicio: \(startTime) - \(event.location)"
        
        // Crear el trigger: usar intervalo de tiempo para testing inmediato
        let trigger: UNNotificationTrigger
        if notificationDate < demoDate {
            // Si la notificación debería haber sido antes, programarla para 10 segundos
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
            print("Notificación ajustada para demo: se enviará en 10 segundos")
        } else {
            // Calcular segundos hasta la notificación desde la fecha de demo
            let timeInterval = notificationDate.timeIntervalSince(demoDate)
            if timeInterval > 0 {
                trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
                print("Notificación programada para dentro de \(Int(timeInterval)) segundos")
            } else {
                // Si es negativo o cero, enviar en 10 segundos
                trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
                print("Notificación inmediata: se enviará en 10 segundos")
            }
        }
        
        // Crear la petición de notificación con el ID del evento
        let identifier = "event_\(event.jsonId)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Programar la notificación
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error programando notificación: \(error)")
            } else {
                print("Notificación programada para \(event.title) - \(minutesBefore) min antes")
            }
        }
    }
    
    /// Cancela la notificación de un evento específico
    /// - Parameter eventId: ID del evento (jsonId)
    func cancelNotification(for eventId: String) {
        let identifier = "event_\(eventId)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("Notificación cancelada para evento: \(eventId)")
    }
    
    /// Cancela todas las notificaciones programadas
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("Todas las notificaciones canceladas")
    }
    
    // MARK: - Batch Operations
    
    /// Reprograma todas las notificaciones de eventos favoritos
    /// - Parameter minutesBefore: Nuevo tiempo de aviso en minutos
    func rescheduleAllFavoriteNotifications(minutesBefore: Int) {
        // Primero cancelar todas las notificaciones existentes
        cancelAllNotifications()
        
        // Obtener eventos favoritos del JSON
        let allEvents = EventDataService.shared.loadEventsFromJSON()
        let favoriteIds = FavoritesManager.shared.getFavorites()
        let favoriteEvents = allEvents.filter { favoriteIds.contains($0.jsonId) }
        
        // Programar notificaciones para cada favorito
        for event in favoriteEvents {
            scheduleEventNotification(event: event, minutesBefore: minutesBefore)
        }
        
        print("Reprogramadas \(favoriteEvents.count) notificaciones con \(minutesBefore) min de aviso")
    }
    
    /// Programa notificación para un nuevo evento favorito
    /// - Parameters:
    ///   - event: Evento a notificar
    ///   - minutesBefore: Minutos de antelación (obtenido de UserDefaults)
    func scheduleNotificationForNewFavorite(event: Event) {
        let minutesBefore = UserDefaults.standard.integer(forKey: "noticeTimeMinutes")
        let finalMinutes = minutesBefore > 0 ? minutesBefore : 15 // Default 15 min
        scheduleEventNotification(event: event, minutesBefore: finalMinutes)
    }
    
    // MARK: - Pending Notifications
    
    /// Obtiene todas las notificaciones pendientes
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    /// Lista todas las notificaciones pendientes (útil para debug)
    func listPendingNotifications() async {
        let requests = await getPendingNotifications()
        print("Notificaciones pendientes: \(requests.count)")
        for request in requests {
            if let trigger = request.trigger as? UNCalendarNotificationTrigger,
               let nextTriggerDate = trigger.nextTriggerDate() {
                print("  - \(request.identifier): \(request.content.title) -> \(nextTriggerDate)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    
    /// Se llama cuando la app está en primer plano y llega una notificación
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Mostrar la notificación incluso cuando la app está abierta
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Se llama cuando el usuario interactúa con una notificación
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if let eventId = userInfo["eventId"] as? String {
            print("Usuario interactuó con notificación del evento: \(eventId)")
            
            // Aquí puedes navegar a la pantalla del evento
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenEventDetails"),
                object: nil,
                userInfo: ["eventId": eventId]
            )
        }
        
        completionHandler()
    }
}
