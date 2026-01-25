import SwiftUI

struct SearchResultsView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    
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
                HStack {
                    Text("\(viewModel.filteredEvents.count) resultado(s)")
                        .font(.headline)
                        .foregroundColor(Color(red: 166/255, green: 47/255, blue: 54/255))
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
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
                        EventCard(event: event) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.toggleFavorite(event: event)
                            }
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Resultados")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
