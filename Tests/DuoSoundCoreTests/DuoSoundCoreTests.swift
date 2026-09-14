import XCTest
@testable import DuoSoundCore

final class FoldDetectorTests: XCTestCase {
    func testInitialClosedIsSilent() { var d = FoldDetector(); XCTAssertNil(d.ingest(angle: 0, at: 0)); XCTAssertEqual(d.state, .closed) }
    func testInitialOpenIsSilent() { var d = FoldDetector(); XCTAssertNil(d.ingest(angle: 180, at: 0)); XCTAssertEqual(d.state, .opened) }
    func testInitialDeadbandRemainsUnknown() {
        var d = FoldDetector(); XCTAssertNil(d.ingest(angle: 14, at: 0)); XCTAssertNil(d.state)
        XCTAssertNil(d.ingest(angle: 40, at: 1)); XCTAssertEqual(d.state, .opened)
    }
    func testEndpointOnlyOpenUsesTimer() {
        var d = closedDetector(); XCTAssertNil(d.ingest(angle: 180, at: 1))
        XCTAssertNil(d.advance(to: 1.04)); XCTAssertEqual(d.advance(to: 1.08), .opened)
        XCTAssertNil(d.advance(to: 2))
    }
    func testCloseUsesTimer() {
        var d = FoldDetector(); _ = d.ingest(angle: 180, at: 0)
        XCTAssertNil(d.ingest(angle: 0, at: 1)); XCTAssertEqual(d.advance(to: 1.08), .closed)
    }
    func testDuplicateSamplesDoNotReplay() {
        var d = closedDetector(); _ = d.ingest(angle: 22, at: 1)
        XCTAssertEqual(d.ingest(angle: 90, at: 1.1), .opened)
        for i in 2...100 { XCTAssertNil(d.ingest(angle: 180, at: Double(i))) }
    }
    func testPartiallyToFullyOpenDoesNotReplay() {
        var d = closedDetector(); _ = d.ingest(angle: 30, at: 1); _ = d.advance(to: 1.1)
        XCTAssertNil(d.ingest(angle: 180, at: 2)); XCTAssertNil(d.advance(to: 3))
    }
    func testJitterInDeadbandKeepsState() {
        var d = closedDetector()
        for i in 1...20 { XCTAssertNil(d.ingest(angle: Double(9 + i % 12), at: Double(i))) }
        XCTAssertEqual(d.state, .closed); XCTAssertNil(d.deadline)
    }
    func testShortSpikeDoesNotTrigger() {
        var d = closedDetector(); _ = d.ingest(angle: 30, at: 1)
        _ = d.ingest(angle: 0, at: 1.02); XCTAssertNil(d.advance(to: 2)); XCTAssertEqual(d.state, .closed)
    }
    func testDeadbandCancelsPendingTransition() {
        var d = closedDetector(); _ = d.ingest(angle: 30, at: 1)
        _ = d.ingest(angle: 14, at: 1.02); XCTAssertNil(d.advance(to: 2))
    }
    func testResetDropsPendingAndSilentlyRebaselines() {
        var d = closedDetector(); _ = d.ingest(angle: 180, at: 1); d.reset()
        XCTAssertNil(d.advance(to: 2)); XCTAssertNil(d.ingest(angle: 180, at: 3))
        XCTAssertEqual(d.state, .opened)
    }
    func testInvalidAnglesCancelPending() {
        for angle in [Double.nan, .infinity, -.infinity, -1, 181] {
            var d = closedDetector(); _ = d.ingest(angle: 180, at: 1)
            XCTAssertNil(d.ingest(angle: angle, at: 1.02)); XCTAssertNil(d.advance(to: 2))
            XCTAssertEqual(d.state, .closed)
        }
    }
    func testBackwardsTimeCancelsPending() {
        var d = closedDetector(); _ = d.ingest(angle: 180, at: 1)
        XCTAssertNil(d.ingest(angle: 180, at: 0.5)); XCTAssertNil(d.advance(to: 2))
    }
    func testInvalidTimeCancelsPending() {
        var d = closedDetector(); _ = d.ingest(angle: 180, at: 1)
        XCTAssertNil(d.advance(to: .nan)); XCTAssertNil(d.advance(to: 2))
    }
    func testRapidCompleteFoldsAreNotRateLimited() {
        var d = closedDetector()
        for i in 1...10 {
            let t = Double(i)
            _ = d.ingest(angle: 180, at: t); XCTAssertEqual(d.advance(to: t + 0.1), .opened)
            _ = d.ingest(angle: 0, at: t + 0.2); XCTAssertEqual(d.advance(to: t + 0.3), .closed)
        }
    }
    func testZeroDwellEmitsImmediately() {
        var d = FoldDetector(dwell: 0); _ = d.ingest(angle: 0, at: 0)
        XCTAssertEqual(d.ingest(angle: 22, at: 1), .opened)
    }
    func testThresholdBoundariesAreInclusive() {
        var d = FoldDetector(dwell: 0); _ = d.ingest(angle: 8, at: 0)
        XCTAssertEqual(d.ingest(angle: 22, at: 1), .opened)
        XCTAssertEqual(d.ingest(angle: 8, at: 2), .closed)
    }
    private func closedDetector() -> FoldDetector {
        var detector = FoldDetector(); _ = detector.ingest(angle: 0, at: 0); return detector
    }
}

