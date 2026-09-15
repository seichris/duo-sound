# App Store release preparation

Status: **prepared for review, blocked for submission**. Updated September 15, 2026.

The marketing name candidate is **Hingy**. Research and rejected keyword intents are in [ASO_SEO_RESEARCH.md](ASO_SEO_RESEARCH.md); the machine-readable listing is `release/listing.json`. A matching App Store Connect record is now visible under **WEB3 FZCO**; no exact-name reservation, signing, TestFlight upload, review submission, live site deployment, or agreement acceptance has been performed.

## Live identity check

Read-only reconciliation against the authenticated App Store Connect account on September 15, 2026:

- Seller/team: **WEB3 FZCO**, team ID `4H5PK8686H`.
- Bundle ID resource: `8W83N73D6Z`, `com.seichris.duosound`, universal platform.
- App Store record: `6812193737`, current name **Hingy - Hinge Sounds**, SKU `hingy-ios-2026`.
- Version: `1.0`, state `PREPARE_FOR_SUBMISSION`; no build is uploaded and availability is not configured.
- The visible New App form accepted `hingy` without an inline conflict, but the resulting record name differs. That is not proof that the exact bare name is reserved; keep name availability unresolved until final metadata review.

The record appeared while the visible form was being completed; it was left unchanged. This branch does not claim that a deliberate Create action, upload, or submission was performed.

## What this branch prepares

A supplied 1024×1024 opaque RGB icon included by the Xcode build; an offline in-app privacy summary and help; US/UK listing exports; review notes; screenshot specifications and actual-runtime capture tooling; a noindex preview product/support/privacy site; simulator UI smoke tests with unmodified screenshot attachments; and an evidence-gated AppStore archive configuration. The original fold/audio engine is not represented as hardware-validated by these additions.

## Commands

```sh
python3 scripts/generate_assets.py
python3 scripts/generate_project.py
swift test
python3 -m unittest discover -s scripts/tests -v
python3 scripts/release_check.py
python3 scripts/export_listing.py --draft
python3 scripts/build_site.py
```

`build/listing-draft/` contains editable text fields with a DO NOT SUBMIT marker. `build/site-preview/` contains portable static HTML, support/privacy pages, CSS, and the original icon. Open locally, or serve with `python3 -m http.server --directory build/site-preview`. It is not deployed. The preview includes noindex and no store download/price/rating claims; no fake canonical domain is generated. Configure actual public URLs before a release-site build. The site copy itself must receive a final hardware/launch-status review before publication; automated metadata checks cannot approve marketing claims.

Open the **DuoSound** Xcode scheme to run the preview. **DuoSound-DuoSDK** isolates SDK experimentation. The dedicated **DuoSound-AppStore** configuration enables `APP_STORE_RELEASE` and `DUO_HINGE_SDK`, targets iOS 27.1, and runs `release_check.py --submission` before compilation. Shared schemes' Archive actions use that guarded configuration. Ordinary preview builds are not distribution evidence.

The supplied logo is validated in the asset catalogue by a repository-owned Python build phase; the PNG and test WAV are also downloadable in the Release preparation workflow artifact. Keep the icon tracked so clean checkouts use the same reviewed bitmap. The build phase has user-script sandboxing disabled to run the repository's local generator/checker; it contains no network calls or signing credentials.

## Remaining gates, in order

**Public API and physical behavior.** Confirm the actual SDK declarations and build the hinge adapter. Record a dated device/OS test of open, close, jitter, first observation, foreground return, interruptions, and especially inner/outer display handoff. Test Silent Mode, system/effect volume, wired/Bluetooth output, valid/invalid imports, persistence, VoiceOver and large text. Do not replace missing sensor data with window geometry or scene activation. Do not keep a silent audio loop alive. The implementation remains foreground only.

