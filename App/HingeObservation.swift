import SwiftUI

#if DUO_HINGE_SDK
import UIKit
#endif

@MainActor
struct HingeObservation: ViewModifier {
    @ObservedObject var model: AppModel

    @ViewBuilder func body(content: Content) -> some View {
        #if DUO_HINGE_SDK
        content.background(
            HingeInteractionBridge(model: model)
                .frame(width: 0, height: 0)
        )
        .onAppear {
            if #unavailable(iOS 27.1) { model.receiveHardware(angle: nil) }
        }
        #else
        content
        #endif
    }
}

#if DUO_HINGE_SDK
/// Uses Apple's typed SDK declarations with runtime availability checks.
@MainActor
private struct HingeInteractionBridge: UIViewRepresentable {
    @ObservedObject var model: AppModel

    func makeCoordinator() -> Coordinator { Coordinator(model: model) }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        if #available(iOS 27.1, *) {
            let coordinator = context.coordinator
            let interaction = UIHingeInteraction { [weak coordinator] _, update in
                coordinator?.receive(update.hinge.map { Double($0.angle) * 180 / .pi })
            }
            interaction.isEnabled = false
            view.addInteraction(interaction)
        }
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        if #available(iOS 27.1, *),
           let interaction = view.interactions.compactMap({ $0 as? UIHingeInteraction }).first {
            let enabled = model.isActive
            guard interaction.isEnabled != enabled else { return }
            context.coordinator.invalidate()
            // Re-enabling delivers the current sample, silently rebaselining
            // after foreground return.
            interaction.isEnabled = enabled
        }
    }

    static func dismantleUIView(_ view: UIView, coordinator: Coordinator) {
        coordinator.invalidate()
    }

    @MainActor
    final class Coordinator {
        private weak var model: AppModel?
        private var generation = 0

        init(model: AppModel) { self.model = model }
        func invalidate() { generation += 1 }

        func receive(_ angle: Double?) {
            let expected = generation
            // Initial/re-enable updates can arrive during updateUIView. Publish
            // after that render pass, discarding callbacks from old lifecycles.
            Task { @MainActor [weak self] in
                guard let self, self.generation == expected, let model = self.model,
                      model.isActive else { return }
                model.receiveHardware(angle: angle)
            }
        }
    }
}
#endif
