import Foundation
import XCTest
@testable import DuoSoundCore

final class SoundLibraryTests: XCTestCase {
    func testRecordedResourcesAndCreditsAreAvailableOffline() throws {
        let recorded = SoundPreset.builtIns.filter(\.isRecorded)
        XCTAssertEqual(recorded.count, 26)
        XCTAssertEqual(Set(recorded.map(\.rawValue)), Set(SoundLibrary.recordings.map(\.id)))
        let credits = try XCTUnwrap(SoundLibrary.credits)
        for preset in recorded {
            XCTAssertTrue(credits.contains(preset.title))
            XCTAssertEqual(SoundLibrary.wav(preset: preset, event: .opened),
                           SoundLibrary.wav(preset: preset, event: .closed))
            XCTAssertNil(SoundSynthesizer.wav(preset: preset, event: .opened))
        }
        XCTAssertTrue(credits.contains("Kenney"))
        XCTAssertTrue(credits.contains("CC0 1.0"))
    }

    func testFartsAndKenneyEffectsCanPersistInEitherSelector() throws {
        let choices: [SoundPreset] = [.tinyFart, .squeaker, .woodKnock, .softOpen]
        for choice in choices {
            var settings = SoundSettings()
            settings.select(choice, for: .opened)
            settings.select(choice, for: .closed)
            let decoded = try JSONDecoder().decode(SoundSettings.self, from: JSONEncoder().encode(settings))
            XCTAssertEqual(try decoded.validated(), settings)
        }
    }

    func testEveryBuiltInAppearsExactlyOnceInTheBrowser() {
        let catalog = SoundCategory.allCases.flatMap(SoundPreset.presets(in:))
        XCTAssertEqual(SoundPreset.builtIns.count, 43)
        XCTAssertEqual(catalog.count, 43)
        XCTAssertEqual(Set(catalog), Set(SoundPreset.builtIns))
        XCTAssertFalse(catalog.contains(.off))
        XCTAssertFalse(catalog.contains(.custom))
        for category in SoundCategory.allCases { XCTAssertFalse(SoundPreset.presets(in: category).isEmpty) }
    }

    func testCatalogLabelsAreUniqueAndReadable() {
        XCTAssertEqual(Set(SoundPreset.builtIns.map(\.title)).count, 43)
        XCTAssertEqual(SoundPreset.musicBox.title, "Music Box")
        XCTAssertEqual(SoundPreset.waterDrop.title, "Water Drop")
        XCTAssertEqual(SoundPreset.powerUp.title, "Power Up / Down")
        for preset in SoundPreset.allCases { XCTAssertFalse(preset.detail.isEmpty) }
    }

