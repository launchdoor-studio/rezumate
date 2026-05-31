import AuthenticationServices
import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var appState: AppState
    @State private var coordinator: AppleSignInCoordinator?
    @State private var isSigningIn = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 24) {
                    Text("REZUMATE")
                        .font(.system(size: 15, weight: .black))
                        .tracking(0)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(RezTheme.ink, in: RoundedRectangle(cornerRadius: 3))
                        .overlay {
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(RezTheme.ink, lineWidth: 2)
                        }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("AI-POWERED\nRESUME\nOPTIMIZATION")
                            .font(.system(size: 31, weight: .black))
                            .tracking(0)
                            .lineSpacing(2)
                            .foregroundStyle(RezTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Analyze. Improve. Land more interviews.")
                            .font(.callout.weight(.bold))
                            .foregroundStyle(RezTheme.ink)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        FeatureRow(icon: "scope", text: "ATS Analysis")
                        FeatureRow(icon: "sparkles", text: "AI Suggestions")
                        FeatureRow(icon: "briefcase", text: "Tailored for Every Role")
                        FeatureRow(icon: "bolt", text: "Instant Results")
                    }
                }
                .padding(.top, 26)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(RezTheme.ink)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RezTheme.error, in: RoundedRectangle(cornerRadius: 6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(RezTheme.ink, lineWidth: 2)
                        }
                }

                RezCard(padding: 16) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("GET STARTED")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(RezTheme.ink)

                        Button {
                            Task { await signIn() }
                        } label: {
                            Label(isSigningIn ? "Signing In..." : "Sign in with Apple", systemImage: "apple.logo")
                        }
                        .buttonStyle(RezPrimaryButtonStyle())
                        .disabled(isSigningIn)

                        #if DEBUG
                        Button {
                            appState.session = AuthSession(token: "dev-token", user: nil)
                        } label: {
                            Label("Use Local Dev Session", systemImage: "terminal")
                        }
                        .buttonStyle(RezSecondaryButtonStyle(fill: RezTheme.warning))
                        #endif
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 440, alignment: .leading)
        }
        .rezScreenBackground()
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

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .black))
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13, weight: .black))
        }
        .foregroundStyle(RezTheme.ink)
    }
}
