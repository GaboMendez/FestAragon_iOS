import SwiftUI

// MARK: - Past Event Overlay
/// Reusable overlay component for past events
struct PastEventOverlay: View {
    var iconSize: CGFloat = 16
    var textSize: CGFloat = 16
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: iconSize, weight: .semibold))
            Text("Evento finalizado")
                .font(.system(size: textSize, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.75))
        )
    }
}

// MARK: - Event Card Wrapper
/// A wrapper view that handles past/future event logic automatically
struct EventCardWrapper<Content: View, Destination: View>: View {
    let event: Event
    let destination: () -> Destination
    let content: () -> Content
    let overlaySize: OverlaySize
    
    enum OverlaySize {
        case small  // For compact cards (MapsView)
        case regular // For standard cards (SearchResults, Favorites)
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 14
            case .regular: return 16
            }
        }
        
        var textSize: CGFloat {
            switch self {
            case .small: return 14
            case .regular: return 16
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 16
            case .regular: return 20
            }
        }
        
        var verticalPadding: CGFloat {
            switch self {
            case .small: return 10
            case .regular: return 12
            }
        }
    }
    
    init(
        event: Event,
        overlaySize: OverlaySize = .regular,
        @ViewBuilder destination: @escaping () -> Destination,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.event = event
        self.overlaySize = overlaySize
        self.destination = destination
        self.content = content
    }
    
    private var isPastEvent: Bool {
        AppConfiguration.isPastDate(event.date)
    }
    
    var body: some View {
        if isPastEvent {
            // Past event - not tappable, with overlay
            ZStack {
                content()
                    .opacity(0.5)
                
                // Centered overlay
                HStack(spacing: 8) {
                    Image(systemName: "clock.badge.xmark")
                        .font(.system(size: overlaySize.iconSize, weight: .semibold))
                    Text("Evento finalizado")
                        .font(.system(size: overlaySize.textSize, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, overlaySize.horizontalPadding)
                .padding(.vertical, overlaySize.verticalPadding)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.75))
                )
            }
        } else {
            // Future event - tappable, navigates to detail
            NavigationLink(destination: destination()) {
                content()
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Convenience initializer for EventView destination
extension EventCardWrapper where Destination == EventView {
    init(
        event: Event,
        overlaySize: OverlaySize = .regular,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.event = event
        self.overlaySize = overlaySize
        self.destination = { EventView(event: event) }
        self.content = content
    }
}

#Preview("Past Event") {
    EventCardWrapper(
        event: Event(
            id: UUID(),
            title: "Evento de prueba",
            description: "Descripción",
            date: Date().addingTimeInterval(-86400), // Yesterday
            endDate: nil,
            category: .music,
            location: "Zaragoza",
            latitude: 41.6488,
            longitude: -0.8891,
            imageURL: nil,
            price: 0
        ),
        overlaySize: .regular
    ) {
        Text("Card Content")
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(12)
    }
    .padding()
}
