import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    RezCard(padding: 18) {
                        HStack(spacing: 14) {
                            Image("RezumateLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 54, height: 54)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(appState.session?.user?.email ?? "Signed in")
                                    .font(.headline)
                                    .foregroundStyle(RezTheme.ink)
                                Text("Free plan")
                                    .font(.subheadline)
                                    .foregroundStyle(RezTheme.muted)
                            }

                            Spacer()
                        }
                    }

                    RezCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle("Account")
                            Button(role: .destructive) {
                                appState.signOut()
                            } label: {
                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .buttonStyle(.bordered)
                            .tint(RezTheme.error)
                        }
                    }
                }
                .padding()
            }
            .rezScreenBackground()
            .navigationTitle("Profile")
        }
    }
}
