import SwiftUI

struct AdminLocationDeleteView: View {
    @StateObject private var viewModel = AdminLocationViewModel()

    var body: some View {
        List {
            if viewModel.locations.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "mappin.slash")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No hay localidades")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 40)
                        Spacer()
                    }
                }
            } else {
                Section {
                    ForEach(viewModel.locations, id: \.name) { location in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(location.name)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                Text("\(location.count) evento\(location.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button {
                                viewModel.requestEdit(location: location.name)
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundColor(.festPrimary)
                            }
                            .buttonStyle(.plain)

                            Button {
                                viewModel.requestDelete(
                                    location: location.name,
                                    count: location.count
                                )
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Gestiona localidades: editar nombre, añadir nuevas o eliminar con sus eventos")
                } footer: {
                    Text("La eliminación de una localidad borra permanentemente todos sus eventos y datos asociados.")
                }
            }
        }
        .navigationTitle("Eventos por Localidad")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.requestAdd()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .confirmationDialog(
            "Eliminar eventos en '\(viewModel.locationToDelete ?? "")'",
            isPresented: $viewModel.showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Eliminar \(viewModel.countToDelete) evento\(viewModel.countToDelete == 1 ? "" : "s")", role: .destructive) {
                viewModel.executeDelete()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se eliminarán permanentemente \(viewModel.countToDelete) evento\(viewModel.countToDelete == 1 ? "" : "s") de '\(viewModel.locationToDelete ?? "")' y todos sus datos asociados (multimedia, favoritos, notificaciones). Esta acción no se puede deshacer.")
        }
        .alert("Nueva localidad", isPresented: $viewModel.showAddDialog) {
            TextField("Nombre de la localidad", text: $viewModel.localityInput)
            Button("Cancelar", role: .cancel) {}
            Button("Añadir") {
                viewModel.executeAdd()
            }
        } message: {
            Text("Las localidades añadidas estarán disponibles en el formulario de eventos.")
        }
        .alert("Editar localidad", isPresented: $viewModel.showEditDialog) {
            TextField("Nombre de la localidad", text: $viewModel.localityInput)
            Button("Cancelar", role: .cancel) {}
            Button("Guardar") {
                viewModel.executeEdit()
            }
        } message: {
            Text("Al renombrar, los eventos existentes se actualizarán a la nueva localidad.")
        }
        .alert(viewModel.resultTitle, isPresented: $viewModel.showResult) {
            Button("OK") {}
        } message: {
            Text(viewModel.resultMessage)
        }
    }
}

#Preview {
    NavigationStack {
        AdminLocationDeleteView()
    }
}
