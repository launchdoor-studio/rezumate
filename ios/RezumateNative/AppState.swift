import Combine
import Foundation

final class AppState: ObservableObject {
    @Published var session: AuthSession? {
        didSet {
            if let token = session?.token {
                KeychainSessionStore.save(token: token)
            } else {
                KeychainSessionStore.clear()
            }
        }
    }

    @Published var upload: UploadResponse?
    @Published var jobDescription = ""
    @Published var latestAnalysis: AnalyzeResponse?
    @Published var selectedVariant: VariantDetail?

    let api = APIClient(baseURL: AppConfiguration.apiBaseURL)

    init() {
        if let token = KeychainSessionStore.loadToken() {
            session = AuthSession(token: token, user: nil)
        }
    }

    var token: String? {
        session?.token
    }

    func signOut() {
        session = nil
        upload = nil
        jobDescription = ""
        latestAnalysis = nil
        selectedVariant = nil
    }
}
