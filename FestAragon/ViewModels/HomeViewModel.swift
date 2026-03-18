import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var events: [Event] = []
    @Published var filteredEvents: [Event] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: EventCategory?
    @Published var selectedDate: Date?
    @Published var selectedLocalities: Set<String> = []
    @Published var showPastEvents: Bool = false
    @Published var showSearchResults: Bool = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let favoritesManager = FavoritesManager.shared
    
    // MARK: - Computed Properties
    var availableDates: [Date] {
        AppConfiguration.upcomingDates(count: 5)
    }
    
    /// Todas las localidades únicas disponibles en los eventos
    var availableLocalities: [String] {
        let allLocalities = events.map { $0.location }.uniqued()
        return allLocalities.sorted()
    }
    
    var categorizedEvents: [EventCategory: [Event]] {
        Dictionary(grouping: filteredEvents, by: \.category)
    }
    
    var todayEvents: [Event] {
        events.filter { event in
            AppConfiguration.isToday(event.date)
        }.sorted { $0.date < $1.date }
    }
    
    // Determina si el usuario está buscando/filtrando
    var isSearching: Bool {
        !searchText.isEmpty || selectedCategory != nil || selectedDate != nil || !selectedLocalities.isEmpty
    }
    
    // Eventos a mostrar: resultados filtrados si está buscando, eventos de hoy si no
    var displayedEvents: [Event] {
        if isSearching {
            return filteredEvents
        } else {
            return todayEvents
        }
    }
    
    // MARK: - Init
    init() {
        loadEvents()
        setupSubscriptions()
    }
    
    // MARK: - Private Methods
    
    private func syncFavoriteStatus() {
        // Sync all events with current favorite status
        for index in events.indices {
            events[index].isFavorite = favoritesManager.isFavorite(eventId: events[index].jsonId)
        }
        for index in filteredEvents.indices {
            filteredEvents[index].isFavorite = favoritesManager.isFavorite(eventId: filteredEvents[index].jsonId)
        }
    }
    
    private func setupSubscriptions() {
        // Observe favorites changes via Combine
        favoritesManager.$favoriteIds
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncFavoriteStatus()
            }
            .store(in: &cancellables)
        
        // Filtrar eventos cuando cambian los parámetros de búsqueda
        Publishers.CombineLatest4(
            $searchText,
            $selectedCategory,
            $selectedDate,
            $selectedLocalities
        )
        .combineLatest($showPastEvents)
        .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] (_, _) in
            guard let self = self else { return }
            self.filterEvents()
            // Only auto-show search results for category/date/locality filters, not for text search
            // Text search requires explicit submit (Enter key)
            if self.selectedCategory != nil || self.selectedDate != nil || !self.selectedLocalities.isEmpty {
                let shouldShowResults = self.isSearching
                if self.showSearchResults != shouldShowResults {
                    self.showSearchResults = shouldShowResults
                }
            } else if self.searchText.isEmpty && self.showSearchResults {
                // Hide search results when text is cleared
                self.showSearchResults = false
            }
        }
        .store(in: &cancellables)
    }
        
    private func filterEvents() {
        // Si hay filtros activos, filtrar; si no, mostrar array vacío
        // (HomeView solo mostrará todayEvents cuando no haya filtros)
        guard isSearching else {
            filteredEvents = []
            return
        }
        
        var result = events
        
        // Filtrar por eventos pasados/futuros basado en demoDate
        if !showPastEvents {
            result = result.filter { $0.date >= AppConfiguration.startOfDemoDay }
        }
        
        // Filtrar por búsqueda (título, descripción o ubicación)
        if !searchText.isEmpty {
            result = result.filter { event in
                event.title.localizedCaseInsensitiveContains(searchText) ||
                event.description.localizedCaseInsensitiveContains(searchText) ||
                event.location.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filtrar por categoría
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        // Filtrar por fecha específica
        if let date = selectedDate {
            let calendar = Calendar.current
            result = result.filter { calendar.isDate($0.date, inSameDayAs: date) }
        }
        
        // Filtrar por localidades (relación 1:N - un evento puede tener múltiples localidades buscadas)
        if !selectedLocalities.isEmpty {
            result = result.filter { selectedLocalities.contains($0.location) }
        }
        
        // Ordenar por fecha: más recientes primero
        filteredEvents = result.sorted { $0.date > $1.date }
    }
    
    // MARK: - Public Methods
    func toggleCategory(_ category: EventCategory) {
        if selectedCategory == category {
            selectedCategory = nil
        } else {
            selectedCategory = category
        }
    }
    
    func toggleDate(_ date: Date) {
        let calendar = Calendar.current
        if let selected = selectedDate, calendar.isDate(selected, inSameDayAs: date) {
            selectedDate = nil
        } else {
            selectedDate = date
        }
    }
    
    /// Alterna la selección de una localidad
    func toggleLocality(_ locality: String) {
        if selectedLocalities.contains(locality) {
            selectedLocalities.remove(locality)
        } else {
            selectedLocalities.insert(locality)
        }
    }
    
    /// Alterna el estado de favorito de un evento
    func toggleFavorite(event: Event) {
        // FavoritesManager already calls NotificationManager.onFavoriteAdded/Removed internally
        favoritesManager.toggleFavorite(eventId: event.jsonId)
    }
    
    func loadEvents() {
        events = EventDataService.shared.loadEvents()
        filterEvents()
    }
    
    /// Refresca los eventos desde el servicio (sincroniza favoritos)
    func refreshEventsWithFavorites() {
        EventDataService.shared.reloadEvents()
        events = EventDataService.shared.loadEvents()
        filterEvents()
    }
    
    // MARK: - Filter Management
    var activeFiltersDescription: [String] {
        var filters: [String] = []
        
        if !searchText.isEmpty {
            filters.append("Búsqueda: \(searchText)")
        }
        
        if let category = selectedCategory {
            filters.append("Categoría: \(category.displayName)")
        }
        
        if let date = selectedDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yy"
            filters.append("Fecha: \(formatter.string(from: date))")
        }
        
        // Agregar filtros de localidades
        for locality in selectedLocalities.sorted() {
            filters.append("Localidad: \(locality)")
        }
        
        return filters
    }
    
    func removeFilter(_ filterDescription: String) {
        if filterDescription.starts(with: "Búsqueda:") {
            searchText = ""
        } else if filterDescription.starts(with: "Categoría:") {
            selectedCategory = nil
        } else if filterDescription.starts(with: "Fecha:") {
            selectedDate = nil
        } else if filterDescription.starts(with: "Localidad:") {
            let parts = filterDescription.split(separator: ":", maxSplits: 1)
            if parts.count == 2 {
                let locality = String(parts[1]).trimmingCharacters(in: .whitespaces)
                selectedLocalities.remove(locality)
            }
        }
    }
    
    func clearAllFilters() {
        searchText = ""
        selectedCategory = nil
        selectedDate = nil
        selectedLocalities.removeAll()
        showSearchResults = false
    }
}
