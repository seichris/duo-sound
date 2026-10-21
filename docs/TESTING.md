> Build 5 adds the recorded-sound checks documented in [SOUND_LIBRARY.md](SOUND_LIBRARY.md). Older counts below describe build 4; current scoped results are in [build 5 validation](RECORDED_AUDIO_VALIDATION.md).

# Validation and release gates

## Implemented checks

`swift test`: 39 tests covering silent initial states, deadband, endpoint-only timer completion, duplicate notifications, partial-to-flat changes, jitter/spikes, reset cancellation/rebaseline, invalid and backwards timestamps, invalid angles, rapid complete cycles, inclusive thresholds, deterministic bounded PCM/WAV, distinct open/close sounds, settings round-trip/corruption, volume validation, custom-file requirements, path traversal, bounded reads and write failures.

Local run: Swift 6.2.1/macOS, **39 passed, zero failures**. Xcode 27.1 builds the default simulator app plus `DuoSound-DuoSDK` for both `iphonesimulator27.1` and `iphoneos27.1`. The default app launches on the installed iOS 27.0 simulator. A successful build or simulator launch is not physical-Duo evidence. CI builds the default simulator app on macOS. Check the actual run status rather than treating the presence of a workflow as a passing result.

The added sound-library tests cover catalog completeness, readable labels, stable saved IDs, all opening/closing combinations, custom-import retention, persisted new presets, 40 unique renders, short durations, PCM format, amplitude bounds and deterministic output. See [SOUND_LIBRARY.md](SOUND_LIBRARY.md) for the offline sampler and browser QA.

## First iOS simulator/device smoke test

Open the default DuoSound scheme. Verify demo labelling, Open/Close and slider sounds; previews with automatic playback disabled; explicit previews and simulation audible in Silent Mode, physical folds muted in Silent Mode; headphones, music mixing, effect/system volume; a second effect replaces the first. Import a valid short WAV/M4A/MP3 supported by AVAudioPlayer; cancel an import; reject an invalid file, >8 MiB file and >5-second clip. Relaunch and verify selection/volume persistence. Missing custom audio must surface an error rather than quietly selecting another sound. Test Dynamic Type, VoiceOver, light/dark appearance and compact/landscape/iPad resizing. The supplied 1024-pixel RGB icon is validated by `scripts/generate_assets.py` and the Xcode build phase; review its appearance on supported devices before release.

## SDK activation — mandatory

1. Use Xcode 27.1 or newer for Duo configurations. The runtime bridge has been replaced by typed public `UIHingeInteraction` calls. Every configuration now requires SDK 27.1; runtime availability checks retain iOS 17 device support.
2. Build the default **DuoSound** scheme for both device and simulator SDKs. It now includes the typed hinge adapter; **DuoSound-DuoSDK** remains an equivalent compatibility scheme.
3. Apple documents initial delivery and a new current-state update when `isEnabled` returns to true. Confirm silent first observation and foreground-return rebaselining in the simulator and on a physical Duo.
4. Confirm the app's 0–180-degree convention, 8/22-degree thresholds and 80 ms dwell on hardware. Angle updates have no guaranteed frequency/precision. Missing hinge data must cancel pending fold work without cancelling manual sound previews.
5. Run hosted **DuoSoundAppTests** and UI **DuoSoundUITests** on iPad as well as iPhone. Hosted tests check actual AVAudioPlayer progress, all 40 built-in auditions, imported audio, no-hinge updates, configuration notifications, route removal, inactive/interrupted playback and Silent Mode category policy. The 12 hosted tests also hold slow audio-session activation blocked on the serial worker, verify main-actor responsiveness and cancel before playback can start. Simulator progress does not prove audible physical output.
6. Test a fresh release installation on iPadOS 27.2 (the review OS). The local 27.0 and 26.5 runtimes cannot establish that result. On iPad without a hinge, selected/library previews and manual simulation must remain usable.

The `Duo SDK validation` workflow uses the typed scheme and optimized configuration on a clean Xcode 27.1 runner. It tests iPadOS 27.0, installs the 27.1 runtime, then tests Duo with `TEST_RUNNER_HINGY_DUO_INTEGRATION=1`. The Duo-only UI test requires a real initial hinge sample and no initial sound; the job rejects skipped tests. This is an initial-callback check, not open/close/display-handoff acceptance. On other devices the one Duo-only test intentionally skips. See [the dated report](RESUBMISSION_VALIDATION.md) for actual results; workflow existence is not a pass.

## Physical Duo acceptance — release blocking

With the app visible/active: closed → partly open → flat gives one opening sound; flat → partly open → closed gives one closing sound. Repeat slowly, rapidly, and with jitter near 8/22 degrees. Adjust the documented app thresholds/dwell only from measurements. Confirm no double playback across inner/outer scene/view handoff.

Pay special attention to callback order while closing: if the scene becomes inactive before the closed sample or 80 ms dwell completes, this implementation suppresses the effect. **Do not claim that closing works until verified.** A lifecycle design change may be required. Do not fix it by claiming background privilege or replaying a stale event on activation.

Lock/unlock, switch apps, present system UI, interrupt with a call, change headphones and reset media services: no old pending sound may fire. Returning establishes a fresh silent baseline. Hinge absence must clear pending state. The single-scene manifest avoids duplicate monitors; reassess ownership before enabling multiple app instances.

## Distribution

Review the supplied app icon, select signing/team/bundle ID, review privacy/API declarations with the release SDK, choose the repository's distribution license, and make an explicit decision about the foreground-only product promise. Do not submit the demo as a working automatic/system-wide utility. No App Store approval, TestFlight build, signed IPA, hardware testing, or background operation is claimed.
