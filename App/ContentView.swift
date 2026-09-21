import SwiftUI
import UniformTypeIdentifiers

@MainActor
struct ContentView: View {
    @ObservedObject var model: AppModel
    @State private var importEvent: FoldEvent = .opened
    @State private var showImporter = false
    @State private var showAbout = false
    @State private var libraryEvent: FoldEvent = .opened
    @State private var showLibrary = false
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
                    Text("Hingy must be visible and active. It does not listen while another app is open, the phone is locked, or this app is suspended. Closing during a display handoff still needs device testing.")
                        .font(.footnote).foregroundStyle(.secondary)
                    if !AppModel.hingeSDKEnabled {
                        Text("Preview build: Apple’s announced hinge API is not compiled in. All fold events here are simulated. See the repository’s SDK activation guide.")
                            .font(.footnote).foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle("Hingy")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("About", systemImage: "info.circle") { showAbout = true }
                }
            }
            .sheet(isPresented: $showAbout) {
                NavigationStack {
                    Form {
                        Section("Sound, not surveillance") {
                            Text("No account, analytics SDK, microphone recording, or app-operated network service. Device backups and external support services are separate.")
                            NavigationLink("Privacy & data") { PrivacyView() }
                                .accessibilityIdentifier("privacyPolicy")
                            NavigationLink("Help with sounds") { SoundHelpView() }
                                .accessibilityIdentifier("soundHelp")
                        }
                        Section("Built for iPhone Duo") {
                            Text("Inspired by Scrunch. Original Swift implementation and original synthesized sounds; no Scrunch code or sound assets are bundled.")
                            Text("Hinge integration is based on Apple’s September 2026 developer talks. The default build remains a demo; the Duo schemes compile the iOS 27.1 hinge API, while physical hinge behavior still needs device validation.")
                        }
                    }
                    .navigationTitle("About Hingy")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showAbout = false } } }
                }
            }
            .sheet(isPresented: $showLibrary) {
                SoundLibraryView(model: model, event: libraryEvent)
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.audio]) { result in
                switch result {
                case .success(let url): model.importSound(from: url, event: importEvent)
                case .failure(let error): model.errorMessage = error.localizedDescription
                }
            }
            .alert("Hingy", isPresented: Binding(get: { !showLibrary && model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } })) {
                    Button("OK", role: .cancel) { model.errorMessage = nil }
                } message: { Text(model.errorMessage ?? "") }
        }
    }
    private func soundSection(_ event: FoldEvent) -> some View {
        Section {
            Button {
                libraryEvent = event
                showLibrary = true
            } label: {
                HStack {
                    Text("Sound").foregroundStyle(.primary)
                    Spacer()
                    Text(model.settings.preset(for: event) == .custom
                         ? (model.settings.imported(for: event)?.displayName ?? "Custom")
                         : model.settings.preset(for: event).title)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                }
            }
            .accessibilityLabel("Choose \(event.title.lowercased()) sound")
            .accessibilityValue(model.settings.preset(for: event).title)
            .accessibilityIdentifier("soundChoice-\(event.rawValue)")
            HStack {
                Button { model.preview(event) } label: { Label("Preview", systemImage: "play.fill") }
                    .accessibilityLabel("Preview \(event.title.lowercased()) sound")
                Spacer()
                Button { importEvent = event; showImporter = true } label: { Label("Import", systemImage: "square.and.arrow.down") }
                    .accessibilityLabel("Import \(event.title.lowercased()) sound")
            }.buttonStyle(.bordered)
        } header: { Text("When \(event.title.lowercased())") }
          footer: { Text("\(SoundPreset.builtIns.count) original presets, or your own audio clip up to 5 seconds and 8 MiB.") }
    }
}


/// Audition any effect without replacing the saved opening/closing selection.
@MainActor
struct SoundLibraryView: View {
    @ObservedObject var model: AppModel
    let event: FoldEvent
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    var body: some View {
        NavigationStack {
            List {
                if search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Section {
                        row(.off)
                        if let imported = model.settings.imported(for: event) {
                            row(.custom, title: imported.displayName)
                        }
                    } header: { Text("Your choice") } footer: {
                        Text("Tap a name to select it. Play buttons only preview; they do not change your selection.")
                    }
                }
                ForEach(SoundCategory.allCases, id: \.self) { category in
                    let presets = SoundPreset.presets(in: category).filter(matches)
                    if !presets.isEmpty {
                        Section(category.title) {
                            ForEach(presets, id: \.self) { preset in row(preset) }
                        }
                    }
                }
                if !search.isEmpty && SoundPreset.builtIns.filter(matches).isEmpty {
                    Text("No matching sounds").foregroundStyle(.secondary)
                        .accessibilityIdentifier("noMatchingSounds")
                }
            }
            .navigationTitle("\(event.title) sounds")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Search \(SoundPreset.builtIns.count) sounds")
            .alert("Hingy", isPresented: Binding(get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } })) {
                    Button("OK", role: .cancel) { model.errorMessage = nil }
                } message: { Text(model.errorMessage ?? "") }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private func matches(_ preset: SoundPreset) -> Bool {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty || preset.title.localizedCaseInsensitiveContains(query)
            || preset.detail.localizedCaseInsensitiveContains(query)
            || (preset.category?.title.localizedCaseInsensitiveContains(query) ?? false)
    }

    private func row(_ preset: SoundPreset, title: String? = nil) -> some View {
        HStack(spacing: 12) {
            Button {
                model.updateSettings { $0.select(preset, for: event) }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: model.settings.preset(for: event) == preset ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(model.settings.preset(for: event) == preset ? Color.accentColor : Color.secondary)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title ?? preset.title).foregroundStyle(.primary)
                        Text(preset.detail).font(.caption).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }.contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(title ?? preset.title)
            .accessibilityValue(model.settings.preset(for: event) == preset ? "Selected" : "Not selected")
            .accessibilityIdentifier("select-\(event.rawValue)-\(preset.rawValue)")
            if preset != .off {
                Button { model.preview(event, preset: preset) } label: {
                    Image(systemName: "play.circle.fill").font(.title2)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Preview \(title ?? preset.title) \(event.title.lowercased()) sound")
                .accessibilityIdentifier("preview-\(event.rawValue)-\(preset.rawValue)")
            }
        }
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