final class SoundSynthesizerTests: XCTestCase {
    func testAllPresetsProduceValidBoundedPCM() throws {
        for preset in SoundPreset.builtIns {
            for event in FoldEvent.allCases {
                let data = try XCTUnwrap(SoundSynthesizer.wav(preset: preset, event: event))
                XCTAssertEqual(String(data: data[0..<4], encoding: .utf8), "RIFF")
                XCTAssertEqual(String(data: data[8..<16], encoding: .utf8), "WAVEfmt ")
                XCTAssertEqual(String(data: data[36..<40], encoding: .utf8), "data")
                XCTAssertEqual(u32(data, 4), data.count - 8)
                XCTAssertEqual(u32(data, 24), 44_100)
                XCTAssertEqual(u32(data, 40), data.count - 44)
                XCTAssertLessThan(data.count, 44_100 * 2 * 5)
                let samples = stride(from: 44, to: data.count, by: 2).map {
                    Int16(bitPattern: UInt16(data[$0]) | UInt16(data[$0 + 1]) << 8)
                }
                XCTAssertEqual(samples.first, 0); XCTAssertEqual(samples.last, 0)
                XCTAssertTrue(samples.contains { $0 != 0 })
                XCTAssertLessThan(samples.map { abs(Int($0)) }.max() ?? 0, 28_000)
            }
        }
    }
    func testSynthesisIsDeterministic() {
        for preset in SoundPreset.builtIns {
            XCTAssertEqual(SoundSynthesizer.wav(preset: preset, event: .opened), SoundSynthesizer.wav(preset: preset, event: .opened))
        }
    }
    func testOpeningAndClosingDiffer() {
        for preset in SoundPreset.builtIns {
            XCTAssertNotEqual(SoundSynthesizer.wav(preset: preset, event: .opened), SoundSynthesizer.wav(preset: preset, event: .closed))
        }
    }
    func testNoSyntheticCustomOrOffSound() {
        XCTAssertNil(SoundSynthesizer.wav(preset: .custom, event: .opened))
        XCTAssertNil(SoundSynthesizer.wav(preset: .off, event: .closed))
    }
    private func u32(_ data: Data, _ offset: Int) -> Int {
        (0..<4).reduce(0) { $0 | Int(data[offset + $1]) << ($1 * 8) }
    }
}

final class SettingsStoreTests: XCTestCase {
    func testMissingSettingsUseDefaults() throws {
        try withStore { XCTAssertEqual(try $0.load(), SoundSettings()) }
    }
    func testAtomicRoundTrip() throws {
        try withStore { store in
            var value = SoundSettings(); value.volume = 0.3; value.enabled = false; value.opening = .orbit
            value.setImported(ImportedSound(fileName: UUID().uuidString + ".sound", displayName: "Close.wav"), for: .closed)
            try store.save(value); XCTAssertEqual(try store.load(), value)
        }
    }
    func testCorruptSettingsFailWithoutOverwritingFile() throws {
        try withStore { store in
            try FileManager.default.createDirectory(at: store.directory, withIntermediateDirectories: true)
            let bad = Data("not json".utf8); try bad.write(to: store.settingsURL)
            XCTAssertThrowsError(try store.load()); XCTAssertEqual(try Data(contentsOf: store.settingsURL), bad)
        }
    }
    func testInvalidVolumeIsRejected() {
        for value in [-0.1, 1.1, Double.nan, Double.infinity] {
            var settings = SoundSettings(); settings.volume = value
            XCTAssertThrowsError(try settings.validated())
        }
    }
    func testCustomSelectionRequiresFile() {
        var settings = SoundSettings(); settings.opening = .custom
        XCTAssertThrowsError(try settings.validated())
    }
    func testPathTraversalIsRejected() throws {
        try withStore { store in
            for file in ["../evil.sound", "/tmp/evil.sound", "foo.sound", "..\\evil.sound", "settings.json"] {
                let record = ImportedSound(fileName: file, displayName: "anything")
                XCTAssertFalse(record.isSafe); XCTAssertThrowsError(try store.soundURL(for: record))
            }
        }
    }
    func testBoundedReaderAtAndOverLimit() throws {
        try withStore { store in
            try FileManager.default.createDirectory(at: store.directory, withIntermediateDirectories: true)
            let url = store.directory.appendingPathComponent("clip")
            try Data(repeating: 42, count: 100).write(to: url)
            XCTAssertEqual(try SettingsStore.readBounded(url, limit: 100).count, 100)
            XCTAssertThrowsError(try SettingsStore.readBounded(url, limit: 99))
        }
    }
    func testWriteFailureDoesNotPretendSuccess() throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: file) }
        try Data([1]).write(to: file)
        XCTAssertThrowsError(try SettingsStore(directory: file).save(SoundSettings()))
    }
    private func withStore(_ body: (SettingsStore) throws -> Void) throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        try body(SettingsStore(directory: url))
    }
}
