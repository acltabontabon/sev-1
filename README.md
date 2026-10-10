# SEV-1: Friday Deployment

**Works on My Machine.** A cinematic third-person corporate-nightmare action game.
The system is down. Management is watching. You're the only engineer online.

**Playtest Build 0.2 / version 0.2.3** (Milestone 12, "Operation Corporate Hell") is a
local macOS tester build that answers the first external feedback on 0.1. It is not
creator-accepted or notarized. No known P0 gameplay failure was reproduced; first-use
hitches and human acceptance of fun, comedy, voice and music remain open. See the
[release notes](docs/release_notes.md) and [release engineering](docs/release.md).

## Play

Unzip `SEV-1-Friday-Deployment-0.2.3-macOS.zip` and open **SEV-1 Friday Deployment.app**.
No Godot installation is needed. Local outputs are under `builds/releases/0.2.3/`.
The build is ad-hoc signed; recipient Macs may require explicit approval. Keep the
included license notices with the app. Apple Silicon/macOS is the initial test platform;
Intel, Windows and the declared macOS 14 minimum are not runtime-validated.

The title screen is the office at 16:59. **Acknowledge Incident** starts a run;
**Corporate Policy** is settings, **Onboarding Docs** the controls, **Legal Has Reviewed
This** the credits and **Attempt to Log Off** quits (after one confirmation). Settings
persist master, effects, voice and music volume, subtitles, sensitivity, camera shake,
damage flash, fullscreen and effects quality, plus whether this device has seen the
opening (which unlocks skipping it). No run progress is saved. Keyboard and mouse only.
See the [tester guide and feedback questions](docs/testing.md).

| Input | Action |
| --- | --- |
| WASD / arrows | Move relative to camera |
| Mouse / wheel | Look / zoom |
| Shift / Space | Sprint / jump |
| Left mouse / F | Light attack; press late in recovery for the three-hit chain |
| Q / right mouse | Dodge in movement direction; backward when stationary |
| E | Use: the OPERATIONS console, the coffee machine and other pantry objects |
| 1 / 2 / 3 | Select evidence or an upgrade/corporate response |
| Tab | Skip the opening (after first viewing) / boss arrival |
| R | Restart run; ignored inside settings/controls |
| Escape | Pause / resume / back; pending decisions are preserved |

Menus support pointer and keyboard focus. Losing app focus pauses ordinary gameplay.
Pause offers Resume Suffering, Onboarding Docs, Corporate Policy, Restart Incident,
Back to Desk and Attempt to Log Off. The postmortem offers Restart Incident, Back to Desk
and Attempt to Log Off. The window close action also exits cleanly.

## Playable scope

**Incident 001 — The Missing Transaction**, in an expanded Office After Hours:

1. A 36-second Friday, 4:59 PM opening (skippable after the first viewing; retries take
   three seconds). Enemies arrive unaware and busy; they notice you by sight, by the
   noise of fighting, or when a colleague flags you. Hitting one unaware is a Surprise
   Review for double damage.
2. Two waves of Corrupted Records and Scope Creep, then a change request (upgrade).
3. Investigate at OPERATIONS: an evidence board shows three systems; press 1/2/3. The
   east wing is open: the pantry's coffee helps once, and Meeting Room 3 holds an
   optional Quick Sync ambush that pays out health and Burnout relief.
4. Answer Leadership's DM, then contain two waves with The Blocker and The Meeting
   Invite. Technical Debt speeds enemies; hits and decisions move Burnout.
5. The security gate lifts. Walk the failing server corridor to the vault, where
   **The Variance** arrives: strike while OPEN, evade while SHIELDED, trust the solid ◆.
6. A blameless postmortem, assigned to you, and a clean retry.

Human run length, difficulty and balance are unmeasured. Characters are original native
models with procedural poses; speech is local TTS candidate audio; music is original
synthesis. No later circles, permanent progression, online account, telemetry,
multiplayer or runtime AI exists.

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

Resource import, every script parse and the voice manifest pass, along with 15 headless
suites (641 assertions): movement/combat/navigation, incident progression, upgrades,
debt, Burnout, corporate paths, narrative, release lifecycle, voice, the expanded office,
the enemy roster and awareness, and the interface. The new release checks perform ten start/pause/decision/report/reset/
menu cycles with stable actor cleanup. Existing full simulations use real melee and
live AI, with staged positions and elevated health; they do not establish game balance.

Rendered 720p menus/settings/reports are inspected separately. The exported app has a
bounded opt-in smoke mode; the ordinary game never enables it. Human listening,
ordinary pacing, camera comfort, difficulty and replay appeal remain acceptance gates.

Current 1080p lifecycle sample on Apple M2 Pro / 16 GiB / macOS 27, Forward+/Metal,
MSAA 2×, SSAO/glow/fog: **128.2 average FPS**, **7.57 ms median**, **9.33 ms p95**,
**365.7 ms maximum** (cold first render), 5,940 frames. Cold first use still hitches; this is not a
sustained-60-FPS guarantee. Full methodology and limitations are in the
[release notes](docs/release_notes.md), with historical context in
[stabilization evidence](docs/stabilization.md).

```sh
sh tools/godot.sh --path . --resolution 1280x720 --script tests/release_preview.gd
sh tools/godot.sh --path . --resolution 1920x1080 --script tests/stabilization_preview.gd
sh tools/godot.sh --path . --resolution 1920x1080 --script tests/incident_preview.gd -- --burnout --measure
sh tools/godot.sh --path . --script tests/m12_preview.gd -- --1080 --only=menu
```

`tests/m12_preview.gd` also takes `--only=areas`, `--only=enemies`, `--only=ui`,
`--only=finale`, `--only=cast` (lineup plus close-ups), `--only=battle` (battle-mode
onset, the elemental combo and enemy spells) and `--only=attacks` (each enemy's strike
landing), and captures the opening shots without `--only`.
`tests/rig_preview.gd` writes `builds/rig_states.png`, a contact sheet of the rigged
engineer's idle, run, every combo phase, dodge, hurt and defeat.

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

New binary assets (fonts, textures, models, sound effects, music) are tracked with Git LFS.
The creator is the final creative decision-maker and playtester.

## Milestone 12 assets and tools

Fonts, interface/effect sounds, PBR textures and pantry props are CC0/OFL with provenance
in the [asset inventory](docs/asset_licenses.md). `tools/build_ui_theme.gd`,
`tools/build_office.py` (then `tools/bake_office_navigation.gd`),
`tools/build_characters.py` and `tools/build_music.py` regenerate the theme, office,
characters and music. Speech lines live in `assets/audio/voices/dialogue.json` and are
generated locally with `tools/voices.py`.
