import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel = FavoritesViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.festBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        VStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                // Notifications Settings - Always visible
                                NotificationsSettingsSection(
                                    isEnabled: $viewModel.notificationsEnabled,
                                    noticeMinutes: $viewModel.noticeTimeMinutes,
                                    onToggleChanged: { isEnabled in
                                        viewModel.setNotificationsEnabled(isEnabled)
                                    },
                                    onNoticeTimeChanged: { minutes in
                                        viewModel.setNoticeTime(minutes)
                                    }
                                )
                                .padding(.top, 16)
                                
                                if viewModel.favoriteEvents.isEmpty {
                                    // Empty state below notifications - centered
                                    FavoritesEmptyState()
                                        .frame(maxWidth: .infinity)
                                        .frame(minHeight: 300)
                                        .padding(.top, 20)
                                } else {
                                    // Favorited Events
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Tus eventos favoritos")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.festPrimary)
                                            .padding(.horizontal, 16)
                                        
                                        ForEach(viewModel.favoriteEvents) { event in
                                            EventCardWrapper(event: event) {
                                                FavoriteEventCard(event: event) {
                                                    withAnimation(.easeInOut(duration: 0.2)) {
                                                        viewModel.removeFavorite(event)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .padding(.top, 8)
                                }
                            }
                            .padding(.vertical, 16)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Favoritos")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
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
                        }
                    }
                }
            }
            .toolbarBackground(Color.festPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear {
            viewModel.loadFavorites()
        }
    }
}

#Preview {
    FavoritesView()
}
