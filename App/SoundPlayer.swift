import AVFoundation
import Foundation

@MainActor
final class SoundPlayer {
    enum Purpose { case preview, fold }

    private var player: AVAudioPlayer?
    private var purpose: Purpose?
    var isPlaying: Bool { player?.isPlaying == true }
    var currentTime: TimeInterval { player?.currentTime ?? 0 }
    private var cleanup: Task<Void, Never>?
    private var playbackID = UUID()

    static func validate(_ data: Data) throws {
        let candidate = try AVAudioPlayer(data: data)
        guard candidate.duration.isFinite, candidate.duration > 0, candidate.duration <= 5 else {
            throw SoundFailure.invalidAudio
        }
        guard candidate.prepareToPlay() else { throw SoundFailure.invalidAudio }
    }

    func play(_ data: Data, volume: Double, purpose: Purpose) throws {
        stop()
        let session = AVAudioSession.sharedInstance()
        do {
            // Explicit auditions work in Silent Mode. Automatic fold effects
            // respect it. Both follow the selected route and mix with music.
            try session.setCategory(purpose == .preview ? .playback : .ambient,
                                    mode: .default,
                                    options: purpose == .preview ? [.mixWithOthers] : [])
            try session.setActive(true)
            let next = try AVAudioPlayer(data: data)
            guard next.duration.isFinite, next.duration > 0, next.duration <= 5 else {
                throw SoundFailure.invalidAudio
            }
            next.volume = Float(max(0, min(1, volume)))
            guard next.prepareToPlay(), next.play() else { throw SoundFailure.playbackFailed }
            player = next
            self.purpose = purpose
            let id = UUID()
            playbackID = id
            cleanup = Task { [weak self] in
                do { try await Task.sleep(nanoseconds: UInt64((next.duration + 0.15) * 1_000_000_000)) }
                catch { return }
                guard self?.playbackID == id else { return }
                self?.stop()
            }
        } catch {
            stop()
            throw error
        }
    }

    func stopFoldSound() {
        if purpose == .fold { stop() }
    }

    func stop() {
        cleanup?.cancel(); cleanup = nil
        playbackID = UUID()
        player?.stop(); player = nil
        purpose = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
