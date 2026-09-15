# Hingy: ASO and web SEO research

Research date: **2026-09-14**. Live name check re-run: **2026-09-15**. Product baseline: `0c2754a3d2cac742e0c53f6b4a9204ee7ae4093c`.

## Decision

Position around **custom opening and closing effects for a folding phone**, not a generic soundboard, ringtones, speaker repair, or background automation. Proposed launch name: **Hingy** (5 characters); subtitle: **Custom Open & Close Audio** (25). These are candidates, not a reserved App Store name or a trademark clearance.

**Do not submit the current demo.** The default scheme simulates folds. The hardware adapter remains SDK/device-unverified. The store listing is a conditional launch draft for a validated foreground-only product; neither changing the copy nor turning on a compiler flag completes that work. Apple still lists the Duo SDK as coming later this month [A1].

## Method and limits

Used public web search, Apple's developer/store documentation, a directly retrieved competing App Store product page, F-Droid's Scrunch listing, and a first-person foldable-user discussion. This was **not** a live on-device App Store ranking scrape, Apple Ads keyword report, Google Keyword Planner, Search Console, or paid ASO dataset. No search volume, CPC, numeric keyword difficulty, installs, market size, name availability, or ranking is asserted. An unhelpful search result is not proof of zero demand or zero competitors. Qualitative priority below is our judgment of intent/product fit, not measured traffic.

### Queries actually searched

| Query | Observed result / interpretation |
|---|---|
| `"iPhone Duo" "sound" app` | Mixed early hardware/audio discussion and unrelated apps; not evidence of established app-search demand. |
| `"fold sound" "App Store"` | No clearly relevant direct iOS hinge app in the returned sample. |
| `"fold phone" "sound" Scrunch` | A first-person request for a sound whenever a phone folds [U1]. |
| `"fold unfold" "sound" app` | Mostly Android/foldable and stock-audio intent. |
| `"Scrunch" fold sounds` | Scrunch/F-Droid is the closest conceptual comparator [C1]. |
| `"iPhone Duo" "apps" sounds` | Broad device/app discussion; not sufficiently specific for the lead keyword. |
| `"folding sound" app iphone` | Noise from paper-folding effects and general iPhone audio. |
| `site:apps.apple.com "fold" "sound"` | Broad/unrelated results; native App Store search still needs checking. |
| `site:apps.apple.com "soundboard" "custom"` | Generic custom-soundboard competition. |
| `site:apps.apple.com "Hingy"` | No dependable exact-name availability conclusion from the returned sample; public-store queries for US, GB, SG and AE returned no exact `Hingy` listing, while the authenticated team has a differently named record. |
| `"Soundbox - Custom Soundboard"` | Direct competing App Store listing retrieved [C2]. |
| `"Scrunch" "iPhone"` | Brand ambiguity, including unrelated phone cases. |
| `"fold sounds" app` | Stock effects and unrelated sound content; qualify with device/action language. |
| `"custom fold sound" app` | Scrunch-related results plus unrelated settings/stock audio. |

Some search results exposed only home-page URLs/snippets; these are discovery leads, not precise competitor evidence. The conclusions rely on the directly accessible sources below.

## Competitor and demand evidence

**Scrunch** is an Android fold/unfold sound utility, making it the conceptual competitor rather than an iOS implementation template [C1]. Its privileged Android detection approach is not an iOS feature. **Soundbox** is an adjacent custom-soundboard competitor: its public listing emphasizes importing effects and manual soundboards, not hinge events [C2]. Its reviews raise import discoverability and playback timing concerns; these suggest useful usability tests, not statistics about all users. A foldable owner explicitly asks for customizable fold/unfold sound effects [U1]. This establishes an example of the problem, not its market size.

“Duo” alone is ambiguous: Duo Mobile is an authentication app [C3]. Keep **Sound** and **Fold Effects** with the brand in titles and web headings. Never put competitors' names or film/franchise sound names in the App Store keyword field. Use original effects and user-selected files, not bundled unlicensed clips.

## Prioritized keyword opportunities

**O** = wording/intent directly observed in the sources or search sample. **H** = proposed long-tail hypothesis; validate later. All volumes and numerical difficulty are **unknown**.

