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
    
    func authenticateWithApple(identityToken: String, email: String?, fullName: String?) async throws -> AuthResponse {
        // Return a local guest user session instantly
        let user = AuthUser(id: UUID(), email: email ?? "local.user@rezumate.local", planTier: "pro")
        return AuthResponse(success: true, token: "local-session-token", user: user)
    }

    func uploadResume(fileURL: URL, token: String) async throws -> UploadResponse {
        let data = try Data(contentsOf: fileURL)
        let result: ExtractionResult
        
        if fileURL.pathExtension.lowercased() == "docx" {
            result = DocxTextExtractor.extractText(from: data)
        } else {
            result = PDFTextExtractor.extractText(from: data)
        }
        
        guard result.status != "failed" else {
            throw APIClientError.server(result.warnings.first ?? "Failed to extract text from document.")
        }
        
        return UploadResponse(
            success: true,
            filename: fileURL.lastPathComponent,
            resumeId: UUID(),
            extractedText: result.text,
            warnings: result.warnings,
            characterCount: result.characterCount
        )
    }

    func analyzeResume(resumeId: UUID, resumeText: String, jobDescription: String, token: String) async throws -> AnalyzeResponse {
        let result = ATSScoringService.analyzeResume(resumeText: resumeText, jobDescription: jobDescription)
        let variantId = UUID()
        
        let localVariant = LocalVariant(
            id: variantId,
            resumeId: resumeId,
            variantName: "Analysis \(Date().formatted(date: .abbreviated, time: .shortened))",
            tailoredContent: resumeText,
            atsScore: result.score,
            analysisFeedback: result,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        LocalStorageManager.shared.saveVariant(localVariant)
        
        return AnalyzeResponse(
            success: true,
            variantId: variantId,
            score: result.score,
            matchedKeywords: result.matchedKeywords,
            missingKeywords: result.missingKeywords,
            weakBullets: result.weakBullets,
            bulletsWithoutMeasurableImpact: result.bulletsWithoutMeasurableImpact,
            formattingWarnings: result.formattingWarnings,
            componentScores: result.componentScores,
            analysisStatus: "complete",
            aiModelName: "Llama 3.2 1B (On-Device)",
            bulletCount: result.bulletCount,
            keywordCoverage: result.keywordCoverage,
            sections: result.sections
        )
    }

    func rewriteBullet(_ bullet: String, focusKeywords: [String], token: String) async throws -> RewriteBulletResponse {
        let rewrites = try await LocalAIService.shared.rewriteBullet(bullet, focusKeywords: focusKeywords)
        return RewriteBulletResponse(
            success: true,
            originalBullet: bullet,
            rewrittenBullets: rewrites,
            aiModelName: LocalAIService.shared.modelExists ? "Llama 3.2 1B (On-Device)" : "Rules-Based Engine (Local)"
        )
    }

    func history(token: String) async throws -> [VariantSummary] {
        let list = LocalStorageManager.shared.loadHistory()
        return list.map { v in
            VariantSummary(
                id: v.id,
                resumeId: v.resumeId,
                variantName: v.variantName,
                atsScore: v.atsScore,
                createdAt: v.createdAt,
                updatedAt: v.updatedAt
            )
        }
    }

    func variant(id: UUID, token: String) async throws -> VariantDetail {
        let list = LocalStorageManager.shared.loadHistory()
        guard let v = list.first(where: { $0.id == id }) else {
            throw APIClientError.server("Variant not found.")
        }
        return VariantDetail(
            id: v.id,
            resumeId: v.resumeId,
            variantName: v.variantName,
            tailoredContent: TailoredContent(rawText: v.tailoredContent),
            atsScore: v.atsScore,
            createdAt: v.createdAt
        )
    }

    func analysisResult(id: UUID, token: String) async throws -> AnalyzeResponse {
        let list = LocalStorageManager.shared.loadHistory()
        guard let v = list.first(where: { $0.id == id }) else {
            throw APIClientError.server("Variant not found.")
        }
        let result = v.analysisFeedback
        return AnalyzeResponse(
            success: true,
            variantId: v.id,
            score: v.atsScore,
            matchedKeywords: result.matchedKeywords,
            missingKeywords: result.missingKeywords,
            weakBullets: result.weakBullets,
            bulletsWithoutMeasurableImpact: result.bulletsWithoutMeasurableImpact,
            formattingWarnings: result.formattingWarnings,
            componentScores: result.componentScores,
            analysisStatus: "complete",
            aiModelName: "Llama 3.2 1B (On-Device)",
            bulletCount: result.bulletCount,
            keywordCoverage: result.keywordCoverage,
            sections: result.sections
        )
    }

    func acceptRewrite(variantId: UUID, originalBullet: String, rewrittenBullet: String, token: String) async throws -> AcceptRewriteResponse {
        var list = LocalStorageManager.shared.loadHistory()
        guard var v = list.first(where: { $0.id == variantId }) else {
            throw APIClientError.server("Variant not found.")
        }
        
        let text = v.tailoredContent
        guard text.contains(originalBullet) else {
            throw APIClientError.server("Original bullet not found in resume.")
        }
        
        let updatedText = text.replacingOccurrences(of: originalBullet, with: rewrittenBullet)
        v.tailoredContent = updatedText
        
        // Re-analyze with the new text to update score
        let result = ATSScoringService.analyzeResume(resumeText: updatedText, jobDescription: v.analysisFeedback.jdKeywords.joined(separator: " "))
        v.atsScore = result.score
        v.analysisFeedback = result
        v.updatedAt = Date()
        
        LocalStorageManager.shared.saveVariant(v)
        
        return AcceptRewriteResponse(success: true, variantId: v.id, updatedResumeText: updatedText)
    }

    func exportVariant(id: UUID, token: String) async throws -> URL {
        let list = LocalStorageManager.shared.loadHistory()
        guard let v = list.first(where: { $0.id == id }) else {
            throw APIClientError.server("Variant not found.")
        }
        
        let text = v.tailoredContent
        let pdfData = PDFExportService.generateATSPDF(textContent: text)
        
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("rezumate-\(id.uuidString).pdf")
        try pdfData.write(to: outputURL, options: .atomic)
        return outputURL
    }
}
