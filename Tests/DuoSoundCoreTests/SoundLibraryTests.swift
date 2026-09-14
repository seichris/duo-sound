import Foundation
import XCTest
@testable import DuoSoundCore

final class SoundLibraryTests: XCTestCase {
    func testEveryBuiltInAppearsExactlyOnceInTheBrowser() {
        let catalog = SoundCategory.allCases.flatMap(SoundPreset.presets(in:))
        XCTAssertEqual(SoundPreset.builtIns.count, 20)
        XCTAssertEqual(catalog.count, 20)
        XCTAssertEqual(Set(catalog), Set(SoundPreset.builtIns))
        XCTAssertFalse(catalog.contains(.off))
        XCTAssertFalse(catalog.contains(.custom))
        for category in SoundCategory.allCases { XCTAssertFalse(SoundPreset.presets(in: category).isEmpty) }
    }

    func testCatalogLabelsAreUniqueAndReadable() {
        XCTAssertEqual(Set(SoundPreset.builtIns.map(\.title)).count, 20)
        XCTAssertEqual(SoundPreset.musicBox.title, "Music Box")
        XCTAssertEqual(SoundPreset.waterDrop.title, "Water Drop")
        XCTAssertEqual(SoundPreset.powerUp.title, "Power Up / Down")
        for preset in SoundPreset.allCases { XCTAssertFalse(preset.detail.isEmpty) }
    }

    func testLegacySavedIDsAndDefaultsStillDecode() throws {
        for value in ["chime", "paper", "arcade", "orbit", "click", "off", "custom"] {
            let data = Data("\"\(value)\"".utf8)
            XCTAssertEqual(try JSONDecoder().decode(SoundPreset.self, from: data).rawValue, value)
        }
        let legacy = Data(#"{"enabled":true,"volume":0.65,"opening":"chime","closing":"paper"}"#.utf8)
        XCTAssertEqual(try JSONDecoder().decode(SoundSettings.self, from: legacy).validated(), SoundSettings())
        XCTAssertEqual(SoundSettings().opening, .chime)
        XCTAssertEqual(SoundSettings().closing, .paper)
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
        XCTAssertEqual(settings.preset(for: .closed), .paper)
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

    func testAllFortyClipsAreDifferent() throws {
        var clips = Set<Data>()
        for preset in SoundPreset.builtIns {
            for event in FoldEvent.allCases {
                let clip = try XCTUnwrap(SoundSynthesizer.wav(preset: preset, event: event))
                XCTAssertTrue(clips.insert(clip).inserted, "Duplicate audio: \(preset) \(event)")
            }
        }
        XCTAssertEqual(clips.count, 40)
    }

    func testAllDurationsAndPCMFormatsMatchCatalog() throws {
        for preset in SoundPreset.builtIns {
            let duration = try XCTUnwrap(preset.duration)
            XCTAssertGreaterThan(duration, 0)
            XCTAssertLessThan(duration, 1)
            for event in FoldEvent.allCases {
                let data = try XCTUnwrap(SoundSynthesizer.wav(preset: preset, event: event))
                XCTAssertEqual(data.count, 44 + Int(duration * 44_100) * 2)
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
                let data = try XCTUnwrap(SoundSynthesizer.wav(preset: preset, event: event))
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
                XCTAssertEqual(SoundSynthesizer.wav(preset: preset, event: event),
                               SoundSynthesizer.wav(preset: preset, event: event))
            }
        }
    }
}
