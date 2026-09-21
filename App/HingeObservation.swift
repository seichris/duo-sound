import SwiftUI

// The default scheme intentionally remains a simulation.  The Duo build uses
// UIKit's public UIHingeInteraction, but resolves the class at runtime so the
// distribution binary can be built with Apple's supported stable SDK.  This
// keeps the app installable on older iOS releases while allowing iOS 27.1 to
// provide real hinge updates.
#if DUO_HINGE_SDK
import ObjectiveC
import UIKit
#endif

@MainActor
struct HingeObservation: ViewModifier {
    @ObservedObject var model: AppModel
    @ViewBuilder func body(content: Content) -> some View {
        #if DUO_HINGE_SDK
        content.background(
            HingeInteractionBridge { angle in
                model.receiveHardware(angle: angle)
            }
            .frame(width: 0, height: 0)
        )
        #else
        content
        #endif
    }
}

#if DUO_HINGE_SDK
/// A zero-size view that installs Apple's public hinge interaction into the
/// SwiftUI hierarchy.  The runtime lookup is deliberate: Xcode 26.6 can build
/// this release while iOS 27.1 supplies the class on a supported Duo device.
@MainActor
private struct HingeInteractionBridge: UIViewRepresentable {
    let onAngle: (Double?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onAngle: onAngle)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        if let interaction = context.coordinator.makeInteraction() {
            view.addInteraction(interaction)
        } else {
            // This is expected on ordinary iPhones and on iOS versions before
            // 27.1.  AppModel reports the resulting lack of hinge data.
            onAngle(nil)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    @MainActor
    final class Coordinator {
        private let onAngle: (Double?) -> Void
        private var interaction: UIInteraction?

        init(onAngle: @escaping (Double?) -> Void) {
            self.onAngle = onAngle
        }

        func makeInteraction() -> UIInteraction? {
            guard #available(iOS 27.1, *) else { return nil }
            guard let interactionType = NSClassFromString("UIHingeInteraction") as? NSObject.Type else {
                return nil
            }

            // UIHingeInteraction has an unavailable `init` in the SDK.  Use
            // Objective-C runtime allocation only to call its documented
            // `initWithUpdateHandler:` initializer; no private selector or
            // framework symbol is used.
            let raw = class_createInstance(interactionType, 0) as! NSObject
            let handler: @convention(block) (AnyObject, AnyObject) -> Void = { [onAngle] _, update in
                let hinge = (update as? NSObject)?.value(forKey: "hinge") as? NSObject
                let radians = (hinge?.value(forKey: "angle") as? NSNumber)?.doubleValue
                let degrees = radians.map { $0 * 180 / .pi }
                Task { @MainActor in
                    onAngle(degrees)
                }
            }
            let selector = NSSelectorFromString("initWithUpdateHandler:")
            guard let initialized = raw.perform(selector, with: handler)?.takeUnretainedValue() as? NSObject,
                  let interaction = initialized as? UIInteraction else {
                return nil
            }
            self.interaction = interaction
            return interaction
        }
    }
}
#endif
