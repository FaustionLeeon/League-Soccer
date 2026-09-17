# Meme match artwork

Generated with the built-in image-generation tool. Exact prompts are in `manifest.json`; the five `*-source.png` files preserve the generated originals.

## Runtime assets

- `data/media/textures/adboards/memes/ad_skill.png`: SKILL ISSUE / sunglasses cat.
- `data/media/textures/adboards/memes/ad_grass.png`: TOUCH GRASS / cheerful frog.
- `data/media/textures/adboards/memes/ad_lag.png`: LAG IS MY COACH / headset potato.
- `data/media/textures/adboards/memes/ad_var.png`: VAR.exe NOT FOUND / referee error robot.
- `data/media/objects/balls/ball.jpg`: BONK / comic-face ball.

Ad tiles were cropped only through their background margins to 4:1, reduced to 256 x 64, and repeated four times into the engine's existing 1024 x 64 board layout. This preserves artwork proportions and puts a readable slogan on each section of a long board. The ball was resampled to the existing 1024 x 1024 JPEG layout with high-quality encoding. No physics or ball dimensions changed.

The match loads only the `memes` directory. The previous ad files remain as inactive source assets. Ads use a shuffled rotation so all four appear before repetition; the former random upper bound excluded the final texture. Four active board textures also reduce the active ad texture count from sixteen to four.

## Validation

Release build passed. All 219 automated tests passed. Quick Match passed at 1280 x 720 and 1920 x 810, Graphics Settings passed, and a full scripted player-control match finished successfully (Arsenal 0 - 1 Manchester United). Captured gameplay confirmed the meme boards are visible in the stadium. All four ad files were logged as loaded; the installed ball JPEG matches the source asset hash. No runtime warnings or errors were reported. Logs and diagnostic frames: `build-win/visual-smoke-20260916-203938/`.

Frame capture is diagnostic only. Normal play leaves `GF_CAPTURE_DIRECTORY` unset to avoid capture-related stutter. Automated tests are muted.
