import Foundation
import Compression

struct DocxTextExtractor {
    static func extractText(from data: Data) -> ExtractionResult {
        var warnings: [String] = []
        
        guard let (fileBytes, compressionMethod, uncompressedSize) = findDocumentXml(in: data) else {
            return ExtractionResult(
                text: "",
                status: "failed",
                warnings: ["Could not read this DOCX file. Please ensure it is a valid Word document."],
                pageCount: 0,
                characterCount: 0
            )
        }
        
        var xmlData: Data? = nil
        if compressionMethod == 0 { // Stored (uncompressed)
            xmlData = fileBytes
        } else if compressionMethod == 8 { // Deflate
            xmlData = decompressDeflate(compressedData: fileBytes, uncompressedSize: uncompressedSize)
        } else {
            warnings.append("Unsupported compression method (\(compressionMethod)) in DOCX file.")
        }
        
        guard let xml = xmlData else {
            return ExtractionResult(
                text: "",
                status: "failed",
                warnings: ["Could not decompress DOCX contents. File might be corrupted."],
                pageCount: 0,
                characterCount: 0
            )
        }
        
        let parser = XMLParser(data: xml)
        let delegate = DocxXMLParserDelegate()
        parser.delegate = delegate
        
        if parser.parse() {
            let text = PDFTextExtractor.normalizeResumeText(delegate.paragraphs.joined(separator: "\n\n"))
            return PDFTextExtractor.evaluateExtractedText(text, warnings: warnings, pageCount: 0)
        } else {
            return ExtractionResult(
                text: "",
                status: "failed",
                warnings: ["Could not parse the DOCX XML structure."],
                pageCount: 0,
                characterCount: 0
            )
        }
    }
    
    private static func findDocumentXml(in data: Data) -> (Data, UInt16, Int)? {
        guard let eocdIdx = findEOCD(in: data) else { return nil }
        
        let cdOffset = Int(readUInt32(from: data, offset: eocdIdx + 16))
        let totalRecords = Int(readUInt16(from: data, offset: eocdIdx + 8))
        
        var currentOffset = cdOffset
        for _ in 0..<totalRecords {
            if currentOffset + 46 > data.count { break }
            let signature = readUInt32(from: data, offset: currentOffset)
            if signature != 0x02014B50 { break }
            
            let compressionMethod = readUInt16(from: data, offset: currentOffset + 10)
            let compressedSize = Int(readUInt32(from: data, offset: currentOffset + 20))
            let uncompressedSize = Int(readUInt32(from: data, offset: currentOffset + 24))
            let fileNameLen = Int(readUInt16(from: data, offset: currentOffset + 28))
            let extraFieldLen = Int(readUInt16(from: data, offset: currentOffset + 30))
            let fileCommentLen = Int(readUInt16(from: data, offset: currentOffset + 32))
            let localHeaderOffset = Int(readUInt32(from: data, offset: currentOffset + 42))
            
            let nameOffset = currentOffset + 46
            if nameOffset + fileNameLen > data.count { break }
            let nameData = data.subdata(in: nameOffset..<(nameOffset + fileNameLen))
            
            if let filename = String(data: nameData, encoding: .utf8), filename == "word/document.xml" {
                if localHeaderOffset + 30 <= data.count {
                    let localFilenameLen = Int(readUInt16(from: data, offset: localHeaderOffset + 26))
                    let localExtraFieldLen = Int(readUInt16(from: data, offset: localHeaderOffset + 28))
                    let dataStart = localHeaderOffset + 30 + localFilenameLen + localExtraFieldLen
                    if dataStart + compressedSize <= data.count {
                        let fileBytes = data.subdata(in: dataStart..<(dataStart + compressedSize))
                        return (fileBytes, compressionMethod, uncompressedSize)
                    }
                }
            }
            
            currentOffset += 46 + fileNameLen + extraFieldLen + fileCommentLen
        }
        
        return nil
    }
    
    private static func findEOCD(in data: Data) -> Int? {
        let size = data.count
        if size < 22 { return nil }
        
        let maxScan = min(size, 65535 + 22)
        for offset in 22...maxScan {
            let idx = size - offset
            if data[idx] == 0x50 && data[idx+1] == 0x4B && data[idx+2] == 0x05 && data[idx+3] == 0x06 {
                return idx
            }
        }
        return nil
    }
    
    private static func readUInt32(from data: Data, offset: Int) -> UInt32 {
        var val: UInt32 = 0
        _ = withUnsafeMutableBytes(of: &val) { buffer in
            data.copyBytes(to: buffer, from: offset..<(offset + 4))
        }
        return val
    }
    
    private static func readUInt16(from data: Data, offset: Int) -> UInt16 {
        var val: UInt16 = 0
        _ = withUnsafeMutableBytes(of: &val) { buffer in
            data.copyBytes(to: buffer, from: offset..<(offset + 2))
        }
        return val
    }
    
    private static func decompressDeflate(compressedData: Data, uncompressedSize: Int) -> Data? {
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: uncompressedSize)
        defer { destinationBuffer.deallocate() }
        
        return compressedData.withUnsafeBytes { (sourceBuffer: UnsafeRawBufferPointer) -> Data? in
            guard let sourceAddress = sourceBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return nil }
            
            let decodedSize = compression_decode_buffer(
                destinationBuffer,
                uncompressedSize,
                sourceAddress,
                compressedData.count,
                nil,
                COMPRESSION_ZLIB
            )
            
            if decodedSize == uncompressedSize {
                return Data(bytes: destinationBuffer, count: uncompressedSize)
            }
            return nil
        }
    }
}

class DocxXMLParserDelegate: NSObject, XMLParserDelegate {
    var paragraphs: [String] = []
    private var currentParagraph = ""
    private var isInsideText = false
    private var textBuffer = ""
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "w:t" {
            isInsideText = true
            textBuffer = ""
        } else if elementName == "w:p" {
            currentParagraph = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if isInsideText {
            textBuffer += string
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "w:t" {
            isInsideText = false
            currentParagraph += textBuffer
        } else if elementName == "w:p" {
            let trimmed = currentParagraph.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                paragraphs.append(trimmed)
            }
        }
    }
}
