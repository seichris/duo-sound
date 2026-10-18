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
                .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
                    .receive(on: DispatchQueue.main)) { _ in model.interruptAudio() }
                .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.mediaServicesWereResetNotification)
                    .receive(on: DispatchQueue.main)) { _ in model.interruptAudio() }
                .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
                    .receive(on: DispatchQueue.main),
                           perform: model.audioRouteChanged)
        }
    }
}
