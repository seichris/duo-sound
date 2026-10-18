# Resolution Center reply draft — not sent

Use only after a replacement build is uploaded, processed and selected. Replace the build placeholder with the actual processed build. Keep the testing paragraph aligned with completed evidence; this draft does not claim physical-device testing.

---

Thank you for reporting the sound playback issue on iPad. The replacement build, **[processed replacement build number]**, includes repairs to the sound-preview path:

- Explicit Preview taps now use an audio session that plays in Silent Mode and mixes with other audio.
- Missing hinge data, which is expected on iPad, no longer cancels manual previews.
- Benign audio-session configuration notifications no longer cancel a sound immediately after playback starts.
- Library previews now display visible feedback, and the app explains how to preview sounds without hinge hardware.

On iPad, please select a non-Off effect, set system and effect volume above zero, and tap **Preview** under Opening or Closing. The sound library's play buttons also work without a hinge and when automatic fold sounds are disabled. Audio follows the current output route, including headphones. The clearly labelled **Simulate hinge** controls provide manual Open/Close playback. Automatic physical fold effects require supported hardware and the app visible and active; those automatic effects respect Silent Mode.

We verified the repaired playback path using hosted AVAudioPlayer tests and UI tests on the iPad Air 11-inch (M3) simulator running iPadOS 18.5 and the iPhone 17 Pro Max simulator running iOS 26.0.1: 15 tests passed on each. The checks include actual playback progress, all built-in clips, an imported clip, missing hinge data and cancellation behavior. We also compiled the public Duo hinge integration with SDK 27.1 for device and simulator.

We have not reproduced the issue on the physical review device or tested physical audio output on iPadOS 27.2. The source-level failure paths above were identified and repaired; the simulator results do not establish the exact cause on that device. No review account or network service is required to use the app.
