import SwiftUI
import AppKit

@main
struct CC2PDFApp: App {
    init() {
        NSApplication.shared.applicationIconImage = AppIconFactory.makeIcon()
    }

    var body: some Scene {
        Window("CC2PDF", id: "main") {
            ContentView()
                .frame(minWidth: 620, minHeight: 460)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
