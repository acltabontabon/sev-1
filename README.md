# SEV-1

*The system is down. Management is watching. You're the only engineer online.*

A single-player, third-person 3D action roguelite about an exhausted software engineer trapped in a corporate nightmare. Satisfying combat, systemic satire, and a visually serious workplace are the direction. The current playable is a small combat lab, not the narrative campaign.

## Project documentation

| Document | Owns |
| --- | --- |
| [Game vision](docs/vision.md) | Identity, audience, creative pillars, and decision status |
| [Game design](docs/game_design.md) | Combat philosophy, six circles, narrative, visual principles, candidate systems, and Incident 001 |
| [Roadmap](docs/roadmap.md) | Milestones, acceptance gates, open decisions, and next step |
| [Implemented architecture](docs/architecture.md) | Actual scenes, scripts, contracts, tuning, tools, and limitations |
| [Agent guidelines](AGENTS.md) | Development and validation rules |

The creative brief supplied on 10 October 2026 establishes long-term direction. It does not authorize implementing the six circles, abilities, progression, or narrative scenes now. Proposed experiments are labeled separately from implemented features.

## Play the combat lab

Double-click `play.command` in Finder, or run from the repository:

```sh
sh tools/godot.sh --path .
```

Alternatively, open `project.godot` in Godot 4.7.2 and press F5. F6 runs `game/main.tscn` when that scene is open. Click the game window to capture the mouse. The first click only resumes; subsequent clicks attack. Close the game window to quit.

| Input | Action |
| --- | --- |
| WASD or arrow keys | Move relative to camera direction |
| Mouse / wheel | Orbit / zoom |
| Shift / Space | Sprint / jump |
| Left click or F | One baton strike toward camera direction |
| R | Restore both fighters, health, and camera; also works while paused or dead |
| Escape / left click | Pause and release cursor / resume |

Changing app focus also pauses the encounter. Approach the red Production Incident in the open center. Watch its orange ground arc, raised arms, and warning sound; move aside, then strike during recovery. Four current baton hits defeat it. R offers a fast retry.

Try the ramp, raised deck, cabinets, and wall-adjacent camera angles for movement feedback. Enemy pursuit is direct and can stick behind obstacles. Character, enemy, animation, audio, and room are prototype assets; the current style is not final art approval. Keyboard/mouse is the only implemented control scheme.

## Current status

Implemented: camera-relative movement, sprint/jump, orbit/zoom and camera obstruction, one grounded melee strike, one enemy with telegraph/attack/recovery, health, hit feedback, defeat, pause, and encounter reset.

Human acceptance of combat feel is pending. Dodge, combos, waves, upgrades, progression, workstation/death fiction, post-incident reviews, bosses, and narrative scenes are not implemented. “Incident Response” remains a generic HUD label; the future narrative slice is **Incident 001: The Missing Transaction**.

Next: playtest attack timing, reach, impact, camera aim, and warning fairness; tune the current encounter before adding a defensive mechanic. The sequence is combat refinement → one polished office → a 5–10-minute narrative incident → a small progression experiment. See the [roadmap](docs/roadmap.md) for gates and deferred scope.

## Validation

```sh
python3 tools/validate.py
```

The existing Python 3 standard-library tool imports resources, parses scripts, and runs fixed-rate movement and combat checks. It has timeouts and checks logged errors as well as exit codes. Logs are ignored under `logs/`. Headless tests skip audio playback; graphical inspection, listening, and human playtests remain necessary.

The last implementation validation on 10 October 2026 passed 16 movement and 29 combat assertions plus import/script checks. A Forward+/Metal combat preview was visually inspected and exited without logged errors. These are prior implementation results; the subsequent documentation-only alignment did not rerun or modify the game. Windows runtime testing and sustained performance measurements remain outstanding.

To capture a staged graphical preview:

```sh
sh tools/godot.sh --path . --script tests/capture_preview.gd -- --combat
```

The output is `builds/combat_preview.png`. This tests presentation, not normal encounter pacing.

## Development setup

Use Godot 4.7.2 standard, GDScript, Forward+, Git, and macOS. Windows remains the future release target. `tools/godot.sh` checks the engine version and searches the Applications folders, Downloads, and PATH; `GODOT_BIN` can specify an absolute executable. No .NET SDK or additional package installation is required for this prototype.

At the initial 10 October 2026 inspection, the machine was an arm64 MacBook Pro with M2 Pro, 16 GB memory, macOS 27.0.1, approximately 98 GiB free, Git 2.56.0, and Godot 4.7.2 in Downloads. Forward+ initialized through Metal. Godot's normal Application Support/cache writes require appropriate execution permissions. These are historical observations, not a current resource or performance guarantee.

Matching export templates and an export preset are needed for future distributions. No templates were found at the initial inspection. Git LFS was absent; add it before committing substantial binary asset libraries. The small synthesized test sounds have their provenance in [assets/audio/README.md](assets/audio/README.md).

No Godot MCP is installed. CLI editing/validation is sufficient for this checkpoint; the creator has authorized an integration if it materially improves live observation. Reassess compatibility and dependencies when needed. Do not add runtime AI services for narrative text or incident reports.

Git ignore and attribute files preserve LF text, omit caches/builds/credentials, and retain UIDs/import sidecars. Preserve the existing identity and signing configuration. At this documentation checkpoint the repository still has no commits or remote, and project files are untracked on `codex/melee-playtest`; a Git baseline/remote remains operational follow-up rather than evidence of a backed-up project. This documentation pass does not switch branches or create a commit.
