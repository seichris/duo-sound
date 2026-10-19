# Resolution Center reply draft — not sent

Build 5 adds 26 recorded sounds and needs its own final validation paragraph; the build 4 results below are historical.

Use only after a replacement build is uploaded, processed and selected. Replace the build placeholder with the actual processed build. Keep the testing paragraph aligned with completed evidence; this draft does not claim physical-device testing.

---

Thank you for reporting the sound playback issue on iPad. The replacement build, **[processed replacement build number]**, includes repairs to the sound-preview path:

- Audio-session activation/deactivation and player setup now run on a serial background queue, keeping slow audio-system calls off the UI thread. Cancellation prevents late activation from replaying an old sound after inactivity.
- Explicit Preview taps now use an audio session that plays in Silent Mode and mixes with other audio.
- Missing hinge data, which is expected on iPad, no longer cancels manual previews.
- Benign audio-session configuration notifications no longer cancel a sound immediately after playback starts.
- Library previews now display visible feedback, and the app explains how to preview sounds without hinge hardware.

On iPad, please select a non-Off effect, set system and effect volume above zero, and tap **Preview** under Opening or Closing. The sound library's play buttons also work without a hinge and when automatic fold sounds are disabled. Audio follows the current output route, including headphones. The clearly labelled **Simulate hinge** controls provide manual Open/Close playback. Automatic physical fold effects require supported hardware and the app visible and active; those automatic effects respect Silent Mode.

Historical build 4 validation (do not present as build 5 testing): the earlier product source passed 16 hosted/UI tests on each of iPhone iOS 26.0.1, iPadOS 18.5 and typed iPadOS 27.0, with zero failures and one intentional Duo-only skip per device. The corrected Duo iOS 27.1 suite passed all 17 tests with no failures or skips, including the actual public hinge initial callback, all 12 audio/model tests and library audition/selection/persistence. A later iPad rerun passed 15 tests but timed out in Xcode while launching the privacy test before its UI assertions; that failed attempt is retained separately. The library flow passed in a targeted local iPad recheck too. Optimized unsigned SDK 27.1 device and simulator builds compiled. The exact-helper standard recheck also passed 16/0/1 on both iPhone and iPad.

We have not reproduced the issue on the physical review device or tested physical audio output on iPadOS 27.2. The source-level failure paths above were identified and repaired; the simulator results do not establish the exact cause on that device. No review account or network service is required to use the app.
