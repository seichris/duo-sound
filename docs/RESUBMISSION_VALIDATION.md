# Hingy resubmission investigation — October 18–19, 2026

## Review issue and evidence boundary

Apple rejected version 1.0 (3) under 2.1(a) on September 23 after sound controls appeared unresponsive on an iPad Air 11-inch (M3), iPadOS 27.2. The rejection text does not distinguish a frozen UI, inaudible audio, or playback cancellation. Its precise device-side cause is not established by source inspection alone.

The October 18 App Store Connect API check confirms version 1.0 is `REJECTED`, attached to build 3 (`855ae495-853d-4838-8b90-d6fbc1739d52`). Build 3 is the newest uploaded build. `asc validate --app 6812193737 --version 1.0 --platform IOS` reports zero blocking metadata errors and an App Privacy advisory: the public API cannot verify privacy publication. This checks the existing record, not the new candidate's behavior.

## Defects addressed

- Audio-session activation/deactivation and player setup previously ran on the main actor. The SDK 27 runtime warned that these calls can block UI responsiveness. They now run on one serial background queue; a lock-protected cancellation token prevents an activation that finishes late from starting a stale sound. Lifecycle notifications are delivered to the model on the main queue. A hosted regression deliberately blocks activation and verifies that the main actor remains responsive and inactivity cancels playback.
- Every sound previously used `.ambient`, which intentionally mutes in Silent Mode, even for an explicit Preview tap. Manual selected/library auditions and simulated folds now use `.playback` with `.mixWithOthers`. Physical fold effects retain `.ambient`. System/effect volume, Off selections and current output routing remain respected.
- A nil hinge update reset observation by stopping the shared audio player. Nil is normal on unsupported iPads and when an interaction leaves its hierarchy. It now cancels pending/playing physical fold effects without cutting off an explicit audition.
- Every route notification except category changes previously stopped playback. Benign route-configuration notifications from session setup could cancel the sound that just started. Only output-device arrival/removal, explicit route overrides and unavailable routes cancel playback; inactivity, interruptions and media-service resets still stop it without replay.
- Library auditions now display feedback, and unsupported devices explain how to use previews and simulation. No hinge is required to audition a preset or imported clip.

These are concrete source-level failure paths. They must not be described as a reproduction of Apple's exact hardware configuration until the corresponding device test is recorded.

## Current SDK audit

The installed Xcode 27.1 (27A9275, RC-named application) supplies the public `UIHingeInteraction` and `UIHinge` headers. The adapter now calls the typed `init(updateHandler:)`, reads nullable `update.hinge` and converts the documented radians to degrees. Objective-C runtime allocation, selector invocation, forced casting and key-value lookup were removed. Availability checks preserve manual previews on iOS 17 and newer.

The interaction is enabled only when the app is active and simulation is off. Apple's documented initial/re-enable callback supplies a fresh silent baseline after foreground return. Nil hinge updates cancel physical fold work. No display geometry, model-name guess, background mode or fold-launch privilege is introduced. Native Form/List/NavigationStack remain the adaptive layout containers.

