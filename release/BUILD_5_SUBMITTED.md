# Hingy 1.0 (5) — submitted

**Waiting for Review**, submitted October 19, 2026 at 02:02:31 UTC (10:02 Singapore). Both the authenticated App Store Connect UI and API confirmed the state. The reply to Apple's original iPad rejection was sent before resubmission.

[App Store Connect receipt](https://appstoreconnect.apple.com/apps/6812193737/distribution/reviewsubmissions/details/a3a51215-0c41-4fa9-b8fd-cb4a76a26593)

| Item | Recorded value |
| --- | --- |
| App / bundle | 6812193737 / `com.seichris.duosound` |
| Version / build | 1.0 / 5 |
| Processed build ID | `51102e4e-0cda-4300-ac5a-798b0595347a` |
| Version ID | `534d131b-2621-48b8-a04b-c196b5b70ec4` |
| Review submission | `a3a51215-0c41-4fa9-b8fd-cb4a76a26593` |
| Build processing | VALID |
| SDK / Xcode build | iPhoneOS 27.1 / 27A9275 |
| Signing | Apple Distribution, team `4H5PK8686H`; signature verified |
| Signed-source commit | `e48383ce7b81c9b54f3958c8162f022db71c6832` |
| Signed-source fingerprint | `0287c83e98774637b55506ce5d25c26415bc7fa5f78973f14c800cda3b88f45c` |
| IPA SHA256 | `ac30b89d5cc4da7c40db50ec0603a90e57629e84741832fad9d321706668f008` |

## Validation and limits

The owner explicitly authorized simulator validation because no physical devices were available. Physical proof remains false in the readiness record, with a build/source-bound authorization. The sent reply and review notes disclose that physical audio/display handoff and the exact iPadOS 27.2 review environment were not tested. Simulator playback-clock/decode checks do not establish perceived audio quality.

App/Sources match tested implementation `d9b74e2e6ceb617a7792a3b73254fc7cefda0ab7`. Full suites passed on iPhone iOS 26.0.1, iPadOS 18.5 and iPadOS 27.0: each 18 passed, zero failed, one intentional Duo-only skip. Duo iOS 27.1 passed all 19 with no failures/skips. Core tests passed 41. [Implementation CI evidence](evidence/build5-ci-2026-10-19.json) records exact source/SDK bindings. The final source fingerprint differs because the release guard, generated archive prebuild phase and listing approval changed. [Release-policy CI](https://github.com/seichris/duo-sound/actions/runs/39186826041) passed on the signed-source commit with all 25 release tests. No unresolved current CI failure remains.

The signed archive/export identity, privacy manifest and all 26 recorded WAV resources were checked. Existing distribution signing assets were used; no private keys were exported or rotated. Apple accepted and processed the actual upload. The CLI could not perform remote checksum comparison because the API supplied no checksum; the local exported IPA hash was verified.

## Privacy and storefront

- Authenticated App Privacy UI confirmed published **Data Not Collected**; signed manifest declares no tracking, collected data or required-reason categories. No embedded third-party executable SDKs were found.
- Listing updated to 46 sounds. Six native iPhone/iPad simulator screenshots uploaded and processed COMPLETE; [manifest](screenshots.json) retains original capture provenance/hashes and uploaded asset IDs.
- Third-party content rights declared; crude humor is INFREQUENT_OR_MILD for the fart recordings. Offline source/license credits included.
- Public support, privacy and marketing URLs checked; review contact complete. Existing GBR/USA availability preserved.
- Pre-submit validation: zero errors/warnings; its privacy-publication advisory was resolved by the authenticated UI check. Duo inner/outer screenshots remain a future requirement; no Duo optimization badge or physical handoff validation is claimed.

## Retained receipts and local deliverables

Evidence directory: [build5-release-2026-10-19](evidence/build5-release-2026-10-19/).

- [Submission API receipt](evidence/build5-release-2026-10-19/submission-final.json), [version/build receipt](evidence/build5-release-2026-10-19/version-final.json), [visual receipt](evidence/build5-release-2026-10-19/submitted-waiting-review.png).
- [Actual sent reply](evidence/build5-release-2026-10-19/review-reply-sent.txt), [actual review notes](REVIEW_NOTES.md), [pre-submit validation](evidence/build5-release-2026-10-19/pre-submit-validate.json).
- [Signed artifact identity](evidence/build5-release-2026-10-19/signed-build.json), [processed build](evidence/build5-release-2026-10-19/apple-processed-build.json), [upload receipt](evidence/build5-release-2026-10-19/upload-result.json), [privacy/store audit](evidence/build5-release-2026-10-19/audit.json).

The IPA, archive, export options and hashes are retained locally under `build/app-store-1.0-build5/` (ignored by Git). Subsequent receipt/documentation commits do not alter the signed source fingerprint. PR #3 remains a draft and has not been merged.
