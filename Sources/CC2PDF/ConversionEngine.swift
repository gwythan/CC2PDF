import Foundation

actor ConversionEngine {
    static let shared = ConversionEngine()

    private init() {}

    func convert(_ inputURL: URL) async throws -> URL {
        let outputURL = inputURL
            .deletingPathExtension()
            .appendingPathExtension("pdf")

        // Placeholder: implement format-specific conversion logic here.
        // For now this is a stub that copies the file as-is.
        let data = try Data(contentsOf: inputURL)
        try data.write(to: outputURL)

        return outputURL
    }
}