Sources: [UIHingeInteraction](https://developer.apple.com/documentation/uikit/uihingeinteraction), [UIHinge](https://developer.apple.com/documentation/uikit/uihinge), [Duo preparation](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo), [playback category](https://developer.apple.com/documentation/avfaudio/avaudiosession/category-swift.struct/playback).

## Validation

Current product fingerprint: `1c273e38705f601855c6b3afcdf645989e2bdf95b2da4adf7085a0e4aa80e5fb`. The supplied logo is included. Test-harness and documentation changes do not change this product fingerprint.

- **Builds and unit checks:** 39 portable tests and 18 release-preparation tests passed. Optimized unsigned Release-Duo device and simulator builds passed with SDK 27.1 / Xcode 27A9275. The [compile manifest](../release/evidence/sdk-compile-2026-10-18-logo.json) binds source, bundle/build, executable, asset catalogue and logo hashes. No signed delivery or upload acceptance is established.
- **iPhone simulator:** 16 hosted/UI tests passed, zero failed, one intentional Duo-only skip on iOS 26.0.1. [Standard CI first attempt](https://github.com/seichris/duo-sound/actions/runs/39141416927/attempts/1).
- **iPadOS 18.5:** 12 audio/model and 3 UI tests passed; one UI test failed before its body because XCTest could not terminate the previous app for relaunch. The library test did not run in that attempt. The Duo-only test intentionally skipped. A fresh-runner retry was requested; no pending retry is counted as green.
- **iPadOS 27.0, typed scheme:** 12 audio/model and 3 UI tests passed, including library audition/selection/persistence. Selected-preview UI testing failed before its body because XCTest could not terminate the prior app. Totals: 15 passed / 1 failed / 1 intentional Duo-only skip. [SDK CI first attempt](https://github.com/seichris/duo-sound/actions/runs/39141416905).
- **Duo iOS 27.1, typed scheme:** all 12 audio/model tests and 4 UI tests passed, including the **actual public hinge callback**, a closed 0-degree reading and a silent initial baseline. One library UI test failed: its tap landed on a partly visible choice row beneath the navigation bar, so the sheet did not open. Totals: 16 passed / 1 failed / 0 skipped. The step also reached its 12-minute timeout during completion. The initial sample does not prove opening/closing transitions or display handoff.
- **Test repair under validation:** `openLibrary` now reveals the entire row below the navigation bar and above the bottom safe area using bounded, small drags. Typed-scheme test steps have a 15-minute limit. This fixes a demonstrated harness targeting error without changing application behavior. Current rechecks: [standard CI](https://github.com/seichris/duo-sound/actions/runs/39143826990), [typed iPad/Duo CI](https://github.com/seichris/duo-sound/actions/runs/39143826991). Pending checks are not acceptance.
- **Local evidence:** the audio-queue source passed 12 audio/model and 3 UI tests on iPadOS 27.0, while the library runner ended with SIGTERM. The current-logo About/privacy UI check passed separately. Local Duo retries failed CoreSimulator data migration before installation; no local Duo app result is claimed. The reviewer OS, iPadOS 27.2, is not installed.

The [machine-readable evidence](../release/evidence/simulator-validation-2026-10-18.json) preserves each failure and its source identity. All original 40 clip auditions, actual player progress, imported audio, session categories, cancellation and slow-activation responsiveness are covered by hosted tests. Route/interruption events are synthetic. These results do not establish audible physical output, accessory transitions or physical Silent Mode behavior.

Earlier successful runs that predate the queue or logo are historical and do not replace current-candidate results. Actual QA screenshots remain separate from reviewed store assets.

## Candidate and remaining gates

The publisher-supplied blue/white logo is the app icon, About-screen logo and the source for site/screenshot-tool branding. The original is preserved under `branding/`. Earlier exported/uploaded store screenshots predate this artwork and remain historical.

Local version/build is 1.0 (4), with the build number persisted in `release/listing.json` so project regeneration cannot reset it to 1. All shared Archive actions use the evidence-gated AppStore configuration. No build has been uploaded or resubmitted by this change.

Before resubmission, record audible selected/library/imported playback and responsive controls on a clean release installation on a physical iPad, including Silent Mode, nonzero/zero system and effect volume, Off, headphones/Bluetooth, rapid previews, foreground return and interruptions. Repeat on iPadOS 27.2 or document the review-OS coverage gap. Validate physical Duo open/close and inner/outer-display handoff with the same source/build. Confirm current distribution-toolchain acceptance, App Privacy publication, reviewed store screenshots and all other evidence gates in `release/readiness.json`.

The April 2027 Duo screenshot requirement for SDK 27.1+ is separate from this rejection. [Apple's current screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications) describe outer and inner display sizes. Updated screenshots should show this candidate's actual UI; none are fabricated as device evidence.

With no physical devices available, see the [simulator validation and resubmission plan](SIMULATOR_RESUBMISSION_PLAN.md). It separates completed CI checks, remaining Duo/iPad simulator work and physical coverage gaps, and links an unsent review-response draft. Apple describes Duo pose/layout testing in Device Hub; Guideline 2.1(a) still asks for on-device testing. The physical gate remains unverified, rather than being renamed or marked passed from simulator results.
