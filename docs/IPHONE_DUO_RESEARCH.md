# iPhone Duo research — September 14, 2026

## Scope and conclusion

Reviewed Apple's Duo developer landing page, the published summaries/code from all six linked Tech Talks, the Human Interface Guidelines entry/indexed excerpts, relevant Apple audio/background guidance, and Scrunch's README and fold detection source. This is the publicly reachable material found on this date, not a claim to have accessed unreleased SDK headers or every forum post. The HIG page body was JavaScript-only in retrieval; its indexed excerpts and the dedicated design talk supplied the design overview. Standalone hinge symbol documentation was not retrievable.

**Verified preview, not verified runtime:** Apple demonstrates SwiftUI `onHingeChange`, nullable `context.hinge`, `hinge.angle` (SwiftUI `Angle`), and `.partiallyOpen`. Its talk also describes UIKit `UIHingeInteraction`. The code uses the demonstrated SwiftUI callback and degrees only; it does not invent a `HingeManager`, device model identifier, permission, or background service. Exact availability, initial delivery, angle semantics at endpoints and lifecycle ordering still need the actual SDK/device.

**Availability:** The developer landing page says Xcode 27.1 beta and the written “Preparing your app” guide are coming later this month. Forward-looking instructions in the talks are not evidence that the SDK has shipped. Accordingly the default build excludes the adapter at compile time. A runtime `#available` check alone would not let an older SDK compile an unknown symbol.

## Apple documentation inventory

| Source | Relevant finding and implementation choice |
|---|---|
| [Developer landing page](https://developer.apple.com/iphone-duo/) | Canonical inventory, six videos, tooling availability and upcoming labs. Recheck here before activating the adapter. |
| [Design for iPhone Duo — 111466](https://developer.apple.com/videos/play/tech-talks/111466/) | Poses, reachable edge controls, resizing and fold avoidance. Use native controls and safe-area-aware layout. |
| [Prepare your app — 111461](https://developer.apple.com/videos/play/tech-talks/111461/) | SDK-linked improvements, size classes, asymmetric safe areas, and Device Hub simulation. Do not detect folds from size classes, orientation, or `UIScreen.main`. |
| [Raise the bar — 111462](https://developer.apple.com/videos/play/tech-talks/111462/) | Standard navigation containers and symbol-labelled toolbar actions adapt with the new SDK. Keep NavigationStack; do not hard-code a custom side bar. |
| [Strike a pose — 111463](https://developer.apple.com/videos/play/tech-talks/111463/) | Reserved regions and arrangement APIs describe layout; hinge data is not a layout proxy. Current UI uses a scrolling native Form. Hinge-region behavior still needs Duo testing. |
| [Multiple displays and scenes — 111464](https://developer.apple.com/videos/play/tech-talks/111464/) | 00:49 introduces hinge APIs; 01:44–02:17 shows the SwiftUI callback and angle. Nil hinge indicates unsupported hardware. The API is described for live interactions. No background wake contract is established here. |
| [Camera experience — 111465](https://developer.apple.com/videos/play/tech-talks/111465/) | Camera direction and display accessory APIs are for capture experiences, not a reason for a sound app to activate the camera. Not used. |
| [Designing for iPhone Duo — HIG](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo) | Design reference for device poses; full retrieved body unavailable. No missing API details inferred from it. |

## Background feasibility

The material reviewed did not establish a public background hinge subscription, a fold-triggered app launch, or a Shortcuts fold automation. That is a bounded research finding, not proof no such API can ever exist. A view callback is not a guarantee that code runs while its process is suspended.

Apple's [background-execution guidance](https://developer.apple.com/documentation/uikit/extending-your-app-s-background-execution-time) concerns completing bounded work, not indefinite arbitrary listening. [App Review Guidelines 2.5.1 and 2.5.4](https://developer.apple.com/app-store/review/guidelines/) require public APIs used for their intended purposes, including background services. Do not keep a silent track running just to evade suspension. No background mode is declared in this project.

Current product boundary: foreground sound toy. **System-wide Scrunch parity is not delivered.** Even foreground close delivery during the inner/outer display transition must be tested. App lifecycle resets intentionally prefer a missed event over a delayed or fabricated one.

## Audio and privacy

[Apple's audio category reference](https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/AudioSessionCategoriesandModes/AudioSessionCategoriesandModes.html) describes Ambient as mixable, playback-only and silenced by Silent Mode/locking. [Audio session configuration](https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/AudioSessionBasics/AudioSessionBasics.html) distinguishes category behavior from background capability. This app uses `.ambient`, activates only for a short effect, then deactivates. Output route changes and interruptions cancel rather than replay sounds.

No microphone, motion sensor or camera access is required. Imported audio is size-bounded, decoder-validated and copied from a user-selected security-scoped URL. Settings use atomic JSON, not UserDefaults. The privacy manifest declares no tracking, collected data or required-reason APIs used directly by this implementation; re-audit against the release SDK before submission.

## Scrunch comparison

[README](https://github.com/DenyTheFlowerpot/Scrunch/blob/main/README.md) and [FoldDetectionStrategies.kt](https://github.com/DenyTheFlowerpot/Scrunch/blob/main/app/src/main/java/com/denytheflowerpot/scrunch/helpers/folding/FoldDetectionStrategies.kt) were inspected. The latter parses Android logcat traces using Samsung and Surface Duo strategies. It cannot be reused as an iOS hinge listener. The README identifies EUPL 1.2 licensing. No source, artwork or sound asset was copied.
