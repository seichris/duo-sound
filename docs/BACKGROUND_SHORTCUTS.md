# Native hinge and background Shortcuts

## Setting up an iPhone Duo

Apple added the **When my iPhone is opened or closed** Shortcuts trigger in iOS 27.2. On the Hingy home screen, **Set up sounds in other apps** opens the setup guide. Each Add button opens an Apple-hosted shortcut with the matching **Get Opening Sound** or **Get Closing Sound** action connected to **Play Sound**. Users can also save both signed files to Files and open them there. The files contain action definitions. Shortcuts receives the selected audio, including a custom import, only when the shortcut runs. [Apple’s Shortcuts release notes](https://support.apple.com/en-us/149045)

The setup screen reads the bundled `FoldShortcuts/Install.json`. For a pair that includes triggers, it asks the user to enable each imported automation. For a playback-only pair, it gives the steps to attach **Opened** and **Closed** in Shortcuts. Adding a shortcut and enabling its automation are separate user actions.

## Background system-dispatch test

On November 7, 2026, Xcode 27.2 (27B52) passed `testSoundActionsReturnAudioWhileAnotherAppIsFrontmost` on the iOS 27.2 Duo simulator (24B91016s). The test selects Chime for opening and Click for closing, backgrounds Hingy, and activates Settings. Apple's AppIntentsTesting service dispatches both real app actions. Each returns a WAV file while Settings stays in the foreground and Hingy stays in the background. The returned opening and closing files decode with durations of 0.42 and 0.13 seconds. The saved selections remain intact.

Keep Xcode's default simulator signing enabled and use a runtime matching the installed Xcode testing framework.

```sh
xcodebuild test -project DuoSound.xcodeproj -scheme DuoSound-DuoSDK \
  -configuration Debug-Duo -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -only-testing:DuoSoundUITests/ReleaseSmokeTests/testSoundActionsReturnAudioWhileAnotherAppIsFrontmost \
  -parallel-testing-enabled NO 'OTHER_SWIFT_FLAGS=$(inherited) -D TEST_SHORTCUT_DISPATCH'
```

The test validates system dispatch and audio-file handoff. Audible playback through Apple's Play Sound action and physical fold-trigger delivery require separate checks. [Result summary](../release/evidence/1.1.2-build10-2026-11-07/background-dispatch-summary.json)

To regenerate the complete pair, run `python3 scripts/generate_fold_shortcuts.py` on a Mac running macOS 27 or later and signed in to iCloud. The script uses Apple’s Anyone signer and checks the trigger, direction, sound action and playback input in each signed output before replacing the packaged pair. `--verify` checks the committed pair offline. `--playback-only` explicitly creates the version that requires manual trigger setup. The published iCloud links identify the corresponding signed files. [Apple’s signing guide](https://support.apple.com/guide/shortcuts-mac/run-shortcuts-from-the-command-line-apd455c82f02/mac)

## October 21, 2026 investigation

Every configuration now includes the typed public iOS 27.1 hinge adapter. Runtime availability checks preserve previews on older devices. Native observation remains active-scene-only; it does not register a suspended-app wake subscription.

### Research findings

Apple documents [UIHingeInteraction](https://developer.apple.com/documentation/uikit/uihingeinteraction) and view-associated angle/status updates. The installed SDK confirms iOS 27.1 availability, nullable hinge, initial/current-state callbacks and discarded updates while disabled.

The [original September 26 report](https://www.reddit.com/r/shortcuts/comments/1wr2idx/iphone_duo_will_support_opened_or_closed/) explicitly used Shortcuts ported from iOS 27.2 in a Duo simulator. It demonstrated wallpaper changes, not locked audio. Its exact source build and minimum stock OS requirement are unspecified. Apple's current [automation guide](https://support.apple.com/guide/shortcuts/add-automations-apdfbdbd7123/ios) does not corroborate the device trigger; documentation omission does not prove binary absence. App Is Opened/Is Closed concerns applications, not device folding.

The local iOS 27.1 Duo simulator did not expose com.apple.shortcuts through the app-container lookup. Local 27.0/27.1 runtimes cannot establish 27.2 behavior. No physical Duo is available here. Stock trigger availability and physical locked sound remain unverified.

The owner requested [ChatGPT Pro research in Brave](https://chatgpt.com/c/6ad88d5c-7df0-83ee-a8a5-abae35684ccf) and supplied its completed answer as an attachment. It recommends enabling native support and evaluating file-returning intents before app-owned background playback. This is advisory analysis, not device proof; its release-version statements are not independently asserted here.

### Implemented route

Create two shortcuts: **Get Opening Sound → Play Sound** and **Get Closing Sound → Play Sound**. Explicitly use the getter's returned audio as Play Sound's input. Run each while unlocked to resolve access prompts. Avoid interactive pickers and Ask Each Time in an unattended workflow.

Connect these to a device Opened or Closed automation only if the installed Shortcuts app offers that trigger. Otherwise test with an available trigger. Use the installed OS's automatic-execution controls. Apple's current iOS 27 guide describes **Edit → Info → Privacy → Allow Running When Locked**; options for the unverified fold trigger must be checked on-device.

The getters use public [App Intents background execution](https://developer.apple.com/documentation/appintents/configuring-the-runtime-behavior-of-your-app-intents) and [IntentFile](https://developer.apple.com/documentation/appintents/intentfile). Each invocation loads current atomic settings without a scene or AppModel, then returns in-memory audio bytes. Shortcuts owns subsequent playback. Hingy does not create an audio session, retain a player, add a background audio mode, or weaken file protection for this handoff.

The current selected sound, including a custom import, is copied to Shortcuts. Workflows may play, save or share it. Generic filenames avoid exposing imported names. A missing/protected file fails; Off returns a clear error rather than empty input that could cause a default notification sound. Original bytes are exported: system/shortcut volume and routing apply, while the effect-volume slider applies inside Hingy.

Disable **Enable fold sounds** in Hingy when using a device-fold automation to avoid both native and Shortcuts paths sounding while the app is visible. Explicit previews and file-returning actions still work.

### Required acceptance

Record the actual Duo model, OS/build, Shortcuts version, trigger screenshot and execution settings. Test the handoff independently, then test the whole fold automation. Cover warm/cold/force-quit execution, locked after first unlock versus reboot-before-first-unlock, bundled/synthesized/imported files, Silent Mode, zero/nonzero volume, audio routes, rapid folds, missed/overlapping effects, foreground duplication and display handoff. Measure audible onset separately from a successful playback request.

Compilation, intent metadata and simulator callbacks are not physical audio evidence. Do not advertise unattended fold sounds until the stock trigger, permissions, file access and audible output pass on the intended device.

Direct [AudioPlaybackIntent](https://developer.apple.com/documentation/appintents/audioplaybackintent) actions are deferred. Their conformance does not itself replace documented [background audio configuration](https://developer.apple.com/documentation/avfoundation/configuring-your-app-for-media-playback). App-owned playback would need an awaited, cancellation-safe service independent of scene inactivity, with explicit audio-session ownership. The file handoff avoids that additional lifecycle.

### Local validation for build 7

- Core tests: **46 passed**, including current-selection file handoff, safe filenames, missing audio and Off behavior.
- Release preparation tests: **25 passed**.
- Default DuoSound scheme on a fresh iOS 27.1 Duo simulator: **15 passed, zero failures and zero skips**. These are 14 hosted playback tests and the public-hinge initial-callback UI test; the callback reports a real simulated angle and no initial sound.
- Signed Debug device build: succeeded; code signature verified. **Hingy 1.0 (7)** was installed and its installed metadata verified on Ultra (iPhone 16 Pro Max, iOS 27.0.1).
- Physical launch verification was blocked when the phone locked again. Actual Shortcuts invocation, audible output through Play Sound, locked execution and a physical Duo fold automation remain unverified.

The simulator result bundle and captured initial-state image are retained outside the checkout in the task worktree's NativeHinge.xcresult and NativeAttachments directories. No GitHub CI, App Store upload or physical-Duo success is implied by these local results.
