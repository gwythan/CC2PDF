import Testing
import Foundation
import PDFKit
@testable import CC2PDF

@Suite("ConversionEngine Tests")
struct ConversionEngineTests {
    @Test("Convert produces a PDF in source folder")
    func convertOutputHasPDFExtension() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)

        let source = tmp.appendingPathComponent("sample.vtt")
        try "WEBVTT\n\n1\n00:00:00.000 --> 00:00:02.000\n<b>Hello world</b>"
            .write(to: source, atomically: true, encoding: .utf8)

        let result = try await ConversionEngine.shared.convert(source)
        #expect(result.pathExtension == "pdf")
        #expect(result.deletingLastPathComponent() == source.deletingLastPathComponent())
        #expect(FileManager.default.fileExists(atPath: result.path))

        try? FileManager.default.removeItem(at: tmp)
    }

    @Test("Removing metadata strips timing and HTML tags")
    func removingMetadataStripsTagsAndTimestamps() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)

        let source = tmp.appendingPathComponent("meta.vtt")
        try "WEBVTT\n\n1\n00:00:00.000 --> 00:00:02.000\n<b>Hello world</b>"
            .write(to: source, atomically: true, encoding: .utf8)

        let output = try await ConversionEngine.shared.convert(source, removeMetadata: true)
        let pdf = try #require(PDFDocument(url: output))
        let text = pdf.string ?? ""

        #expect(text.contains("Hello world"))
        #expect(!text.contains("-->") )
        #expect(!text.contains("<b>"))

        try? FileManager.default.removeItem(at: tmp)
    }

    @Test("Multiple input files create multi-page PDF")
    func multipleFilesCreateMultipagePDF() async throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let docs = root.appendingPathComponent("Tests/VTT Documents")

        let sourceA = docs.appendingPathComponent("[SEQ2] UP00-3 About This Course.vtt")
        let sourceB = docs.appendingPathComponent("[SEQ3] UP00-3 About This Course.vtt")

        let output = try await ConversionEngine.shared.convert([sourceA, sourceB], removeMetadata: true)
        let pdf = try #require(PDFDocument(url: output))
        #expect(pdf.pageCount >= 2)

        try? FileManager.default.removeItem(at: output)
    }
}
