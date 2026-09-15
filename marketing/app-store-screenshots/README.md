# Hingy App Store assets

This is a local, reproducible App Store screenshot renderer built for Hingy using the `app-store-screenshots` skill workflow.

The page uses the reviewed simulator captures in `public/screenshots/` and the tracked 1024px app icon. It exports the 6.9-inch iPhone master size, `1320x2868`, through the bundled Playwright exporter and validates dimensions and PNG opacity.

## Export

From this directory:

```sh
npm install --ignore-scripts
npm run build
npm run dev
```

In another terminal, run `npm run export` while the local server is running, then `npm run validate`. The export writes to `release/app-store-assets/` and includes a manifest, validation report, contact sheet, and zip archive.

These assets are candidate simulator/preview marketing materials. They retain the app's simulation disclosure and must not be described as physical Duo validation until a supported device build is tested.
