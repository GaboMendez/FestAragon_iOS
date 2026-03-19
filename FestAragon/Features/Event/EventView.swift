//
//  EventView.swift
//  FestAragon
//
//  Created by Gabriel Mendez Reyes on 14/1/26.
//

import SwiftUI
import MapKit

struct EventView: View {
    @StateObject private var viewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showAdminForm = false
    private let sessionManager = SessionManager.shared
    
    init(event: Event) {
        self._viewModel = StateObject(wrappedValue: EventViewModel(event: event))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Event Image with Video Badge
                ZStack(alignment: .topTrailing) {
                    if let imageURL = viewModel.event.imageURL, let url = URL(string: imageURL) {
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
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 220)
                            @unknown default:
                                imagePlaceholder
                            }
                        }
                    } else {
                        imagePlaceholder
                    }
                    
                    // Video badge - only show if event has videos
                    if viewModel.hasVideos {
                        Text("Video")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(6)
                            .padding(12)
                    }
                }
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .clipped()
                
                VStack(alignment: .leading, spacing: 16) {
                    // MARK: - Title
                    Text(viewModel.event.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 16)
                    
                    // MARK: - Category Badge
                    HStack {
                        Image(systemName: viewModel.categoryIcon)
                            .foregroundColor(viewModel.categoryColor)
                        Text(viewModel.event.category.displayName.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // MARK: - Date and Time Row
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.formattedFullDate)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(viewModel.event.timeRange)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // MARK: - Location Row with "Ver mapa" link
                    HStack {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.event.location)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(viewModel.event.address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Button {
                            viewModel.openInMaps()
                        } label: {
                            Text("Ver mapa")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                    .foregroundColor(.festPrimary)
                        }
                    }
                    
                    // MARK: - Organizer Row
                    HStack(spacing: 12) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        Text(viewModel.organizadorNombre)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // MARK: - Description Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Descripción")
                            .font(.headline)
                        
                        Text(viewModel.event.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // MARK: - Multimedia Gallery Section
                    if viewModel.hasMultimedia {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Galería multimedia")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.event.multimedia) { item in
                                        MediaThumbnailView(item: item) {
                                            viewModel.selectMedia(item)
                                        }
                                    }
                                }
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                    }
                    
                    // MARK: - Location Section with Map
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ubicación")
                            .font(.headline)
                        
                        // Mini Map
                        StaticMapView(coordinate: viewModel.event.coordinate)
                            .frame(height: 150)
                            .cornerRadius(12)
                            .overlay(
                                Text("Mapa de Google Maps")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            )
                        
                        // Map Action Buttons
                        HStack(spacing: 12) {
                            Button {
                                viewModel.openDirections()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                        .font(.subheadline)
                                    Text("Cómo llegar")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.festPrimary)
                                .cornerRadius(25)
                            }
                            
                            Button {
                                viewModel.openInMaps()
                            } label: {
                                HStack {
                                    Image(systemName: "mappin.and.ellipse")
                                        .font(.caption)
                                    Text("Ver en mapa")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(25)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // MARK: - Organizer Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Organizador")
                            .font(.headline)
                        
                        HStack {
                            // Organizer Avatar
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "building.2")
                                        .font(.title3)
                                        .foregroundColor(.secondary)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.organizadorNombre)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(viewModel.organizadorSubtitulo)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                viewModel.contactOrganizer()
                            } label: {
                                Text("Contactar")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.festPrimary)
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // MARK: - Reminder Button
                    Button {
                        viewModel.scheduleReminder()
                    } label: {
                        HStack {
                            Image(systemName: "bell.fill")
                            Text(viewModel.reminderButtonText)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.festPrimary)
                        .cornerRadius(12)
                    }
                    
                    // MARK: - Calendar and Share Buttons
                    HStack(spacing: 12) {
                        Button {
                            viewModel.addToCalendar()
                        } label: {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                Text("Añadir a calendario")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        }
                        
                        Button {
                            viewModel.shareEvent()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Compartir evento")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        }
                    }
                    
                    // MARK: - Price info
                    if viewModel.event.price > 0 {
                        Divider()
                            .padding(.vertical, 8)
                        
                        HStack {
                            Text("Precio")
                                .font(.headline)
                            Spacer()
                            Text(String(format: "%.2f €", viewModel.event.price))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.festPrimary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    if sessionManager.isAdmin {
                        Button {
                            showAdminForm = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(.festPrimary)
                        }
                    }
                    Button {
                        viewModel.toggleFavorite()
                    } label: {
                        Image(systemName: viewModel.isFavorite ? "star.fill" : "star")
                            .foregroundColor(viewModel.isFavorite ? .yellow : .gray)
                    }
                }
            }
        }
        .sheet(isPresented: $showAdminForm) {
            AdminEventFormView(event: viewModel.event)
        }
        .onChange(of: viewModel.eventWasDeleted) { _, deleted in
            if deleted { dismiss() }
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showingAlert) {
            Button("OK", role: .cancel) { }
            if viewModel.showSettingsButton {
                Button("Abrir Ajustes") {
                    viewModel.openSettings()
                }
            }
        } message: {
            Text(viewModel.alertMessage)
        }
        .alert("Contacto", isPresented: $viewModel.showingContactAlert) {
            Button("Copiar email") {
                UIPasteboard.general.string = viewModel.organizadorEmail
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
        .sheet(isPresented: $viewModel.showingMediaViewer) {
            if let selectedItem = viewModel.selectedMediaItem {
                MediaViewerSheet(
                    mediaItem: selectedItem,
                    allMedia: viewModel.event.multimedia
                )
            }
        }
    }
    
    // MARK: - View Components
    
    private var imagePlaceholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(height: 220)
            .overlay(
                VStack {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Imagen del Evento")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            )
    }
}

// MARK: - Media Thumbnail View
struct MediaThumbnailView: View {
    let item: MediaItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                if item.type == .image {
                    AsyncImage(url: URL(string: item.url)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                    .background(Color.festPrimary)
                        case .failure(_):
                            placeholderView
                        case .empty:
                            ProgressView()
                                .frame(width: 80, height: 80)
                        @unknown default:
                            placeholderView
                        }
                    }
                } else {
                    // Video thumbnail with play icon overlay
                    AsyncImage(url: URL(string: item.url)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .overlay(
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Image(systemName: "play.fill")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                        )
                                )
                        case .failure(_):
                            videoPlaceholderView
                        case .empty:
                            ProgressView()
                                .frame(width: 80, height: 80)
                        @unknown default:
                            videoPlaceholderView
                        }
                    }
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemGray4))
            .frame(width: 80, height: 80)
            .overlay(
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundColor(.white)
            )
    }
    
    private var videoPlaceholderView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemGray4))
            .frame(width: 80, height: 80)
            .overlay(
                Image(systemName: "play.fill")
                    .font(.title2)
                    .foregroundColor(.festPrimary)
                )
    }
}

