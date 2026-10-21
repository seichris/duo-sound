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
        _ = await audio.playbackState()
        try? FileManager.default.removeItem(at: directory)
        model = nil
        audio = nil
    }

    func testNativeHingeIsEnabled() {
        XCTAssertTrue(AppModel.hingeSDKEnabled)
        model.receiveHardware(angle: nil)
        XCTAssertEqual(model.status, "NO HINGE AVAILABLE")
    }

    func testPreviewUsesSilentModeIndependentMixablePlayback() async throws {
        model.updateSettings { $0.enabled = false }
        model.preview(.opened, preset: .musicBox)
        XCTAssertNil(model.errorMessage)
        try await assertPlaybackAdvances()
        XCTAssertEqual(AVAudioSession.sharedInstance().category, .playback)
        XCTAssertTrue(AVAudioSession.sharedInstance().categoryOptions.contains(.mixWithOthers))
    }

    func testEveryBuiltInPreviewStartsInBothDirections() async throws {
        for event in [FoldEvent.opened, .closed] {
            for preset in SoundPreset.builtIns {
                model.preview(event, preset: preset)
                XCTAssertNil(model.errorMessage, "\(event) \(preset)")
                await assertPlaying()
                await assertEventContains(preset.title)
            }
        }
    }

    func testRecordedFartProgressSurvivesMissingHinge() async throws {
        model.receiveHardware(angle: nil)
        model.preview(.closed, preset: .tinyFart)
        model.receiveHardware(angle: nil)
        try await assertPlaybackAdvances()
        await assertEventContains("Tiny Fart")
        XCTAssertEqual(AVAudioSession.sharedInstance().category, .playback)
    }

    func testMissingHingeDoesNotCancelIPadPreview() async throws {
        model.receiveHardware(angle: nil)
        model.preview(.opened, preset: .musicBox)
        model.receiveHardware(angle: nil)
        XCTAssertEqual(model.hardwareAvailable, false)
        XCTAssertNil(model.angle)
        try await assertPlaybackAdvances()
    }

    func testHingeHierarchyLossCancelsFoldButPreservesManualPreview() async throws {
        model.receiveHardware(angle: 180)
        model.preview(.closed, preset: .musicBox)
        model.receiveHardware(angle: nil)
        try await assertPlaybackAdvances()
        let clip = try XCTUnwrap(SoundSynthesizer.wav(preset: .musicBox, event: .opened))
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            audio.play(clip, volume: 0.65, purpose: .fold) { continuation.resume(with: $0) }
        }
        model.receiveHardware(angle: nil)
        await assertStopped()
    }

    func testSessionConfigurationNotificationsDoNotCancelPreview() async throws {
        model.preview(.opened, preset: .musicBox)
        for reason in [AVAudioSession.RouteChangeReason.categoryChange, .routeConfigurationChange, .unknown] {
            model.audioRouteChanged(routeNotification(reason))
        }
        model.audioRouteChanged(Notification(name: AVAudioSession.routeChangeNotification))
        try await assertPlaybackAdvances()
    }

    func testHeadphoneRemovalAndExplicitRouteChangesStopPlayback() async {
        for reason in [AVAudioSession.RouteChangeReason.oldDeviceUnavailable, .newDeviceAvailable,
                       .override, .noSuitableRouteForCategory] {
            model.preview(.opened, preset: .musicBox)
            await assertPlaying()
            model.audioRouteChanged(routeNotification(reason))
            await assertStopped()
        }
    }

    func testFoldSoundsStillRespectSilentModeAndMissingHingeCancelsDwell() async throws {
        model.receiveHardware(angle: 0)
        model.receiveHardware(angle: 180)
        try await Task.sleep(for: .milliseconds(110))
        await assertPlaying()
        XCTAssertEqual(AVAudioSession.sharedInstance().category, .ambient)
        model.receiveHardware(angle: nil)
        await assertStopped()
        model.receiveHardware(angle: 0)
        model.receiveHardware(angle: 180)
        model.receiveHardware(angle: nil)
        try await Task.sleep(for: .milliseconds(110))
        await assertStopped()
    }

    func testInactiveAndInterruptedAppStopsPreviewWithoutResuming() async throws {
        model.preview(.opened, preset: .musicBox)
        await assertPlaying()
        model.setActive(false)
        await assertStopped()
        model.preview(.closed, preset: .musicBox)
        await assertStopped()
        model.setActive(true)
        await assertStopped()
        model.preview(.opened, preset: .musicBox)
        await assertPlaying()
        model.interruptAudio()
        await assertStopped()
        try await Task.sleep(for: .milliseconds(100))
        await assertStopped()
    }

    func testImportedClipPreviewUsesSamePlaybackPath() async throws {
        let clip = directory.appendingPathComponent("fixture.wav")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try XCTUnwrap(SoundSynthesizer.wav(preset: .musicBox, event: .closed)).write(to: clip)
        model.importSound(from: clip, event: .closed)
        XCTAssertNil(model.errorMessage)
        model.preview(.closed)
        try await assertPlaybackAdvances()
        XCTAssertEqual(AVAudioSession.sharedInstance().category, .playback)
        model.importSound(from: directory.appendingPathComponent("missing.wav"), event: .closed)
        XCTAssertNotNil(model.errorMessage)
        XCTAssertEqual(model.settings.closing, .custom)
    }

    func testOffAndZeroVolumeStayUserControlled() async {
        model.preview(.opened, preset: .off)
        await assertStopped()
        XCTAssertTrue(model.lastEvent.contains("sound is off"))
        model.updateSettings { $0.volume = 0 }
        model.preview(.opened, preset: .musicBox)
        await assertPlaying()
        XCTAssertEqual(model.settings.volume, 0)
        XCTAssertNil(model.errorMessage)
    }

    func testSlowSessionActivationDoesNotBlockMainActorOrReplayAfterCancel() async {
        let started = expectation(description: "Activation runs off the main thread")
        let release = DispatchSemaphore(value: 0)
        audio.stop()
        _ = await audio.playbackState()
        audio = SoundPlayer { _ in
            XCTAssertFalse(Thread.isMainThread)
            started.fulfill()
            release.wait()
        }
        model = AppModel(directory: directory, audio: audio)
        model.setActive(true)
        model.preview(.opened, preset: .musicBox)
        await fulfillment(of: [started], timeout: 3)
        // This must execute while activation is still blocked on the worker.
        model.setActive(false)
        XCTAssertFalse(model.isActive)
        release.signal()
        await assertStopped()
        await Task.yield()
        XCTAssertEqual(model.lastEvent, "No sound triggered yet")
        XCTAssertNil(model.errorMessage)
    }

    private func assertPlaying(file: StaticString = #filePath, line: UInt = #line) async {
        let state = await audio.playbackState()
        XCTAssertTrue(state.isPlaying, file: file, line: line)
    }

    private func assertStopped(file: StaticString = #filePath, line: UInt = #line) async {
        let state = await audio.playbackState()
        XCTAssertFalse(state.isPlaying, file: file, line: line)
    }

    private func assertEventContains(_ value: String, file: StaticString = #filePath, line: UInt = #line) async {
        for _ in 0..<100 {
            if model.lastEvent.contains(value) { return }
            try? await Task.sleep(for: .milliseconds(10))
        }
        XCTAssertTrue(model.lastEvent.contains(value), file: file, line: line)
    }

    private func assertPlaybackAdvances() async throws {
        await assertPlaying()
        try await Task.sleep(for: .milliseconds(80))
        let state = await audio.playbackState()
        XCTAssertTrue(state.isPlaying, "Hinge/configuration updates must not cancel an audition")
        XCTAssertGreaterThan(state.currentTime, 0.01, "AVAudioPlayer must actually advance")
    }

    private func routeNotification(_ reason: AVAudioSession.RouteChangeReason) -> Notification {
        Notification(name: AVAudioSession.routeChangeNotification,
                     userInfo: [AVAudioSessionRouteChangeReasonKey: NSNumber(value: reason.rawValue)])
    }
}
