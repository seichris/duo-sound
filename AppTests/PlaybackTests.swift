import AVFoundation
import XCTest
@testable import DuoSound

@MainActor
final class PlaybackTests: XCTestCase {
    private var directory: URL!
    private var audio: SoundPlayer!
    private var model: AppModel!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        audio = SoundPlayer()
        model = AppModel(directory: directory, audio: audio)
        model.setActive(true)
    }

    override func tearDown() async throws {
        audio.stop()
        try? FileManager.default.removeItem(at: directory)
        model = nil
        audio = nil
    }

    func testPreviewUsesSilentModeIndependentMixablePlayback() async throws {
        model.updateSettings { $0.enabled = false }
        model.preview(.opened, preset: .musicBox)
        XCTAssertNil(model.errorMessage)
        XCTAssertEqual(AVAudioSession.sharedInstance().category, .playback)
        XCTAssertTrue(AVAudioSession.sharedInstance().categoryOptions.contains(.mixWithOthers))
        try await assertPlaybackAdvances()
    }

    func testEveryBuiltInPreviewStartsInBothDirections() throws {
        for event in [FoldEvent.opened, .closed] {
            for preset in SoundPreset.builtIns {
                model.preview(event, preset: preset)
                XCTAssertNil(model.errorMessage, "\(event) \(preset)")
                XCTAssertTrue(audio.isPlaying, "\(event) \(preset)")
                XCTAssertTrue(model.lastEvent.contains(preset.title))
            }
        }
    }

    func testMissingHingeDoesNotCancelIPadPreview() async throws {
        model.setDemo(false)
        model.receiveHardware(angle: nil)
        model.preview(.opened, preset: .musicBox)
        model.receiveHardware(angle: nil)
        XCTAssertEqual(model.hardwareAvailable, false)
        XCTAssertNil(model.angle)
        try await assertPlaybackAdvances()
    }

    func testHingeHierarchyLossCancelsFoldButPreservesManualPreview() async throws {
        model.setDemo(false)
        model.receiveHardware(angle: 180)
        model.preview(.closed, preset: .musicBox)
        model.receiveHardware(angle: nil)
        try await assertPlaybackAdvances()
        let clip = try XCTUnwrap(SoundSynthesizer.wav(preset: .musicBox, event: .opened))
        try audio.play(clip, volume: 0.65, purpose: .fold)
        model.receiveHardware(angle: nil)
        XCTAssertFalse(audio.isPlaying)
    }

    func testSessionConfigurationNotificationsDoNotCancelPreview() async throws {
        model.preview(.opened, preset: .musicBox)
        for reason in [AVAudioSession.RouteChangeReason.categoryChange, .routeConfigurationChange, .unknown] {
            model.audioRouteChanged(routeNotification(reason))
        }
        model.audioRouteChanged(Notification(name: AVAudioSession.routeChangeNotification))
        try await assertPlaybackAdvances()
    }

    func testHeadphoneRemovalAndExplicitRouteChangesStopPlayback() {
        for reason in [AVAudioSession.RouteChangeReason.oldDeviceUnavailable, .newDeviceAvailable,
                       .override, .noSuitableRouteForCategory] {
            model.preview(.opened, preset: .musicBox)
            XCTAssertTrue(audio.isPlaying)
            model.audioRouteChanged(routeNotification(reason))
            XCTAssertFalse(audio.isPlaying)
        }
    }

    func testFoldSoundsStillRespectSilentModeAndMissingHingeCancelsDwell() async throws {
        model.setDemo(false)
        model.receiveHardware(angle: 0)
        model.receiveHardware(angle: 180)
        try await Task.sleep(for: .milliseconds(110))
        XCTAssertEqual(AVAudioSession.sharedInstance().category, .ambient)
        XCTAssertTrue(audio.isPlaying)
        model.receiveHardware(angle: nil)
        XCTAssertFalse(audio.isPlaying)
        model.receiveHardware(angle: 0)
        model.receiveHardware(angle: 180)
        model.receiveHardware(angle: nil)
        try await Task.sleep(for: .milliseconds(110))
        XCTAssertFalse(audio.isPlaying)
    }

    func testManualSimulationUsesSilentModeIndependentPlayback() async throws {
        model.setDemo(true)
        model.setDemoAngle(180)
        try await Task.sleep(for: .milliseconds(110))
        XCTAssertTrue(model.lastEvent.contains("Demo fold · Opening"))
        XCTAssertEqual(AVAudioSession.sharedInstance().category, .playback)
        XCTAssertTrue(audio.isPlaying)
    }

    func testInactiveAndInterruptedAppStopsPreviewWithoutResuming() async throws {
        model.preview(.opened, preset: .musicBox)
        model.setActive(false)
        XCTAssertFalse(audio.isPlaying)
        model.preview(.closed, preset: .musicBox)
        XCTAssertFalse(audio.isPlaying)
        model.setActive(true)
        XCTAssertFalse(audio.isPlaying)
        model.preview(.opened, preset: .musicBox)
        model.interruptAudio()
        XCTAssertFalse(audio.isPlaying)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertFalse(audio.isPlaying)
    }

    func testImportedClipPreviewUsesSamePlaybackPath() async throws {
        let clip = directory.appendingPathComponent("fixture.wav")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try XCTUnwrap(SoundSynthesizer.wav(preset: .musicBox, event: .closed)).write(to: clip)
        model.importSound(from: clip, event: .closed)
        XCTAssertNil(model.errorMessage)
        model.preview(.closed)
        XCTAssertEqual(AVAudioSession.sharedInstance().category, .playback)
        try await assertPlaybackAdvances()
        model.importSound(from: directory.appendingPathComponent("missing.wav"), event: .closed)
        XCTAssertNotNil(model.errorMessage)
        XCTAssertEqual(model.settings.closing, .custom)
    }

    func testOffAndZeroVolumeStayUserControlled() {
        model.preview(.opened, preset: .off)
        XCTAssertFalse(audio.isPlaying)
        XCTAssertTrue(model.lastEvent.contains("sound is off"))
        model.updateSettings { $0.volume = 0 }
        model.preview(.opened, preset: .musicBox)
        XCTAssertEqual(model.settings.volume, 0)
        XCTAssertNil(model.errorMessage)
    }

    private func assertPlaybackAdvances() async throws {
        XCTAssertTrue(audio.isPlaying)
        try await Task.sleep(for: .milliseconds(80))
        XCTAssertTrue(audio.isPlaying, "Hinge/configuration updates must not cancel an audition")
        XCTAssertGreaterThan(audio.currentTime, 0.01, "AVAudioPlayer must actually advance")
    }

    private func routeNotification(_ reason: AVAudioSession.RouteChangeReason) -> Notification {
        Notification(name: AVAudioSession.routeChangeNotification,
                     userInfo: [AVAudioSessionRouteChangeReasonKey: NSNumber(value: reason.rawValue)])
    }
}
