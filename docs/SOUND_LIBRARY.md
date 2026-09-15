# Original sound library

Duo Sound now has **20 built-in presets and 40 direction-specific clips**. Opening and closing can use different presets, either side can be Off, and existing custom imports are still available. The original five preset IDs, defaults and audio algorithms are unchanged.

| Category | Presets | New in this expansion |
|---|---|---|
| Musical | Chime, Crystal, Marimba, Music Box | Glassy bells, wooden notes, a delicate ascending/descending melody |
| Mechanical | Paper, Click, Zipper, Latch, Typewriter | A zip/unzip texture, release/catch impacts, mechanical key bursts |
| Nature | Water Drop, Bird, Rain | Paired resonant drops, contrasting chirps, a short noise-and-droplet shower |
| Playful | Arcade, Bubble, Spring, Cork | Bubble pops, an elastic boing, hollow pop/snug thump |
| Sci-Fi | Orbit, Laser, Robot, Power Up / Down | Swept zap, three-syllable robotic tones, ascending startup/descending shutdown |

These are deliberately stylized effects, not field recordings or imitations of branded soundtracks. Every clip is synthesized locally from original code. Nothing downloads audio, records a microphone, or includes third-party sound assets. The app's existing distribution-license decision is unchanged.

## In the app

Tap the Sound row under When opening or When closing. Browse the five categories or search names, descriptions and category names. Tap a name to save it; the checkmark identifies the selection. A row's Play button auditions that preset for the current direction **without changing the saved selection**. Done returns to the fold controls. Off and an existing custom import remain available under Your choice when search is empty.

All built-in effects are 0.13–0.72 seconds, with distinct opening/closing synthesis. PCM is 44.1 kHz, 16-bit mono. Deterministic noise seeds make repeated renders reproducible within a toolchain. The original peak cap and playback volume controls remain; no physical listening-volume safety guarantee is implied. Current sounds remain well below the cap in the tested renders.

## Audition without Xcode

From the repository root:

```sh
swift run -c release SoundPreview build/sound-library
```

Use a new output directory on subsequent runs; the tool refuses to overwrite an existing one. Open `build/sound-library/index.html` to audition all 40 WAV files locally. `manifest.json` records preset IDs, categories, directions and actual sample durations. Start at low device volume: standalone WAVs are unscaled; the app defaults to 65% effect volume. No browser autoplay, JavaScript, network request or tracking is added.

CI also exports the `original-sound-library-40-clips` artifact. These are audio samples, **not physical-Duo validation or App Store screenshots**.

## Regression coverage

`swift test` includes checks for all 20 catalog entries, unique labels, stable legacy IDs/defaults, 441 opening/closing selection combinations, custom-import retention, persisted new selections, 40 distinct clips, deterministic audio in both directions, WAV metadata/durations, non-silent output, amplitude limits and zero-valued endpoints. The existing fold detector and storage tests still run.

The simulator UI smoke test browses/searches the library, previews without selecting, assigns Crystal to opening and Laser to closing, and verifies both choices after relaunch. It does not establish that audio is audible through a physical speaker or that hardware folding works. Listening on intended devices, headphones and accessibility settings remains part of release QA.

The hinge adapter, foreground-only policy, audio session behavior and blocked submission evidence are unchanged. This PR is stacked on the App Store preparation branch so draft listing/site copy reflects the same catalog.
