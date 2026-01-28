# ¡Viva mi pueblo en fiestas!

## Descripción

Nuestra aplicación deberá publicar información de un pueblo de Aragón en fiestas. Durante nuestras fiestas, los pueblos organizan distintos tipos de eventos de muy diversas categorías. Estos pueden ser: conciertos, espectáculos musicales y culturales, ferias y atracciones para niños, torneos de cartas, mercados o eventos tradicionales.

Los usuarios deben poder navegar durante los días festivos de forma directa, mostrando los eventos de cada uno de los días. Queremos además proponer búsquedas rápidas por las categorías principales o búsquedas textuales. Todas las búsquedas podrán ir filtradas de forma por proximidad futura. Es decir, el usuario decidirá si quiere ver o no eventos pasados.

Cualquier evento o actividad, deberá tener: título, fecha, lugar, imagen o recurso multimedia, descripción del evento y organizador. Toda esta información será visible desde la pantalla de detalle, donde mostraremos la ubicación donde va a tener lugar (habrá que geolocalizarlos), y de forma recomendada la posibilidad de obtener la ruta a dicho lugar desde donde nos encontremos.

Para poder disfrutar de las fiestas, podremos marcar eventos como favoritos, creando nuestra propia agenda que, idealmente, deberá notificarnos con alertas o avisos 15 minutos antes de que tenga lugar el evento.

Se espera un diseño, tanto gráfico como de patrones de interacción, estandarizado. No será necesario incluir peticiones de red ya que todos los eventos irán definidos en un único archivo JSON.

Además, también podremos compartir eventos por email compartiendo un texto fijo y pudiendo añadir un archivo multimedia.

## Presupuesto

El presupuesto disponible es de 120 horas, ya que el grupo está compuesto por 4 integrantes y cada uno debe dedicarle 30h al proyecto.

## Objetivo

Entregar una aplicación completamente funcional que presente los eventos más relevantes de las festividades de un pueblo de la comunidad autónoma de Aragón.

## Requisitos

- Navegación por fecha.
- Navegación por categoría.
- Filtrado por valor más cercano.
- Filtrado por categoría.
- Manejo de funcionalidades del dispositivo.
- Gestión de permisos.
- Gestión de tareas.
- Mapas y herramientas de GoogleMaps.
- Gestión de estado y ciclo de vida.
- Estilo unificado: interacciones, diseño y codificación.

## Guía para Desarrolladores

Para mantener un flujo de trabajo organizado y colaborativo, seguiremos una metodología de desarrollo basada en features. Cada requisito del proyecto será tratado como una feature individual.

### Ramas de Features (Feature Branches)

Cada vez que comiences a trabajar en un nuevo requisito, deberás crear una nueva rama (branch) a partir de la rama `develop`. El nombre de la rama debe seguir la siguiente convención:

`feature/<nombre-del-requisito>`

Por ejemplo, si estás trabajando en el requisito "Navegación por fecha", el nombre de tu rama sería:

`feature/navegacion-por-fecha`

**Flujo de trabajo:**

1.  Asegúrate de que tu rama `develop` local esté actualizada: `git checkout develop && git pull origin develop`
2.  Crea tu rama de feature: `git checkout -b feature/<nombre-del-requisito>`
3.  Realiza los commits necesarios en tu rama de feature.
4.  Una vez que hayas completado el desarrollo de la feature, sube tu rama al repositorio remoto: `git push origin feature/<nombre-del-requisito>`
5.  Crea un Pull Request (PR) en GitHub/GitLab para fusionar tu rama de feature en `develop`.
6.  Asigna revisores a tu PR para que revisen el código.
7.  Una vez que el PR sea aprobado y las pruebas pasen, se podrá fusionar a `develop`.

Este enfoque nos permitirá trabajar en paralelo en diferentes funcionalidades, mantener el código de la rama principal estable y facilitar la revisión de código.

## Arquitectura de Notificaciones

La gestión de notificaciones sigue una arquitectura centralizada para garantizar la sincronización entre todas las vistas de la aplicación (Perfil, Favoritos y Detalle de Evento).

