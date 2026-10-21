# App Review notes — submitted with 1.0 (5)

Submitted October 19, 2026. [Final submission receipt](BUILD_5_SUBMITTED.md). The following is the actual review-notes text; existing private review contact details were preserved.

Build 5 fixes manual sound playback on iPad and iPhone without a hinge. No login or network is required.

On iPad: choose a non-Off sound, set system/effect volume above zero, then tap Preview under Opening or Closing. Library play buttons also work without a hinge and with automatic fold sounds paused. Manual previews play in Silent Mode, mix with other audio, and follow the current output route. Simulate hinge provides labelled manual Open/Close controls.

Automatic hinge effects require supported iPhone Duo hardware and Hingy visible and active; automatic effects respect Silent Mode and stop when inactive. They are not a background/system sound replacement.

Audio session/player setup runs on a serial background worker. Missing hinge data and benign route-configuration notices no longer cancel manual previews. Visible feedback confirms explicit preview requests. The offline library contains 46 choices (20 original presets and 26 CC0 recordings) with creator credits in About.

Testing basis: owner-authorized simulator validation; no physical devices were available. Full simulator suites: iPhone iOS 26.0.1, iPadOS 18.5 and iPadOS 27.0 each 18 passed, zero failures, one intentional Duo-only skip; Duo iOS 27.1 all 19 passed with zero failures/skips, including the actual public hinge silent initial callback. Every preset decodes/starts in both selectors, with playback-clock progress regression coverage. Core tests 41 passed; release/archive-policy checks 25 passed. The exact physical iPadOS 27.2 review setup and physical audio/display handoff were not tested.

Privacy: no account, advertising, analytics SDK, microphone recording, tracking or app-operated data collection. App Privacy is published as Data Not Collected. Imported files remain local. No review account is required.
