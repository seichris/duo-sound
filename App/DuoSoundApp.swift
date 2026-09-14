import SwiftUI
import AVFoundation

@MainActor
@main
struct DuoSoundApp: App {
    @StateObject private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .modifier(HingeObservation(model: model))
                .onChange(of: scenePhase, initial: true) { _, phase in model.setActive(phase == .active) }
                .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { _ in model.interruptAudio() }
                .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.mediaServicesWereResetNotification)) { _ in model.interruptAudio() }
                .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)) { note in
                    // Category changes caused by our own activation aren't an interruption.
                    let reason = (note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? NSNumber)?.uintValue
                    if reason != AVAudioSession.RouteChangeReason.categoryChange.rawValue { model.interruptAudio() }
                }
        }
    }
}
