import Foundation

public enum SoundPreset: String, Codable, CaseIterable, Sendable {
    case chime, paper, arcade, orbit, click, off, custom
    public var title: String { rawValue.capitalized }
    public static var builtIns: [Self] { [.chime, .paper, .arcade, .orbit, .click] }
}

public struct ImportedSound: Codable, Equatable, Sendable {
    public let fileName: String
    public let displayName: String
    public init(fileName: String, displayName: String) {
        self.fileName = fileName; self.displayName = displayName
    }
    public var isSafe: Bool {
        fileName.hasSuffix(".sound") && UUID(uuidString: String(fileName.dropLast(6))) != nil
            && !fileName.contains("/") && !fileName.contains("\\")
    }
}

public struct SoundSettings: Codable, Equatable, Sendable {
    public var enabled = true
    public var volume: Double = 0.65
    public var opening: SoundPreset = .chime
    public var closing: SoundPreset = .paper
    public var openingFile: ImportedSound?
    public var closingFile: ImportedSound?
    public init() {}
    public func preset(for event: FoldEvent) -> SoundPreset { event == .opened ? opening : closing }
    public func imported(for event: FoldEvent) -> ImportedSound? { event == .opened ? openingFile : closingFile }
    public mutating func select(_ preset: SoundPreset, for event: FoldEvent) {
        if event == .opened { opening = preset } else { closing = preset }
    }
    public mutating func setImported(_ sound: ImportedSound, for event: FoldEvent) {
        if event == .opened { openingFile = sound; opening = .custom }
        else { closingFile = sound; closing = .custom }
    }
    public func validated() throws -> Self {
        guard volume.isFinite, (0...1).contains(volume),
              openingFile.map(\.isSafe) ?? true, closingFile.map(\.isSafe) ?? true,
              opening != .custom || openingFile != nil,
              closing != .custom || closingFile != nil else { throw SoundFailure.invalidSettings }
        return self
    }
}

public enum SoundFailure: LocalizedError {
    case invalidSettings, tooLarge, invalidAudio, missingSound, playbackFailed
    public var errorDescription: String? {
        switch self {
        case .invalidSettings: return "Saved settings are invalid. Your files have not been deleted."
        case .tooLarge: return "Choose an audio file smaller than 8 MB."
        case .invalidAudio: return "Choose a playable, unprotected audio clip between 0 and 5 seconds."
        case .missingSound: return "The custom sound is missing. Import it again or choose a built-in sound."
        case .playbackFailed: return "Audio could not start. Check the audio output and try the preview again."
        }
    }
}

/// Private, atomic JSON storage. No UserDefaults, analytics or cloud services.
public struct SettingsStore: Sendable {
    public let directory: URL
    public var settingsURL: URL { directory.appendingPathComponent("settings.json") }
    public init(directory: URL) { self.directory = directory }
    public func load() throws -> SoundSettings {
        guard FileManager.default.fileExists(atPath: settingsURL.path) else { return SoundSettings() }
        let data = try Self.readBounded(settingsURL, limit: 65_536)
        return try JSONDecoder().decode(SoundSettings.self, from: data).validated()
    }
    public func save(_ settings: SoundSettings) throws {
        let valid = try settings.validated()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(valid).write(to: settingsURL, options: .atomic)
    }
    public func soundURL(for record: ImportedSound) throws -> URL {
        guard record.isSafe else { throw SoundFailure.invalidSettings }
        return directory.appendingPathComponent(record.fileName)
    }
    public static func readBounded(_ url: URL, limit: Int) throws -> Data {
        precondition(limit > 0 && limit < Int.max)
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var result = Data()
        while result.count <= limit {
            guard let chunk = try handle.read(upToCount: min(65_536, limit + 1 - result.count)),
                  !chunk.isEmpty else { return result }
            result.append(chunk)
        }
        throw SoundFailure.tooLarge
    }
}