### NotificationSettingsManager

Ubicación: `FestAragon/Services/NotificationSettingsManager.swift`

Este es el **único punto de verdad** para la configuración de notificaciones:

```swift
@MainActor
final class NotificationSettingsManager: ObservableObject {
    static let shared = NotificationSettingsManager()
    
    @Published private(set) var isEnabled: Bool = false
    @Published private(set) var noticeTimeMinutes: Int = 15
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
}
```

### Propiedades Reactivas

| Propiedad | Descripción |
|-----------|-------------|
| `isEnabled` | Estado de activación de recordatorios de eventos |
| `noticeTimeMinutes` | Minutos de antelación para la notificación |
| `authorizationStatus` | Estado de permisos del sistema |

### Métodos Principales

| Método | Descripción |
|--------|-------------|
| `setNotificationsEnabled(_ enabled: Bool) async -> Bool` | Activa/desactiva notificaciones con manejo de permisos |
| `setNoticeTime(_ minutes: Int)` | Configura el tiempo de aviso previo |
| `onFavoriteAdded(_ event: Event)` | Programa notificación al añadir favorito |
| `onFavoriteRemoved(eventId: String)` | Cancela notificación al eliminar favorito |

### Flujo de Datos

```
┌─────────────────────────────────────┐
│   NotificationSettingsManager       │
│   (Fuente Única de Verdad)          │
│   - isEnabled                       │
│   - noticeTimeMinutes               │
└─────────────────┬───────────────────┘
                  │ @Published (Combine)
    ┌─────────────┼─────────────┐
    ▼             ▼             ▼
┌────────┐  ┌──────────┐  ┌───────────┐
│Perfil  │  │Favoritos │  │Detalle    │
│ View   │  │  View    │  │  Evento   │
└────────┘  └──────────┘  └───────────┘
```

### Integración en ViewModels

Los ViewModels observan el manager centralizado mediante Combine:

```swift
// En FavoritesViewModel, ProfileViewModel
private func setupNotificationSettingsObserver() {
    notificationSettings.$isEnabled
        .receive(on: DispatchQueue.main)
        .sink { [weak self] enabled in
            self?.notificationsEnabled = enabled
        }
        .store(in: &cancellables)
    
    notificationSettings.$noticeTimeMinutes
        .receive(on: DispatchQueue.main)
        .sink { [weak self] minutes in
            self?.noticeTimeMinutes = minutes
        }
        .store(in: &cancellables)
}
```

### Sincronización Automática

- **FavoritesManager**: Al añadir/eliminar favoritos, automáticamente programa/cancela notificaciones
- **Cambio de configuración**: Al modificar el tiempo de aviso, se reprograman todas las notificaciones existentes
- **Permisos denegados**: Si el sistema deniega permisos, el estado se actualiza automáticamente en todas las vistas

## Arquitectura de Privacidad y Permisos

La gestión de permisos de privacidad sigue la misma arquitectura centralizada que las notificaciones, garantizando sincronización entre Perfil, Mapas y Detalle de Evento.

### PrivacySettingsManager

Ubicación: `FestAragon/Services/PrivacySettingsManager.swift`

Este es el **único punto de verdad** para la configuración de privacidad:

```swift
@MainActor
final class PrivacySettingsManager: NSObject, ObservableObject {
    static let shared = PrivacySettingsManager()
    
    @Published private(set) var locationPermissionGranted: Bool = false
    @Published private(set) var cameraPermissionGranted: Bool = false
    @Published private(set) var shareEventsEnabled: Bool = true
    @Published private(set) var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var cameraAuthorizationStatus: AVAuthorizationStatus = .notDetermined
}
```

### Propiedades Reactivas

| Propiedad | Descripción |
|-----------|-------------|
| `locationPermissionGranted` | Estado del permiso de ubicación |
| `cameraPermissionGranted` | Estado del permiso de cámara |
| `shareEventsEnabled` | Preferencia del usuario para compartir eventos |
| `locationAuthorizationStatus` | Estado de autorización del sistema para ubicación |
| `cameraAuthorizationStatus` | Estado de autorización del sistema para cámara |

