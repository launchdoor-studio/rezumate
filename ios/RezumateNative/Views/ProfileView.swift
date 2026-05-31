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
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(RezTheme.ink, lineWidth: 2)
                                }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(appState.session?.user?.email ?? "Signed in")
                                    .font(.headline.weight(.black))
                                    .foregroundStyle(RezTheme.ink)
                                Text("Free plan")
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(RezTheme.ink)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(RezTheme.warning, in: RoundedRectangle(cornerRadius: 4))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(RezTheme.ink, lineWidth: 2)
                                    }
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
                            }
                            .buttonStyle(RezSecondaryButtonStyle(fill: RezTheme.error))
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