// MARK: - Media Viewer Sheet
struct MediaViewerSheet: View {
    let mediaItem: MediaItem
    let allMedia: [MediaItem]
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    
    init(mediaItem: MediaItem, allMedia: [MediaItem]) {
        self.mediaItem = mediaItem
        self.allMedia = allMedia
        // Find the initial index
        if let index = allMedia.firstIndex(where: { $0.id == mediaItem.id }) {
            self._currentIndex = State(initialValue: index)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                TabView(selection: $currentIndex) {
                    ForEach(Array(allMedia.enumerated()), id: \.element.id) { index, item in
                        MediaContentView(item: item)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
            }
            .navigationTitle("\(currentIndex + 1) de \(allMedia.count)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - Media Content View
struct MediaContentView: View {
    let item: MediaItem
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            if item.type == .image {
                AsyncImage(url: URL(string: item.url)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = value
                                    }
                                    .onEnded { _ in
                                        withAnimation {
                                            scale = 1.0
                                        }
                                    }
                            )
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    case .failure(_):
                        VStack {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("Error al cargar la imagen")
                                .foregroundColor(.gray)
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    case .empty:
                        ProgressView()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                // Video placeholder - in a real app, you'd use AVPlayer
                VStack(spacing: 16) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                    
                    Text("Reproducir video")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Toca para abrir en el navegador")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Rectangle())
                .onTapGesture {
                    if let url = URL(string: item.url) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
    }
}

// MARK: - Static Map View (prevents Metal crashes in Simulator)
struct StaticMapView: View {
    let coordinate: CLLocationCoordinate2D
    @State private var mapImage: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if let image = mapImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        ProgressView()
                    )
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        VStack {
                            Image(systemName: "map")
                                .font(.title)
                                .foregroundColor(.secondary)
                            Text("Mapa no disponible")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
            }
            
            // Pin overlay
            if mapImage != nil {
                Image(systemName: "mappin.circle.fill")
                    .font(.title)
                    .foregroundColor(.red)
                    .background(
                        Circle()
                            .fill(.white)
                            .frame(width: 20, height: 20)
                    )
            }
        }
        .onAppear {
            generateSnapshot()
        }
    }
    
    private func generateSnapshot() {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        options.size = CGSize(width: 400, height: 200)
        options.scale = UIScreen.main.scale
        
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { snapshot, error in
            DispatchQueue.main.async {
                isLoading = false
                if let snapshot = snapshot {
                    mapImage = snapshot.image
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EventView(event: Event(
            jsonId: "preview",
            title: "Concierto de Año Nuevo",
            description: "Un maravilloso concierto para celebrar el nuevo año con la mejor música clásica.",
            date: Date(),
            endDate: Date().addingTimeInterval(7200),
            category: .music,
            location: "Auditorio de Zaragoza",
            address: "Eduardo Ibarra, 3",
            latitude: 41.6436,
            longitude: -0.8926,
            imageURL: "https://images.unsplash.com/photo-1465847899084-d164df4dedc6",
            multimedia: [
                MediaItem(type: .image, url: "https://images.unsplash.com/photo-1465847899084-d164df4dedc6"),
                MediaItem(type: .image, url: "https://images.unsplash.com/photo-1519683109079-d5f539e1542f"),
                MediaItem(type: .video, url: "https://example.com/video.mp4")
            ],
            price: 25.0,
            organizadorNombre: "Auditorio de Zaragoza",
            organizadorEmail: "info@auditoriozaragoza.com"
        ))
    }
}
