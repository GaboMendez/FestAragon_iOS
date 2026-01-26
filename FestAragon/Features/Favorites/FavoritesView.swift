import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel = FavoritesViewModel()
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 250/255, green: 245/255, blue: 235/255)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Toolbar
                    HStack {
                        Text("Favoritos")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if !viewModel.favoriteEvents.isEmpty {
                            Menu {
                                Button(role: .destructive) {
                                    viewModel.clearAllFavorites()
                                } label: {
                                    Label("Limpiar todos", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .foregroundColor(.white)
                                    .font(.system(size: 18))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 166/255, green: 47/255, blue: 54/255))
                    .frame(height: 56)
                    
                    if viewModel.isLoading {
                        VStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if viewModel.favoriteEvents.isEmpty {
                        FavoritesEmptyState()
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                // Notifications Settings
                                NotificationsSettingsSection(
                                    isEnabled: $viewModel.notificationsEnabled,
                                    noticeMinutes: $viewModel.noticeTimeMinutes
                                ) {
                                    viewModel.setNotificationsEnabled(viewModel.notificationsEnabled)
                                    if viewModel.notificationsEnabled {
                                        viewModel.setNoticeTime(viewModel.noticeTimeMinutes)
                                    }
                                }
                                .padding(.top, 16)
                                
                                // Favorited Events
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Tus eventos favoritos")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(red: 166/255, green: 47/255, blue: 54/255))
                                        .padding(.horizontal, 16)
                                    
                                    ForEach(viewModel.favoriteEvents) { event in
                                        FavoriteEventCard(event: event) {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                viewModel.removeFavorite(event)
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            }
                            .padding(.vertical, 16)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
        }
        .onAppear {
            viewModel.loadFavorites()
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Sync with HomeView changes whenever the app comes to foreground
            if newPhase == .active {
                viewModel.loadFavorites()
            }
        }
    }
}

#Preview {
    FavoritesView()
}
