# SEV-1: Friday Deployment

**Works on My Machine.** A cinematic third-person corporate-nightmare action game.
The system is down. Management is watching. You're the only engineer online.

**Vertical Slice v0.1 / version 0.1.0** is a local macOS tester candidate. It is not
creator-accepted or notarized for trusted public distribution. No known P0 gameplay
failure was reproduced; first-use hitches and human gameplay/audio acceptance remain
open. See [release notes](docs/release_notes.md) and [release engineering](docs/release.md).

## Play

Unzip `SEV-1-Friday-Deployment-0.1.0-macOS.zip` and open **SEV-1 Friday Deployment.app**.
No Godot installation is needed. Local outputs are under `builds/releases/0.1.0/`.
The build is ad-hoc signed; recipient Macs may require explicit approval. Keep the
included license notices with the app. Apple Silicon/macOS is the initial test platform;
Intel, Windows and the declared macOS 14 minimum are not runtime-validated.

Choose **Start Incident**, **Controls**, or **Settings** on the title screen.
Settings persist master/effects volume, mouse sensitivity, camera shake, damage flash,
fullscreen and standard/reduced effects. No run modifiers/progress are saved.
Keyboard/mouse only. See the [tester guide and feedback questions](docs/testing.md).

| Input | Action |
| --- | --- |
| WASD / arrows | Move relative to camera |
| Mouse / wheel | Look / zoom |
| Shift / Space | Sprint / jump |
| Left mouse / F | Light attack; press late in recovery for the three-hit chain |
| Q / right mouse | Dodge in movement direction; backward when stationary |
| E | Inspect nearby OPERATIONS console |
| 1 / 2 / 3 | Select evidence or an upgrade/corporate response |
| Tab | Skip opening / boss arrival |
| R | Restart run; ignored inside settings/controls |
| Escape | Pause / resume / back; pending decisions are preserved |

Menus support pointer and keyboard focus. Losing app focus pauses ordinary gameplay.
Pause offers Resume, Controls, Settings, Restart, Main Menu and Quit. Reports provide
Restart, Main Menu and Quit. The window close action also exits cleanly.

## Playable scope

**Incident 001 — The Missing Transaction**, in one Office After Hours environment:

1. A skippable Friday, 4:59 PM opening leads to two sequential corrupted records.
2. Choose a temporary upgrade, inspect three system statements at OPERATIONS, and
   identify the missing payment record. Wrong answers provide immediate retry clues.
3. Make one corporate decision; contain three records (four on the dependency path).
   Technical Debt increases future pursuit; meaningful hits and decisions affect
   Burnout's outgoing/incoming damage tradeoff. Select a second upgrade.
4. Fight **The Variance**. Strike during OPEN, evade during SHIELDED. A solid diamond
   and VERIFIED ORIGINAL identify the real boss; hollow copies are harmless.
5. Receive a handcrafted victory/defeat postmortem and retry with a clean run.

The opening lasts 24 active seconds; Tab skips it. In-scene retries shorten it to
three seconds. The intended 5–10-minute human duration is still unmeasured. Combat
uses camera-directed melee cones, one dodge, and a three-hit combo. Native geometry,
procedural poses and synthesized audio are temporary presentation assets, not finished
rigged characters or AAA art. Furniture-top pursuit is unsupported. No later circles,
permanent progression, online account, telemetry, multiplayer or runtime AI exists.

## Development

Use **Godot 4.7.2 stable standard**, typed GDScript, Forward+, and Python 3. Work on
`main` following [AGENTS.md](AGENTS.md). `GODOT_BIN` overrides engine discovery.

```sh
sh tools/godot.sh --path .
python3 tools/validate.py
sh tools/release.sh
```

`play.command` is the source-project Finder launcher and requires the pinned engine.
The packaged `.app` does not. F5 opens the title screen; F6 can run the standalone
incident scene or `game/main.tscn` combat lab. Those regression scenes retain the
original click-to-capture pause UI.

Release builds require matching official export templates. The release script always
validates before export, checks bundle integrity/signing, performs a packaged headless
combat-to-victory/restart/defeat test, and produces a ZIP plus SHA-256 manifest. Outputs,
engine caches, logs, and local template downloads are ignored. See
[release instructions](docs/release.md) for prerequisites and signing limits.

## Validation

Resource import and every script parse pass, along with movement/combat/navigation,
incident progression, upgrades, debt, Burnout, corporate paths, narrative and release
lifecycle checks. The new release checks perform ten start/pause/decision/report/reset/
menu cycles with stable actor cleanup. Existing full simulations use real melee and
live AI, with staged positions and elevated health; they do not establish game balance.

Rendered 720p menus/settings/reports are inspected separately. The exported app has a
bounded opt-in smoke mode; the ordinary game never enables it. Human listening,
ordinary pacing, camera comfort, difficulty and replay appeal remain acceptance gates.

Current 1080p lifecycle sample on Apple M2 Pro / 16 GiB / macOS 27.0.1, Forward+/Metal,
MSAA 2×, SSAO/glow/fog: **133.54 average FPS**, **7.12 ms median**, **9.75 ms p95**,
**176.51 ms maximum**, 4,140 frames. Cold first use still hitches; this is not a
sustained-60-FPS guarantee. Full methodology and limitations are in the
[release notes](docs/release_notes.md), with historical context in
[stabilization evidence](docs/stabilization.md).

```sh
sh tools/godot.sh --path . --resolution 1280x720 --script tests/release_preview.gd
sh tools/godot.sh --path . --resolution 1920x1080 --script tests/stabilization_preview.gd
sh tools/godot.sh --path . --resolution 1920x1080 --script tests/incident_preview.gd -- --burnout --measure
```

## Documentation

| Document | Owns |
| --- | --- |
| [Vision](docs/vision.md) | Identity, audience and creative pillars |
| [Game design](docs/game_design.md) | Established direction, implemented experiments and deferred concepts |
| [Roadmap](docs/roadmap.md) | Evidence-based acceptance gates and next increment |
| [Implemented architecture](docs/architecture.md) | Runtime contracts, tuning and tools |
| [Release engineering](docs/release.md) | Baseline audit, packaging and verification |
| [Release notes](docs/release_notes.md) | Version, improvements and known limitations |
| [Tester guide](docs/testing.md) | Launch, incident walkthrough, bug reports and feedback |
| [Asset inventory](docs/asset_licenses.md) | Original-content provenance and engine notices |

No remote backup is configured. Establish Git LFS before substantial binary art intake.
The creator is the final creative decision-maker and playtester.

## Milestone 11 voice candidate

Incident 001 now includes prerecorded candidate speech and synchronized subtitles. Settings adds **Voice volume** and **Subtitles**. Play normally with `sh tools/godot.sh --path .`; Tab skips introductions and R retries. See the [casting, generation and listening guide](docs/voices.md). Human performance/mix acceptance remains pending. Build this audio candidate separately with `sh tools/release.sh --voice-candidate`.