### Métodos Principales

| Método | Descripción |
|--------|-------------|
| `requestLocationPermission() async -> Bool` | Solicita permiso de ubicación |
| `requestCameraPermission() async -> Bool` | Solicita permiso de cámara |
| `setShareEventsEnabled(_ enabled: Bool)` | Configura la preferencia de compartir |
| `refreshAllPermissionStates()` | Actualiza todos los estados de permisos |

### Flujo de Datos

```
┌─────────────────────────────────────┐
│   PrivacySettingsManager            │
│   (Fuente Única de Verdad)          │
│   - locationPermissionGranted       │
│   - cameraPermissionGranted         │
│   - shareEventsEnabled              │
└─────────────────┬───────────────────┘
                  │ @Published (Combine)
    ┌─────────────┼─────────────┐
    ▼             ▼             ▼
┌────────┐  ┌──────────┐  ┌───────────┐
│Perfil  │  │  Mapas   │  │Detalle    │
│ View   │  │  View    │  │  Evento   │
└────────┘  └──────────┘  └───────────┘
```

### Integración en ViewModels

Los ViewModels observan el manager centralizado mediante Combine:

```swift
// En ProfileViewModel, MapsViewModel
privacySettings.$locationPermissionGranted
    .receive(on: DispatchQueue.main)
    .sink { [weak self] granted in
        self?.locationPermissionGranted = granted
    }
    .store(in: &cancellables)

privacySettings.$shareEventsEnabled
    .receive(on: DispatchQueue.main)
    .sink { [weak self] enabled in
        self?.shareEventsEnabled = enabled
    }
    .store(in: &cancellables)
```

### Funcionalidades Sincronizadas

| Vista | Funcionalidad | Permiso |
|-------|---------------|---------|
| Perfil | Toggle de ubicación | `locationPermissionGranted` |
| Perfil | Toggle de cámara | `cameraPermissionGranted` |
| Perfil | Toggle de compartir | `shareEventsEnabled` |
| Mapas | Ubicación del usuario | `locationPermissionGranted` |
| Detalle Evento | Botón compartir | `shareEventsEnabled` |
| Perfil | Tomar foto de perfil | `cameraPermissionGranted` |

### Comportamiento de Compartir

Cuando el usuario desactiva "Compartir eventos" en Perfil, el botón de compartir en Detalle de Evento muestra un mensaje informativo:

```swift
func shareEvent() {
    guard PrivacySettingsManager.shared.canShare else {
        showAlert(
            title: "Compartir desactivado",
            message: "Puedes activar esta opción en tu perfil, sección Privacidad y permisos."
        )
        return
    }
    // ... continúa con el compartir
}
```

## Configuración de Fecha Demo

La aplicación utiliza una configuración centralizada para la fecha de demostración.

### AppConfiguration

Ubicación: `FestAragon/Services/AppConfiguration.swift`

```swift
enum AppConfiguration {
    /// Fecha actual del sistema
    static var demoDate: Date {
        Date()
    }
    
    /// Inicio del día de demo (00:00)
    static var startOfDemoDay: Date
    
    /// Verifica si una fecha es pasada
    static func isPastDate(_ date: Date) -> Bool
    
    /// Verifica si una fecha es hoy
    static func isToday(_ date: Date) -> Bool
    
    /// Obtiene las próximas N fechas
    static func upcomingDates(count: Int) -> [Date]
}
```

### Uso en la Aplicación

```swift
// Verificar si un evento es pasado
if AppConfiguration.isPastDate(event.date) {
    // Mostrar overlay "Evento finalizado"
}

// Obtener eventos de hoy
let todayEvents = events.filter { AppConfiguration.isToday($0.date) }

// Obtener próximos 5 días
let dates = AppConfiguration.upcomingDates(count: 5)
```

## TRELLO
https://trello.com/invite/b/6967b73bf1e99a8647f839c3/ATTIbe24d7173321ea67fc7ec88e7b7e4e5a623C257E/trabajo-grupal-ios