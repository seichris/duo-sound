import Foundation

/// A snapshot of the current selection for a system-owned audio consumer.
/// It deliberately has no player, audio session, or foreground lifecycle.
public struct SelectedSoundFile: Sendable {
    public let data: Data
    public let filename: String

    public static func load(for event: FoldEvent, from store: SettingsStore) throws -> Self {
        // Read atomically saved settings for each invocation, including a cold
        // background launch. Never instantiate the foreground AppModel here.
        let settings = try store.load()
        let preset = settings.preset(for: event)
        guard preset != .off else { throw SoundFailure.soundDisabled }
        let data: Data
        let ext: String
        if preset == .custom {
            guard let record = settings.imported(for: event) else { throw SoundFailure.missingSound }
            data = try SettingsStore.readBounded(store.soundURL(for: record), limit: 8 * 1_024 * 1_024)
            let candidate = (record.displayName as NSString).pathExtension.lowercased()
            // Use only the extension, never the imported filename or a path.
            let safe = !candidate.isEmpty && candidate.count <= 8 && candidate.utf8.allSatisfy {
                (97...122).contains($0) || (48...57).contains($0)
            }
            ext = safe ? candidate : "audio"
        } else {
            guard let rendered = SoundLibrary.wav(preset: preset, event: event) else {
                throw SoundFailure.missingBuiltIn
            }
            data = rendered
            ext = "wav"
        }
        guard !data.isEmpty else { throw SoundFailure.invalidAudio }
        // Export original bytes. The consuming shortcut owns playback volume;
        // the in-app effect-volume slider never changes an exported recording.
        return Self(data: data, filename: "Hingy-\(event.title).\(ext)")
    }
}
