import Foundation
import Combine

enum UserRole: String {
    case admin
    case user
}

@MainActor
final class SessionManager: ObservableObject {
    static let shared = SessionManager()

    @Published var currentRole: UserRole?

    private let roleKey = "user_role"

    var isAdmin: Bool { currentRole == .admin }
    var isLoggedIn: Bool { currentRole != nil }

    private init() {
        if let stored = UserDefaults.standard.string(forKey: roleKey),
           let role = UserRole(rawValue: stored) {
            currentRole = role
        }
    }

    func login(as role: UserRole) {
        currentRole = role
        UserDefaults.standard.set(role.rawValue, forKey: roleKey)
    }

    func logout() {
        currentRole = nil
        UserDefaults.standard.removeObject(forKey: roleKey)
    }
}
