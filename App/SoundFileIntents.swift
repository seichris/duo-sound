import AppIntents
import Foundation
import UniformTypeIdentifiers

private enum SoundFileIntentSupport {
    static func file(for event: FoldEvent) throws -> IntentFile {
        let sound = try SelectedSoundFile.load(for: event, from: SettingsStore.applicationSupport())
        let candidate = UTType(filenameExtension: (sound.filename as NSString).pathExtension)
        let type: UTType
        if let candidate, candidate.conforms(to: .audio) { type = candidate }
        else { type = .audio }
        // In-memory data lets the system own the transferred file's lifetime.
        // No background audio mode or app audio session is needed for this action.
        return IntentFile(data: sound.data, filename: sound.filename, type: type)
    }
}

struct GetOpeningSoundIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Opening Sound"
    static let description = IntentDescription("Get the selected opening audio file. Add Shortcuts’ Play Sound action next to play it without opening Hingy. Playback uses the shortcut’s volume.")
    static let openAppWhenRun = false
    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { .background }
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        .result(value: try SoundFileIntentSupport.file(for: .opened))
    }
}

struct GetClosingSoundIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Closing Sound"
    static let description = IntentDescription("Get the selected closing audio file. Add Shortcuts’ Play Sound action next to play it without opening Hingy. Playback uses the shortcut’s volume.")
    static let openAppWhenRun = false
    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { .background }
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        .result(value: try SoundFileIntentSupport.file(for: .closed))
    }
}

struct HingyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: GetOpeningSoundIntent(),
                    phrases: ["Get the opening sound from \(.applicationName)"],
                    shortTitle: "Opening Sound", systemImageName: "waveform")
        AppShortcut(intent: GetClosingSoundIntent(),
                    phrases: ["Get the closing sound from \(.applicationName)"],
                    shortTitle: "Closing Sound", systemImageName: "waveform")
    }
}
