# Resolution Center reply draft — not sent

Candidate 1.0 (5) has completed the scoped simulator checks in `docs/RECORDED_AUDIO_VALIDATION.md`. The full CI matrix is tracked separately; update this draft only from completed evidence.

Use only after a replacement build is uploaded, processed and selected. Replace the build placeholder with the actual processed build. Keep the testing paragraph aligned with completed evidence; this draft does not claim physical-device testing.

---

Thank you for reporting the sound playback issue on iPad. The replacement build, **[processed replacement build number]**, includes repairs to the sound-preview path:

- Audio-session activation/deactivation and player setup now run on a serial background queue, keeping slow audio-system calls off the UI thread. Cancellation prevents late activation from replaying an old sound after inactivity.
- Explicit Preview taps now use an audio session that plays in Silent Mode and mixes with other audio.
- Missing hinge data, which is expected on iPad, no longer cancels manual previews.
- Benign audio-session configuration notifications no longer cancel a sound immediately after playback starts.
- Library previews now display visible feedback, and the app explains how to preview sounds without hinge hardware.

On iPad, please select a non-Off effect, set system and effect volume above zero, and tap **Preview** under Opening or Closing. The sound library's play buttons also work without a hinge and when automatic fold sounds are disabled. Audio follows the current output route, including headphones. The clearly labelled **Simulate hinge** controls provide manual Open/Close playback. Automatic physical fold effects require supported hardware and the app visible and active; those automatic effects respect Silent Mode.

Candidate 1.0 (5) passed 41 core tests and 22 release-preparation tests. Targeted optimized simulator checks passed 14 tests on iPad Air 11-inch (M3), iPadOS 27.0, and 15 tests on Duo, iOS 27.1, with zero failures or skips. These cover all 13 hosted audio/model tests, recorded-sound preview/selection/persistence and offline credits; Duo also verifies the actual public hinge silent initial callback. Every built-in sound decodes and starts in both selectors, and recorded audio continues after a missing-hinge update. Optimized unsigned SDK 27.1 device and simulator builds compile with all 46 choices (20 original presets and 26 bundled CC0 recordings). These targeted runs do not represent the complete CI matrix or a listening review.

We have not reproduced the issue on the physical review device or tested physical audio output on iPadOS 27.2. The source-level failure paths above were identified and repaired; the simulator results do not establish the exact cause on that device. No review account or network service is required to use the app.
