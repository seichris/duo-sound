# Hingy simulator validation and resubmission preparation

Assessed October 18, 2026. Candidate: version 1.0 (4), PR #3. No physical iPad or Duo is available.

## What simulator validation establishes

Simulators are useful for verifying responsive controls, actual AVAudioPlayer progress, imports, saved selections, nil-hinge behavior, simulated lifecycle notifications and adaptive layouts. Apple's [Duo preparation talk](https://developer.apple.com/videos/play/tech-talks/111461/) explicitly describes Device Hub's open, close, rotate and fold controls for testing poses and display layouts.

This does not establish audible output from a physical iPad, the device's Silent Mode/volume/routing behavior, or the order and timing of hinge and scene callbacks during a physical display handoff. Injected model events test our reaction to those events; they do not prove that hardware delivers them in that order. A host playback clock advancing is stronger than a UI label changing, but it is not a recording of device output.

Apple's [App Review Guideline 2.1(a)](https://developer.apple.com/app-store/review/guidelines/#app-completeness) asks developers to test on-device for bugs and stability before submission. The repository's `physical_open_close_and_handoff` gate is a local release policy; it is not a separate requirement to upload a physical-device test certificate to App Store Connect. Neither a green metadata preflight nor simulator testing proves that all of Apple's review expectations have been met.

## Recorded results

| Check | Evidence | Scope |
| --- | --- | --- |
| Core logic | 39 tests passed | Portable detector, sound generation, settings and file validation |
| Release preparation | 18 tests passed | Packaging/preparation checks; submission gate remains blocked |
| iPad runtime | 11 hosted audio/model tests and 4 UI tests passed, no skips | iPad Air 11-inch (M3), iPadOS 18.5, default scheme |
| iPhone runtime | 11 hosted audio/model tests and 4 UI tests passed, no skips | iPhone 17 Pro Max, iOS 26.0.1, default scheme |
| Typed Duo adapter | SDK 27.1 unsigned device and simulator Release-Duo builds succeeded | Compilation, version/build identity; no hardware runtime proof |
| Current ASC metadata | `asc validate` reports zero blocking errors | Existing rejected version and attached build 3; App Privacy publication cannot be verified by this API |

The hosted audio tests exercise all 40 built-in opening/closing clips, playback progress, imported clips, explicit-preview audio category, nil-hinge updates, route-notification policy and inactive/interrupted cancellation. They invoke route/interruption handlers synthetically. They do not exercise a real Bluetooth/headphone transition or a physical Silent Mode switch.

CI: [passing audio/UI run](https://github.com/seichris/duo-sound/actions/runs/39133213710), [passing release-preparation run](https://github.com/seichris/duo-sound/actions/runs/39133213818). See [machine-readable simulator evidence](../release/evidence/simulator-validation-2026-10-18.json) and [SDK compile evidence](../release/evidence/sdk-compile-2026-10-18.json).

## Remaining simulator work

Use dedicated Hingy devices; do not reset CoreSimulator globally or change another task's simulator. Use Xcode 27.1 and the **DuoSound-DuoSDK** scheme for the typed hinge path. Testing the default scheme's manual simulation does not validate `UIHingeInteraction` callbacks.

1. On a fresh iPad installation, run hosted and UI suites, then inspect selected/library preview feedback and output, imports, cancellation, relaunch persistence, Dynamic Type, contrast and landscape/resizing. Prefer the review OS, iPadOS 27.2, when available. It is not installed locally; the installed 27.1 runtime only supports Duo.
2. On Duo, leave **Simulate hinge** off. In Device Hub, establish a silent baseline, then test open/close, partial poses, rotation and inner/outer display transitions. Confirm actual hinge status/angle changes, one event per complete transition, no stale replay after foreground return, and accessible controls throughout. Record whether lifecycle handoff suppresses the closing effect. Do not substitute taps on the app's manual Open/Close controls for this check.
3. Run the same audio and UI suites on Duo. Keep results for the typed scheme separate from older-OS/default-scheme CI results.
4. Capture actual candidate screens for iPhone, iPad and Duo's inner/outer display sizes. Check search/sheets, text clipping and safe areas in each pose. Populate `release/screenshots.json` only with reviewed, correctly sized captures and their real provenance. A simulator screenshot can be a store asset; it is not physical-device evidence.

Fresh local simulator attempts in this follow-up did not complete runtime acceptance: the optimized build installed on a dedicated Duo and its process launched, but UI automation timed out and the display capture was black. The dedicated iPad's installation and launch commands eventually reported success after long delays; no completed UI/runtime test result was obtained. Available disk space fell from 7.2 GiB to 131 MiB during the attempts, and this task's two simulators were shut down. These are unresolved local runtime/tooling symptoms under severe storage pressure, not passing tests and not an established reproduction of Apple's reported sound failure. No global simulator reset or modification of the other task's active Duo session was performed. The task-created simulators remain available for a later retry after storage is sufficient.

## Submission package

The [review response draft](../release/REVIEW_RESPONSE_DRAFT.md) states exactly which defects were repaired and which tests actually ran. Before attaching a replacement build, add its processed build identity and results from any additional completed checks. Do not tell App Review that build 4 was installed on a physical iPad or that the exact iPadOS 27.2 failure was reproduced.

Store copy, reviewed screenshots, privacy publication, public support/privacy links, seller/age-rating/rights/availability and distribution-toolchain acceptance remain separate checks. None requires ownership of a physical device to prepare. A simulator binary cannot be uploaded: App Store delivery needs an appropriately signed device archive and a processed replacement build. The April 2027 Duo screenshot deadline is separate from the current audio rejection.

The repository remains blocked for release. This plan prepares a truthful resubmission package and defines the simulator work still needed; it does not silently turn missing physical evidence into a pass.
