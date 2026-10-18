# Hingy App Store asset candidate

This directory contains the previously uploaded English iPhone 6.9-inch screenshot candidate rendered at Apple's accepted master size, `1320x2868`.

- Renderer: `marketing/app-store-screenshots` (Next.js + Playwright)
- Source: simulator captures from `main` commit `00ab74d`
- Provenance: iPhone 17 Pro Max simulator, iOS 26.5, preview/demo build
- Validation: all five PNGs are opaque and pass the local and `asc screenshots validate` checks
- App Store Connect: uploaded to version `1.0`, `en-US`, display type `APP_IPHONE_67`

These are candidate marketing assets, not proof of physical Duo hinge behavior. The app's simulation disclosure remains visible until the iOS 27.1 Duo SDK build and real-device qualification are complete.

These exports predate the publisher-supplied logo selected on October 18, 2026 and the current audio repair. The renderer now uses the new logo; these PNGs/ZIP are historical and must be regenerated from reviewed candidate captures before re-upload.

## Current raw candidate captures — October 19

Two native iPhone 17 Pro Max simulator images from current-source CI are saved under `release/screenshots/2026-10-19/`, with dimensions, source/build, provenance and visual review in `release/screenshots.json`. They retain visible simulation disclosure and are not physical Duo evidence. These raw candidates have not been framed or uploaded. The 13-inch iPad local retry produced an Apple boot-logo frame despite a successful launch command, so it was rejected; iPad and Duo inner/outer slots remain incomplete.
