# Screenshot plan and provenance

Research date: September 14, 2026. Source: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/

Apple currently lists **1398×2034 / 2034×1398** for Duo's outer display and **2007×2853 / 2853×2007** for its inner display. The 6.9-inch group also accepts **1320×2868**, **1290×2796**, and **1260×2736** (and landscape equivalents). For supported iPads, the 13-inch group accepts **2064×2752** or **2048×2732**, plus landscape. Recheck App Store Connect's actual required slots when uploading; do not infer a Duo simulator's marketing dimensions from another device.

The project still targets iPhone and iPad. Do not silently remove iPad support to avoid its screenshots, or claim every iPad has a hinge.

## Proposed sequence

1. **Choose your opening and closing sounds.** Actual main screen; small but readable foreground requirement.
2. **Two actions. Your own sound.** Actual independent selections and previews.
3. **20 original effects.** Actual grouped, searchable sound library, without third-party franchise names.
4. **Import a short clip.** Real Files/import interaction using an original fixture, no private filenames.
5. **You control the quiet.** Volume/Off and clear Silent Mode/output-route explanation.

For launch, add genuine physical-hinge imagery only after the real device build is validated. Never remove a demo label, replace the status with fabricated hardware activity, or relabel an ordinary iPhone screenshot as Duo. Never stretch a screenshot into another device's aspect ratio.

## Capture workflow

Use the UI-test attachments from CI for **preview QA only**. They are generated from the running app, not marketing mockups; a successful test does not equal visual approval. For launch, use `scripts/capture_screenshot.sh <simulator-UDID> <output.png>` after manually navigating the validated build to the desired state. This captures the actual simulator pixels without rescaling. Real-device screenshots should be exported from that device. Keep raw files, candidate/build identity, device/OS, and review notes in a private release workspace; avoid committing personal media.

`release/screenshots.json` is deliberately empty until final captures exist. To complete it, copy accepted PNGs into `release/screenshots/`, record their dimensions and SHA-256 values, and record whether they depict real or simulated hinge input. A labelled simulation QA capture is not a launch-hardware screenshot. The release checker verifies checksums, dimensions, and review evidence. No screenshots or App Store assets have been uploaded by this preparation PR.
