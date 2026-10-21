# Hingy

A native SwiftUI sound toy for opening and closing iPhone Duo, inspired by [Scrunch](https://github.com/DenyTheFlowerpot/Scrunch).

> **October 21, 2026: native hinge enabled by default.** All configurations now compile against Apple's public `UIHingeInteraction` declarations in the iOS 27.1 SDK. Runtime availability checks preserve sound previews on older supported devices. Native hinge detection starts automatically on supported hardware; simulation is opt-in. Native hinge observation remains foreground only. Shortcuts can retrieve selected audio for system-owned playback; a stock fold trigger and locked execution require separate device verification. [Research and sources](docs/IPHONE_DUO_RESEARCH.md).

## Included

Independent opening and closing sounds; 43 choices: 17 original procedural presets and 26 bundled CC0 recordings, including six farts and eight Kenney effects; a searchable library with non-destructive per-sound previews; per-event Off; effect volume; explicit previews; imported audio up to 5 seconds / 8 MiB; visible demo slider and Open/Close controls; private atomic settings storage; an isolated public-API hinge adapter; portable regression tests; a dependency-free Xcode project; macOS CI for the core and the default iOS simulator build.

Automatic fold sounds respect Silent Mode. Explicit previews and simulated folds play in Silent Mode; both mix with other audio and follow the current output route. Nothing records microphone input or requests camera, notification, motion, or background permissions. Settings and copied imports stay in Application Support. No accounts, analytics, network clients, or copied Scrunch assets.

## Run the preview

Open `DuoSound.xcodeproj` in Xcode 27.1 or later. Select the **DuoSound** scheme and an iPhone simulator; Run. For a physical phone, select your development team under Signing & Capabilities and change the bundle identifier if needed. Minimum deployment target is iOS 17; ordinary iPhones/iPads can try the demo.

On a device without a supported hinge, the app reports **NO HINGE AVAILABLE**. Enable **Simulate hinge** to try manual folds; simulation visibly says **DEMO · SIMULATED HINGE**. Tap Open, Close, or drag the angle slider. The first state is silent; actual transitions play sounds after an 80 ms stability check. Preview buttons explicitly bypass the automatic-sounds toggle. Custom clips are copied into app storage only after decoding and duration validation; failed imports do not replace the previous selection.

## Native hinge API

The standard **DuoSound** scheme includes `DUO_HINGE_SDK`. The older **DuoSound-DuoSDK** scheme remains available for existing validation workflows. The adapter uses the typed public UIKit interaction on iOS 27.1 or newer, and reports no hinge on older devices. It enables observation only while active and outside simulation; re-enabling requests the current hinge state to seed a fresh baseline. Follow [the SDK/device validation checklist](docs/TESTING.md) before claiming automatic support or making a release.

An angle below 8 degrees is treated as closed; opening is detected at 22 degrees, not only at fully flat. These are tunable **app thresholds**, not Apple specifications. The 0–180-degree convention and actual callback/scene lifecycle behavior must be verified on the released SDK and device. Neither screen resizing nor app activation is used as a proxy for folding. First observations, source changes and foreground resumes silently rebaseline. No historical events are reconstructed.

See [the full sound library and offline audio sampler](docs/SOUND_LIBRARY.md) for all 43 choices (34 procedural renders plus 26 recordings, independently selectable for either direction). Existing saved selections and custom imports remain compatible.

## Tests and structure

```sh
swift test
python3 scripts/generate_project.py  # only needed after adding/removing source files
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project DuoSound.xcodeproj -scheme DuoSound \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

`Sources/DuoSoundCore` contains detection, synthesis and persistence. `App` contains UI, playback, lifecycle coordination and the guarded hinge adapter. Core sources are compiled directly into the app; the Swift package exists for portable tests and adds no dependency. `.github/workflows/ci.yml` checks core tests, project regeneration and the standard iOS build; it does **not** validate Duo hardware. No code-signing credentials are stored.

**Local validation:** 41 XCTest tests passed on Swift 6.2.1/macOS. The September runtime-bridge validation no longer applies to this source. See [the resubmission report](docs/RESUBMISSION_VALIDATION.md) for current toolchain and test evidence. These are compile/simulator checks, not physical-device evidence. The App Store candidate is signed separately during release.

## Shortcuts and background limits

Native hinge sounds require the app to be visible and active. Leaving it, locking, interruption or suspension cancels pending in-app effects and resets observation. Get Opening Sound and Get Closing Sound return the selected audio to Shortcuts without opening Hingy; add Play Sound to each workflow. See [setup, sources and acceptance boundaries](docs/BACKGROUND_SHORTCUTS.md). A close event may coincide with a display handoff/inactive state; whether it arrives in time for playback is a **release-blocking device test**, not a guaranteed feature. No silent audio loop, private APIs, fake background entitlement, or invented Shortcuts fold trigger is used. See the research document before promising Scrunch parity.

## Attribution

Scrunch by DenyTheFlowerpot is the inspiration. Its repository identifies EUPL 1.2 licensing; this is an independent implementation, not a port of its code or artwork. All included audio is generated by this project's own synthesizer. The repository owner should select a distribution license before wider reuse.

## App Store preparation

See [the sourced SEO/ASO research](docs/ASO_SEO_RESEARCH.md) and [the release guide](docs/APP_STORE_RELEASE.md). Proposed listing: **Hingy** / **Custom Open & Close Audio**. Preparation includes English US/UK copy, the supplied app icon, in-app privacy/help, a static noindex preview site, screenshot capture tooling, UI smoke tests and guarded native archive/export. Verified team, bundle and App Store record identities are documented separately; no credentials, search metrics or hardware validation are invented.

```sh
python3 scripts/generate_assets.py
python3 scripts/generate_project.py
python3 scripts/release_check.py
python3 scripts/export_listing.py --draft
python3 scripts/build_site.py
python3 scripts/release_check.py --submission  # currently fails: real release gates remain
```

The **Release preparation** workflow publishes a reviewable ZIP artifact; **CI** runs real simulator UI tests and retains raw screenshot attachments. Neither is an App Store upload or physical-Duo validation. The dedicated **DuoSound-AppStore** configuration and shared Archive actions require the release gate. The supplied logo is validated before Xcode compiles the asset catalogue. No site is deployed by this workflow.
