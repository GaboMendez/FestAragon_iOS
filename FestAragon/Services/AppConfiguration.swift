//
//  AppConfiguration.swift
//  FestAragon
//
//  Created by Gabriel Mendez Reyes on 28/1/26.
//

import Foundation

/// Configuración centralizada de la aplicación
///
/// **Uso:**
/// ```swift
/// // Obtener la fecha de demo
/// let today = AppConfiguration.demoDate
///
/// // Verificar si un evento es pasado
/// if event.date < AppConfiguration.demoDate {
///     // Evento finalizado
/// }
/// ```
enum AppConfiguration {
    
    // MARK: - Demo Date
    
    /// Fecha de demo fija para testing: 28 de enero de 2026 a las 12:00
    ///
    /// Esta fecha se usa en lugar de `Date()` para simular un momento específico
    /// durante las fiestas del pueblo. Cambiar esta fecha afecta:
    /// - Qué eventos se muestran como "hoy"
    /// - Qué eventos se consideran pasados
    /// - Las notificaciones programadas
    static let demoDate: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 28
        components.hour = 12
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    /// Inicio del día de demo (00:00)
    static var startOfDemoDay: Date {
        Calendar.current.startOfDay(for: demoDate)
    }
    
    // MARK: - Helper Methods
    
    /// Verifica si una fecha es pasada respecto a la fecha de demo
    static func isPastDate(_ date: Date) -> Bool {
        date < demoDate
    }
    
    /// Verifica si una fecha es hoy (respecto a la fecha de demo)
    static func isToday(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: demoDate)
    }
    
    /// Obtiene las próximas N fechas desde la fecha de demo
    static func upcomingDates(count: Int) -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: demoDate)
        return (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }
}
