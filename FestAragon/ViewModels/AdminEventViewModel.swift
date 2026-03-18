import Foundation
import SwiftUI
import Combine

extension Notification.Name {
    static let adminEventDataChanged = Notification.Name("AdminEventDataChanged")
}

@MainActor
class AdminEventViewModel: ObservableObject {
    // MARK: - Editable Fields
    @Published var title: String
    @Published var eventDescription: String
    @Published var date: Date
    @Published var endDate: Date
    @Published var hasEndDate: Bool
    @Published var category: EventCategory
    @Published var location: String
    @Published var address: String
    @Published var latitude: String
    @Published var longitude: String
    @Published var imageURL: String
    @Published var price: String
    @Published var organizerName: String
    @Published var organizerEmail: String

    // MARK: - Feedback State
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var isError = false
    @Published var didSave = false
    @Published var didDelete = false

    // MARK: - Delete Confirmation
    @Published var showDeleteConfirmation = false

    let eventJsonId: String
    let eventTitle: String

    init(event: Event) {
        self.eventJsonId = event.jsonId
        self.eventTitle = event.title
        self.title = event.title
        self.eventDescription = event.description
        self.date = event.date
        self.endDate = event.endDate ?? event.date
        self.hasEndDate = event.endDate != nil
        self.category = event.category
        self.location = event.location
        self.address = event.address
        self.latitude = String(event.latitude)
        self.longitude = String(event.longitude)
        self.imageURL = event.imageURL ?? ""
        self.price = String(format: "%.2f", event.price)
        self.organizerName = event.organizadorNombre
        self.organizerEmail = event.organizadorEmail
    }

    // MARK: - Save

    func saveChanges() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            showFeedback(title: "Error", message: "El título no puede estar vacío.", isError: true)
            return
        }
        guard !location.trimmingCharacters(in: .whitespaces).isEmpty else {
            showFeedback(title: "Error", message: "La localidad no puede estar vacía.", isError: true)
            return
        }

        let lat = Double(latitude) ?? 0.0
        let lng = Double(longitude) ?? 0.0
        let parsedPrice = Double(price) ?? 0.0
        let finalEndDate: Date? = hasEndDate ? endDate : nil

        do {
            try EventDataService.shared.updateEvent(
                jsonId: eventJsonId,
                title: title.trimmingCharacters(in: .whitespaces),
                description: eventDescription,
                date: date,
                endDate: finalEndDate,
                categoryIdentifier: category.storageIdentifier,
                location: location.trimmingCharacters(in: .whitespaces),
                address: address,
                latitude: lat,
                longitude: lng,
                imageURL: imageURL.isEmpty ? nil : imageURL,
                price: parsedPrice,
                organizerName: organizerName,
                organizerEmail: organizerEmail
            )
            didSave = true
            NotificationCenter.default.post(name: .adminEventDataChanged, object: nil)
            showFeedback(title: "Éxito", message: "El evento se ha actualizado correctamente.", isError: false)
        } catch {
            showFeedback(title: "Error", message: error.localizedDescription, isError: true)
        }
    }

    // MARK: - Delete

    func confirmDelete() {
        showDeleteConfirmation = true
    }

    func deleteEvent() {
        do {
            try EventDataService.shared.deleteEvent(jsonId: eventJsonId)
            didDelete = true
            NotificationCenter.default.post(name: .adminEventDataChanged, object: nil)
            // Delay alert so confirmationDialog finishes dismissing first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.showFeedback(title: "Eliminado", message: "El evento '\(self?.eventTitle ?? "")' se ha eliminado correctamente.", isError: false)
            }
        } catch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.showFeedback(title: "Error", message: error.localizedDescription, isError: true)
            }
        }
    }

    // MARK: - Private

    private func showFeedback(title: String, message: String, isError: Bool) {
        self.alertTitle = title
        self.alertMessage = message
        self.isError = isError
        self.showAlert = true
    }
}
