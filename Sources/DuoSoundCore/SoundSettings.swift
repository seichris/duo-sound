import Foundation

/// Stable categories for browsing, not persisted selection identifiers.
public enum SoundCategory: String, CaseIterable, Sendable {
    case musical, mechanical, nature, playful, scienceFiction

    public var title: String {
        switch self {
        case .scienceFiction: return "Sci-Fi"
        default: return rawValue.capitalized
        }
    }
}

public enum SoundPreset: String, Codable, CaseIterable, Sendable {
    // Keep existing raw values and defaults stable for previously saved settings.
    case chime, paper, arcade, orbit, click
    case crystal, marimba, musicBox, zipper, latch, typewriter
    case waterDrop, bird, rain, bubble, spring, cork, laser, robot, powerUp
    case off, custom

    public var title: String {
        switch self {
        case .musicBox: return "Music Box"
        case .waterDrop: return "Water Drop"
        case .powerUp: return "Power Up / Down"
        default: return rawValue.capitalized
        }
    }

    public var category: SoundCategory? {
        switch self {
        case .chime, .crystal, .marimba, .musicBox: return .musical
        case .paper, .click, .zipper, .latch, .typewriter: return .mechanical
        case .waterDrop, .bird, .rain: return .nature
        case .arcade, .bubble, .spring, .cork: return .playful
        case .orbit, .laser, .robot, .powerUp: return .scienceFiction
        case .off, .custom: return nil
        }
    }

    public var detail: String {
        switch self {
        case .chime: return "A soft three-note welcome or goodbye."
        case .paper: return "A dry paper crinkle."
        case .arcade: return "Retro notes climbing or falling."
        case .orbit: return "An airy electronic sweep."
        case .click: return "A tiny, crisp tap."
        case .crystal: return "Bright, shimmering glass bells."
        case .marimba: return "Two warm wooden notes."
        case .musicBox: return "A delicate, sparkling melody."
        case .zipper: return "A quick, textured zip or unzip."
        case .latch: return "A metal release and a solid catch."
        case .typewriter: return "A short flurry of mechanical keys."
        case .waterDrop: return "Rounded, rippling water drops."
        case .bird: return "Two small, clear chirps."
        case .rain: return "A soft shower with scattered droplets."
        case .bubble: return "Playful, rising or falling bubble pops."
        case .spring: return "A wobbly, elastic boing."
        case .cork: return "A hollow pop and a snug little thump."
        case .laser: return "A bright sci-fi zap."
        case .robot: return "A tiny robot greeting or farewell."
        case .powerUp: return "An ascending startup or descending shutdown."
        case .off: return "No sound for this direction."
        case .custom: return "Your imported audio clip."
        }
    }

    /// Every generated clip is deliberately short. Legacy durations stay intact.
    public var duration: Double? {
        switch self {
        case .chime, .paper, .arcade, .orbit: return 0.42
        case .click: return 0.13
        case .crystal: return 0.65
        case .marimba: return 0.50
        case .musicBox: return 0.72
        case .zipper: return 0.34
        case .latch: return 0.24
        case .typewriter: return 0.26
        case .waterDrop: return 0.46
        case .bird: return 0.56
        case .rain: return 0.60
        case .bubble: return 0.34
        case .spring: return 0.60
        case .cork: return 0.22
        case .laser: return 0.40
        case .robot: return 0.50
        case .powerUp: return 0.70
        case .off, .custom: return nil
        }
    }

    public static var builtIns: [Self] { allCases.filter { $0.category != nil } }
    public static func presets(in category: SoundCategory) -> [Self] {
        builtIns.filter { $0.category == category }
    }
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
