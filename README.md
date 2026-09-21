# Hingy

A native SwiftUI sound toy for opening and closing iPhone Duo, inspired by [Scrunch](https://github.com/DenyTheFlowerpot/Scrunch).

> **September 20, 2026: developer preview, not a working system-wide fold-sound utility.** Xcode 27.1 beta now provides the iOS 27.1 SDK used by the opt-in hinge adapter. `DuoSound-DuoSDK` compiles Apple's `onHingeChange` path for simulator and iPhone targets; the default scheme still has **simulated folds only**. Duo simulator/device behavior remains validation work, and this app is foreground only: no background/lock-screen listener is claimed. [Research and sources](docs/IPHONE_DUO_RESEARCH.md).

## Included

Independent opening and closing sounds; 20 original procedural presets across Musical, Mechanical, Nature, Playful and Sci-Fi categories; a searchable library with non-destructive per-sound previews; per-event Off; effect volume; explicit previews; imported audio up to 5 seconds / 8 MiB; visible demo slider and Open/Close controls; private atomic settings storage; an isolated public-API hinge adapter; 39 portable tests; a dependency-free Xcode project; macOS CI for the core and the default iOS simulator build.

Sounds respect Silent Mode, mix with other audio, and follow the current output route. Nothing records microphone input or requests camera, notification, motion, or background permissions. Settings and copied imports stay in Application Support. No accounts, analytics, network clients, or copied Scrunch assets.

## Run the preview

Open `DuoSound.xcodeproj` in Xcode 16 or later. Select the **DuoSound** scheme and an iPhone simulator; Run. For a physical phone, select your development team under Signing & Capabilities and change the bundle identifier if needed. Minimum deployment target is iOS 17; ordinary iPhones/iPads can try the demo.

The default build visibly says **DEMO · SIMULATED HINGE**. Tap Open, Close, or drag the angle slider. The first state is silent; actual transitions play sounds after an 80 ms stability check. Preview buttons explicitly bypass the automatic-sounds toggle. Custom clips are copied into app storage only after decoding and duration validation; failed imports do not replace the previous selection.

## Activate the announced hinge API

With Xcode 27.1 beta (or a newer compatible SDK), inspect the declarations and select **DuoSound-DuoSDK**. That scheme sets `DUO_HINGE_SDK`; the default scheme does not. This is a compile-time gate, not a hidden runtime API lookup. Follow [the SDK/device validation checklist](docs/TESTING.md) before claiming automatic support or making a release. Do not enable this scheme in an older SDK: a compile error is expected.

An angle below 8 degrees is treated as closed; opening is detected at 22 degrees, not only at fully flat. These are tunable **app thresholds**, not Apple specifications. The 0–180-degree convention and actual callback/scene lifecycle behavior must be verified on the released SDK and device. Neither screen resizing nor app activation is used as a proxy for folding. First observations, source changes and foreground resumes silently rebaseline. No historical events are reconstructed.

See [the full sound library and offline audio sampler](docs/SOUND_LIBRARY.md) for all 20 presets and 40 direction-specific clips. Existing saved selections and custom imports remain compatible.

## Tests and structure

```sh
swift test
python3 scripts/generate_project.py  # only needed after adding/removing source files
DEVELOPER_DIR=/Applications/Xcode-27.1.app/Contents/Developer xcodebuild -project DuoSound.xcodeproj -scheme DuoSound \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

`Sources/DuoSoundCore` contains detection, synthesis and persistence. `App` contains UI, playback, lifecycle coordination and the guarded hinge adapter. Core sources are compiled directly into the app; the Swift package exists for portable tests and adds no dependency. `.github/workflows/ci.yml` checks core tests, project regeneration and the standard iOS build; it does **not** validate Duo hardware. No code-signing credentials are stored.

**Local validation:** 39 XCTest tests passed on Swift 6.2.1/macOS. Xcode 27.1 builds both the default simulator app and the opt-in Duo scheme for simulator and iPhone SDKs; the default app also launches on the installed iOS 27.0 simulator. These are compile/simulator checks, not physical-Duo evidence. The App Store preparation branch includes the supplied 1024px app icon; there is still no signed distribution archive.

## Important limitation

The app must be visible and active. Leaving it, locking, interruption or suspension cancels pending effects and resets observation. A close event may coincide with a display handoff/inactive state; whether it arrives in time for playback is a **release-blocking device test**, not a guaranteed feature. No silent audio loop, private APIs, fake background entitlement, or invented Shortcuts fold trigger is used. See the research document before promising Scrunch parity.

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
