import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    Text(appState.session?.user?.email ?? "Signed in")
                    Text("Free plan")
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        appState.signOut()
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}
