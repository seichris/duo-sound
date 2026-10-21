import Foundation
import XCTest
@testable import DuoSoundCore

final class SelectedSoundFileTests: XCTestCase {
    func testEachInvocationReadsTheCurrentIndependentSelection() throws {
        try withStore { store in
            var settings = SoundSettings()
            settings.opening = .musicBox
            settings.closing = .woodKnock
            settings.enabled = false // Explicit exports also work when folds are paused.
            try store.save(settings)
            XCTAssertEqual(try SelectedSoundFile.load(for: .opened, from: store).data,
                           SoundLibrary.wav(preset: .musicBox, event: .opened))
            XCTAssertEqual(try SelectedSoundFile.load(for: .closed, from: store).data,
                           SoundLibrary.wav(preset: .woodKnock, event: .closed))
            settings.opening = .laser
            try store.save(settings)
            XCTAssertEqual(try SelectedSoundFile.load(for: .opened, from: store).data,
                           SoundLibrary.wav(preset: .laser, event: .opened))
        }
    }

    func testCustomExportPreservesBytesWithoutExposingTheOriginalFilename() throws {
        try withStore { store in
            var settings = SoundSettings()
            let record = ImportedSound(fileName: UUID().uuidString + ".sound", displayName: "private-name.M4A")
            settings.setImported(record, for: .closed)
            try store.save(settings)
            let bytes = Data([1, 2, 3, 4])
            try bytes.write(to: store.soundURL(for: record))
            let sound = try SelectedSoundFile.load(for: .closed, from: store)
            XCTAssertEqual(sound.data, bytes)
            XCTAssertEqual(sound.filename, "Hingy-Closing.m4a")
            XCTAssertEqual(try store.load(), settings)
        }
    }

    func testOffAndMissingCustomAudioNeverSubstituteAnotherSound() throws {
        try withStore { store in
            var settings = SoundSettings()
            settings.opening = .off
            try store.save(settings)
            XCTAssertThrowsError(try SelectedSoundFile.load(for: .opened, from: store))
            settings.setImported(ImportedSound(fileName: UUID().uuidString + ".sound", displayName: "Missing.wav"), for: .opened)
            try store.save(settings)
            XCTAssertThrowsError(try SelectedSoundFile.load(for: .opened, from: store))
        }
    }

    private func withStore(_ body: (SettingsStore) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try body(SettingsStore(directory: directory))
    }
}
