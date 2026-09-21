import SwiftUI

/// The ONLY Duo SDK dependency. Keep the default build working on released SDKs.
/// Public preview: Apple Tech Talk 111464, 01:44–02:17 (September 9, 2026).
/// Xcode 27.1 beta exposes the demonstrated `onHingeChange` declarations.
/// The Duo schemes compile this branch; physical hinge behavior still needs
/// validation on the Duo simulator or a real device.
@MainActor
struct HingeObservation: ViewModifier {
    @ObservedObject var model: AppModel
    @ViewBuilder func body(content: Content) -> some View {
        #if DUO_HINGE_SDK
        if #available(iOS 27.1, *) {
            content.onHingeChange { _, context in
                model.receiveHardware(angle: context.hinge?.angle.degrees)
            }
        } else {
            content.onAppear { model.receiveHardware(angle: nil) }
        }
        #else
        content
        #endif
    }
}
