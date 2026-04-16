import Foundation
import AppKit
import CoreText

actor ConversionEngine {
    static let shared = ConversionEngine()

    enum ConversionError: LocalizedError {
        case noInputFiles
        case unsupportedInput(URL)
        case failedToCreatePDFContext(URL)
        case invalidTextEncoding(URL)

        var errorDescription: String? {
            switch self {
            case .noInputFiles:
                return "No input files were provided."
            case .unsupportedInput(let url):
                return "Unsupported input file: \(url.lastPathComponent). Only .vtt files are supported."
            case .failedToCreatePDFContext(let url):
                return "Could not create PDF at \(url.path)."
            case .invalidTextEncoding(let url):
                return "Unable to read \(url.lastPathComponent) as UTF-8 text."
            }
        }
    }

    private init() {}

    func convert(_ inputURL: URL, removeMetadata: Bool = true) async throws -> URL {
        try await convert([inputURL], removeMetadata: removeMetadata)
    }

    func convert(_ inputURLs: [URL], removeMetadata: Bool = true) async throws -> URL {
        let sources = inputURLs.sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
        guard !sources.isEmpty else {
            throw ConversionError.noInputFiles
        }

        for url in sources where url.pathExtension.lowercased() != "vtt" {
            throw ConversionError.unsupportedInput(url)
        }

        let outputURL = sources[0].deletingPathExtension().appendingPathExtension("pdf")
        let payloads = try sources.map { try makePayload(for: $0, removeMetadata: removeMetadata) }

        try createPDF(payloads: payloads, at: outputURL)
        return outputURL
    }

    private func makePayload(for inputURL: URL, removeMetadata: Bool) throws -> (title: String, body: String) {
        guard let raw = try String(contentsOf: inputURL, encoding: .utf8) as String? else {
            throw ConversionError.invalidTextEncoding(inputURL)
        }

        let body = removeMetadata ? stripMetadata(fromVTT: raw) : normalizePlainVTT(raw)
        let title = inputURL.deletingPathExtension().lastPathComponent
        return (title: title, body: body)
    }

    private func normalizePlainVTT(_ content: String) -> String {
        content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func stripMetadata(fromVTT content: String) -> String {
        let normalized = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let tagRegex = try? NSRegularExpression(pattern: "<[^>]+>")

        var cleanedLines: [String] = []
        var previousWasBlank = false

        for originalLine in normalized.components(separatedBy: "\n") {
            var line = originalLine.trimmingCharacters(in: .whitespaces)

            if line.isEmpty {
                if !previousWasBlank {
                    cleanedLines.append("")
                }
                previousWasBlank = true
                continue
            }

            if line == "WEBVTT" || line.allSatisfy(\.isNumber) || line.contains("-->") {
                continue
            }

            if let tagRegex {
                let range = NSRange(location: 0, length: (line as NSString).length)
                line = tagRegex.stringByReplacingMatches(in: line, range: range, withTemplate: "")
            }

            line = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !line.isEmpty {
                cleanedLines.append(line)
                previousWasBlank = false
            }
        }

        return cleanedLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func createPDF(payloads: [(title: String, body: String)], at outputURL: URL) throws {
        guard let context = CGContext(outputURL as CFURL, mediaBox: nil, nil) else {
            throw ConversionError.failedToCreatePDFContext(outputURL)
        }

        defer { context.closePDF() }

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let margin: CGFloat = 54
        let textRect = CGRect(
            x: margin,
            y: margin,
            width: pageRect.width - (margin * 2),
            height: pageRect.height - (margin * 2)
        )

        for payload in payloads {
            let composedText = "\(payload.title)\n\n\(payload.body.isEmpty ? "(No caption text found)" : payload.body)"
            drawTextPages(composedText, in: context, pageRect: pageRect, textRect: textRect)
        }
    }

    private func drawTextPages(_ text: String, in context: CGContext, pageRect: CGRect, textRect: CGRect) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        paragraphStyle.paragraphSpacing = 6

        let attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.black,
                .paragraphStyle: paragraphStyle
            ]
        )

        let framesetter = CTFramesetterCreateWithAttributedString(attributedText as CFAttributedString)
        var range = CFRange(location: 0, length: 0)
        let fullLength = attributedText.length

        while range.location < fullLength {
            context.beginPDFPage([kCGPDFContextMediaBox as String: pageRect] as CFDictionary)

            context.saveGState()
            context.textMatrix = .identity

            let path = CGMutablePath()
            path.addRect(textRect)
            let frame = CTFramesetterCreateFrame(framesetter, range, path, nil)
            CTFrameDraw(frame, context)

            let visibleRange = CTFrameGetVisibleStringRange(frame)
            range.location += visibleRange.length
            context.restoreGState()
            context.endPDFPage()
        }
    }

}
