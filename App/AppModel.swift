import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var settings = SoundSettings()
    @Published private(set) var angle: Double?
    @Published private(set) var hardwareAvailable: Bool?
    @Published private(set) var lastEvent = "No sound triggered yet"
    @Published var errorMessage: String?
    @Published private(set) var demoAngle = 0.0
    @Published private(set) var isActive = false
    @Published private(set) var isDemo = !AppModel.hingeSDKEnabled

    static var hingeSDKEnabled: Bool {
        #if DUO_HINGE_SDK
        return true
        #else
        return false
        #endif
    }
    private var store: SettingsStore?
    private let audio = SoundPlayer()
    private var detector = FoldDetector()
    private var pending: Task<Void, Never>?
    private let epoch = ContinuousClock.now
    private var generated: [String: Data] = [:]

    init() {
        do {
            let directory = try FileManager.default.url(for: .applicationSupportDirectory,
                in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("DuoSound", isDirectory: true)
            let storage = SettingsStore(directory: directory)
            store = storage
            settings = try storage.load()
        } catch { errorMessage = "Could not load settings: \(error.localizedDescription)" }
    }

    var status: String {
        if isDemo { return "DEMO · SIMULATED HINGE" }
        if !Self.hingeSDKEnabled { return "HINGE SDK NOT ENABLED" }
        if hardwareAvailable == false { return "NO HINGE AVAILABLE" }
        if hardwareAvailable == nil { return "AWAITING HINGE DATA" }
        return isActive && settings.enabled ? "FOREGROUND LISTENING" : "SOUNDS PAUSED"
    }
    var stateLabel: String {
        guard let angle else { return "No hinge reading" }
        if angle <= 8 { return "Closed" }
        if angle >= 172 { return "Fully open" }
        return "Partially open"
    }
    private var now: Double {
        let value = epoch.duration(to: .now).components
        return Double(value.seconds) + Double(value.attoseconds) / 1e18
    }

    func setActive(_ value: Bool) {
        guard isActive != value else { return }
        isActive = value
        resetObservation()
    }
    func setDemo(_ value: Bool) {
        guard isDemo != value else { return }
        isDemo = value
        resetObservation()
    }
    func setDemoAngle(_ value: Double) {
        guard value.isFinite else { return }
        demoAngle = min(180, max(0, value))
        guard isDemo else { return }
        receive(demoAngle)
    }
    func receiveHardware(angle value: Double?) {
        hardwareAvailable = value != nil
        guard !isDemo else { return }
        guard let value else {
            resetObservation(); return
        }
        receive(value)
    }
    func interruptAudio() {
        // Never resume an old effect after a call, route change, or media reset.
        resetObservation()
    }
    func updateSettings(_ edit: (inout SoundSettings) -> Void) {
        var next = settings
        edit(&next)
        do { try commit(next) }
        catch { errorMessage = "Could not save settings: \(error.localizedDescription)" }
    }
    private func commit(_ next: SoundSettings) throws {
        guard let store else { throw SoundFailure.invalidSettings }
        try store.save(next)
        let enabledChanged = settings.enabled != next.enabled
        settings = next
        if enabledChanged { resetObservation() }
    }
    func preview(_ event: FoldEvent, preset: SoundPreset? = nil) {
        guard isActive else { return }
        play(event, label: "Preview", preset: preset)
    }
    func importSound(from url: URL, event: FoldEvent) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            guard let store else { throw SoundFailure.invalidSettings }
            let data = try SettingsStore.readBounded(url, limit: 8 * 1_024 * 1_024)
            try SoundPlayer.validate(data)
            let record = ImportedSound(fileName: UUID().uuidString + ".sound",
                                       displayName: String(url.lastPathComponent.prefix(120)))
            let destination = try store.soundURL(for: record)
            try FileManager.default.createDirectory(at: store.directory, withIntermediateDirectories: true)
            try data.write(to: destination, options: .atomic)
            let old = settings.imported(for: event)
            var next = settings
            next.setImported(record, for: event)
            do { try commit(next) }
            catch {
                try? FileManager.default.removeItem(at: destination)
                throw error
            }
            if let old, old != next.openingFile, old != next.closingFile,
               let oldURL = try? store.soundURL(for: old) {
                try? FileManager.default.removeItem(at: oldURL)
            }
        } catch { errorMessage = "Could not import audio: \(error.localizedDescription)" }
    }

    private func resetObservation() {
        pending?.cancel(); pending = nil
        detector.reset()
        audio.stop()
        angle = isDemo ? demoAngle : nil
        if isActive && isDemo { _ = detector.ingest(angle: demoAngle, at: now) }
    }
    private func receive(_ value: Double) {
        guard isActive else { return }
        pending?.cancel(); pending = nil
        guard value.isFinite, (0...180).contains(value) else {
            detector.reset(); angle = nil; return
        }
        angle = value
        if let event = detector.ingest(angle: value, at: now) { trigger(event) }
        guard let deadline = detector.deadline else { return }
        let delay = max(0, deadline - now)
        pending = Task { [weak self] in
            do { try await Task.sleep(nanoseconds: UInt64((delay + 0.001) * 1e9)) }
            catch { return }
            guard let self, self.isActive, !Task.isCancelled else { return }
            if let event = self.detector.advance(to: self.now) { self.trigger(event) }
        }
    }
    private func trigger(_ event: FoldEvent) {
        guard isActive, settings.enabled else { return }
        play(event, label: isDemo ? "Demo fold" : "Hinge")
    }
    private func play(_ event: FoldEvent, label: String, preset override: SoundPreset? = nil) {
        let preset = override ?? settings.preset(for: event)
        guard preset != .off else {
            audio.stop(); lastEvent = "\(label) · \(event.title) sound is off"; return
        }
        do {
            let data: Data
            if preset == .custom {
                guard let record = settings.imported(for: event), let store else { throw SoundFailure.missingSound }
                data = try SettingsStore.readBounded(store.soundURL(for: record), limit: 8 * 1_024 * 1_024)
            } else {
                let key = preset.rawValue + event.rawValue
                if let cached = generated[key] { data = cached }
                else {
                    guard let rendered = SoundSynthesizer.wav(preset: preset, event: event) else {
                        throw SoundFailure.missingSound
                    }
                    generated[key] = rendered; data = rendered
                }
            }
            try audio.play(data, volume: settings.volume)
            lastEvent = "\(label) · \(event.title) · \(preset.title)"
        } catch { errorMessage = error.localizedDescription }
    }
}
