import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "person.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.purple)
                    .padding()
                
                Text("Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your account settings")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileView()
}
