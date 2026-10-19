# Screenshot plan and provenance

Specifications rechecked: October 19, 2026. Source: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/

Apple currently lists **1398×2034 / 2034×1398** for Duo's outer display and **2007×2853 / 2853×2007** for its inner display. The 6.9-inch group also accepts **1320×2868**, **1290×2796**, and **1260×2736** (and landscape equivalents). For supported iPads, the 13-inch group accepts **2064×2752** or **2048×2732**, plus landscape. Recheck App Store Connect's actual required slots when uploading; do not infer a Duo simulator's marketing dimensions from another device.

The project still targets iPhone and iPad. Do not silently remove iPad support to avoid its screenshots, or claim every iPad has a hinge.

## Proposed sequence

1. **Choose your opening and closing sounds.** Actual main screen; small but readable foreground requirement.
2. **Two actions. Your own sound.** Actual independent selections and previews.
3. **46 sounds to make it yours.** Actual grouped, searchable sound library, including the recorded farts and Kenney effects, without third-party franchise names.
4. **Import a short clip.** Real Files/import interaction using an original fixture, no private filenames.
5. **You control the quiet.** Volume/Off and clear Silent Mode/output-route explanation.

For launch, add genuine physical-hinge imagery only after the real device build is validated. Never remove a demo label, replace the status with fabricated hardware activity, or relabel an ordinary iPhone screenshot as Duo. Never stretch a screenshot into another device's aspect ratio.

## Capture workflow

Automated UI-test captures start as preview QA. A successful test alone does not approve an image. A native CI capture may become a raw store candidate only after a separate visual review confirms the actual UI, readable content, disclosure of simulated input, accepted native dimensions, source/build identity and complete provenance. Preserve the original pixels and attachment identity. Do not stretch, relabel devices or fabricate status. Manual capture is also supported with `scripts/capture_screenshot.sh <simulator-UDID> <output.png>` after navigating the validated build to the desired state; verify the pixels show Hingy, since a successful launch command can still return a boot frame on an unhealthy simulator.

Build 5 native candidates are recorded in `release/screenshots.json` with source, device/OS, dimensions, hashes and visual-review notes. The iPhone captures show the actual demo home, Tiny Fart preview and persisted Wood Knock selection; matching 13-inch iPad captures show the typed build with No hinge available and manual preview controls. All six pass local asc dimension validation with zero errors/warnings. Build 4 captures remain historical. These images are not physical-hinge imagery, final marketing-page approval or proof of audio output. The earlier 13-inch iPad boot-logo capture was rejected despite correct dimensions; current attempts and accepted candidates are recorded separately. Duo inner/outer store assets remain incomplete; Apple's current specification makes them mandatory starting April 2027 for apps using SDK 27.1 or later.

For additional accepted images, copy PNGs into `release/screenshots/` and record whether they depict real or simulated hinge input. Real-device captures must come from that device; avoid personal media. The release checker verifies paths, checksums and dimensions, while the separate store-screenshot gate remains false until the full required set is reviewed. No current screenshots or App Store assets have been uploaded by this preparation PR.
