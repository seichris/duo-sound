# Hingy 1.0 (5) resubmission preparation

Prepared October 19, 2026. **Preparation complete within the recorded scope; signed archive and submission remain blocked.** No replacement build, screenshots or review reply have been uploaded/sent.

Implementation: `d9b74e2e6ceb617a7792a3b73254fc7cefda0ab7`; product fingerprint `3679a10f0e9fc3c9d2323f39b5b5588265e0948e742838221361d21a728a4442`. Documentation, evidence and screenshot follow-ups leave the product fingerprint unchanged.

## CI

- [Release preparation](https://github.com/seichris/duo-sound/actions/runs/39182370809): passed.
- [Standard CI](https://github.com/seichris/duo-sound/actions/runs/39182370871): passed. iPhone 17 Pro Max / iOS 26.0.1 and iPad Air 11-inch (M3) / iPadOS 18.5 each passed 18 tests, failed zero and intentionally skipped the Duo-only initial-hinge test.
- [Typed SDK 27.1 matrix](https://github.com/seichris/duo-sound/actions/runs/39182370955): passed. Optimized device/simulator compilation passed. iPadOS 27.0 passed 18 tests with zero failures and one intentional Duo-only skip; Duo iOS 27.1 passed all 19 tests with zero failures/skips, including the actual public hinge initial callback.

All three workflows passed on implementation `d9b74e2`; generated merge checkout `f1ee09ab5dd54ae076f53ae214007fd9fb5d0ad9` has the same product fingerprint. No build 5 CI failures needed a code repair. [Final CI evidence](evidence/build5-ci-2026-10-19.json) preserves run IDs, exact device/OS counts, checkout identity and the SDK fingerprint. Subsequent commits change only documentation, evidence and screenshot records and use `[skip ci]` to avoid repeating the unchanged matrix.

See [the audio validation report](../docs/RECORDED_AUDIO_VALIDATION.md) for the earlier 41 core / 22 release tests, targeted iPad 14/0/0 and Duo 15/0/0, playback progress checks and resource integrity/reproduction. Build 4 attempts remain historical and do not validate the expanded build 5 resources.

## Prepared materials

- Forty-six selectable sounds, including six farts, eight Kenney effects and twelve other recommended CC0 recordings; original IDs/defaults preserved. Offline credits and exact acquired-source/license/processing ledger are included.
- Six visually inspected native screenshot candidates: three iPhone images at 1320×2868 and three 13-inch iPad images at 2064×2752. All pass `asc screenshots validate` with zero errors/warnings. The manifest preserves attachment identity, test/source/build/OS details and hashes. They are unmodified runtime captures with truthful demo/no-hinge labels; final store presentation is not approved.
- The local 13-inch iPad capture run passed both selected UI tests with zero failures/skips. XcodeBuildMCP's wrapper timed out after 300 seconds; the underlying completed `.xcresult` and `TEST EXECUTE SUCCEEDED` log independently confirm the result. This transport timeout is retained, not represented as a successful MCP response.
- US/UK draft listing exports, support/privacy site preview and unsent review-response draft reflect the expanded library. The draft marker is retained.
- App Store Connect third-party-content declaration updated to `USES_THIRD_PARTY_CONTENT` and confirmed by readback. The age questionnaire's `profanityOrCrudeHumor` field changed from `NONE` to `INFREQUENT_OR_MILD` for the six bodily-function jokes. Other fields/overrides were preserved. Apple's [definition](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/) explicitly covers this content.
- Existing-record `asc validate` reports zero errors/warnings and an App Privacy publication advisory. Uploaded build 3 remains the newest build and version 1.0 remains rejected. This API result does not validate or process build 5.
- Public support, privacy and marketing URLs returned HTTP 200. A valid local Apple Distribution identity exists; no private keys were exported or modified. Neither check establishes a completed signed archive.

[Preparation evidence](evidence/build5-resubmission-2026-10-19/preparation.json) and [current submission blockers](evidence/build5-resubmission-2026-10-19/submission-status-blocked.txt) distinguish these scopes.

## Remaining release gates

`BUILD_NUMBER=5 bash scripts/archive_app.sh` runs `release_check.py --submission` **before signing/archive**. It stops because the existing readiness record still requires:

- Physical audio, open/close and display-handoff evidence. No physical devices are available; iPadOS 27.2 and perceived audio quality have not been tested.
- Full import/lifecycle/accessibility QA and listening review.
- Final privacy manifest/archive audit and confirmation that App Privacy is published. Public API cannot verify publication; no cached `asc web` session or browser-extension surface is available for the authenticated UI check.
- Final store presentation approval, public contact/owner/storefront declarations, launch-copy approval and Apple acceptance of the distribution SDK/build.

The six native files remove the missing-current-iPhone/iPad-file error, but do not set the final store-review gate to passed. Apple's [current screenshot specification](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) makes Duo inner/outer screenshots mandatory starting April 2027 for SDK 27.1+ apps. Those assets remain incomplete; no Duo optimization badge is claimed.

After the remaining evidence is supplied, reconcile `release/readiness.json` with the unchanged product fingerprint, approve launch copy, run the submission check, archive/export build 5, upload and wait for processing, then attach the actual processed build and reviewed assets to version 1.0. The reply draft must use the actual uploaded build number. The existing guard is retained; this package is not an IPA or authorization to submit an unvalidated build.
