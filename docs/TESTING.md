# Validation and release gates

## Implemented checks

`swift test`: 39 tests covering silent initial states, deadband, endpoint-only timer completion, duplicate notifications, partial-to-flat changes, jitter/spikes, reset cancellation/rebaseline, invalid and backwards timestamps, invalid angles, rapid complete cycles, inclusive thresholds, deterministic bounded PCM/WAV, distinct open/close sounds, settings round-trip/corruption, volume validation, custom-file requirements, path traversal, bounded reads and write failures.

Local run: Swift 6.2.1/macOS, **39 passed, zero failures**. Xcode 27.1 builds the default simulator app plus `DuoSound-DuoSDK` for both `iphonesimulator27.1` and `iphoneos27.1`. The default app launches on the installed iOS 27.0 simulator. A successful build or simulator launch is not physical-Duo evidence. CI builds the default simulator app on macOS. Check the actual run status rather than treating the presence of a workflow as a passing result.

The added sound-library tests cover catalog completeness, readable labels, stable saved IDs, all opening/closing combinations, custom-import retention, persisted new presets, 40 unique renders, short durations, PCM format, amplitude bounds and deterministic output. See [SOUND_LIBRARY.md](SOUND_LIBRARY.md) for the offline sampler and browser QA.

## First iOS simulator/device smoke test

Open the default DuoSound scheme. Verify demo labelling, Open/Close and slider sounds; previews with automatic playback disabled; Silent Mode, headphones, music mixing, effect/system volume; a second effect replaces the first. Import a valid short WAV/M4A/MP3 supported by AVAudioPlayer; cancel an import; reject an invalid file, >8 MiB file and >5-second clip. Relaunch and verify selection/volume persistence. Missing custom audio must surface an error rather than quietly selecting another sound. Test Dynamic Type, VoiceOver, light/dark appearance and compact/landscape/iPad resizing. The supplied 1024-pixel RGB icon is validated by `scripts/generate_assets.py` and the Xcode build phase; review its appearance on supported devices before release.

## SDK activation — mandatory

1. Verify that Xcode 27.1 beta (or newer compatible SDK) is genuinely available on Apple's Duo developer/download pages. Select that Xcode installation. This project was checked with Xcode 27.1 beta build 27A9269.
2. Open the actual SDK declarations for `View.onHingeChange`, hinge context, angle and status. Confirm callback syntax and availability. The isolated adapter currently matches the iOS 27.1 SDK and must be corrected if a later SDK changes it.
3. Confirm that 0 degrees is closed, 180 degrees is flat, and endpoint angles are valid; do not assume this from our demo. Confirm whether an initial callback is delivered. The first live sample deliberately seeds a silent baseline, so without initial delivery the first gesture may be consumed as that baseline.
4. Select **DuoSound-DuoSDK**, which sets `DUO_HINGE_SDK` in Debug-Duo/Release-Duo, and build. A green default-scheme CI run says nothing about this path.
5. Use the Duo Device Hub simulator when available. Test both a supported hinge and a nil hinge. Never infer hardware support from model strings or display geometry.

## Physical Duo acceptance — release blocking

With the app visible/active: closed → partly open → flat gives one opening sound; flat → partly open → closed gives one closing sound. Repeat slowly, rapidly, and with jitter near 8/22 degrees. Adjust the documented app thresholds/dwell only from measurements. Confirm no double playback across inner/outer scene/view handoff.

Pay special attention to callback order while closing: if the scene becomes inactive before the closed sample or 80 ms dwell completes, this implementation suppresses the effect. **Do not claim that closing works until verified.** A lifecycle design change may be required. Do not fix it by claiming background privilege or replaying a stale event on activation.

Lock/unlock, switch apps, present system UI, interrupt with a call, change headphones and reset media services: no old pending sound may fire. Returning establishes a fresh silent baseline. Hinge absence must clear pending state. The single-scene manifest avoids duplicate monitors; reassess ownership before enabling multiple app instances.

## Distribution

Review the supplied app icon, select signing/team/bundle ID, review privacy/API declarations with the release SDK, choose the repository's distribution license, and make an explicit decision about the foreground-only product promise. Do not submit the demo as a working automatic/system-wide utility. No App Store approval, TestFlight build, signed IPA, hardware testing, or background operation is claimed.
