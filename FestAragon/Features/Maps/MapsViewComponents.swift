import SwiftUI
import MapKit

// MARK: - Event Map Marker
struct EventMapMarker: View {
    let category: EventCategory
    var isSelected: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(markerColor)
                    .frame(width: isSelected ? 40 : 32, height: isSelected ? 40 : 32)
                    .shadow(color: markerColor.opacity(0.4), radius: isSelected ? 6 : 3, x: 0, y: 2)
                
                Image(systemName: iconName)
                    .font(.system(size: isSelected ? 18 : 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Marker point
            Triangle()
                .fill(markerColor)
                .frame(width: 12, height: 8)
                .offset(y: -2)
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
    
    private var markerColor: Color {
        switch category {
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
    
    private var iconName: String {
        switch category {
        case .music:
            return "music.note"
        case .cultural:
            return "theatermasks.fill"
        case .infantil:
            return "figure.and.child.holdinghands"
        case .traditional:
            return "sparkles"
        }
    }
}

// MARK: - Map Event Callout
struct MapEventCallout: View {
    let event: Event
    let distance: String
    let onClose: () -> Void
    let onFavoriteToggle: () -> Void
    
    private let themeColor = Color.festPrimary
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "EEE, d MMM • HH:mm"
        return formatter.string(from: event.date).capitalized
    }
    
    private var isPastEvent: Bool {
        AppConfiguration.isPastDate(event.date)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Event Image
            ZStack {
                if let imageURL = event.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_):
                            imagePlaceholder
                        case .empty:
                            ProgressView()
                                .frame(width: 60, height: 60)
                        @unknown default:
                            imagePlaceholder
                        }
                    }
                } else {
                    imagePlaceholder
                }
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            .clipped()
            
            // Event Info
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                    Text(formattedDate)
                        .font(.system(size: 11))
                }
                .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.system(size: 10))
                    Text("\(event.location) • \(distance)")
                        .font(.system(size: 11))
                        .lineLimit(1)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 8) {
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray.opacity(0.6))
                }
                
                Button(action: onFavoriteToggle) {
                    Image(systemName: event.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 18))
                        .foregroundColor(event.isFavorite ? .yellow : .gray)
                }
            }
            
            // Navigate to detail (if not past event)
            if !isPastEvent {
                NavigationLink(destination: EventView(event: event)) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.festPrimary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeColor.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var imagePlaceholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .overlay(
                Image(systemName: "photo")
                    .font(.caption)
                    .foregroundColor(.secondary)
            )
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Category Pill
struct CategoryPill: View {
    let title: String
    let icon: String
    var isSelected: Bool
    let action: () -> Void
    
    private let themeColor = Color.festPrimary
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? themeColor : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - Nearby Event Card
struct NearbyEventCard: View {
    let event: Event
    let distance: String
    let onFavoriteToggle: () -> Void
    let onMapTap: () -> Void
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "EEE, d MMM"
        return formatter.string(from: event.date).capitalized
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Event Image
            ZStack {
                if let imageURL = event.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_):
                            imagePlaceholder
                        case .empty:
                            ProgressView()
                                .frame(width: 80, height: 80)
                        @unknown default:
                            imagePlaceholder
                        }
                    }
                } else {
                    imagePlaceholder
                }
            }
            .frame(width: 80, height: 80)
            .cornerRadius(8)
            .clipped()
            
            // Event Info
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption2)
                    Text("\(event.location) - \(distance)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(formattedDate)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(event.timeRange)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: onFavoriteToggle) {
                    Image(systemName: event.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 18))
                        .foregroundColor(event.isFavorite ? .yellow : .gray)
                }
                
                Button(action: onMapTap) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.festPrimary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var imagePlaceholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .overlay(
                Text("Imagen")
                    .font(.caption)
                    .foregroundColor(.secondary)
            )
    }
}

