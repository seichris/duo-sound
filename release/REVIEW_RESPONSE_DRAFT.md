# Resolution Center reply draft — not sent

Use only after a replacement build is uploaded, processed and selected. Replace the build placeholder with the actual processed build. Keep the testing paragraph aligned with completed evidence; this draft does not claim physical-device testing.

---

Thank you for reporting the sound playback issue on iPad. The replacement build, **[processed replacement build number]**, includes repairs to the sound-preview path:

- Audio-session activation/deactivation and player setup now run on a serial background queue, keeping slow audio-system calls off the UI thread. Cancellation prevents late activation from replaying an old sound after inactivity.
- Explicit Preview taps now use an audio session that plays in Silent Mode and mixes with other audio.
- Missing hinge data, which is expected on iPad, no longer cancels manual previews.
- Benign audio-session configuration notifications no longer cancel a sound immediately after playback starts.
- Library previews now display visible feedback, and the app explains how to preview sounds without hinge hardware.

On iPad, please select a non-Off effect, set system and effect volume above zero, and tap **Preview** under Opening or Closing. The sound library's play buttons also work without a hinge and when automatic fold sounds are disabled. Audio follows the current output route, including headphones. The clearly labelled **Simulate hinge** controls provide manual Open/Close playback. Automatic physical fold effects require supported hardware and the app visible and active; those automatic effects respect Silent Mode.

Current candidate validation is still incomplete. Optimized SDK 27.1 device and simulator builds compiled with the supplied logo. The iPhone simulator passed 16 hosted/UI tests, with one intentional Duo-only skip. All 12 audio/model tests passed on both iPad simulator OS versions and Duo. Each iPad suite had one XCTest app-termination failure during test relaunch. Duo's actual public hinge callback and silent initial state passed; its library UI test failed because the test tapped a partially obscured row. The test's scrolling helper has been corrected and rechecks are pending. Replace this paragraph with final completed results before sending; no partial suite is claimed as passing acceptance.

We have not reproduced the issue on the physical review device or tested physical audio output on iPadOS 27.2. The source-level failure paths above were identified and repaired; the simulator results do not establish the exact cause on that device. No review account or network service is required to use the app.