    func testLegacySavedIDsAndDefaultsStillDecode() throws {
        for value in ["chime", "arcade", "orbit", "click", "off", "custom"] {
            let data = Data("\"\(value)\"".utf8)
            XCTAssertEqual(try JSONDecoder().decode(SoundPreset.self, from: data).rawValue, value)
        }
        let legacy = Data(#"{"enabled":true,"volume":0.65,"opening":"chime","closing":"paper"}"#.utf8)
        XCTAssertEqual(try JSONDecoder().decode(SoundSettings.self, from: legacy).validated(), SoundSettings())
        XCTAssertEqual(SoundSettings().opening, .chime)
        XCTAssertEqual(SoundSettings().closing, .click)
    }

    func testRetiredSoundsAreUnavailableAndSavedSelectionsMigrate() throws {
        for retired in ["paper", "zipper", "rain"] {
            XCTAssertNil(SoundPreset(rawValue: retired))
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: directory) }
            let store = SettingsStore(directory: directory)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let imported = ImportedSound(fileName: UUID().uuidString + ".sound", displayName: "My clip")
            var saved = SoundSettings()
            saved.volume = 0.35
            saved.enabled = false
            saved.openingFile = imported
            var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(saved)) as? [String: Any])
            json["opening"] = retired
            json["closing"] = retired
            try JSONSerialization.data(withJSONObject: json).write(to: store.settingsURL)

            let loaded = try store.load()
            XCTAssertEqual(loaded.opening, .click)
            XCTAssertEqual(loaded.closing, .click)
            XCTAssertEqual(loaded.volume, 0.35)
            XCTAssertFalse(loaded.enabled)
            XCTAssertEqual(loaded.openingFile, imported)
            try store.save(loaded)
            XCTAssertEqual(try store.load(), loaded)
            let persisted = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: store.settingsURL)) as? [String: Any])
            XCTAssertEqual(persisted["opening"] as? String, "click")
            XCTAssertEqual(persisted["closing"] as? String, "click")
        }
    }

    func testUnknownSoundIDStillFailsDecoding() {
        XCTAssertThrowsError(try JSONDecoder().decode(SoundPreset.self, from: Data(#""unknown-sound""#.utf8)))
    }

    func testEveryPairRoundTripsWithoutCouplingDirections() throws {
        for opening in SoundPreset.builtIns + [.off] {
            for closing in SoundPreset.builtIns + [.off] {
                var settings = SoundSettings()
                settings.select(opening, for: .opened)
                settings.select(closing, for: .closed)
                let data = try JSONEncoder().encode(settings.validated())
                let loaded = try JSONDecoder().decode(SoundSettings.self, from: data).validated()
                XCTAssertEqual(loaded.preset(for: .opened), opening)
                XCTAssertEqual(loaded.preset(for: .closed), closing)
            }
        }
    }

    func testChoosingBuiltInKeepsImportedFileAvailable() throws {
        var settings = SoundSettings()
        let sound = ImportedSound(fileName: UUID().uuidString + ".sound", displayName: "My clip")
        settings.setImported(sound, for: .opened)
        settings.select(.laser, for: .opened)
        XCTAssertEqual(settings.imported(for: .opened), sound)
        settings.select(.custom, for: .opened)
        XCTAssertEqual(try settings.validated().preset(for: .opened), .custom)
        XCTAssertEqual(settings.preset(for: .closed), .click)
    }

    func testNewPresetPersistsToDisk() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = SettingsStore(directory: directory)
        var settings = SoundSettings()
        settings.opening = .musicBox
        settings.closing = .powerUp
        try store.save(settings)
        XCTAssertEqual(try store.load(), settings)
    }

    func testAllSynthesizedClipsAreDifferent() throws {
        var clips = Set<Data>()
        for preset in SoundPreset.synthesized {
            for event in FoldEvent.allCases {
                let clip = try XCTUnwrap(SoundLibrary.wav(preset: preset, event: event))
                XCTAssertTrue(clips.insert(clip).inserted, "Duplicate audio: \(preset) \(event)")
            }
        }
        XCTAssertEqual(clips.count, 34)
    }

    func testAllDurationsAndPCMFormatsMatchCatalog() throws {
        for preset in SoundPreset.builtIns {
            let duration = try XCTUnwrap(preset.duration)
            XCTAssertGreaterThan(duration, 0)
            XCTAssertLessThanOrEqual(duration, 5)
            for event in FoldEvent.allCases {
                let data = try XCTUnwrap(SoundLibrary.wav(preset: preset, event: event))
                let frames = preset.isRecorded ? Int((duration * 44_100).rounded()) : Int(duration * 44_100)
                XCTAssertEqual(data.count, 44 + frames * 2)
                XCTAssertEqual(Array(data[20..<24]), [1, 0, 1, 0]) // PCM, mono
                XCTAssertEqual(Array(data[32..<36]), [2, 0, 16, 0]) // block alignment, 16 bits
            }
        }
        XCTAssertNil(SoundPreset.off.duration)
        XCTAssertNil(SoundPreset.custom.duration)
    }

    func testClipsAreAudibleBoundedAndStartAndEndAtZero() throws {
        for preset in SoundPreset.builtIns {
            for event in FoldEvent.allCases {
                let data = try XCTUnwrap(SoundLibrary.wav(preset: preset, event: event))
                let samples = stride(from: 44, to: data.count, by: 2).map {
                    Double(Int16(bitPattern: UInt16(data[$0]) | UInt16(data[$0 + 1]) << 8)) / 32_767
                }
                XCTAssertEqual(samples.first, 0)
                XCTAssertEqual(samples.last, 0)
                let rms = sqrt(samples.reduce(0) { $0 + $1 * $1 } / Double(samples.count))
                XCTAssertGreaterThan(rms, 0.015, "Effect is unexpectedly quiet: \(preset) \(event)")
                XCTAssertLessThan(rms, 0.30)
                XCTAssertTrue(samples.allSatisfy { abs($0) < 0.85 })
            }
        }
    }

    func testBothDirectionsRemainDeterministic() {
        for preset in SoundPreset.builtIns {
            for event in FoldEvent.allCases {
                XCTAssertEqual(SoundLibrary.wav(preset: preset, event: event),
                               SoundLibrary.wav(preset: preset, event: event))
            }
        }
    }
}
