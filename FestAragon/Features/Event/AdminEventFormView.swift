import SwiftUI

struct AdminEventFormView: View {
    @StateObject private var viewModel: AdminEventViewModel
    @Environment(\.dismiss) private var dismiss

    /// Create mode
    init() {
        self._viewModel = StateObject(wrappedValue: AdminEventViewModel())
    }

    /// Edit mode
    init(event: Event) {
        self._viewModel = StateObject(wrappedValue: AdminEventViewModel(event: event))
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Información General
                Section("Información General") {
                    TextField("Título", text: $viewModel.title)
                    
                    VStack(alignment: .leading) {
                        Text("Descripción")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $viewModel.eventDescription)
                            .frame(minHeight: 100)
                    }

                    Picker("Categoría", selection: $viewModel.category) {
                        ForEach(EventCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }

                // MARK: - Fecha y Hora
                Section("Fecha y Hora") {
                    DatePicker("Fecha de inicio", selection: $viewModel.date)

                    Toggle("Tiene fecha de fin", isOn: $viewModel.hasEndDate)

                    if viewModel.hasEndDate {
                        DatePicker("Fecha de fin", selection: $viewModel.endDate)
                    }
                }

                // MARK: - Ubicación
                Section("Ubicación") {
                    if viewModel.availableLocalities.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("No hay localidades disponibles")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Añade localidades desde el panel de administración de localidades.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Picker("Localidad", selection: $viewModel.location) {
                            ForEach(viewModel.availableLocalities, id: \.self) { locality in
                                Text(locality).tag(locality)
                            }
                        }
                    }

                    TextField("Dirección", text: $viewModel.address)

                    HStack {
                        TextField("Latitud", text: $viewModel.latitude)
                            .keyboardType(.decimalPad)
                        TextField("Longitud", text: $viewModel.longitude)
                            .keyboardType(.decimalPad)
                    }
                }

                // MARK: - Detalles
                Section("Detalles") {
                    TextField("URL de imagen", text: $viewModel.imageURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)

                    HStack {
                        Text("Precio (€)")
                        Spacer()
                        TextField("0.00", text: $viewModel.price)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }

                // MARK: - Organizador
                Section("Organizador") {
                    TextField("Nombre del organizador", text: $viewModel.organizerName)
                    TextField("Email del organizador", text: $viewModel.organizerEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                // MARK: - Guardar
                Section {
                    Button {
                        viewModel.saveChanges()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text(viewModel.isCreating ? "Crear evento" : "Guardar cambios")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .disabled(viewModel.availableLocalities.isEmpty)
                    .listRowBackground(Color.festPrimary)
                }

                // MARK: - Eliminar
                if !viewModel.isCreating {
                    Section {
                        Button(role: .destructive) {
                            viewModel.confirmDelete()
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Eliminar evento")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle(viewModel.isCreating ? "Nuevo Evento" : "Editar Evento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "¿Eliminar '\(viewModel.eventTitle)'?",
                isPresented: $viewModel.showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Eliminar evento", role: .destructive) {
                    viewModel.deleteEvent()
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Esta acción eliminará permanentemente el evento '\(viewModel.eventTitle)' y todos sus datos asociados. No se puede deshacer.")
            }
            .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
                Button("OK") {
                    if viewModel.didDelete || viewModel.didSave {
                        dismiss()
                    }
                }
            } message: {
                Text(viewModel.alertMessage)
            }
        }
    }
}
