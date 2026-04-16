import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    private static let supportedTypes: [UTType] = [UTType(filenameExtension: "vtt") ?? .plainText, .plainText]

    @State private var inputURLs: [URL] = []
    @State private var outputURL: URL?
    @State private var removeMetadata = true
    @State private var isConverting = false
    @State private var conversionMessage: String?
    @State private var isShowingFilePicker = false
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 18) {
            Text("CC2PDF")
                .font(.system(size: 40, weight: .bold, design: .rounded))

            Text("Drop one or more .vtt files below, then click Convert.")
                .foregroundStyle(.secondary)

            GroupBox("Source VTT Files") {
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isDropTargeted ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.35),
                                            style: StrokeStyle(lineWidth: 1.5, dash: [8, 6]))
                            )
                        VStack(spacing: 6) {
                            Text("Drag files here")
                                .font(.headline)
                            Text("Supports single-file conversion or multi-file merged PDF")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: 132)

                    if inputURLs.isEmpty {
                        Text("No files selected")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(inputURLs, id: \.self) { url in
                                    Text(url.lastPathComponent)
                                        .font(.callout)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .frame(maxHeight: 110)
                    }

                    HStack {
                        Button("Choose…") {
                            isShowingFilePicker = true
                        }
                        Spacer()
                        Button("Clear") {
                            inputURLs = []
                            conversionMessage = nil
                            outputURL = nil
                        }
                        .disabled(inputURLs.isEmpty)
                    }
                }
                .padding(6)
            }

            Toggle("Remove metadata (sequence, timestamps, and formatting tags)", isOn: $removeMetadata)
                .toggleStyle(.checkbox)

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
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: convert) {
                if isConverting {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Convert")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(inputURLs.isEmpty || isConverting)
        }
        .padding(28)
        .dropDestination(for: URL.self, action: { droppedURLs, _ in
            handleNewURLs(droppedURLs)
            return true
        }, isTargeted: { isTargeted in
            isDropTargeted = isTargeted
        })
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: Self.supportedTypes,
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                handleNewURLs(urls)
            case .failure(let error):
                conversionMessage = "Error selecting file: \(error.localizedDescription)"
            }
        }
    }

    private func handleNewURLs(_ urls: [URL]) {
        let vttURLs = urls.filter { $0.pathExtension.lowercased() == "vtt" }
        guard !vttURLs.isEmpty else {
            conversionMessage = "Error: only .vtt files are supported."
            return
        }

        inputURLs = vttURLs.sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
        conversionMessage = nil
        outputURL = nil
    }

    private func convert() {
        guard !inputURLs.isEmpty else { return }
        isConverting = true
        conversionMessage = nil
        let sourceURLs = inputURLs
        let shouldRemoveMetadata = removeMetadata

        Task {
            do {
                let result = try await ConversionEngine.shared.convert(
                    sourceURLs,
                    removeMetadata: shouldRemoveMetadata
                )
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
