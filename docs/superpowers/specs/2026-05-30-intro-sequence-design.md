# Intro Sequence Design

## Goal

The game starts with the full opening video, then immediately shows the supplied title image with the text "点击屏幕开始你的归途". Gameplay only begins after the player clicks or taps the title screen.

## Architecture

Add a full-screen `Intro` canvas layer to the existing `scenes/main.tscn`. The current gameplay nodes remain in place, but `scripts/main.gd` keeps them hidden and stopped until the intro emits `start_requested`.

## Assets

The source media files are copied byte-for-byte into `assets/intro`:

- `assets/intro/homeward_intro.mp4`
- `assets/intro/homeward_title.png`

No compression or resizing is applied to either original asset. Godot's built-in video player may require an `.ogv` version for runtime playback; if a playable converted stream is available later, the intro script can prefer it while keeping the original MP4 in the project.

## Behavior

On launch, `Intro.begin()` tries to play the opening video at full viewport coverage. When playback finishes, the title image is shown immediately in the same canvas layer. The click prompt is centered over the title image. A mouse click, screen touch, or keyboard accept input while the title is visible hides the intro and starts the run.

If the runtime cannot load the video stream, the intro falls back to the title image instead of degrading or transcoding the original video at runtime.

## Testing

Static tests verify that:

- The copied intro assets exist.
- `main.tscn` contains the intro node, video player, title image, and prompt.
- `intro_screen.gd` exposes the expected start signal and video-finished flow.
- `main.gd` starts with gameplay inactive and enables it only when the intro emits `start_requested`.
