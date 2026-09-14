import SwiftUI

/// The ONLY Duo SDK dependency. Keep the default build working on released SDKs.
/// Public preview: Apple Tech Talk 111464, 01:44–02:17 (September 9, 2026).
/// Apple lists Xcode 27.1 beta as coming later this month on September 14.
/// Enable DUO_HINGE_SDK only after checking the actual 27.1 SDK declarations.
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
