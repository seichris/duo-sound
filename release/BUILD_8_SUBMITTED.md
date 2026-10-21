# Hingy 1.1 (8) submitted

Submitted at 2026-10-21T22:53:27.24Z (October 22 in Singapore). The release is configured for automatic publication after Apple approval; submission is not public availability of 1.1.

- App: `6812193737`, bundle `com.seichris.duosound`.
- App Store version: `ec6b3b38-419a-470a-8c60-6fa9ccfecbfb`.
- Processed VALID build: `fda3f261-a909-4a21-a2eb-6f37f112885a`.
- Review submission: `4137d441-30a4-426d-88c6-ab5d5f475c42`.
- Product source fingerprint: `8bed71d5277505034c82bdce2e7ba6d07c281c62ec65a0b68aef25c800e7ea5c`.
- Distribution IPA SHA-256: `a1616eb29161c2fa631dee6207e0c3d9652f71761c9a0d807b591224ebba9326`.
- Source and public privacy policy merged in [PR #4](https://github.com/seichris/duo-sound/pull/4), merge `67a4325470a0b5227554bf21e94104d4b62c0293`.

The update removes Paper, Zipper, Rain and in-app fold simulation, including the Try a fold and Foreground only sections. It enables the public native hinge adapter and adds the two file-returning Shortcuts actions. The library contains 43 sounds. App Review notes and store description disclose native foreground observation and device-dependent automation/locked playback.

A signed development build 1.1 (8) was installed, its installed version queried, and the app launched on a connected iPhone 16 Pro Max with iOS 27.0.1. This is separate from the distribution IPA accepted by Apple. Audible output was not independently confirmed during this release run.

46 core tests and 25 release-policy tests passed. The optimized iPhone hosted playback suite passed all 13 tests; its four ordinary UI scenarios passed across the recorded runs. The iPad run passed 16 tests with one intentional Duo-only skip and one selection-test failure: XCTest tapped an obsolete pre-filter row position. The driver now waits for stable result frames and checks selection before relaunch; the affected test passed, including persistence. The current native Duo simulator callback passed with zero skipped tests. Full cloud CI was still running when the release receipt was prepared; the typed iPad and standard iPhone steps had passed.

No physical Duo folding/display-handoff or locked Shortcuts automation proof is claimed. The owner explicitly authorized simulator-based release for this exact candidate; the physical evidence field remains false with the source-bound exception.

Four current native iPhone/iPad screenshots are COMPLETE. A redundant fifth image was omitted after Apple asset processing timed out. Final strict App Store API validation reported zero errors and zero warnings; its privacy-publication advisory was resolved by the live public Data Not Collected label and the source audit. Existing review contact, content-rights, age-rating, pricing and availability declarations were preserved.

[Evidence and receipts](evidence/1.1-build8-2026-10-22/) retain build hashes, testing limitations, authorization, reviewed screenshot provenance and final submission status. The public privacy policy was verified after merge and includes the explicit Shortcuts audio handoff.
