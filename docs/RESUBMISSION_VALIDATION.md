# Hingy resubmission investigation — October 18, 2026

## Review issue and evidence boundary

Apple rejected version 1.0 (3) under 2.1(a) on September 23 after sound controls appeared unresponsive on an iPad Air 11-inch (M3), iPadOS 27.2. The rejection text does not distinguish a frozen UI, inaudible audio, or playback cancellation. Its precise device-side cause is not established by source inspection alone.

The October 18 App Store Connect API check confirms version 1.0 is `REJECTED`, attached to build 3 (`855ae495-853d-4838-8b90-d6fbc1739d52`). Build 3 is the newest uploaded build. `asc validate --app 6812193737 --version 1.0 --platform IOS` reports zero blocking metadata errors and an App Privacy advisory: the public API cannot verify privacy publication. This checks the existing record, not the new candidate's behavior.

## Defects addressed

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

- Core package: 39 tests passed, zero failures.
- Release-preparation checks: 18 tests passed, zero failures; ordinary preparation checks pass.
- Typed Duo adapter: simulator Debug-Duo and unsigned device Release-Duo builds compiled with SDK 27.1. An optimized device build succeeded. These are compile checks, not signed-device or audible-playback evidence.
- The installed iPadOS 27.0 test runner stalled before tests executed, including the baseline attempt. Initial launch attempts ended without a test result and were stopped. A fresh dedicated iPad simulator also stalled. Do not count these as passing tests or as a reproduced app freeze.
- Current simulator attempts/results are recorded below after completion. The reviewer OS, iPadOS 27.2, is not installed. The 27.1 runtime is Duo-only and rejects creation of an iPad device.

## Candidate and remaining gates

Local version/build is 1.0 (4), with the build number persisted in `release/listing.json` so project regeneration cannot reset it to 1. All shared Archive actions use the evidence-gated AppStore configuration. No build has been uploaded or resubmitted by this change.

Before resubmission, record audible selected/library/imported playback and responsive controls on a clean release installation on a physical iPad, including Silent Mode, nonzero/zero system and effect volume, Off, headphones/Bluetooth, rapid previews, foreground return and interruptions. Repeat on iPadOS 27.2 or document the review-OS coverage gap. Validate physical Duo open/close and inner/outer-display handoff with the same source/build. Confirm current distribution-toolchain acceptance, App Privacy publication, reviewed store screenshots and all other evidence gates in `release/readiness.json`.

The April 2027 Duo screenshot requirement for SDK 27.1+ is separate from this rejection. [Apple's current screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications) describe outer and inner display sizes. Updated screenshots should show this candidate's actual UI; none are fabricated as device evidence.
