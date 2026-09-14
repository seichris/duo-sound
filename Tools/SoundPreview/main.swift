import Foundation
import DuoSoundCore

/// Offline review aid, never linked into the iOS application.
/// Refuse existing output to avoid silently replacing someone else's samples.
@main
struct SoundPreview {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            throw PreviewError.usage
        }
        let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        guard !FileManager.default.fileExists(atPath: output.path) else {
            throw PreviewError.outputExists
        }
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        var rows = ""
        var manifest: [Clip] = []
        for category in SoundCategory.allCases {
            rows += "<h2>\(category.title)</h2>"
            for preset in SoundPreset.presets(in: category) {
                rows += "<section><h3>\(preset.title)</h3><p>\(preset.detail)</p><div class=pair>"
                for event in FoldEvent.allCases {
                    guard let data = SoundSynthesizer.wav(preset: preset, event: event) else { continue }
                    let file = "\(preset.rawValue)-\(event.rawValue).wav"
                    try data.write(to: output.appendingPathComponent(file), options: .atomic)
                    manifest.append(Clip(preset: preset.rawValue, category: category.rawValue, event: event.rawValue,
                                         file: file, duration: Double((data.count - 44) / 2) / Double(SoundSynthesizer.sampleRate)))
                    rows += "<div><label>\(event.title)<audio aria-label='\(preset.title) \(event.title.lowercased())' controls preload=none src='\(file)'></audio></label></div>"
                }
                rows += "</div></section>"
            }
        }
        let html = """
        <!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
        <title>Duo Sound — original sound library</title>
        <style>body{font:17px system-ui,sans-serif;max-width:850px;margin:40px auto;padding:0 20px}h1{line-height:1.1}section{padding:8px 0 20px;border-bottom:1px solid #bbb}.pair{display:flex;flex-wrap:wrap;gap:24px}audio{display:block;max-width:100%;margin-top:8px}h2{margin-top:40px}</style>
        <h1>\(SoundPreset.builtIns.count) sounds. Both directions.</h1>
        <p>Original procedural audio exported from Duo Sound. Start at a low device volume. These unscaled files play at full effect level; the app defaults to 65% effect volume. This is an audio sampler, not evidence of physical hinge detection.</p>
        <p>No network, autoplay, tracking, or third-party audio assets.</p>\(rows)</html>
        """
        try html.write(to: output.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(manifest).write(to: output.appendingPathComponent("manifest.json"), options: .atomic)
        print("Exported \(manifest.count) clips to \(output.path). Open index.html to audition them.")
    }

    struct Clip: Encodable {
        let preset, category, event, file: String
        let duration: Double
    }
    enum PreviewError: Error {
        case usage, outputExists
    }
}
