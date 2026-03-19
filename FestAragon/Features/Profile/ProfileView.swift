import SwiftUI
import PhotosUI
import UIKit

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingEditDialog = false
    @State private var editingField: ProfileEditField?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Profile Header Section
                    ProfileHeaderView(
                        profileImage: viewModel.profileImage,
                        name: viewModel.userName,
                        email: viewModel.userEmail,
                        phone: viewModel.userPhone,
                        onImageTap: { showImagePickerOptions() }
                    )
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    
                    // Personal Info Section
                    PersonalInfoSection(
                        viewModel: viewModel,
                        onEditField: { field in
                            editingField = field
                            showingEditDialog = true
                        }
                    )
                    
                    // Notifications Section
                    NotificationsSection(viewModel: viewModel)
                    
                    // Privacy & Permissions Section
                    PrivacyPermissionsSection(viewModel: viewModel)
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 12)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Mi Perfil")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color(red: 166/255, green: 47/255, blue: 54/255), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .background(Color.festBackground)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $viewModel.profileImage)
        }
        .sheet(isPresented: $showingEditDialog) {
            if let field = editingField {
                EditProfileDialog(
                    field: field,
                    viewModel: viewModel,
                    isPresented: $showingEditDialog
                )
            }
        }
        .onAppear {
            viewModel.loadUserData()
        }
    }
    
    private func showImagePickerOptions() {
        let alert = UIAlertController(title: "Elige una opción", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Elegir de la galería", style: .default) { _ in
            showingImagePicker = true
        })
        
        alert.addAction(UIAlertAction(title: "Tomar foto", style: .default) { _ in
            if viewModel.cameraPermissionGranted {
                showingCamera = true
            } else {
                let alert = UIAlertController(
                    title: "Permiso denegado",
                    message: "El acceso a la cámara está desactivado en la configuración de privacidad",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                presentAlert(alert)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        
        presentAlert(alert)
    }
    
    private func presentAlert(_ alert: UIAlertController) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
}

#Preview {
    ProfileView()
}
