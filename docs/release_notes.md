# SEV-1: Friday Deployment — Vertical Slice v0.1

Version **0.1.0**, 10 October 2026. Local macOS tester candidate; creator acceptance
and trusted public distribution are not complete. See the accompanying TESTING.md.

## Playable

Incident 001: The Missing Transaction combines Office After Hours, a skippable Friday
opening, two authored encounters, console investigation, two temporary upgrades,
Technical Debt, hit-driven Burnout, a corporate decision, The Variance, and contextual
victory/defeat postmortems. Repeated runs reset all gameplay modifiers.

## This release

- Title screen: SEV-1 / Works on My Machine; Start Incident, Controls, Settings, Quit,
  and credits. Existing mechanics and combat balance are preserved.
- Explicit pause/resume, restart and return-to-menu actions. Decisions survive pause
  and settings; postmortems provide visible retry/menu/quit actions.
- Saved master/effects volume, sensitivity, shake intensity, damage-flash toggle,
  fullscreen and standard/reduced effects. No music track exists, so none is advertised.
- macOS universal app, versioned ZIP, engine notices, release manifest and repeatable
  validation/export/signature/smoke workflow. Windows preset is preparation only.
- Ten application lifecycle checks supplement existing full incident/combat tests.

## Known issues and testing limits

- **P0:** none reproduced in automated incident/lifecycle coverage. This is not a
  claim that every possible player action has been tested.
- **P1 — performance gate open:** reproducible first-use frame hitches remain. A
  1080p M2 Pro lifecycle probe averaged 133.54 FPS but peaked at 176.51 ms; management
  first use reached 49.33 ms and boss arrival 29.36 ms. Steady speed does not prove
  consistently smooth play. Creator acceptance of the remaining hitch is pending.
- **P1 — distribution limitation:** ad-hoc signed, no Developer ID signature or
  notarization. Recipient Macs may block launch pending explicit approval. Public
  trusted distribution and another-Mac testing are outstanding.
- **P2:** native characters/furniture and procedural motion remain temporary; sound
  is synthesized and lacks human mix acceptance. Default Godot application icon.
  Camera-directed cone hit detection and furniture-top pursuit have known limits.
- **P2:** ordinary pacing, difficulty, tradeoff balance, humor and desire to replay
  require human testing. No claim of a measured 5–10-minute human run.
- **P3:** controller support, Intel/Windows runtime validation, more extensive
  accessibility/remapping, finished rigs/sound, and further chapters are deferred.

Performance evidence: Apple M2 Pro / 16 GiB, macOS 27.0.1, Godot 4.7.2,
Forward+/Metal, 1920×1080, MSAA 2×, SSAO, glow and fog. The three staged lifecycles
sampled 4,140 frames (about 31 seconds), including cold first render and UI pauses;
median/p95/p99 were 7.12/9.75/11.56 ms. Twelve frames exceeded 16.667 ms. Tracked
static/video memory peaked at 81.41/340.81 MiB (not OS resident memory). This is a
synthetic source-project probe, not a packaged long-duration or Windows benchmark.

Validation passed 487 assertions plus resource import and every script parse. The
macOS export, ad-hoc signature verification, packaged headless and graphical
combat-to-victory/restart/defeat probes passed. Ten application lifecycle cycles passed.

Automated checks use staged positions and sometimes elevated health/controlled
damage. Graphical rendering is inspected separately; human gameplay/audio acceptance
remains open. No new floor, boss, progression, online service or runtime AI was added.

## Milestone 11 voice candidate

Adds 22 prerecorded local Kokoro candidate clips, authored subtitles, separate Voice volume and saved subtitle preference. No runtime network or AI credentials. Voice candidate artifacts are isolated under `builds/releases/0.1.0-voices`; the previous tester package is preserved. Human casting, pronunciation, mixing and positional listening acceptance remain pending. See [voice evidence and listening route](voices.md).
