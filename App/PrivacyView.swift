import SwiftUI

@MainActor
struct PrivacyView: View {
    private var summary: String {
        guard let url = Bundle.main.url(forResource: "PrivacySummary", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return "The local privacy summary could not be loaded. Please use the full privacy policy link."
        }
        return text
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(summary).textSelection(.enabled).accessibilityIdentifier("privacySummary")
                Link("Full privacy policy", destination: Self.link("DuoPrivacyURL",
                    fallback: "https://github.com/seichris/duo-sound/blob/main/docs/PRIVACY.md"))
                Link("Contact support", destination: Self.link("DuoSupportURL",
                    fallback: "https://github.com/seichris/duo-sound/issues"))
            }.padding()
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
    static func link(_ key: String, fallback: String) -> URL {
        if let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String,
           let url = URL(string: raw), url.scheme == "https", url.host != nil { return url }
        // Both fallback literals are repository-owned public HTTPS URLs.
        return URL(string: fallback)!
    }
}

@MainActor
struct SoundHelpView: View {
    var body: some View {
        Form {
            Section("No sound?") {
                Text("Turn off Silent Mode, check system and effect volume, and check whether audio is routed to headphones or Bluetooth. Select a sound other than Off, then tap Preview.")
            }
            Section("When fold effects work") {
                Text("Hingy must be visible and active. The default preview simulates the hinge; it does not detect a physical fold. Hardware support requires a validated Duo SDK build. Locking or switching apps stops observation and cancels pending effects.")
            }
            Section("Importing audio") {
                Text("Choose Import for opening or closing, then select an unprotected audio file in Files. Use a playable clip up to 5 seconds and 8 MiB (8,388,608 bytes). Failed imports leave the previous selection unchanged. Use only audio you have permission to use.")
            }
            Section("Missing imported file?") {
                Text("Import the clip again or choose an original preset. Deleting the app removes local settings and imported copies. Offloading may retain them, and backups are managed separately in iOS.")
            }
            Section {
                Link("Contact support", destination: PrivacyView.link("DuoSupportURL",
                    fallback: "https://github.com/seichris/duo-sound/issues"))
                Text("Project issues are public. Never post private audio, credentials, or personal information.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Sound help")
    }
}
