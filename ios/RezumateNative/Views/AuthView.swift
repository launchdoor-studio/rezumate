import AuthenticationServices
import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var appState: AppState
    @State private var coordinator: AppleSignInCoordinator?
    @State private var isSigningIn = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 36)

                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Image("RezumateLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 86, height: 86)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)

                        VStack(spacing: 10) {
                            Text("Rezumate")
                                .font(.system(size: 42, weight: .bold))
                                .multilineTextAlignment(.center)

                            Text("Tailor a resume to a role in minutes with ATS scoring, missing keywords, and focused bullet rewrites.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(spacing: 12) {
                        Button {
                            Task { await signIn() }
                        } label: {
                            Label(isSigningIn ? "Signing In..." : "Sign in with Apple", systemImage: "apple.logo")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 52)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.black)
                        .disabled(isSigningIn)

                        #if DEBUG
                        Button {
                            appState.session = AuthSession(token: "dev-token", user: nil)
                        } label: {
                            Label("Use Local Dev Session", systemImage: "terminal")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 48)
                        }
                        .buttonStyle(.bordered)
                        #endif
                    }
                }
                .padding(24)
                .frame(maxWidth: 420)

                Spacer(minLength: 36)
            }
        }
    }

    private func signIn() async {
        isSigningIn = true
        errorMessage = nil
        do {
            let signInCoordinator = AppleSignInCoordinator(api: appState.api)
            coordinator = signInCoordinator
            let response = try await signInCoordinator.signIn()
            appState.session = AuthSession(token: response.token, user: response.user)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSigningIn = false
    }
}
