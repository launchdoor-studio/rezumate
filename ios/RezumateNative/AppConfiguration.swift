import Foundation

enum AppConfiguration {
    static var apiBaseURL: URL {
        if let value = Bundle.main.object(forInfoDictionaryKey: "REZUMATE_API_BASE_URL") as? String,
           let url = URL(string: value) {
            return url
        }
        return URL(string: "http://127.0.0.1:8000")!
    }
}
