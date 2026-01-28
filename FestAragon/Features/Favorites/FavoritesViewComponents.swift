import SwiftUI

// MARK: - Image Loader
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    
    private var urlString: String?
    private static let cache = NSCache<NSString, UIImage>()
    
    func load(from urlString: String?) {
        guard let urlString = urlString, !urlString.isEmpty else {
            self.image = nil
            return
        }
        
        self.urlString = urlString
        
        // Check cache first
        if let cached = ImageLoader.cache.object(forKey: urlString as NSString) {
            self.image = cached
            return
        }
        
        guard let url = URL(string: urlString) else {
            self.image = nil
            return
        }
        
        isLoading = true
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                guard let data = data, error == nil,
                      let loadedImage = UIImage(data: data) else {
                    self?.image = nil
                    return
                }
                
                // Cache the image
                ImageLoader.cache.setObject(loadedImage, forKey: urlString as NSString)
                
                // Only update if URL hasn't changed
                if self?.urlString == urlString {
                    self?.image = loadedImage
                }
            }
        }.resume()
    }
}

// MARK: - Cached Async Image
struct CachedAsyncImage: View {
    let urlString: String?
    let height: CGFloat
    
    @StateObject private var loader = ImageLoader()
    
    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: height)
                    .clipped()
            } else if loader.isLoading {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: height)
                    .overlay(
                        ProgressView()
                    )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: height)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
            }
        }
        .onAppear {
            loader.load(from: urlString)
        }
        .onChange(of: urlString) { newValue in
            loader.load(from: newValue)
        }
    }
}

// MARK: - Favorite Event Card
struct FavoriteEventCard: View {
    let event: Event
    let onRemove: () -> Void
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy, HH:mm"
        return formatter.string(from: event.date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Imagen del evento
            CachedAsyncImage(urlString: event.imageURL, height: 180)
            
            // Contenido de la tarjeta
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(formattedDate)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Text(event.location)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        
                        HStack(spacing: 8) {
                            Text(event.category.displayName)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(red: 166/255, green: 47/255, blue: 54/255))
                                .cornerRadius(4)
                            
                            if event.price > 0 {
                                Text(String(format: "€%.2f", event.price))
                                    .font(.caption)
                                    .foregroundColor(.black)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.top, 4)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        onRemove()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(red: 166/255, green: 47/255, blue: 54/255))
                    }
                    .buttonStyle(.borderless)
                }
                .padding(16)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

// MARK: - Empty State View
struct FavoritesEmptyState: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "star")
                .font(.system(size: 80))
                .foregroundColor(Color(red: 166/255, green: 47/255, blue: 54/255).opacity(0.3))
            
            VStack(spacing: 8) {
                Text("No tienes favoritos")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                
                Text("Marca eventos como favoritos para verlos aquí")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 250/255, green: 245/255, blue: 235/255))
    }
}

// MARK: - Notifications Settings Section
struct NotificationsSettingsSection: View {
    @Binding var isEnabled: Bool
    @Binding var noticeMinutes: Int
    let onToggleChanged: (Bool) -> Void
    let onNoticeTimeChanged: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Notificaciones")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                
                Spacer()
                
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
                    .tint(Color(red: 166/255, green: 47/255, blue: 54/255))
                    .onChange(of: isEnabled) { _, newValue in
                        onToggleChanged(newValue)
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            if isEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notificar con")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                    
                    HStack(spacing: 12) {
                        ForEach([15, 30, 60, 1440], id: \.self) { minutes in
                            Button(action: {
                                onNoticeTimeChanged(minutes)
                            }) {
                                Text(minutes == 1440 ? "1d" : "\(minutes)m")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(noticeMinutes == minutes ? .white : Color(red: 166/255, green: 47/255, blue: 54/255))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(noticeMinutes == minutes ? Color(red: 166/255, green: 47/255, blue: 54/255) : Color(red: 166/255, green: 47/255, blue: 54/255).opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
}
