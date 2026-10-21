# Preserved CC0 sound inputs

These 26 source files reproduce the app's added recordings. `sources.json` records creators, asset pages, observed public download URLs, license URLs, page hashes, original-source byte counts/hashes and exact ZIP member/archive hashes. All selected sounds are CC0 1.0. Kenney's original pack license notices are preserved.

Freesound inputs are official public HQ MP3 previews, not the login-gated original uploads. OpenGameArt inputs are original WAV members, and Kenney inputs are original Ogg members from the official pack ZIPs. No account or private download token was used. The archives themselves are not bundled: selected member bytes are preserved here.

The app ships only the processed WAVs, catalog and offline credits in `Sources/DuoSoundCore/Resources/RecordedSounds/`. The source files here are development inputs, excluded from application resources. Rebuild with `python3 scripts/prepare_recorded_sounds.py`, then run `python3 scripts/check_recorded_sounds.py`. Regeneration never fetches the network. The output manifest records ffmpeg version and actual edits; a different decoder can change bytes and must be reviewed as a new asset revision.

Creator-page license declarations were rechecked on October 19, 2026. This is recorded provenance, not a claim that technical checks establish all rights or that the audio has been auditioned. No optional CC BY recordings or excluded ambiguous recordings from the GPT report are included.
