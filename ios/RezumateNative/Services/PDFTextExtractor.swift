import Foundation
import PDFKit

struct ExtractionResult {
    let text: String
    let status: String
    let warnings: [String]
    let pageCount: Int
    let characterCount: Int
}

struct PDFTextExtractor {
    static func extractText(from data: Data) -> ExtractionResult {
        guard let provider = CGDataProvider(data: data as CFData),
              let pdfDoc = CGPDFDocument(provider) else {
            return ExtractionResult(
                text: "",
                status: "failed",
                warnings: ["Could not read this PDF. Try exporting it again or uploading a text-based PDF."],
                pageCount: 0,
                characterCount: 0
            )
        }
        
        let pageCount = pdfDoc.numberOfPages
        var textParts: [String] = []
        var warnings: [String] = []
        
        // Use PDFKit PDFDocument for higher-level text extraction
        if let document = PDFDocument(data: data) {
            for i in 0..<pageCount {
                if let page = document.page(at: i) {
                    let pageText = page.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    if !pageText.isEmpty {
                        textParts.append(pageText)
                    } else {
                        warnings.append("Page \(i + 1) did not contain extractable text.")
                    }
                }
            }
        }
        
        let extractedText = normalizeResumeText(textParts.joined(separator: "\n\n"))
        return evaluateExtractedText(extractedText, warnings: warnings, pageCount: pageCount)
    }
    
    static func normalizeResumeText(_ text: String) -> String {
        let lines = text.replacingOccurrences(of: "\r\n", with: "\n")
                        .replacingOccurrences(of: "\r", with: "\n")
                        .components(separatedBy: "\n")
        var normalizedLines: [String] = []
        var previousBlank = false
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleaned = trimmed.components(separatedBy: .whitespaces)
                                 .filter { !$0.isEmpty }
                                 .joined(separator: " ")
            
            let isBlank = cleaned.isEmpty
            if isBlank && previousBlank {
                continue
            }
            
            normalizedLines.append(cleaned)
            previousBlank = isBlank
        }
        
        return normalizedLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    static func evaluateExtractedText(_ text: String, warnings: [String], pageCount: Int) -> ExtractionResult {
        var mutableWarnings = warnings
        let characterCount = text.count
        let status: String
        
        if text.isEmpty {
            mutableWarnings.append("No extractable resume text was found.")
            status = "empty"
        } else if characterCount < 400 {
            mutableWarnings.append("Very little text was extracted, so the analysis may be incomplete.")
            status = "low_quality"
        } else {
            status = "ok"
        }
        
        if !text.isEmpty && text.components(separatedBy: "\n").count < 4 {
            mutableWarnings.append("The extracted text has very few line breaks, which can reduce section detection accuracy.")
        }
        
        return ExtractionResult(
            text: text,
            status: status,
            warnings: mutableWarnings,
            pageCount: pageCount,
            characterCount: characterCount
        )
    }
}
