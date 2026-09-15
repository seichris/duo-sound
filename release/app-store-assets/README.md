# Hingy App Store asset candidate

This directory contains the current English iPhone 6.9-inch screenshot candidate rendered at Apple's accepted master size, `1320x2868`.

- Renderer: `marketing/app-store-screenshots` (Next.js + Playwright)
- Source: simulator captures from `main` commit `00ab74d`
- Provenance: iPhone 17 Pro Max simulator, iOS 26.5, preview/demo build
- Validation: all five PNGs are opaque and pass the local and `asc screenshots validate` checks
- App Store Connect: uploaded to version `1.0`, `en-US`, display type `APP_IPHONE_67`

These are candidate marketing assets, not proof of physical Duo hinge behavior. The app's simulation disclosure remains visible until the iOS 27.1 Duo SDK build and real-device qualification are complete.
