# App Review notes for Hingy 1.1 (8)

Hingy 1.1 (8) adds public native hinge detection on supported iPhone Duo hardware with iOS 27.1+, two audio-file actions for Shortcuts, and a simpler main screen. Paper, Zipper and Rain are removed; old selections migrate to Click. The offline library has 43 sounds (17 original procedural presets and 26 CC0 recordings), with credits in About. No login is required.

On any iPhone or iPad: select a non-Off sound, raise system/effect volume, then tap Preview for opening or closing. Library play buttons also preview without changing the saved selection. Previews work in Silent Mode and with automatic fold sounds disabled. Simulation controls have been removed.

On supported iPhone Duo: enable fold sounds and open/close while Hingy is visible and active. The first native reading silently establishes a baseline. Automatic hinge effects respect Silent Mode; app switching/locking ends observation. Hingy does not monitor a hinge or run an audio service while suspended.

Shortcuts: create a shortcut with Hingy's Get Opening Sound (or Get Closing Sound), followed by Apple's Play Sound using the returned file. Hingy's action returns an IntentFile and does not open the UI or play audio itself. Shortcuts owns playback. Use Shortcuts/system volume; Hingy's effect-volume slider applies only inside Hingy. Available system automation triggers, locked execution and timing depend on the installed OS and workflow. No claim is made that a stock fold automation trigger is available on every OS. A selection of Off or unavailable import returns a clear error. Running the action explicitly passes a copy of the chosen audio to Shortcuts.

Validation includes simulator playback, native public hinge callback and actual UI checks, plus installation and launch on an iPhone 16 Pro Max with iOS 27.0.1. Physical iPhone Duo folding, display handoff and locked Shortcuts automation were not tested. No camera, microphone, notification, motion or background entitlement is used.

Privacy: no accounts, ads, analytics SDK, tracking, microphone recording or app-operated data collection. Imports/settings remain local; user-invoked Shortcuts actions hand over only the selected audio. Published App Privacy is Data Not Collected. Existing review contact details remain valid.
