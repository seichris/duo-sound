import Foundation

/// Original procedural effects; no third-party audio assets or downloads.
public enum SoundSynthesizer {
    public static let sampleRate = 44_100
    public static func wav(preset: SoundPreset, event: FoldEvent) -> Data? {
        guard SoundPreset.builtIns.contains(preset) else { return nil }
        let duration = preset == .click ? 0.13 : 0.42
        let count = Int(duration * Double(sampleRate))
        let opening = event == .opened
        var noise: UInt64 = opening ? 417 : 913
        var lowPass = 0.0
        var phase = 0.0
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
    private static func append<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
        var little = value.littleEndian
        withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
    }
}
