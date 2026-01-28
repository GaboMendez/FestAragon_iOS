import SwiftUI

struct SearchResultsView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    
    private func isPastEvent(_ event: Event) -> Bool {
        AppConfiguration.isPastDate(event.date)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Resumen de filtros activos
                if !viewModel.activeFiltersDescription.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Filtros activos:")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.activeFiltersDescription, id: \.self) { filter in
                                    HStack(spacing: 4) {
                                        Text(filter)
                                            .font(.caption)
                                            .foregroundColor(.white)
                                        
                                        Button {
                                            viewModel.removeFilter(filter)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(red: 166/255, green: 47/255, blue: 54/255))
                                    .cornerRadius(16)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 8)
                }
                
                // Contador de resultados
                HStack(spacing: 8) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 166/255, green: 47/255, blue: 54/255))
                    
                    Text("\(viewModel.filteredEvents.count) resultado\(viewModel.filteredEvents.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal)
                
                // Lista de eventos
                if viewModel.filteredEvents.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No se encontraron eventos")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Intenta ajustar los filtros de búsqueda")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    ForEach(viewModel.filteredEvents) { event in
                        let isPast = isPastEvent(event)
                        
                        if isPast {
                            // Past event - not tappable, with overlay
                            ZStack {
                                EventCard(event: event) {
                                    // Favorites still work for past events
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.toggleFavorite(event: event)
                                    }
                                }
                                .opacity(0.5)
                                
                                // Centered overlay indicating past event
                                HStack(spacing: 8) {
                                    Image(systemName: "clock.badge.xmark")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Evento finalizado")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.75))
                                )
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        } else {
                            // Future event - tappable, navigates to detail
                            NavigationLink(destination: EventView(event: event)) {
                                EventCard(event: event) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.toggleFavorite(event: event)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Resultados")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Resultados")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.clearAllFilters()
                } label: {
                    Text("Limpiar")
                        .foregroundColor(.white)
                }
            }
        }
        .toolbarBackground(Color(red: 166/255, green: 47/255, blue: 54/255), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .background(Color(red: 250/255, green: 245/255, blue: 235/255))
    }
}

#Preview {
    NavigationStack {
        SearchResultsView(viewModel: HomeViewModel())
    }
}
