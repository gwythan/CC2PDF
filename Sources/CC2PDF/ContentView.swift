import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var inputURL: URL?
    @State private var outputURL: URL?
    @State private var isConverting = false
    @State private var conversionMessage: String?
    @State private var isShowingFilePicker = false

    var body: some View {
        VStack(spacing: 24) {
            Text("CC2PDF")
                .font(.largeTitle)
                .fontWeight(.bold)

            GroupBox("Input File") {
                HStack {
                    Text(inputURL?.lastPathComponent ?? "No file selected")
                        .foregroundStyle(inputURL == nil ? .secondary : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button("Choose…") {
                        isShowingFilePicker = true
                    }
                }
                .padding(4)
            }

            if let outputURL {
                GroupBox("Output") {
                    Text(outputURL.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(4)
                }
            }

            if let message = conversionMessage {
                Text(message)
                    .foregroundStyle(message.hasPrefix("Error") ? .red : .green)
                    .font(.callout)
            }

            Button(action: convert) {
                if isConverting {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Convert to PDF")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(inputURL == nil || isConverting)
        }
        .padding(32)
        .frame(minWidth: 420, minHeight: 300)
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                inputURL = urls.first
                conversionMessage = nil
                outputURL = nil
            case .failure(let error):
                conversionMessage = "Error selecting file: \(error.localizedDescription)"
            }
        }
    }

    private func convert() {
        guard let inputURL else { return }
        isConverting = true
        conversionMessage = nil

        Task {
            do {
                let result = try await ConversionEngine.shared.convert(inputURL)
                await MainActor.run {
                    outputURL = result
                    conversionMessage = "Conversion complete."
                    isConverting = false
                }
            } catch {
                await MainActor.run {
                    conversionMessage = "Error: \(error.localizedDescription)"
                    isConverting = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
