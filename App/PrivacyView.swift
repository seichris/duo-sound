import SwiftUI

@MainActor
struct SoundCreditsView: View {
    var body: some View {
        ScrollView {
            Text(SoundLibrary.credits ?? "Sound credits could not be loaded.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled).padding()
                .accessibilityIdentifier("soundCreditsText")
        }
        .navigationTitle("Sound credits")
        .navigationBarTitleDisplayMode(.inline)
    }
}

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
                Text("Select a sound other than Off, then tap Preview. Previews play even in Silent Mode. Check system and effect volume and whether audio is routed to headphones or Bluetooth. Automatic fold sounds respect Silent Mode.")
            }
            Section("When fold effects work") {
                Text("On supported iPhone Duo hardware with iOS 27.1 or newer, Hingy observes the native hinge while visible and active. Other devices can preview sounds. Locking or switching apps stops observation and cancels pending automatic effects.")
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

@MainActor
struct SoundShortcutsHelpView: View {
    var body: some View {
        Form {
            Section("Create an opening shortcut") {
                Text("1. In Shortcuts, create a shortcut and add Hingy’s Get Opening Sound action.")
                Text("2. Add Play Sound next, using the audio file returned by Hingy as its input.")
                Text("3. Run it once to grant any requested access and check the volume and audio output.")
            }
            Section("Create a closing shortcut") {
                Text("Create a second shortcut using Get Closing Sound followed by Play Sound. Each run reads your current selection in Hingy, including an imported clip.")
            }
            Section("Choose an automation") {
                Text("If your Duo’s Shortcuts app offers an Opened or Closed device trigger, connect each event to the matching shortcut. If that trigger is absent, use an available trigger to test playback; Hingy cannot add a missing system trigger.")
                Text("To avoid duplicate sounds when Hingy is visible, turn off Enable fold sounds in Hingy while using a fold automation. The explicit Get Sound actions still work.")
                Text("Allow the shortcut to run automatically and enable Allow Running When Locked if your iOS version offers it. Other actions or protected files may still require unlocking. Test your complete automation on the intended phone.")
            }
            Section("Playback outside Hingy") {
                Text("Shortcuts owns playback, so Hingy does not need to stay visible or keep listening in the background. Fold-trigger availability, locked playback and timing must be tested on your device; native hinge observation runs while Hingy is visible and active.")
                Text("Use system volume or a volume action in Shortcuts. Hingy exports the original audio; its effect-volume slider applies only inside Hingy. A direction set to Off returns an explanation instead of playing another sound.")
            }
            Section("Audio access") {
                Text("Running these actions gives Shortcuts a copy of the selected sound, including a custom import. Your workflow controls whether that file is played, saved or shared. Hingy does not upload it or change file protection to bypass a locked device.")
            }
        }
        .navigationTitle("Sounds in Shortcuts")
        .navigationBarTitleDisplayMode(.inline)
    }
}