// MARK: - Legend Row
struct LegendRow: View {
    let icon: String
    let title: String
    let category: EventCategory
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(markerColor)
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    private var markerColor: Color {
        switch category {
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
}

// MARK: - Map Controls
struct MapControls: View {
    let onLocationTap: () -> Void
    let onZoomIn: () -> Void
    let onZoomOut: () -> Void
    
    private let themeColor = Color.festPrimary
    
    var body: some View {
        VStack(spacing: 8) {
            // User location button
            Button(action: onLocationTap) {
                Image(systemName: "location.fill")
                    .font(.system(size: 16))
                    .foregroundColor(themeColor)
                    .frame(width: 36, height: 36)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            
            // Zoom controls
            VStack(spacing: 0) {
                Button(action: onZoomIn) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 36, height: 36)
                }
                
                Divider()
                    .frame(width: 36)
                
                Button(action: onZoomOut) {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 36, height: 36)
                }
            }
            .frame(width: 36)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Map Search Bar
struct MapSearchBar: View {
    @Binding var searchText: String
    
    private let themeColor = Color.festPrimary
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(themeColor.opacity(0.7))
            
            TextField("Buscar ubicación...", text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            if !searchText.isEmpty {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(themeColor.opacity(0.6))
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.festCardBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(themeColor.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.vertical, 8)
        .animation(.easeInOut, value: searchText)
    }
}

// MARK: - Localities Toggle
struct LocalitiesToggle: View {
    @Binding var showLocalitiesMode: Bool
    
    private let themeColor = Color.festPrimary
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: showLocalitiesMode ? "map.circle.fill" : "pin.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeColor)
            
            Text(showLocalitiesMode ? "Agrupar por zonas" : "Todos los eventos")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            Toggle("", isOn: $showLocalitiesMode)
                .tint(.festPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(themeColor.opacity(0.08))
        )
        .padding(.horizontal)
    }
}

// MARK: - Map Legend Section
struct MapLegendSection: View {
    let categories: [EventCategory]
    let iconName: (EventCategory) -> String
    let legendTitle: (EventCategory) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Leyenda del Mapa")
                .font(.headline)
            
            ForEach(categories, id: \.self) { category in
                LegendRow(
                    icon: iconName(category),
                    title: legendTitle(category),
                    category: category
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

// MARK: - Category Filters Section
struct CategoryFiltersSection: View {
    let categories: [EventCategory]
    let selectedCategories: Set<EventCategory>
    let displayName: (EventCategory) -> String
    let iconName: (EventCategory) -> String
    let onToggle: (EventCategory) -> Void
    let onClear: () -> Void
    
    private let themeColor = Color.festPrimary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Filtrar por categoría")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !selectedCategories.isEmpty {
                    Button("Limpiar", action: onClear)
                        .font(.subheadline)
                        .foregroundColor(themeColor)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { category in
                        CategoryPill(
                            title: displayName(category),
                            icon: iconName(category),
                            isSelected: selectedCategories.contains(category)
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                onToggle(category)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
// MARK: - Locality Map Marker
struct LocalityMapMarker: View {
    let locality: String
    let eventCount: Int
    var isSelected: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Background circle
                Circle()
                    .fill(isSelected ? Color.festPrimary : Color(.systemBackground))
                    .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                    .shadow(color: Color.festPrimary.opacity(0.4), radius: isSelected ? 8 : 4, x: 0, y: 2)
                
                // Event count text
                VStack(spacing: 2) {
                    Text("\(eventCount)")
                        .font(.system(size: isSelected ? 18 : 14, weight: .bold))
                        .foregroundColor(isSelected ? .white : .festPrimary)
                    
                    Text("evento\(eventCount == 1 ? "" : "s")")
                        .font(.system(size: isSelected ? 8 : 7, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .festPrimary)
                }
            }
            
            // Marker point
            Triangle()
                .fill(isSelected ? Color.festPrimary : Color(.systemBackground))
                .frame(width: 12, height: 8)
                .offset(y: -2)

            Text(locality)
                .font(.system(size: isSelected ? 11 : 10, weight: .semibold))
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color.festPrimary : Color(.systemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                .offset(y: 1)
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

// MARK: - Locality Events Callout
struct LocalityEventsCallout: View {
    let locality: String
    let events: [Event]
    let onClose: () -> Void
    let onFavoriteToggle: (Event) -> Void

    private var sortedEvents: [Event] {
        events.sorted { $0.date < $1.date }
    }

    private var headerText: String {
        "\(events.count) evento\(events.count == 1 ? "" : "s") en \(locality)"
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(locality)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(headerText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
            }

            if sortedEvents.isEmpty {
                Text("No hay eventos en esta localidad")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(sortedEvents) { event in
                            NavigationLink(destination: EventView(event: event)) {
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(event.title)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                            .lineLimit(1)

                                        Text(event.timeRange)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Button {
                                        onFavoriteToggle(event)
                                    } label: {
                                        Image(systemName: event.isFavorite ? "star.fill" : "star")
                                            .foregroundColor(event.isFavorite ? .yellow : .gray)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 160)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.festPrimary.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Map Category Legend (for individual events mode)
struct MapCategoryLegend: View {
    let categories: [EventCategory]
    let iconName: (EventCategory) -> String
    let legendTitle: (EventCategory) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categorías de Eventos")
                .font(.headline)
            
            ForEach(categories, id: \.self) { category in
                HStack(spacing: 12) {
                    // Color indicator circle
                    Circle()
                        .fill(categoryColor(for: category))
                        .frame(width: 12, height: 12)
                    
                    Image(systemName: iconName(category))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(categoryColor(for: category))
                        .frame(width: 20)
                    
                    Text(legendTitle(category))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.festCardBackground)
        )
        .padding(.horizontal)
    }
    
    private func categoryColor(for category: EventCategory) -> Color {
        switch category {
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
}