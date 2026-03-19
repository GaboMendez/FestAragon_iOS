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
                        Button {
                            viewModel.requestDelete(
                                location: location.name,
                                count: location.count
                            )
                        } label: {
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
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                } header: {
                    Text("Selecciona una localidad para eliminar todos sus eventos")
                } footer: {
                    Text("La eliminación es permanente e incluye todos los datos asociados a cada evento.")
                }
            }
        }
        .navigationTitle("Eventos por Localidad")
        .navigationBarTitleDisplayMode(.inline)
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
