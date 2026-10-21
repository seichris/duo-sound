# Hingy sound library

Build 6 has **43 independently selectable sounds**: 17 original procedural presets and 26 bundled CC0 recordings. The original presets provide 34 distinct opening/closing renders; recordings play the same unmodified-direction clip in either selector. There are 60 unique clips and 86 direction options. Paper, Zipper and Rain have been removed. Saved selections for these sounds migrate to Click, the new closing default; other choices, volume and custom imports are preserved.

| Group | Added recordings | Source |
| --- | --- | --- |
| Farts | Tiny Fart, Micro Fart, Wet Pop, Low Rumble, Squeaker, Wet Splutter | Breviceps, MacKaffee, DSISStudios / Freesound |
| Everyday | Can Tab, Cork Pop, Zip Shut, Creaky Hinge, Lock Click, Page Flick | Freesound creators and laleksic / OpenGameArt |
| Nature | Water Plip, Cat Hello | bolkmar, steffcaffrey / Freesound |
| Playful | Rubber Ducky, Bubble Pop, Suction Plop, Jaw Boing | Freesound creators |
| Clicks & Impacts | Button Click, Soft Switch, Confirm, Soft Open, Soft Close, Glass Tap, Metal Tap, Wood Knock | Kenney Interface Sounds / Impact Sounds |

The first 18 are GPT Pro's recommended CC0 set; eight Kenney effects supplement it. The report's optional CC BY files, ambiguous sources and unselected Gastric Distress editing reserve are not bundled. Every added file has an individually verified CC0 declaration or comes from an explicitly CC0 creator pack. See the per-record source URLs, hashes, exact archive members and license evidence in `third_party/audio/sources.json`. Kenney's supplied license notices are preserved alongside it. CC0 does not require attribution; **About → Sound credits** nevertheless credits all creators offline.

## Playback and browsing

Choose Sound under Opening or Closing; search names, descriptions or category names. A play button previews without changing selection. All 43 choices are available on either side, including farts and Kenney effects. Both new recordings and procedural audio use the same existing audio worker, output routing, volume and lifecycle rules. Recorded files are bundled in the application and Swift package; no catalogue, account, download, microphone or network service is required during playback. A missing bundled file produces an error instead of substituting another sound.

## Processing and provenance

The selected **Freesound inputs are official public HQ MP3 previews**, not the login-gated original WAVs. The creator's asset-specific CC0 declaration applies to the selected sound; the ledger records the preview distinction. Kenney inputs are original Ogg members from the official pack downloads; the three OpenGameArt inputs are original WAV members. Exact acquired bytes are preserved under `third_party/audio/originals/` with SHA-256 hashes.

`python3 scripts/prepare_recorded_sounds.py` regenerates resources offline using the preserved sources and installed ffmpeg. Output is mono 44.1 kHz PCM16 WAV. Quiet leaders/tails are trimmed while complete actions and interior pauses are retained; GPT's speculative Cork/Zip/Jaw sub-cuts were not treated as verified edits. Gain targets RMS 0.10 with peak cap 0.80, and boundary fades avoid edit discontinuities. Tiny impacts use a 0.25 ms edge to preserve their transient; longer clips use 3 ms. There is no pitch shift, reversal or repeated lossy encoding.

The 26 output WAVs total **1,704,102 bytes (1.63 MiB)**, ranging from about 0.045 to 2.814 seconds. `Sources/DuoSoundCore/Resources/RecordedSounds/manifest.json` records exact output frames/durations, gain, cut points, fades, bytes and hashes. `python3 scripts/check_recorded_sounds.py` verifies files, original hashes, licensing fields and PCM limits without a decoder or network; Xcode preflight and release preparation run this check too. Files remain below 5 seconds / 8 MiB.

These are technical checks, **not a claimed listening review**. GPT did not audition its candidates, and this implementation does not label them auditioned. Listening on the intended device and judging perceived balance remain release QA.

## Offline audition

```sh
swift run -c release SoundPreview build/sound-library-expanded
```

The new directory contains a local HTML player, 86 direction WAV exports, a manifest and offline credits. The tool refuses to overwrite existing output; it has no autoplay or network requests. CI exports the `offline-sound-library-86-options` artifact. Recordings intentionally appear identically in both direction exports. These samples do not establish physical hinge behavior.

Core tests check all 43 entries, 34 distinct procedural renders, 26 recording resources and credits, 1,936 independent non-custom selection combinations, legacy settings, format/duration/amplitude bounds and determinism. Hosted tests decode and start every preset in both directions, plus verify recorded-preview progress without hinge data. A UI regression searches and auditions a fart without selecting it, saves a Kenney effect across relaunch, and opens offline credits. Physical audio and Duo display handoff remain separate, unverified release gates.

Completed build 5 checks and their scope are recorded in [RECORDED_AUDIO_VALIDATION.md](RECORDED_AUDIO_VALIDATION.md).