| Priority | Keyword / cluster | Evidence | Intent / placement | Product-fit qualification |
|---|---|---|---|---|
| P1 | iPhone Duo opening sound | H: A1 + U1 | Launch landing page title/H1 | Only after physical opening is validated. |
| P1 | iPhone Duo closing sound | H: A1 + U1 | Landing page / opening-and-closing guide | Closing during scene handoff is release blocking. |
| P1 | custom fold sound | O: C1 + U1 | ASO concept and description | Explicitly foreground only. |
| P1 | sound when opening phone | O: C1 | Subtitle/description; web guide | Exclude app-opening and lock/unlock ambiguity. |
| P1 | sound when closing phone | O: C1 | Subtitle/description; web guide | Not call hang-up or system lock sound. |
| P1 | fold and unfold sound effects | O: C1 | Name + keyword combinations | Do not claim system-wide Android parity. |
| P1 | iPhone Duo sound effects app | H | Launch landing page | Device-specific, not a speaker troubleshooting page. |
| P1 | change iPhone Duo fold sound | H | Honest how-to article | Explain this is not changing an iOS system setting. |
| P2 | hinge sound app | H | Keyword field | Software effect, not repair of a noisy hinge. |
| P2 | custom open close audio | H | Subtitle | Closely describes independent selections. |
| P2 | import custom fold sound | H: C2 usability signal | Support/import guide | Short unprotected playable files only. |
| P2 | fold sound not playing | H | Support troubleshooting | Silent Mode, output route, app state, unsupported SDK. |
| P2 | opening chime | H | Keyword field / preset copy | One of the original effects. |
| P2 | closing click sound | H | Keyword field / preset copy | One of the original effects. |
| P2 | paper fold sound effect | O: search sample | Preset-specific supporting copy | Stock-audio intent may not convert. |
| P2 | personalize folding phone sounds | H | US metadata / guide | Foreground utility, not OS personalization. |
| P2 | personalise folding phone sounds | H | UK metadata / guide | UK spelling; no measured demand difference. |
| P3 | Scrunch alternative for iPhone | H: C1 | Factual web comparison only | Never ASO keyword stuffing; explain missing background parity. |
| P3 | custom soundboard | O: C2 | Secondary keyword only | Broad, crowded, and weak differentiation. |
| Exclude | ringtone / notification / alarm / charging sound | Negative intent | Do not target | Features not implemented. |
| Exclude | automatic background fold sounds / lock screen fold sound | Negative claim | FAQ explaining limitation only | No verified suspended-app fold listener. |
| Exclude | hinge crackling / phone speaker repair | Negative intent | Do not target | Hardware fault, not entertainment customization. |

## Store listing strategy

The launch candidate is in `release/listing.json`. Name/subtitle/keywords are validated by `scripts/release_check.py`. Keep one English product with en-US and en-GB metadata; no duplicate apps or speculative localization claims. US uses “personalize,” UK “personalise”; the lead name and subtitle stay the same. Neither spelling choice is based on measured volumes.

Apple's guidance: relevant metadata matters, the keyword field is limited to 100 characters, duplicating name/subtitle/category terms wastes space, competing app names should not be keywords, and promotional text is not a keyword-ranking field [A2]. The proposed keyword field is 71 ASCII bytes/characters, leaves spare space rather than stuffing unrelated terms, and omits “iPhone,” competing brands, and unsupported features. Do not claim a keyword combination guarantees indexing.

Suggested category: **Entertainment**, subject to owner confirmation. The hardware interaction is the differentiator; generic sound effects face an explicit review concern under 4.3(b), alongside completeness and accurate-metadata requirements [A3]. No “works everywhere,” “always listening,” “changes system sounds,” “first,” or “best” claims.

## Website content to ship, in order

1. One canonical product page answering “Can my iPhone Duo play a sound when it opens/closes?” Lead with compatibility and foreground limits, then original presets and imports. The checked-in site builder emits a **noindex prerelease page** until a validated release is explicitly requested; there is no fake download button, price, review score, or App Store ID.
2. A support page covering Silent Mode, headphones/Bluetooth routing, missing sounds, file limits, deletion, and the difference between preview controls and physical detection. Link from the app and listing.
3. A privacy page matching actual local storage, device backups, and voluntary external support disclosures—not an absolute “no data ever leaves the phone” promise.
4. After physical validation, an illustrated opening/closing guide made from real Duo captures. Later, a clearly attributed Scrunch comparison explaining platform limitations; do not make doorway pages for every synonym.

## Measure after the product is eligible

Reserve the name in App Store Connect, check relevant native US/UK App Store search results, and obtain Apple Ads popularity data if the owner uses that service. Record dated observations rather than filling missing metrics with estimates. After launch, compare App Store search impressions → product-page views → downloads and web search clicks → legitimate store referrals. Change one listing/screenshot hypothesis at a time; wait for enough traffic rather than inventing a significance threshold or promising a fixed uplift. No paid advertising, analytics SDK, account access, or live listing change was performed by this PR.

## Sources (accessed September 14, 2026)

- **A1** Apple Duo developer hub: https://developer.apple.com/iphone-duo/
- **A2** Apple App Store search guidance: https://developer.apple.com/app-store/search/
- **A3** App Review Guidelines, especially 2.1–2.3, 4.2, 4.3(b): https://developer.apple.com/app-store/review/guidelines/
- **A4** Product page guidance: https://developer.apple.com/app-store/product-page/
- **C1** Scrunch's F-Droid listing: https://f-droid.org/en/packages/com.denytheflowerpot.scrunch/
- **C2** Soundbox's public US App Store listing: https://apps.apple.com/us/app/soundbox-custom-soundboard/id1512618448
- **C3** Duo Mobile's public US App Store listing: https://apps.apple.com/us/app/duo-mobile/id422663827
- **U1** First-person foldable customization request: https://www.reddit.com/r/GalaxyFold/comments/17dh7gb/is_there_an_app_to_play_a_customised_sound_every/
