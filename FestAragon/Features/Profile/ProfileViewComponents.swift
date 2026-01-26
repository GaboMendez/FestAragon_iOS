import SwiftUI
import PhotosUI

// MARK: - Edit Profile Dialog
struct EditProfileDialog: View {
    let field: ProfileEditField
    @ObservedObject var viewModel: ProfileViewModel
    @Binding var isPresented: Bool
    @State private var editedValue: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack {
                    Text("Editar \(fieldTitle)")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal)
                
                TextField("", text: $editedValue)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Cancelar") {
                        isPresented = false
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    
                    Button("Guardar") {
                        viewModel.updateUserInfo(field: field, value: editedValue)
                        isPresented = false
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .onAppear {
                editedValue = currentValue
            }
        }
    }
    
    private var fieldTitle: String {
        switch field {
        case .name:
            return "Nombre"
        case .email:
            return "Email"
        case .phone:
            return "Teléfono"
        case .location:
            return "Ubicación"
        }
    }
    
    private var currentValue: String {
        switch field {
        case .name:
            return viewModel.userName
        case .email:
            return viewModel.userEmail
        case .phone:
            return viewModel.userPhone
        case .location:
            return viewModel.userLocation
        }
    }
}

#Preview {
    @State var isPresented = true
    return EditProfileDialog(
        field: .name,
        viewModel: ProfileViewModel(),
        isPresented: $isPresented
    )
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

// MARK: - Notifications Section
struct NotificationsSection: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var showingNoticeTimeAlert = false
    
    let noticeTimeOptions = [(label: "5 min", value: 5), (label: "10 min", value: 10), (label: "15 min", value: 15), (label: "30 min", value: 30), (label: "60 min", value: 60)]
    
    var body: some View {
        VStack(spacing: 0) {
            // Section Header
            HStack {
                Text("Notificaciones")
                    .font(.system(.headline, design: .default))
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(16)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Event Reminders
            HStack(spacing: 16) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.black)
                    .frame(width: 24, alignment: .center)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recordatorios de eventos")
                        .font(.system(.body, design: .default))
                        .foregroundColor(.primary)
                    
                    Text("\(viewModel.noticeTimeMinutes) min antes")
                        .font(.system(.caption, design: .default))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Toggle("", isOn: $viewModel.eventRemindersEnabled)
                    .onChange(of: viewModel.eventRemindersEnabled) { _, isEnabled in
                        if isEnabled {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { //Añadido estas porque me crasheo la aplicacion una de las opciones (Particularmente la de persmisos de camara) y decidí que nunca mas.
                                viewModel.checkAndRequestNotificationPermission()
                            }
                        }
                    }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Email Notifications
            HStack(spacing: 16) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.black)
                    .frame(width: 24, alignment: .center)
                
                Text("Notificaciones por email")
                    .font(.system(.body, design: .default))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.emailNotificationsEnabled)
                    .onChange(of: viewModel.emailNotificationsEnabled) { _, newValue in
                        DispatchQueue.main.async {
                            viewModel.saveEmailNotificationPreference(newValue)
                        }
                    }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Push Notifications
            HStack(spacing: 16) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.black)
                    .frame(width: 24, alignment: .center)
                
                Text("Notificaciones push")
                    .font(.system(.body, design: .default))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.pushNotificationsEnabled)
                    .onChange(of: viewModel.pushNotificationsEnabled) { _, newValue in
                        DispatchQueue.main.async {
                            viewModel.savePushNotificationPreference(newValue)
                        }
                    }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Notice Time
            Button(action: { showingNoticeTimeAlert = true }) {
                HStack(spacing: 16) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                        .frame(width: 24, alignment: .center)
                    
                    Text("Tiempo de aviso")
                        .font(.system(.body, design: .default))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(viewModel.noticeTimeMinutes) min")
                        .font(.system(.body, design: .default))
                        .foregroundColor(.gray)
                        .padding(.trailing, 8)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .contentShape(Rectangle())
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .actionSheet(isPresented: $showingNoticeTimeAlert) {
            ActionSheet(
                title: Text("Seleccionar tiempo de aviso"),
                buttons: noticeTimeOptions.map { option in
                    .default(Text(option.label)) {
                        viewModel.setNoticeTime(option.value)
                    }
                } + [.cancel()]
            )
        }
    }
}

#Preview {
    NotificationsSection(viewModel: ProfileViewModel())
        .padding()
}

