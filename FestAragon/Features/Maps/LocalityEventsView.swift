import SwiftUI

struct LocalityEventsView: View {
    @ObservedObject var viewModel: MapsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Localidad Header
                        if let locality = viewModel.selectedLocality {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(locality)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.festPrimary)
                                        
                                        Text("\(viewModel.eventsInSelectedLocality.count) evento\(viewModel.eventsInSelectedLocality.count == 1 ? "" : "s")")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button {
                                        viewModel.deselectLocality()
                                        dismiss()
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.secondary.opacity(0.7))
                                    }
                                }
                                .padding()
                                .background(Color.festCardBackground)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            }
                            .padding(.horizontal)
                            .padding(.top, 16)
                        }
                        
                        // Eventos list
                        if viewModel.eventsInSelectedLocality.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 50))
                                    .foregroundColor(.secondary.opacity(0.6))
                                
                                Text("No hay eventos en esta localidad")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("Selecciona otra zona para ver sus eventos")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(viewModel.eventsInSelectedLocality.sorted { $0.date < $1.date }) { event in
                                    NavigationLink(destination: EventView(event: event)) {
                                        EventCard(event: event) {
                                            viewModel.toggleFavorite(event: event)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                            .frame(height: 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("\(viewModel.selectedLocality ?? "Zona")")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color.festPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .background(Color.festBackground)
        }
    }
}

#Preview {
    LocalityEventsView(viewModel: MapsViewModel())
}
