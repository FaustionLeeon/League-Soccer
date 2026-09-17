# Game changes audit

Scope: all pending source, shader, artwork, documentation, and test changes.

## Findings and fixes

- Pitch sampling now clamps unique markings and noise, while wrapping tiled grass. Four regression tests cover interpolation, borders, negative wrapping coordinates, and one-pixel textures.
- Generated pitch maps clamp at chunk edges to prevent opposite-edge color bleed. Overlay alpha uses 255 for full opacity.
- ASE texture coordinates use `1 - V`, preserving tiled materials and allowing unique clamped maps to render correctly. Diagnostic gameplay captures confirmed pitch markings, players, goals, shadows, scoreboard, and radar.
- The corner vignette now darkens by at most 12%, compared with about 49% previously. Grain uses subtle zero-mean dither.
- Stadium boards use four generated meme designs in a shuffled rotation; the prior selection excluded the final texture. The generated ball keeps its existing dimensions and physics. Originals, exact prompts, and a gameplay preview are in `artwork/meme-kit/`.
- Animation quadrants no longer include an eleventh angle with an uninitialized value.
- The headless match-clock helper preserves stoppage time across periods, starts elapsed time at zero, rejects premature knockout transitions, and distinguishes pending shootouts from completed matches. Eight added regression tests cover these issues, repeated kickoff, final-state preservation, clock overflow, goals outside live play, and reductions in stoppage time. Goals cannot change a finished score, and reducing stoppage time cannot rewind elapsed play. This helper is used by tests; it does not control the live match clock. Shootout completion remains caller-controlled after the required kicks.
- Important log messages still flush immediately. Global unbuffered console output was removed to avoid unnecessary overhead.
- The Windows runner detects the logger's actual fatal-error label, rejects a competing game session, gives result folders millisecond timestamps, and retains the process handle so Windows PowerShell can reliably read the exit code.

## Verification

- Release build passed; all 227 automated tests passed. The final two regressions were reproduced as failing tests before the fix. Latest build and automated-test logs: `build-win/error-audit-build.log` and `build-win/error-audit-tests.log`.
- Final capture-free runtime suite passed all four cases: Quick Match at both aspect ratios, Graphics Settings, and the scripted player-control match. The match continued through both extra-time periods, reached its completion marker, and exited cleanly. No runtime warnings or errors were reported. Logs: `build-win/visual-smoke-20260916-205049-143/`; suite output: `build-win/change-audit-tests.log`.
- All 166 packaged PNGs passed signature, chunk checksum, and compressed-stream checks.
- All five installed meme textures match their source hashes. Board textures retain the expected 1024 x 64 layout.
- Earlier visual tests confirmed the new ads in the stadium and correct pitch rendering. Evidence: `artwork/meme-kit/in-match-preview.png` and `build-win/visual-smoke-20260916-203938/`.
- A subsequent complete scripted playtest ended Arsenal 0 - 1 Manchester United, with confirmed player input, halftime progression, final results, and clean exit. No warnings or errors were logged (`build-win/playtest-20260916-205453/`). The latest fixes affect only the headless test helper, so this playtest remains applicable to the live game.
- The user confirmed visible, smooth gameplay after diagnostic capture was disabled.

## Repeatable Windows testing

Run `powershell -ExecutionPolicy Bypass -File tests/run_visual_smoke.ps1` to build, run CTest, and exercise Quick Match at 1280 x 720 and 1920 x 810, Graphics Settings, and a full scripted player-control match. Tests are muted and check clean exit, explicit success markers, and logged warnings/errors. Close the game first to avoid competing sessions.

Add `-SkipBuild` to test an existing build, or `-CaptureFrames` to save visual evidence. The smoke configs retain debug startup mode so they can skip the intro.

`GF_CAPTURE_DIRECTORY` enables synchronous framebuffer readback and PNG writing every two seconds, up to 60 files. It causes diagnostic stutter and must stay unset for normal play or performance assessment. The runner disables capture unless explicitly requested and restores the prior environment afterward. Launch normal play with `run.bat`.

Desktop inspection was unavailable because the Windows automation runtime could not start. Visual evidence came from opt-in engine captures. Automated smoke tests verify startup, scripted input, and match completion; they do not replace subjective gameplay testing or measure frame pacing.
