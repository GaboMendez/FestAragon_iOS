import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @Namespace private var animation
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header con toggle de eventos pasados
                    HStack {
                        Text("Ver eventos pasados")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Toggle("", isOn: $viewModel.showPastEvents)
                            .labelsHidden()
                            .tint(Color(red: 166/255, green: 47/255, blue: 54/255))
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .animation(.easeInOut, value: viewModel.showPastEvents)
                    
                    // Barra de búsqueda
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(red: 166/255, green: 47/255, blue: 54/255).opacity(0.7))
                        
                        TextField("Buscar evento, lugar...", text: $viewModel.searchText)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .onSubmit {
                                if !viewModel.searchText.isEmpty {
                                    viewModel.showSearchResults = true
                                }
                            }
                        
                        if !viewModel.searchText.isEmpty {
                            Button {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    viewModel.searchText = ""
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(red: 166/255, green: 47/255, blue: 54/255).opacity(0.6))
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(red: 166/255, green: 47/255, blue: 54/255).opacity(0.15), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .animation(.easeInOut, value: viewModel.searchText)
                    
                    // Categorías
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Categorías")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 166/255, green: 47/255, blue: 54/255))
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(EventCategory.allCases, id: \.self) { category in
                                CategoryButton(
                                    title: category.displayName,
                                    isSelected: viewModel.selectedCategory == category
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        viewModel.toggleCategory(category)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Fecha
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Fecha")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 166/255, green: 47/255, blue: 54/255))
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.availableDates, id: \.self) { date in
                                    DateButton(
                                        date: date,
                                        isSelected: viewModel.selectedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            viewModel.toggleDate(date)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Eventos de Hoy
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Eventos de Hoy")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 166/255, green: 47/255, blue: 54/255))
                            .padding(.horizontal)
                        
                        if viewModel.todayEvents.isEmpty {
                            Text("No hay eventos para hoy")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity)
                        } else {
                            ForEach(viewModel.todayEvents) { event in
                                NavigationLink(destination: EventView(event: event)) {
                                    EventCard(event: event) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            viewModel.toggleFavorite(event: event)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("FestAragon")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color(red: 166/255, green: 47/255, blue: 54/255), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .background(Color(red: 250/255, green: 245/255, blue: 235/255))
            .navigationDestination(isPresented: $viewModel.showSearchResults) {
                SearchResultsView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(red: 235/255, green: 235/255, blue: 235/255))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color(red: 166/255, green: 47/255, blue: 54/255) : Color.clear, lineWidth: 2)
                )
                .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Date Button
struct DateButton: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void
    
    private var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: action) {
            Text(dayString)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.black)
                .frame(width: 60, height: 50)
                .background(isSelected ? Color(red: 200/255, green: 200/255, blue: 200/255) : Color(red: 215/255, green: 215/255, blue: 215/255))
                .cornerRadius(8)
                .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Event Card
struct EventCard: View {
    let event: Event
    let onFavorite: () -> Void
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy, HH:mm"
        return formatter.string(from: event.date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Imagen del evento
            AsyncImage(url: event.imageURL.flatMap { URL(string: $0) }) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay(
                            ProgressView()
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            
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
                    }
                    
                    Spacer()
                    
                    Button(action: onFavorite) {
                        Image(systemName: event.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 24))
                            .foregroundColor(event.isFavorite ? Color(red: 166/255, green: 47/255, blue: 54/255) : Color.gray.opacity(0.5))
                    }
                    .scaleEffect(event.isFavorite ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: event.isFavorite)
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

#Preview {
    HomeView()
}
