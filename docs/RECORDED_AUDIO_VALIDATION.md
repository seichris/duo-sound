# Build 5 recorded-audio validation — October 19, 2026

Candidate **1.0 (5)** expands Hingy to 46 choices: 20 existing synthesized presets and 26 bundled CC0 recordings. The added set is GPT's recommended 18 CC0 recordings plus eight Kenney effects. Source declarations were independently checked before acquisition; optional CC BY clips and the unedited reserve are excluded. [Library and processing details](SOUND_LIBRARY.md), [source ledger](../third_party/audio/sources.json).

Implementation commit: `d9b74e2e6ceb617a7792a3b73254fc7cefda0ab7`. Product fingerprint: `3679a10f0e9fc3c9d2323f39b5b5588265e0948e742838221361d21a728a4442`. Later documentation/evidence edits do not change this product fingerprint. The earlier build 4 reports remain historical.

## Completed local checks

| Check | Result | Scope |
| --- | --- | --- |
| Swift core tests | 41 passed, zero failures | All 46 choices, 2,209 independent selection pairs, legacy persistence, PCM/duration/amplitude, distinct original renders, bundled recordings and credits |
| Release preparation tests | 22 passed, zero failures | Includes rejection of altered output, original-source and license records |
| Resource preflight | 26 recordings passed | Source/output hashes, complete resources, CC0 metadata, PCM16 mono 44.1 kHz, duration and size limits |
| Offline reproduction | 28 generated files identical | Regenerated every WAV, manifest and credits in a temporary output directory and compared bytes with committed resources |
| iPad Air 11-inch (M3), iPadOS 27.0 | 14 passed, zero failures/skips | All 13 hosted audio/model tests plus the new recorded-library/credits UI test |
| Duo, iOS 27.1 | 15 passed, zero failures/skips | Same hosted tests, recorded-library/credits UI, actual public hinge silent initial callback |
| Optimized SDK 27.1 compilation | Device and simulator passed | Release-Duo, unsigned, testability disabled; both products contain all 26 recordings and build number 5 |

The simulator tests use optimized Release-Duo with testability enabled for hosted test access. They are targeted runs, not the complete 19-test SDK matrix. The iPad run used the same app code; its UI preview assertion was then made repeat-safe by comparing the selection before/after preview. The final assertion ran successfully on Duo.

The player tests decode and start every choice in both directions. A new recorded-fart test checks actual playback-clock advancement after a missing-hinge update. The UI test previews Tiny Fart without changing selection, saves Wood Knock across termination/relaunch, and opens offline credits. Exported iPad and Duo attachments were visually inspected. These are QA captures, not approved store screenshots; system overlays in Duo captures are retained.

[Local test evidence](../release/evidence/recorded-audio-validation-2026-10-19.json) includes test summaries, logs and capture provenance. [Compile evidence](../release/evidence/recorded-audio-compile-2026-10-19.json) records app identity, binary/resource hashes, SDK and signing/testability scope.

## CI and release boundary

The implementation commit starts [standard CI](https://github.com/seichris/duo-sound/actions/runs/39182370871), [the full SDK matrix](https://github.com/seichris/duo-sound/actions/runs/39182370955), and [release preparation](https://github.com/seichris/duo-sound/actions/runs/39182370809). All three workflows have now passed. Standard iPhone iOS 26.0.1, standard iPadOS 18.5 and typed iPadOS 27.0 each passed 18 tests with zero failures and one intentional Duo-only skip. Duo iOS 27.1 passed all 19 with zero failures/skips. The generated merge checkout `f1ee09ab5dd54ae076f53ae214007fd9fb5d0ad9` records the same product fingerprint as implementation `d9b74e2`. [Final CI results](../release/evidence/build5-ci-2026-10-19.json) preserve exact counts and source binding. No current CI failure required a repair. [Resubmission preparation](../release/BUILD_5_RESUBMISSION.md) adds six fresh native screenshot candidates, declaration changes and current blockers.

The Freesound inputs are official public HQ MP3 previews, not original WAV downloads. Preserved source bytes and actual processing metadata make the packaged assets reproducible offline. The 26 WAVs total 1,704,102 bytes, and the local sampler exports 92 direction options without autoplay or network access.

Neither GPT's research nor this technical validation constitutes a listening review. Perceived balance and unwanted recorded content still need listening QA. There is no physical-device output/handoff proof, iPadOS 27.2 test, signed archive, replacement upload or submission. Six current native iPhone/13-inch iPad candidates have since passed local asc validation; final storefront presentation and the other existing readiness gates remain unverified. Only the public-SDK compilation gate has been updated to this candidate.
