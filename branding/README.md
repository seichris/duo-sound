# Hingy logo

The publisher supplied `hingy-logo-original.png` on October 18, 2026. It is the unchanged 1254×1254 opaque original (SHA-256 `ebbac8235f28ebe7b1d619b8d2aa6a7b011320dc20a2445a3a31a23d8f1c7eab`).

The app icon, in-app About logo and screenshot renderer icon use the same 1024×1024 opaque RGB export. The support/site generator copies the app icon automatically. Export with:

```sh
sips -z 1024 1024 branding/hingy-logo-original.png --out App/Assets.xcassets/AppIcon.appiconset/AppIcon.png
cp App/Assets.xcassets/AppIcon.appiconset/AppIcon.png App/Assets.xcassets/HingyLogo.imageset/HingyLogo.png
cp App/Assets.xcassets/AppIcon.appiconset/AppIcon.png marketing/app-store-screenshots/public/app-icon.png
python3 scripts/generate_assets.py
```

The animated in-app hinge illustration represents the live angle; it remains separate from the brand logo. Previously rendered/uploaded marketing screenshots predate this logo and are not current candidate assets. Regenerate and review captures before replacing store screenshots.
