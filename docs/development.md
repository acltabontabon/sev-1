# SEV-1 development guide

The [README](../README.md) is the player-facing introduction, launch guide, and
controls reference. This page collects source-project commands and preview tools.
Follow [AGENTS.md](../AGENTS.md) when changing the game.

## Run from source

Use **Godot 4.7.2 stable standard**, typed GDScript, Forward+, and Python 3.
`GODOT_BIN` overrides engine discovery. Run commands from the repository root.

```sh
sh tools/godot.sh --path .
python3 tools/validate.py
sh tools/release.sh
```

`play.command` is the source-project Finder launcher and requires the pinned engine.
Packaged releases do not require an editor. F5 opens the title screen; F6 can run
standalone scenes, including `game/main.tscn`, the combat lab. Regression scenes
retain the original click-to-capture pause UI.

For export prerequisites, package formats, signing, and CI, use
[release engineering](release.md). Player installation instructions live in
[install.md](install.md); version history lives in [CHANGELOG.md](../CHANGELOG.md).

## Focused playtest checkpoints

These commands preview the current source checkout. Consult the changelog for what
is included in a packaged release. R restarts the episode; rerun a checkpoint command
to return directly to its scene. Tab skips supported cinematics.

| Checkpoint | Command | Feedback to collect |
| --- | --- | --- |
| Boss transformation | `sh tools/godot.sh --path . --script tests/rage_preview.gd` | Pacing, shout, hair silhouette, emotional payoff |
| Operations handoff | `sh tools/godot.sh --path . --script tests/operations_preview.gd -- --play` | Answer with E; judge containment purpose and deadline consequence |
| Quick Sync | `sh tools/godot.sh --path . --script tests/quick_sync_preview.gd -- --play` | Walk into Meeting Room 3; judge retreat space, transformations, floor hazards, comedy |
| Ending | `sh tools/godot.sh --path . --script tests/ending_preview.gd` | Duel, departure, Monday, and return to menu |
| Finale | `sh tools/godot.sh --path . --script tests/finale_preview.gd` | Grief, sword placement, pickup, memories, animation, and music mix |
| Closing shots | `sh tools/godot.sh --path . --script tests/finale_preview.gd -- --closing` | Final reply and return to work |

In an ordinary run, use E with Morgan, Nadia, Jun, Jo, or Val and choose
“Tell me something normal”; win the boss fight to hear the conversation recalled.
The [tester guide](testing.md) owns the incident walkthrough and player feedback.

## Validation and rendered inspection

Run `python3 tools/validate.py` after gameplay changes. Headless checks cover
resource imports, script parsing, and gameplay outcomes. They do not establish
visual quality, audio, ordinary performance, balance, or fun.

```sh
sh tools/godot.sh --path . --resolution 1280x720 --script tests/release_preview.gd
sh tools/godot.sh --path . --resolution 1920x1080 --script tests/stabilization_preview.gd
sh tools/godot.sh --path . --resolution 1920x1080 --script tests/incident_preview.gd -- --burnout --measure
sh tools/godot.sh --path . --script tests/m12_preview.gd -- --1080 --only=menu
```

`tests/m12_preview.gd` also takes `--only=areas`, `--only=enemies`, `--only=ui`,
`--only=finale`, `--only=cast`, `--only=battle`, and `--only=attacks`.
Without `--only`, it also captures opening shots. `tests/rig_preview.gd` writes
`builds/rig_states.png`, a contact sheet of engineer animation states.

Historical check counts, measured frame times, hardware/settings, and acceptance
limits are recorded in [release notes](release_notes.md) and
[stabilization evidence](stabilization.md). First-use hitches remain a playtest concern.
Gameplay defaults to 60 FPS; Corporate Policy offers 120 FPS. Menus and paused/report
screens run at up to 30 FPS; an unfocused game runs at up to 15 FPS and automatically
pauses ordinary gameplay. See the
[frame-budget investigation](stabilization.md#fanload-investigation-and-frame-budgets--11-october-2026).

## Assets and regeneration

Record provenance in the [asset inventory](asset_licenses.md). New binary assets
are tracked with Git LFS. Preserve import and UID sidecars.

- `tools/build_ui_theme.gd` regenerates the interface theme.
- `tools/build_office.py`, then `tools/bake_office_navigation.gd`, regenerate the office.
- `tools/build_characters.py` and `tools/build_music.py` regenerate native characters
  and music.
- `assets/audio/voices/dialogue.json` owns speech lines; `tools/voices.py` generates
  local prerecorded speech.

## Documentation map

| Document | Owns |
| --- | --- |
| [Vision](vision.md) | Identity, audience, and creative pillars |
| [Game design](game_design.md) | Established direction, implemented experiments, and deferred concepts |
| [Roadmap](roadmap.md) | Acceptance gates and the next increment |
| [Architecture](architecture.md) | Runtime contracts, tuning, and tools |
| [Release engineering](release.md) | Packaging and verification |
| [Release notes](release_notes.md) | Historical evidence and known limitations |
| [Changelog](../CHANGELOG.md) | Release version and changes |
| [Tester guide](testing.md) | Walkthrough, bug reports, and feedback |
| [Asset inventory](asset_licenses.md) | Sources, licenses, and attribution |

The human creator is the final creative decision-maker and playtester.
