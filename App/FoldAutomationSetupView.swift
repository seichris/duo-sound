import SwiftUI
import UIKit

private struct FoldShortcutPack: Decodable {
    let opening: URL
    let closing: URL
    let includesFoldTriggers: Bool

    static let bundled: Self? = {
        guard let url = Bundle.main.url(forResource: "Install", withExtension: "json", subdirectory: "FoldShortcuts"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Self.self, from: data)
    }()

    static let files = FoldEvent.allCases.compactMap { event in
        Bundle.main.url(forResource: "Hingy \(event.title) Sound", withExtension: "shortcut", subdirectory: "FoldShortcuts")
    }
}

@MainActor
struct FoldAutomationSetupView: View {
    @State private var saveFiles = false

    var body: some View {
        Form {
            if let pack = FoldShortcutPack.bundled {
                Section {
                    Link("Add opening shortcut", destination: pack.opening)
                        .accessibilityIdentifier("addOpeningShortcut")
                    Link("Add closing shortcut", destination: pack.closing)
                        .accessibilityIdentifier("addClosingShortcut")
                } header: {
                    Text("Add both shortcuts")
                } footer: {
                    Text("Open each link and tap Add Shortcut in Shortcuts. Each uses the sound you currently have selected in Hingy.")
                }
                Section("Turn on fold sounds") {
                    if pack.includesFoldTriggers {
                        Text("On iPhone Duo with iOS 27.2 or later, open each added shortcut and turn on its fold automation. The opening and closing triggers are already set.")
                    } else {
                        Text("On iPhone Duo with iOS 27.2 or later, edit Hingy Opening Sound in Shortcuts. Choose Edit → Automation → Opened or Closed, then select Opened.")
                        Text("Repeat for Hingy Closing Sound and select Closed.")
                    }
                    Text("Run each shortcut once while unlocked to grant any requested access and check the sound.")
                }
                if FoldShortcutPack.files.count == FoldEvent.allCases.count {
                    Section {
                        Button("Save both shortcut files…") { saveFiles = true }
                            .accessibilityIdentifier("saveBothShortcuts")
                    } footer: {
                        Text("You can also save both to Files. Tap each file there to add it to Shortcuts.")
                    }
                }
            } else {
                Section {
                    Text("The shortcut downloads are unavailable. In Shortcuts, create one shortcut with Get Opening Sound followed by Play Sound and another with Get Closing Sound followed by Play Sound.")
                }
            }
            Section("Playback") {
                Text("Shortcuts plays the audio at system volume, including clips you import. If you hear a sound twice while Hingy is open, turn off Enable fold sounds in Hingy.")
                Text("To use a shortcut while locked, check its privacy settings in Shortcuts. Some audio files require unlocking.")
            }
        }
        .navigationTitle("Sounds in other apps")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $saveFiles) { ShortcutFileExporter(files: FoldShortcutPack.files) }
    }
}

private struct ShortcutFileExporter: UIViewControllerRepresentable {
    let files: [URL]

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        UIDocumentPickerViewController(forExporting: files, asCopy: true)
    }

    func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) {}
}
