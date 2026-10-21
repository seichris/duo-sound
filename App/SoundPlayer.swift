import AVFoundation
import Foundation

@MainActor
final class SoundPlayer {
    enum Purpose: Sendable { case preview, fold }
    struct PlaybackState: Sendable {
        let isPlaying: Bool
        let currentTime: TimeInterval
    }

    private let worker: Worker
    private var request: Request?
    private var purpose: Purpose?

    init(configureSession: (@Sendable (Purpose) throws -> Void)? = nil) {
        let configure: @Sendable (Purpose) throws -> Void = { purpose in
            try Worker.configureSession(purpose)
        }
        worker = Worker(configureSession: configureSession ?? configure)
    }

    deinit { request?.cancel(); worker.stop() }

    static func validate(_ data: Data) throws {
        let candidate = try AVAudioPlayer(data: data)
        guard candidate.duration.isFinite, candidate.duration > 0, candidate.duration <= 5 else {
            throw SoundFailure.invalidAudio
        }
        // Preparing playback can activate the audio session. Validation only
        // inspects the clip; hardware/session work belongs to the worker queue.
    }

    func play(_ data: Data, volume: Double, purpose: Purpose,
              completion: @escaping @MainActor @Sendable (Result<Void, Error>) -> Void) {
        stop()
        let request = Request()
        self.request = request
        self.purpose = purpose
        worker.play(data, volume: volume, purpose: purpose, request: request) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self, self.request === request, !request.isCancelled else { return }
                completion(result)
            }
        }
    }

    func playbackState() async -> PlaybackState {
        await withCheckedContinuation { continuation in
            worker.readState { continuation.resume(returning: $0) }
        }
    }

    func stopFoldSound() {
        if purpose == .fold { stop() }
    }

    func stop() {
        // Invalidate immediately, including activation that is still blocked.
        // An old effect must never start after inactivity or display handoff.
        request?.cancel(); request = nil
        purpose = nil
        worker.stop()
    }

    /// The only shared cross-queue state is this lock-protected cancellation bit.
    private final class Request: @unchecked Sendable {
        private let lock = NSLock()
        private var cancelled = false
        var isCancelled: Bool {
            lock.lock(); defer { lock.unlock() }
            return cancelled
        }
        func cancel() { lock.lock(); cancelled = true; lock.unlock() }
    }

    /// AVAudioSession and AVAudioPlayer are confined to one serial queue.
    /// No synchronous queue hop or activation/deactivation blocks the main actor.
    private final class Worker: @unchecked Sendable {
        private let queue = DispatchQueue(label: "com.seichris.duosound.audio", qos: .userInitiated)
        private let configure: @Sendable (Purpose) throws -> Void
        private var player: AVAudioPlayer?
        private var request: Request?
        private var cleanup: DispatchWorkItem?

        init(configureSession: @escaping @Sendable (Purpose) throws -> Void) {
            configure = configureSession
        }

        static func configureSession(_ purpose: Purpose) throws {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(purpose == .preview ? .playback : .ambient,
                                    mode: .default,
                                    options: purpose == .preview ? [.mixWithOthers] : [])
            try session.setActive(true)
        }

        func play(_ data: Data, volume: Double, purpose: Purpose, request: Request,
                  completion: @escaping @Sendable (Result<Void, Error>) -> Void) {
            queue.async {
                guard !request.isCancelled else { return }
                do {
                    try self.configure(purpose)
                    guard !request.isCancelled else { self.stopNow(); return }
                    let next = try AVAudioPlayer(data: data)
                    guard next.duration.isFinite, next.duration > 0, next.duration <= 5 else {
                        throw SoundFailure.invalidAudio
                    }
                    next.volume = Float(max(0, min(1, volume)))
                    self.player = next
                    self.request = request
                    guard next.prepareToPlay() else { throw SoundFailure.invalidAudio }
                    guard !request.isCancelled else { self.stopNow(); return }
                    guard next.play() else { throw SoundFailure.playbackFailed }
                    guard !request.isCancelled else { self.stopNow(); return }
                    let cleanup = DispatchWorkItem { [weak worker = self] in
                        guard let worker, worker.request === request else { return }
                        worker.stopNow()
                    }
                    self.cleanup = cleanup
                    self.queue.asyncAfter(deadline: .now() + next.duration + 0.15, execute: cleanup)
                    completion(.success(()))
                } catch {
                    self.stopNow()
                    completion(.failure(error))
                }
            }
        }

        func stop() { queue.async { self.stopNow() } }

        func readState(_ completion: @escaping @Sendable (PlaybackState) -> Void) {
            queue.async {
                completion(PlaybackState(isPlaying: self.player?.isPlaying == true,
                                         currentTime: self.player?.currentTime ?? 0))
            }
        }

        private func stopNow() {
            cleanup?.cancel(); cleanup = nil
            player?.stop(); player = nil
            request = nil
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
}
