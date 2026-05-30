import AuthenticationServices
import Foundation
import UIKit

@MainActor
final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let api: APIClient
    private var continuation: CheckedContinuation<AuthResponse, Error>?

    init(api: APIClient) {
        self.api = api
    }

    func signIn() async throws -> AuthResponse {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.email, .fullName]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            continuation?.resume(throwing: APIClientError.server("Sign in with Apple did not return an identity token."))
            continuation = nil
            return
        }

        let email = credential.email
        let fullName = credential.fullName.map { PersonNameComponentsFormatter().string(from: $0) }

        Task {
            do {
                let response = try await api.authenticateWithApple(identityToken: tokenString, email: email, fullName: fullName)
                continuation?.resume(returning: response)
            } catch {
                continuation?.resume(throwing: error)
            }
            continuation = nil
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}
