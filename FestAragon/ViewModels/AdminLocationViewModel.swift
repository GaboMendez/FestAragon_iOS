import Foundation
import SwiftUI

@MainActor
class AdminLocationViewModel: ObservableObject {
    @Published var locations: [(name: String, count: Int)] = []
    @Published var showResult = false
    @Published var resultTitle = ""
    @Published var resultMessage = ""
    @Published var isError = false

    // Confirmation state
    @Published var locationToDelete: String?
    @Published var countToDelete: Int = 0
    @Published var showDeleteConfirmation = false

    init() {
        loadLocations()
    }

    func loadLocations() {
        locations = EventDataService.shared.allLocations()
    }

    func requestDelete(location: String, count: Int) {
        locationToDelete = location
        countToDelete = count
        showDeleteConfirmation = true
    }

    func executeDelete() {
        guard let location = locationToDelete else { return }
        do {
            let count = try EventDataService.shared.deleteEventsByLocation(location)
            NotificationCenter.default.post(name: .adminEventDataChanged, object: nil)
            resultTitle = "Eliminación completada"
            resultMessage = "Se han eliminado \(count) evento\(count == 1 ? "" : "s") de '\(location)' correctamente."
            isError = false
            loadLocations()
            // Delay alert so confirmationDialog finishes dismissing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.showResult = true
            }
        } catch {
            resultTitle = "Error"
            resultMessage = error.localizedDescription
            isError = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.showResult = true
            }
        }
        locationToDelete = nil
    }
}
