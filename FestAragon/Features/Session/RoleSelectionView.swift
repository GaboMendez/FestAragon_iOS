import SwiftUI

struct RoleSelectionView: View {
    @ObservedObject private var sessionManager = SessionManager.shared

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // App logo area
            VStack(spacing: 16) {
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(red: 166/255, green: 47/255, blue: 54/255))

                Text("FestAragón")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 166/255, green: 47/255, blue: 54/255))

                Text("Selecciona tu modo de acceso")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Role buttons
            VStack(spacing: 16) {
                Button {
                    sessionManager.login(as: .admin)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "shield.fill")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Administrador")
                                .font(.headline)
                            Text("Gestionar y editar eventos")
                                .font(.caption)
                                .opacity(0.8)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 166/255, green: 47/255, blue: 54/255))
                    .cornerRadius(14)
                }

                Button {
                    sessionManager.login(as: .user)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.fill")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Usuario")
                                .font(.headline)
                            Text("Explorar y descubrir eventos")
                                .font(.caption)
                                .opacity(0.8)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.primary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()
                .frame(height: 60)
        }
        .background(Color(red: 250/255, green: 245/255, blue: 235/255))
    }
}

#Preview {
    RoleSelectionView()
}
