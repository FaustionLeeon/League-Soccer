# Audio audit and polish

## Changes

- Menu click and hover sounds now read the current master volume when played, fixing stale levels after a settings change. The Audio Settings slider applies changes immediately, clamps its initial value, and displays a percentage. The chosen volume is still saved when leaving the page.
- Replaced the fixed-size WAV reader with SDL's WAV decoder. It respects the sample-data boundary, skips metadata and padded chunks, and no longer truncates audio at 4 MiB. The loader validates nonempty mono/stereo 8-bit or 16-bit PCM before creating an OpenAL buffer.
- OpenAL context creation now checks both allocation and activation. Failure releases the device and allows the existing silent-audio fallback to run; shutdown safely handles an absent context.
- Both stereo crowd recordings now have a 40 ms overlap crossfade at the loop join. Each loop is 40 ms shorter; sample rate, channel layout, and peak level are preserved.
- Goalpost and long-whistle effects now peak at -1.5 dBFS, with 1 ms attack and 2 ms release fades to remove abrupt endpoints. This adds modest headroom without changing the character of the effects. Lowering peaks does not reconstruct any distortion already present in a recording.
- Added Audio Settings to the Windows runtime test runner.

## Verification

- Production WAV-loader regression tests passed for odd-sized metadata before the sample data, trailing metadata, and a sound larger than 4 MiB.
- All eight packaged WAVs decode completely and have peak headroom. Installed copies match source hashes.
- Release build passed without warning/error diagnostics. All 229 automated tests passed.
- All five runtime cases passed: Quick Match at standard and ultrawide sizes, Graphics Settings, Audio Settings, and a full scripted player-control match. OpenAL initialized and shut down cleanly, with no logged runtime warnings or errors. Logs: `build-win/visual-smoke-20260916-210345-925/`.

Asset hashes and before/after peak measurements are in `audio-asset-audit.json`. Build output: `build-win/audio-audit-build.log`. Test output: `build-win/audio-audit-tests.log`.

Automated runtime checks use OpenAL with master volume zero, so they exercise decoding, source creation, and match transitions without playing hidden audio. Diagnostic graphics capture stays disabled. Waveform measurements and tests validate technical behavior; speaker/headphone listening balance has not been subjectively verified in this audit. Audio-device failure cleanup was reviewed but not tested by disconnecting the user's device.
