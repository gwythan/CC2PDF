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

    @Test("Rendered line order is top-to-bottom")
    func renderedLineOrderIsTopToBottom() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)

        let source = tmp.appendingPathComponent("order.vtt")
        let vtt = """
        WEBVTT

        1
        00:00:00.000 --> 00:00:01.000
        first line

        2
        00:00:01.000 --> 00:00:02.000
        second line

        3
        00:00:02.000 --> 00:00:03.000
        third line
        """
        try vtt.write(to: source, atomically: true, encoding: .utf8)

        let output = try await ConversionEngine.shared.convert(source, removeMetadata: true)
        let pdf = try #require(PDFDocument(url: output))
        let page = try #require(pdf.page(at: 0))

        let firstMatches = pdf.findString("first line", withOptions: [])
        let thirdMatches = pdf.findString("third line", withOptions: [])
        #expect(!firstMatches.isEmpty)
        #expect(!thirdMatches.isEmpty)

        let firstSelection = try #require(firstMatches.first)
        let thirdSelection = try #require(thirdMatches.first)

        let firstBounds = firstSelection.bounds(for: page)
        let thirdBounds = thirdSelection.bounds(for: page)

        #expect(firstBounds.minY > thirdBounds.minY)

        try? FileManager.default.removeItem(at: tmp)
    }

    @Test("Rendered text is not mirrored horizontally")
    func renderedTextIsNotMirroredHorizontally() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)

        let source = tmp.appendingPathComponent("mirror.vtt")
        let vtt = """
        WEBVTT

        1
        00:00:00.000 --> 00:00:01.000
        left right
        """
        try vtt.write(to: source, atomically: true, encoding: .utf8)

        let output = try await ConversionEngine.shared.convert(source, removeMetadata: true)
        let pdf = try #require(PDFDocument(url: output))
        let page = try #require(pdf.page(at: 0))

        let leftMatches = pdf.findString("left", withOptions: [])
        let rightMatches = pdf.findString("right", withOptions: [])
        #expect(!leftMatches.isEmpty)
        #expect(!rightMatches.isEmpty)

        let leftSelection = try #require(leftMatches.first)
        let rightSelection = try #require(rightMatches.first)

        let leftBounds = leftSelection.bounds(for: page)
        let rightBounds = rightSelection.bounds(for: page)

        #expect(leftBounds.midX < rightBounds.midX)

        try? FileManager.default.removeItem(at: tmp)
    }
}