// MARK: - Personal Info Section
struct PersonalInfoSection: View {
    @ObservedObject var viewModel: ProfileViewModel
    let onEditField: (ProfileEditField) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Section Header
            HStack {
                Text("Información Personal")
                    .font(.system(.headline, design: .default))
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.gray)
            }
            .padding(16)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Name Row
            ProfileInfoRow(
                icon: "person.fill",
                title: "Nombre completo",
                value: viewModel.userName,
                onTap: { onEditField(.name) }
            )
            
            Divider()
                .padding(.horizontal, 16)
            
            // Email Row
            ProfileInfoRow(
                icon: "envelope.fill",
                title: "Email",
                value: viewModel.userEmail,
                onTap: { onEditField(.email) }
            )
            
            Divider()
                .padding(.horizontal, 16)
            
            // Phone Row
            ProfileInfoRow(
                icon: "phone.fill",
                title: "Teléfono",
                value: viewModel.userPhone,
                onTap: { onEditField(.phone) }
            )
            
            Divider()
                .padding(.horizontal, 16)
            
            // Location Row
            ProfileInfoRow(
                icon: "mappin.circle.fill",
                title: "Ubicación",
                value: viewModel.userLocation,
                onTap: { onEditField(.location) }
            )
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

struct ProfileInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .frame(width: 24, alignment: .center)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.body, design: .default))
                        .foregroundColor(.primary)
                    
                    Text(value)
                        .font(.system(.caption, design: .default))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "pencil")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    PersonalInfoSection(
        viewModel: ProfileViewModel(),
        onEditField: { _ in }
    )
    .padding()
}

// MARK: - Privacy & Permissions Section
struct PrivacyPermissionsSection: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var showingPermissionAlert = false
    @State private var permissionType: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Section Header
            HStack {
                Text("Privacidad y Permisos")
                    .font(.system(.headline, design: .default))
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(16)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Location Permission
            HStack(spacing: 16) {
                Image(systemName: "location.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.black)
                    .frame(width: 24, alignment: .center)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Acceso a ubicación")
                        .font(.system(.body, design: .default))
                        .foregroundColor(.primary)
                    
                    Text("Para eventos cercanos")
                        .font(.system(.caption, design: .default))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Toggle("", isOn: $viewModel.locationPermissionGranted)
                    .onChange(of: viewModel.locationPermissionGranted) { _, isEnabled in
                        if isEnabled {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                viewModel.checkAndRequestLocationPermission()
                            }
                        } else {
                            permissionType = "ubicación"
                            showingPermissionAlert = true
                        }
                    }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Camera Permission
            HStack(spacing: 16) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.black)
                    .frame(width: 24, alignment: .center)
                
                Text("Acceso a cámara")
                    .font(.system(.body, design: .default))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.cameraPermissionGranted)
                    .onChange(of: viewModel.cameraPermissionGranted) { _, isEnabled in
                        if isEnabled {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                viewModel.checkAndRequestCameraPermission()
                            }
                        } else {
                            permissionType = "cámara"
                            showingPermissionAlert = true
                        }
                    }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Share Events
            HStack(spacing: 16) {
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.black)
                    .frame(width: 24, alignment: .center)
                
                Text("Compartir eventos")
                    .font(.system(.body, design: .default))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.shareEventsEnabled)
                    .onChange(of: viewModel.shareEventsEnabled) { _, newValue in
                        DispatchQueue.main.async {
                            viewModel.saveShareEventsPreference(newValue)
                        }
                    }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .alert(isPresented: $showingPermissionAlert) {
            Alert(
                title: Text("Revocar permisos"),
                message: Text("Para desactivar completamente el acceso a la \(permissionType), debes hacerlo desde los ajustes de la aplicación."),
                primaryButton: .default(Text("Ir a Ajustes")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                },
                secondaryButton: .cancel(Text("Cancelar")) {
                    viewModel.updatePermissionStates()
                }
            )
        }
    }
}

#Preview {
    PrivacyPermissionsSection(viewModel: ProfileViewModel())
        .padding()
}

// MARK: - Profile Header View
struct ProfileHeaderView: View {
    let profileImage: UIImage?
    let name: String
    let email: String
    let phone: String
    let onImageTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile Image
            ZStack(alignment: .center) {
                if let image = profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(red: 1.0, green: 0.84, blue: 0.0), lineWidth: 3)
                        )
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 72, height: 72)
                        .overlay(
                            Circle()
                                .stroke(Color(red: 1.0, green: 0.84, blue: 0.0), lineWidth: 3)
                        )
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.gray)
                        )
                }
            }
            .onTapGesture {
                onImageTap()
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(name.split(separator: " ").first.map(String.init) ?? "Usuario")
                    .font(.system(.title3, design: .default))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(email)
                    .font(.system(.body, design: .default))
                    .foregroundColor(.secondary)
                
                Text(phone)
                    .font(.system(.caption, design: .default))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ProfileHeaderView(
        profileImage: nil,
        name: "María García López",
        email: "maria.garcia@email.com",
        phone: "+34 612 345 678",
        onImageTap: {}
    )
    .padding()
}
