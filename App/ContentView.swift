import SwiftUI
import UniformTypeIdentifiers

@MainActor
struct ContentView: View {
    @ObservedObject var model: AppModel
    @State private var importEvent: FoldEvent = .opened
    @State private var showImporter = false
    @State private var showAbout = false
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("A little sound.\nEvery fold.")
                            .font(.largeTitle.bold()).fixedSize(horizontal: false, vertical: true)
                        Label(model.status, systemImage: model.isDemo ? "play.circle" : "waveform")
                            .font(.caption.weight(.semibold)).foregroundStyle(model.isDemo ? Color.orange : Color.indigo)
                            .accessibilityIdentifier("monitoringStatus")
                        HingeIllustration(angle: model.angle ?? 90)
                            .frame(height: 100).frame(maxWidth: .infinity).accessibilityHidden(true)
                        HStack {
                            Text(model.stateLabel).font(.headline)
                            Spacer()
                            Text(model.angle.map { "\(Int($0.rounded()))°" } ?? "—")
                                .font(.title2.monospacedDigit())
                        }
                        Text(model.lastEvent).font(.caption).foregroundStyle(.secondary)
                            .accessibilityIdentifier("lastEvent")
                    }.padding(.vertical, 8)
                }
                Section {
                    Toggle("Enable fold sounds", isOn: Binding(get: { model.settings.enabled },
                        set: { value in model.updateSettings { $0.enabled = value } }))
                    VStack(alignment: .leading) {
                        Text("Effect volume · \(Int(model.settings.volume * 100))%")
                        Slider(value: Binding(get: { model.settings.volume },
                            set: { value in model.updateSettings { $0.volume = value } }), in: 0...1, step: 0.05)
                            .accessibilityLabel("Effect volume")
                    }
                } footer: {
                    Text("Respects Silent Mode and system volume. Audio follows your current output, including headphones. Preview buttons work even when fold sounds are paused.")
                }
                soundSection(.opened)
                soundSection(.closed)
                Section {
                    Toggle("Simulate hinge", isOn: Binding(get: { model.isDemo }, set: model.setDemo))
                    if model.isDemo {
                        Slider(value: Binding(get: { model.demoAngle }, set: model.setDemoAngle), in: 0...180, step: 1)
                            .accessibilityLabel("Simulated hinge angle").accessibilityIdentifier("demoAngle")
                        HStack {
                            Button { model.setDemoAngle(180) } label: { Label("Open", systemImage: "arrow.up.left.and.arrow.down.right") }
                                .accessibilityIdentifier("demoOpen")
                            Spacer()
                            Button { model.setDemoAngle(0) } label: { Label("Close", systemImage: "arrow.down.right.and.arrow.up.left") }
                                .accessibilityIdentifier("demoClose")
                        }.buttonStyle(.bordered)
                    }
                } header: { Text("Try a fold") } footer: {
                    Text(model.isDemo ? "Simulated events only; these controls do not read your phone’s hinge." : "Automatic detection needs a build with the Duo hinge SDK and a supported device. This build never guesses from screen size, rotation, or lock state.")
                }
                Section {
                    Label("Foreground only", systemImage: "info.circle")
                    Text("Duo Sound must be visible and active. It does not listen while another app is open, the phone is locked, or this app is suspended. Closing during a display handoff still needs device testing.")
                        .font(.footnote).foregroundStyle(.secondary)
                    if !AppModel.hingeSDKEnabled {
                        Text("Preview build: Apple’s announced hinge API is not compiled in. All fold events here are simulated. See the repository’s SDK activation guide.")
                            .font(.footnote).foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle("Duo Sound")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("About", systemImage: "info.circle") { showAbout = true }
                }
            }
            .sheet(isPresented: $showAbout) {
                NavigationStack {
                    Form {
                        Section("Sound, not surveillance") {
                            Text("No account, analytics, microphone permission, or network service. Settings and imported sounds stay in this app’s private storage. The activity label is not saved.")
                        }
                        Section("Built for iPhone Duo") {
                            Text("Inspired by Scrunch. Original Swift implementation and original synthesized sounds; no Scrunch code or sound assets are bundled.")
                            Text("Hinge integration is based on Apple’s September 2026 developer talks. The default build is a demo until the iOS 27.1 SDK integration is compiled and tested.")
                        }
                    }
                    .navigationTitle("About Duo Sound")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showAbout = false } } }
                }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.audio]) { result in
                switch result {
                case .success(let url): model.importSound(from: url, event: importEvent)
                case .failure(let error): model.errorMessage = error.localizedDescription
                }
            }
            .alert("Duo Sound", isPresented: Binding(get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } })) {
                    Button("OK", role: .cancel) { model.errorMessage = nil }
                } message: { Text(model.errorMessage ?? "") }
        }
    }
    private func soundSection(_ event: FoldEvent) -> some View {
        Section {
            Picker("Sound", selection: Binding(get: { model.settings.preset(for: event) },
                set: { preset in model.updateSettings { $0.select(preset, for: event) } })) {
                ForEach(SoundPreset.builtIns + [.off], id: \.self) { Text($0.title).tag($0) }
                if let imported = model.settings.imported(for: event) {
                    Text(imported.displayName).tag(SoundPreset.custom)
                }
            }
            HStack {
                Button { model.preview(event) } label: { Label("Preview", systemImage: "play.fill") }
                    .accessibilityLabel("Preview \(event.title.lowercased()) sound")
                Spacer()
                Button { importEvent = event; showImporter = true } label: { Label("Import", systemImage: "square.and.arrow.down") }
                    .accessibilityLabel("Import \(event.title.lowercased()) sound")
            }.buttonStyle(.bordered)
        } header: { Text("When \(event.title.lowercased())") }
          footer: { Text("Original presets or your own audio clip, up to 5 seconds and 8 MB.") }
    }
}

private struct HingeIllustration: View {
    let angle: Double
    var body: some View {
        HStack(spacing: 4) {
            panel.rotation3DEffect(.degrees(-(180 - angle) * 0.42), axis: (x: 0, y: 1, z: 0), anchor: .trailing)
            panel.rotation3DEffect(.degrees((180 - angle) * 0.42), axis: (x: 0, y: 1, z: 0), anchor: .leading)
        }
    }
    private var panel: some View {
        RoundedRectangle(cornerRadius: 12).fill(.indigo.gradient)
            .overlay { Image(systemName: "waveform").font(.title).foregroundStyle(.white.opacity(0.8)) }
            .frame(width: 78, height: 98)
    }
}
