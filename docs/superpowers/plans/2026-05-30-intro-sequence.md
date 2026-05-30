# Intro Sequence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a full opening sequence that plays the supplied video, transitions directly to the supplied title image, and starts gameplay only after a click or tap.

**Architecture:** Keep the existing `Main` gameplay scene as the entry point and add a full-screen `Intro` canvas layer above it. `Main` owns gameplay activation, while `Intro` owns video/title/prompt state and emits `start_requested`.

**Tech Stack:** Godot 4 GDScript, `VideoStreamPlayer`, `TextureRect`, `CanvasLayer`, Python `unittest` static checks.

---

### Task 1: Lock Intro Behavior With Static Tests

**Files:**
- Modify: `tests/test_minimal_playable_static.py`

- [x] **Step 1: Add a failing static test for intro structure**

Add assertions for copied assets, `Intro` scene nodes, `intro_screen.gd`, and `main.gd` startup gating.

- [x] **Step 2: Run the targeted test and verify it fails**

Run: `python -m unittest tests.test_minimal_playable_static.MinimalPlayableStaticTest.test_intro_assets_and_flow_are_wired_before_gameplay`

Expected: FAIL because `scripts/intro_screen.gd` and the intro nodes do not exist yet.

### Task 2: Copy Source Media

**Files:**
- Create: `assets/intro/homeward_intro.mp4`
- Create: `assets/intro/homeward_intro.ogv`
- Create: `assets/intro/homeward_title.png`

- [x] **Step 1: Create the intro asset directory**

Run: `New-Item -ItemType Directory -Force -Path assets\intro`

- [x] **Step 2: Copy the source files without re-encoding**

Copy the MP4 and PNG from the user-provided QQ media paths into `assets/intro`.

- [x] **Step 3: Create the Godot-playable stream**

Use FFmpeg to create `assets/intro/homeward_intro.ogv` from the copied MP4 with Theora/Vorbis high-quality settings. Keep the copied MP4 as the untouched source file.

### Task 3: Add Intro Screen Script

**Files:**
- Create: `scripts/intro_screen.gd`

- [x] **Step 1: Implement `HomewardIntroScreen`**

Create a `CanvasLayer` script that binds `VideoStreamPlayer`, `TextureRect`, and `Label`, plays the video in `begin()`, switches to title in `_on_video_finished()`, and emits `start_requested` on click/tap while the title is visible.

- [x] **Step 2: Keep fallback behavior explicit**

If no video stream is assigned, call `show_title()` rather than trying to transform the MP4 at runtime.

### Task 4: Wire Intro Into Main Scene

**Files:**
- Modify: `scenes/main.tscn`
- Modify: `scripts/main.gd`

- [x] **Step 1: Add intro scene resources and nodes**

Add a `CanvasLayer` named `Intro` with `VideoStreamPlayer`, `TextureRect`, and `Label` children. The title image uses `res://assets/intro/homeward_title.png`; the video player uses `res://assets/intro/homeward_intro.ogv`, and the intro layer keeps metadata pointing at the original MP4 path so the source asset is tracked.

- [x] **Step 2: Gate gameplay startup in `main.gd`**

Add `_intro_active`, connect `intro.start_requested`, call `_set_gameplay_active(false)` on ready, and call `_reset_run()` only after the intro finishes.

### Task 5: Verify

**Files:**
- Test: `tests/test_minimal_playable_static.py`

- [x] **Step 1: Run the targeted intro test**

Run: `python -m unittest tests.test_minimal_playable_static.MinimalPlayableStaticTest.test_intro_assets_and_flow_are_wired_before_gameplay`

Expected: PASS.

- [x] **Step 2: Run the full static test suite**

Run: `python -m unittest tests.test_minimal_playable_static`

Expected: PASS.

- [x] **Step 3: Inspect git diff**

Run: `git diff -- scenes/main.tscn scripts/main.gd scripts/intro_screen.gd tests/test_minimal_playable_static.py`

Expected: Diff only covers the intro sequence and related tests.
