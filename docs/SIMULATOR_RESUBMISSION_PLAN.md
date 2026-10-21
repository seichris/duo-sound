# Hingy simulator validation and resubmission preparation

> **Historical build 4 snapshot.** Build 5 adds the recorded-audio expansion described in [the sound library](SOUND_LIBRARY.md). The results below bind the earlier product fingerprint and do not validate changed build 5 assets. Current scoped results are in [build 5 validation](RECORDED_AUDIO_VALIDATION.md).

Started October 18; checkpoint updated October 19, 2026 (Singapore). Candidate: version 1.0 (4), PR #3. No physical iPad or Duo is available.

## What simulator validation establishes

Simulators are useful for verifying responsive controls, actual AVAudioPlayer progress, imports, saved selections, nil-hinge behavior, simulated lifecycle notifications and adaptive layouts. Apple's [Duo preparation talk](https://developer.apple.com/videos/play/tech-talks/111461/) explicitly describes Device Hub's open, close, rotate and fold controls for testing poses and display layouts.

This does not establish audible output from a physical iPad, the device's Silent Mode/volume/routing behavior, or the order and timing of hinge and scene callbacks during a physical display handoff. Injected model events test our reaction to those events; they do not prove that hardware delivers them in that order. A host playback clock advancing is stronger than a UI label changing, but it is not a recording of device output.

Apple's [App Review Guideline 2.1(a)](https://developer.apple.com/app-store/review/guidelines/#app-completeness) asks developers to test on-device for bugs and stability before submission. The repository's `physical_open_close_and_handoff` gate is a local release policy; it is not a separate requirement to upload a physical-device test certificate to App Store Connect. Neither a green metadata preflight nor simulator testing proves that all of Apple's review expectations have been met.

## Recorded results

The current logo candidate uses a serial background audio queue. Product fingerprint: `1c273e38705f601855c6b3afcdf645989e2bdf95b2da4adf7085a0e4aa80e5fb`.

| Check | Result | Scope |
| --- | --- | --- |
| Core / release preparation | 39 / 18 tests passed | Product logic and packaging |
| SDK 27.1 | Optimized unsigned device and simulator builds passed | Compilation and source/assets identity |
| iPhone iOS 26.0.1 | 16 passed / 0 failed / 1 intentional Duo-only skip | Audio, UI and relaunch persistence |
| iPadOS 18.5 | 16 passed / 0 failed / 1 intentional skip | All 12 audio/model and 4 UI tests passed |
| Typed iPadOS 27.0 | 16 passed / 0 failed / 1 intentional skip | All 12 audio/model and 4 UI tests passed |
| Typed Duo iOS 27.1 | 17 passed / 0 failed / 0 skipped | All audio/model and 5 UI tests, including real initial public hinge sample, library persistence, previews and manual simulation |
| Local current-logo iPad | About/privacy check passed | Actual new-logo app opens the About and privacy screens |
| Local Duo / iPad library | 1 passed each / 0 failed / 0 skipped | Compact/native search, audition, selection and relaunch persistence; targeted checks only |
| Current screenshots | Two iPhone CI images visually reviewed | Native 1320×2868; iPad and Duo inner/outer slots incomplete; no uploads |
| ASC metadata | Zero errors and warnings | Existing rejected version / uploaded build 3; API cannot verify App Privacy publication |

Completed current-source runs: [standard CI for PR head f753197](https://github.com/seichris/duo-sound/actions/runs/39143953412), [typed iPad full pass for that head](https://github.com/seichris/duo-sound/actions/runs/39143953403), and [typed Duo full pass for head 8965c7e](https://github.com/seichris/duo-sound/actions/runs/39146623513). The last workflow is **failed overall**: its additional iPad run passed 15 and timed out launching the privacy test through Xcode, with one intentional Duo-only skip. The earlier full iPad pass is preserved, and the exact new library helper passed locally on iPad. The [standard recheck for 8965c7e](https://github.com/seichris/duo-sound/actions/runs/39146623517) passed both test steps, 16/0/1 on each of iPhone and iPad. [Runtime evidence](../release/evidence/simulator-validation-2026-10-18.json) preserves earlier failures, PR heads, generated merge checkout identities and the product fingerprint. See [SDK compile evidence](../release/evidence/sdk-compile-2026-10-18-logo.json).

Hosted tests cover all 40 built-in clips, actual player progress, imported audio, explicit-preview session category, nil hinge data and cancellation. The slow-activation test blocks a worker while the main actor cancels the request. Accessory/interruption events are synthetic. The Duo integration test receives the real initial callback; it does not change the simulator's physical pose or test display handoff.

## Remaining simulator work

Use dedicated Hingy devices; do not reset CoreSimulator globally or change another task's simulator. Use Xcode 27.1 and the **DuoSound-DuoSDK** scheme for the typed hinge path. Testing the default scheme's manual simulation does not validate `UIHingeInteraction` callbacks.

1. On a fresh iPad installation, run hosted and UI suites, then inspect selected/library preview feedback and output, imports, cancellation, relaunch persistence, Dynamic Type, contrast and landscape/resizing. Prefer the review OS, iPadOS 27.2, when available. It is not installed locally; the installed 27.1 runtime only supports Duo.
2. On Duo, leave **Simulate hinge** off. In Device Hub, establish a silent baseline, then test open/close, partial poses, rotation and inner/outer display transitions. Confirm actual hinge status/angle changes, one event per complete transition, no stale replay after foreground return, and accessible controls throughout. Record whether lifecycle handoff suppresses the closing effect. Do not substitute taps on the app's manual Open/Close controls for this check.
3. Run the same audio and UI suites on Duo. Keep results for the typed scheme separate from older-OS/default-scheme CI results.
4. Capture actual candidate screens for iPhone, iPad and Duo's inner/outer display sizes. Check search/sheets, text clipping and safe areas in each pose. Two current-source iPhone images are already recorded in `release/screenshots.json`. Add only reviewed, correctly sized captures with their real provenance. A simulator screenshot can be a store asset; it is not physical-device evidence.

The approved cleanup removed the old task-created iPad/Duo devices and five exact build-cache directories, reclaiming an observed 3.08 GiB. Source, test results and products were preserved. The retry used fresh dedicated simulators; it did not reset CoreSimulator or modify the other task's simulator. The local iPad produced a partial test result and actual QA captures. An earlier Duo failed data migration, but a fresh dedicated Duo subsequently booted, installed and launched the current logo candidate, showing a silent closed baseline. Full pose testing remains incomplete: Device Hub shares its selected device with another active task, which has been left untouched. Local store-capture attempts timed out or returned a rejected boot-logo frame. Separate reviewed iPhone CI candidates are recorded; required iPad and Duo slots remain incomplete. All failed attempts remain recorded.

## Submission package

The [review response draft](../release/REVIEW_RESPONSE_DRAFT.md) states exactly which defects were repaired and which tests actually ran. Before attaching a replacement build, add its processed build identity and results from any additional completed checks. Do not tell App Review that build 4 was installed on a physical iPad or that the exact iPadOS 27.2 failure was reproduced.

Store copy, reviewed screenshots, privacy publication, public support/privacy links, seller/age-rating/rights/availability and distribution-toolchain acceptance remain separate checks. None requires ownership of a physical device to prepare. A simulator binary cannot be uploaded: App Store delivery needs an appropriately signed device archive and a processed replacement build. The April 2027 Duo screenshot deadline is separate from the current audio rejection.

The repository remains blocked for release. This plan prepares a truthful resubmission package and defines the simulator work still needed; it does not silently turn missing physical evidence into a pass.
