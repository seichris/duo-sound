# App Review notes — blocked launch draft

**Do not paste these notes as evidence that testing has happened.** Complete `readiness.json` and replace this heading with version/build/device/OS details from the tested candidate before submission. No review account is needed because the app has no login.

## Product and scope

Hingy offers independently selected opening and closing sound effects through the public hinge API on supported hardware. It is a **foreground-only** experience, not an iOS system sound replacement or background fold listener. On unsupported hardware, sound previews and explicitly labelled simulation do not claim to detect a physical hinge.

The distinct intended interaction is a physical fold with individually assigned original/imported effects, not a collection of web links or a reskinned soundboard. Please evaluate this description against the actual build: the default developer preview has not yet established the physical interaction and must not be submitted as the finished product. Review Guideline 4.3(b) explicitly covers generic sound-effect apps; approval is not guaranteed by adding metadata or more presets.

## Reviewer flow for the validated hardware build

With the app visible and active on supported hardware, establish its initial hinge state; the first observation is silent. Open and close, and verify the separate selections. Confirm actual endpoint/handoff behavior against the attached validation report. Use Preview to audition effects, change the volume, select Off, and import a short audio file through Files. A suitable fixture can be generated with `scripts/generate_assets.py` for testing; no protected third-party audio is bundled.

The app respects Silent Mode and current output routing. It intentionally suppresses pending effects when inactive, interrupted, locked, or suspended. No microphone, camera, background-audio entitlement, private API, account, ads, purchases, or analytics SDK is used. There is no remote content catalogue or user-to-user sharing service.

## Attach before submitting

The owner must supply the actual build number, release SDK/toolchain, device/OS results (especially close/display handoff), a real recorded demonstration if useful, valid support/contact and privacy URLs, completed privacy/age-rating responses, rights/copyright information, and truthful availability/compatibility settings. Do not add invented phone numbers, developer identities, approval statements, or treat the existing App Store record as approval. See `docs/APP_STORE_RELEASE.md`.
