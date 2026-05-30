import Foundation
import UniformTypeIdentifiers

enum APIClientError: Error, LocalizedError {
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an invalid response."
        case .server(let message):
            return message
        }
    }
}

struct APIClient {
    let baseURL: URL
    var session: URLSession = .shared

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: value) {
                return date
            }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: value) {
                return date
            }
            let fallback = DateFormatter()
            fallback.locale = Locale(identifier: "en_US_POSIX")
            fallback.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            if let date = fallback.date(from: value) {
                return date
            }
            fallback.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = fallback.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(value)")
        }
        return decoder
    }()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    func authenticateWithApple(identityToken: String, email: String?, fullName: String?) async throws -> AuthResponse {
        try await postJSON("/api/auth/apple", body: AppleAuthRequest(identityToken: identityToken, email: email, fullName: fullName), token: nil)
    }

    func uploadResume(fileURL: URL, token: String) async throws -> UploadResponse {
        let data = try Data(contentsOf: fileURL)
        var request = URLRequest(url: endpoint("/api/upload"))
        let boundary = "Boundary-\(UUID().uuidString)"
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = MultipartFormData.build(
            boundary: boundary,
            name: "resume_file",
            filename: fileURL.lastPathComponent,
            mimeType: mimeType(for: fileURL),
            data: data
        )
        return try await send(request)
    }

    func analyzeResume(resumeId: UUID, resumeText: String, jobDescription: String, token: String) async throws -> AnalyzeResponse {
        try await postJSON(
            "/api/analyze",
            body: AnalyzeRequest(resumeId: resumeId, resumeText: resumeText, jobDescription: jobDescription),
            token: token
        )
    }

    func rewriteBullet(_ bullet: String, focusKeywords: [String], token: String) async throws -> RewriteBulletResponse {
        try await postJSON(
            "/api/rewrite-bullet",
            body: RewriteBulletRequest(originalBullet: bullet, focusKeywords: focusKeywords),
            token: token
        )
    }

    func history(token: String) async throws -> [VariantSummary] {
        var request = URLRequest(url: endpoint("/api/history"))
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let response: HistoryResponse = try await send(request)
        return response.variants
    }

    func variant(id: UUID, token: String) async throws -> VariantDetail {
        var request = URLRequest(url: endpoint("/api/variants/\(id.uuidString)"))
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let response: VariantDetailEnvelope = try await send(request)
        return response.variant
    }

    func exportVariant(id: UUID, token: String) async throws -> URL {
        var request = URLRequest(url: endpoint("/api/export"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(["variant_id": id.uuidString])

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("rezumate-\(id.uuidString).pdf")
        try data.write(to: outputURL, options: .atomic)
        return outputURL
    }

    private func postJSON<T: Encodable, U: Decodable>(_ path: String, body: T, token: String?) async throws -> U {
        var request = URLRequest(url: endpoint(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try encoder.encode(body)
        return try await send(request)
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return try decoder.decode(T.self, from: data)
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            if let payload = try? decoder.decode(APIErrorPayload.self, from: data) {
                throw APIClientError.server(payload.detail)
            }
            throw APIClientError.server("Request failed with status \(http.statusCode).")
        }
    }

    private func endpoint(_ path: String) -> URL {
        let normalized = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return baseURL.appendingPathComponent(normalized)
    }

    private func mimeType(for url: URL) -> String {
        if url.pathExtension.lowercased() == "docx" {
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        }
        return UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "application/pdf"
    }
}

enum MultipartFormData {
    static func build(boundary: String, name: String, filename: String, mimeType: String, data: Data) -> Data {
        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n")
        return body
    }
}

private extension Data {
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}
