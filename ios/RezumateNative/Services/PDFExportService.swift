import UIKit

struct PDFExportService {
    static func generateATSPDF(textContent: String) -> Data {
        let pdfMetaData = [
            kCGPDFContextTitle as String: "Tailored Resume",
            kCGPDFContextCreator as String: "Rezumate iOS"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String : Any]
        
        // Standard US Letter page size: 8.5 x 11 inches = 612 x 792 points
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 54 // 0.75 inch margins
        
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let printableWidth = pageWidth - (2 * margin)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        let lines = textContent.components(separatedBy: .newlines)
        
        let fontNormal = UIFont.systemFont(ofSize: 10.5)
        let fontHeader = UIFont.boldSystemFont(ofSize: 13.0)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2.5
        paragraphStyle.alignment = .left
        
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: fontNormal,
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraphStyle
        ]
        
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: fontHeader,
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraphStyle
        ]
        
        let data = renderer.writePDF { context in
            context.beginPage()
            var currentY = margin
            
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    currentY += 8 // Spacer
                    continue
                }
                
                let isUpper = trimmed == trimmed.uppercased() && trimmed.rangeOfCharacter(from: CharacterSet.letters) != nil
                let isHeader = trimmed.count < 40 && (isUpper || trimmed.hasSuffix(":"))
                
                let attrs = isHeader ? headerAttributes : normalAttributes
                let attributedString = NSAttributedString(string: trimmed, attributes: attrs)
                
                let constraintSize = CGSize(width: printableWidth, height: CGFloat.greatestFiniteMagnitude)
                let textHeight = attributedString.boundingRect(with: constraintSize, options: .usesLineFragmentOrigin, context: nil).height
                
                // Page overflow check
                if currentY + textHeight > pageHeight - margin {
                    context.beginPage()
                    currentY = margin
                }
                
                let textRect = CGRect(x: margin, y: currentY, width: printableWidth, height: textHeight)
                attributedString.draw(in: textRect)
                
                currentY += textHeight + (isHeader ? 5 : 3.5)
            }
        }
        
        return data
    }
}
