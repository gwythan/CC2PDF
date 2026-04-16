import Testing
import Foundation
@testable import CC2PDF

@Suite("ConversionEngine Tests")
struct ConversionEngineTests {
    @Test("Convert produces a URL with .pdf extension")
    func convertOutputHasPDFExtension() async throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("txt")
        try "hello".write(to: tmp, atomically: true, encoding: .utf8)

        let result = try await ConversionEngine.shared.convert(tmp)
        #expect(result.pathExtension == "pdf")

        try? FileManager.default.removeItem(at: tmp)
        try? FileManager.default.removeItem(at: result)
    }
}