**Seller and public URLs.** In `release/readiness.json`, provide the actual legal publisher, public support email, copyright, and live HTTPS marketing/support/privacy URLs. The team ID, bundle ID, and App Store record ID recorded above are verified live; the remaining seller and URL fields are still null. URLs need real reachable content and a genuine contact route, not just a source file with placeholders. Regenerate the Xcode project after changing the URLs; its Info.plist substitutions feed the in-app links. Review the full privacy policy and website, not only the offline summary.

**App Store Connect declarations.** Review the existing app record using the matching bundle ID. Confirm the final name is available, choose the actual price and storefronts, complete the current age-rating questionnaire (do not copy a competitor's rating), content rights, encryption questions, and App Privacy responses. The implementation suggests no developer-operated app-data collection, but the owner must audit the final archive and any third-party/testing/support services before selecting that response. Inspect the Xcode privacy report and actual SDK required-reason API declarations, including timing/file access. Do not invent reason codes. EU availability requires the seller's actual Digital Services Act trader determination and verified contact information where applicable; Mainland China and other storefront-specific obligations must be checked for the actual publisher before enabling those regions. No legal status is decided by this PR.

**Screenshots and review materials.** Use the actual running candidate and Apple's accepted slots in `release/SCREENSHOTS.md`. The universal target requires iPad assets too. CI attachments retain visible simulation labels and are QA evidence, not physical-Duo marketing images. Populate `release/screenshots.json` with real files, dimensions, SHA-256, family, locale and provenance; preserve originals and record manual review. Complete `release/REVIEW_NOTES.md` using actual test/build/device details. There is no login/demo account to invent.

**Distribution eligibility.** Apple's current upload baseline is Xcode/iOS SDK 26 or newer; that general baseline does not supply the announced Duo API. Recheck both Apple's current requirements and whether the actual Duo SDK is accepted for the intended distribution channel. A beta SDK announcement is not App Store upload eligibility. Generic sound-effects and unfinished demos face specific review risks; do not market a simulated utility as a completed physical-fold app.

## Evidence and local archive

After validating the candidate, run `python3 scripts/release_check.py --fingerprint`. Record that fingerprint in `validated_source_sha256`, attach real dated references for every required evidence item, approve the launch copy by changing its status to `approved_launch_copy`, and set readiness to `ready` only after all gates are truly complete. Changing a flag alone cannot satisfy the checked-in tests/checker; missing evidence, stale source, unknown seller fields and missing screenshots remain blockers. The checker validates records and files; it cannot independently certify a human's hardware test, legal conclusion or Apple's approval.

```sh
python3 scripts/release_check.py --submission
python3 scripts/export_listing.py
BUILD_NUMBER=1 bash scripts/archive_app.sh  # choose a unique real build number
```

The archive helper requires local Xcode/signing setup and the evidence gate. It archives/exports only; it never uploads or submits. Inspect its ExportOptions against the installed Xcode's `xcodebuild -help` when the release SDK ships. Use Xcode Organizer/App Store Connect deliberately to upload the approved build, review processing/privacy warnings, assign screenshots/metadata, and request review. Keep certificates, API keys, passwords, review contact details and account agreements out of the public repository.

A simulator build or preparation workflow being green means **those checks passed**, not that the physical app is complete or Apple will approve it. Keep the submission blocker report attached to each preparation artifact until resolved.

## Primary sources checked September 14, 2026

- Duo developer/SDK availability: https://developer.apple.com/iphone-duo/
- Announced device/iOS context: https://www.apple.com/newsroom/2026/09/apple-unveils-iphone-duo/
- Current upload SDK requirements: https://developer.apple.com/news/upcoming-requirements/
- Listing fields/contact URL: https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/
- Screenshot dimensions: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/
- Privacy declarations/policy URL: https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/
- Required-reason API reference (full body requires interactive documentation; inspect actual SDK/report): https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
- Current age-rating workflow: https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/
- DSA seller requirements: https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/
- Review requirements and risks: https://developer.apple.com/app-store/review/guidelines/
