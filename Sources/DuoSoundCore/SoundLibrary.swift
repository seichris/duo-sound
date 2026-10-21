import Foundation

public struct SoundRecording: Decodable, Sendable {
    public let id, title, detail, creator: String
    public let duration: Double
    public let file: String
}

/// One offline playback path for procedural presets and bundled CC0 recordings.
/// A recording is deliberately unchanged between directions; each selector is
/// independent. Original procedural presets retain their two distinct renders.
public enum SoundLibrary {
    private struct Manifest: Decodable { let assets: [SoundRecording] }

    private static var bundle: Bundle {
        #if SWIFT_PACKAGE
        return .module
        #else
        return .main
        #endif
    }

    private static func resource(_ name: String, extension ext: String) -> URL? {
        bundle.url(forResource: name, withExtension: ext, subdirectory: "RecordedSounds")
    }

    public static let recordings: [SoundRecording] = {
        guard let url = resource("manifest", extension: "json"),
              let data = try? Data(contentsOf: url),
              let manifest = try? JSONDecoder().decode(Manifest.self, from: data) else { return [] }
        return manifest.assets
    }()

    public static func recording(for preset: SoundPreset) -> SoundRecording? {
        recordings.first { $0.id == preset.rawValue }
    }

    public static func wav(preset: SoundPreset, event: FoldEvent) -> Data? {
        guard preset.isRecorded else { return SoundSynthesizer.wav(preset: preset, event: event) }
        guard let recording = recording(for: preset), recording.file == preset.rawValue + ".wav",
              let url = resource(preset.rawValue, extension: "wav") else { return nil }
        return try? Data(contentsOf: url, options: .mappedIfSafe)
    }

    public static var credits: String? {
        guard let url = resource("CREDITS", extension: "txt") else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }
}
