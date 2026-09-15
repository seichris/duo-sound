import Foundation

/// Original procedural effects; no third-party audio assets or downloads.
public enum SoundSynthesizer {
    public static let sampleRate = 44_100
    public static func wav(preset: SoundPreset, event: FoldEvent) -> Data? {
        guard let duration = preset.duration else { return nil }
        let count = Int(duration * Double(sampleRate))
        let opening = event == .opened
        var noise: UInt64 = opening ? 417 : 913
        var lowPass = 0.0
        var phase = 0.0
        // Secondary voices carry continuous phase for drops/chirps. No random
        // source, sample assets, allocation or disk access inside these voices.
        var secondPhase = 0.0
        let melody = opening ? [880.0, 1_108.73, 1_318.51] : [1_318.51, 1_108.73, 880.0]
        let powerNotes = opening ? [261.63, 329.63, 392.0, 523.25, 659.25]
                                 : [659.25, 523.25, 392.0, 329.63, 261.63]
        var pcm = [Int16]()
        pcm.reserveCapacity(count)
        for i in 0..<count {
            let t = Double(i) / Double(sampleRate)
            let progress = Double(i) / Double(count - 1)
            let ramp = min(1, t / 0.008) * min(1, (duration - t) / 0.025)
            noise = noise &* 6_364_136_223_846_793_005 &+ 1
            let white = Double(noise >> 33) / Double(UInt32.max >> 1) * 2 - 1
            lowPass += 0.18 * (white - lowPass)
            let direction = opening ? progress : 1 - progress
            let sample: Double
            switch preset {
            case .chime:
                let frequencies = opening ? [523.25, 659.25, 783.99] : [783.99, 659.25, 523.25]
                var value = 0.0
                for (index, frequency) in frequencies.enumerated() {
                    let local = t - Double(index) * 0.055
                    if local > 0 {
                        value += sin(2 * .pi * frequency * local) * exp(-local * 12) * min(1, local / 0.004)
                    }
                }
                sample = value * 0.24
            case .paper:
                let crinkles = pow(abs(sin(2 * .pi * (opening ? 19.0 : 27.0) * t)), 7)
                sample = (white * 0.12 + lowPass * 0.8) * (0.25 + crinkles) * (1 - progress * 0.55)
            case .arcade:
                let step = min(3, Int(direction * 4))
                let frequency = [261.63, 329.63, 392.0, 523.25][step]
                phase += 2 * .pi * frequency / Double(sampleRate)
                sample = (sin(phase) + sin(phase * 3) / 3 + sin(phase * 5) / 5) * 0.27
            case .orbit:
                let frequency = 170 + 1_000 * direction * direction
                phase += 2 * .pi * frequency / Double(sampleRate)
                sample = sin(phase) * 0.32 + lowPass * 0.25
            case .click:
                sample = (sin(2 * .pi * (opening ? 1_180.0 : 640.0) * t) * 0.42 + white * 0.16) * exp(-t * 48)
            case .crystal:
                let frequency = opening ? 1_568.0 : 1_174.66
                sample = bell(t, frequency: frequency) * 0.28
                    + bell(t - 0.11, frequency: frequency * (opening ? 1.5 : 0.75)) * 0.22
            case .marimba:
                let first = opening ? 523.25 : 440.0
                let second = opening ? 659.25 : 329.63
                sample = wood(t, frequency: first) * 0.40
                    + wood(t - 0.12, frequency: second) * 0.38
            case .musicBox:
                var notes = 0.0
                for (index, frequency) in melody.enumerated() {
                    let local = t - 0.10 * Double(index)
                    notes += bell(local, frequency: frequency) * 0.20
                }
                sample = notes
            case .zipper:
                let teeth = opening ? 90 + 150 * progress : 240 - 150 * progress
                phase += 2 * .pi * teeth / Double(sampleRate)
                let rasp = pow((1 + sin(phase)) / 2, 5)
                sample = (white * 0.36 + lowPass * 0.45) * (0.2 + rasp * 0.8)
                    * pow(sin(.pi * progress), 0.6)
            case .latch:
                let release = opening ? 1_450.0 : 920.0
                let catchPitch = opening ? 390.0 : 240.0
                sample = impact(t - 0.012, frequency: release, noise: white, decay: 85) * 0.34
                    + impact(t - 0.10, frequency: catchPitch, noise: lowPass, decay: 55) * 0.55
            case .typewriter:
                var keys = 0.0
                for index in 0..<3 {
                    let local = t - 0.012 - Double(index) * (opening ? 0.055 : 0.045)
                    let pitch = (opening ? 850.0 : 650.0) + Double(index) * 135
                    keys += impact(local, frequency: pitch, noise: white, decay: 110) * 0.46
                    keys += tone(local, frequency: pitch * 0.24, decay: 65) * 0.23
                }
                sample = keys
            case .waterDrop:
                let first = opening ? 900.0 : 700.0
                let second = opening ? 1_350.0 : 510.0
                phase += 2 * .pi * (first + 1_000 * exp(-t * 28)) / Double(sampleRate)
                let local = max(0, t - 0.16)
                secondPhase += 2 * .pi * (second + 850 * exp(-local * 30)) / Double(sampleRate)
                sample = sin(phase) * envelope(t, decay: 22) * 0.45
                    + (t >= 0.16 ? sin(secondPhase) * envelope(local, decay: 24) * 0.38 : 0)
            case .bird:
                let firstProgress = min(1, t / 0.15)
                let secondProgress = min(1, max(0, (t - 0.24) / 0.18))
                let first = opening ? 2_000 + 1_400 * firstProgress : 3_200 - 1_000 * firstProgress
                let second = opening ? 2_500 + 1_100 * secondProgress : 2_700 - 900 * secondProgress
                phase += 2 * .pi * (first + 70 * sin(2 * .pi * 35 * t)) / Double(sampleRate)
                secondPhase += 2 * .pi * second / Double(sampleRate)
                sample = sin(phase) * pulse(t, length: 0.15) * 0.30
                    + sin(secondPhase) * pulse(t - 0.24, length: 0.18) * 0.28
            case .rain:
                let shower = (white - lowPass) * 0.17 * pow(sin(.pi * progress), 0.8)
                var drops = 0.0
                for index in 0..<5 {
                    let offset = 0.035 + Double(index) * (opening ? 0.103 : 0.089)
                    let frequency = (opening ? 1_250.0 : 1_000.0) + Double(index % 3) * 310
                    drops += tone(t - offset, frequency: frequency, decay: 110) * 0.21
                }
                sample = shower + drops
            case .bubble:
                let local = max(0, t - 0.13)
                let first = opening ? 420 + 1_500 * t : 800 - 700 * t
                let second = opening ? 690 + 2_000 * local : 590 - 650 * local
                phase += 2 * .pi * first / Double(sampleRate)
                secondPhase += 2 * .pi * second / Double(sampleRate)
                sample = sin(phase) * envelope(t, decay: 36) * 0.53
                    + (t >= 0.13 ? sin(secondPhase) * envelope(local, decay: 40) * 0.48 : 0)
            case .spring:
                let base = opening ? 210.0 : 155.0
                let wobble = (opening ? 70.0 : -55.0) * sin(2 * .pi * 17 * t) * exp(-t * 6)
                phase += 2 * .pi * (base + wobble) / Double(sampleRate)
                sample = (sin(phase) + 0.25 * sin(phase * 3)) * envelope(t, decay: 7) * 0.44
            case .cork:
                phase += 2 * .pi * ((opening ? 560.0 : 390.0) * exp(-t * 24) + 105) / Double(sampleRate)
                sample = (sin(phase) * 0.62 + white * 0.10) * envelope(t, decay: opening ? 32 : 42)
            case .laser:
                let frequency = opening ? 380 * pow(8, progress) : 3_040 * pow(0.125, progress)
                phase += 2 * .pi * frequency / Double(sampleRate)
                sample = (sin(phase) + 0.22 * sin(phase * 2)) * 0.34 * (1 - progress * 0.65)
            case .robot:
                let syllable = min(2, Int(t / 0.14))
                let frequency = (opening ? 175.0 : 225.0) + Double(syllable) * (opening ? 65 : -45)
                phase += 2 * .pi * frequency / Double(sampleRate)
                let voice = sin(phase) + 0.45 * sin(phase * 2) + 0.25 * sin(phase * 5)
                sample = voice * 0.28 * pulse(t - Double(syllable) * 0.14, length: 0.11)
            case .powerUp:
                let index = min(4, Int(t / 0.11))
                let local = t - Double(index) * 0.11
                phase += 2 * .pi * powerNotes[index] / Double(sampleRate)
                sample = (sin(phase) + 0.20 * sin(phase * 2)) * 0.40
                    * pulse(local, length: index == 4 ? 0.26 : 0.11)
            case .off, .custom: sample = 0
            }
            let value = max(-0.85, min(0.85, sample * ramp))
            pcm.append(Int16((value * Double(Int16.max)).rounded()))
        }
        pcm[0] = 0; pcm[count - 1] = 0
        var data = Data("RIFF".utf8)
        append(UInt32(36 + count * 2), to: &data)
        data.append(contentsOf: "WAVEfmt ".utf8)
        append(UInt32(16), to: &data); append(UInt16(1), to: &data); append(UInt16(1), to: &data)
        append(UInt32(sampleRate), to: &data); append(UInt32(sampleRate * 2), to: &data)
        append(UInt16(2), to: &data); append(UInt16(16), to: &data)
        data.append(contentsOf: "data".utf8); append(UInt32(count * 2), to: &data)
        for sample in pcm { append(UInt16(bitPattern: sample), to: &data) }
        return data
    }
    // Smooth transient attacks and release windows keep the new voices free of
    // discontinuities at note boundaries. Final PCM still has the legacy cap.
    private static func envelope(_ time: Double, decay: Double) -> Double {
        guard time > 0 else { return 0 }
        return min(1, time / 0.003) * exp(-time * decay)
    }

    private static func pulse(_ time: Double, length: Double) -> Double {
        guard time > 0, time < length else { return 0 }
        return pow(sin(.pi * time / length), 2)
    }

    private static func tone(_ time: Double, frequency: Double, decay: Double) -> Double {
        sin(2 * .pi * frequency * time) * envelope(time, decay: decay)
    }

    private static func bell(_ time: Double, frequency: Double) -> Double {
        tone(time, frequency: frequency, decay: 9)
            + tone(time, frequency: frequency * 2.76, decay: 17) * 0.24
            + tone(time, frequency: frequency * 4.07, decay: 24) * 0.09
    }

    private static func wood(_ time: Double, frequency: Double) -> Double {
        tone(time, frequency: frequency, decay: 18)
            + tone(time, frequency: frequency * 3.99, decay: 60) * 0.28
    }

    private static func impact(_ time: Double, frequency: Double, noise: Double, decay: Double) -> Double {
        (sin(2 * .pi * frequency * time) * 0.65 + noise * 0.35) * envelope(time, decay: decay)
    }

    private static func append<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
        var little = value.littleEndian
        withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
    }
}
