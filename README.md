# SEV-1

*The system is down. Management is watching. You're the only engineer online.*

A single-player, third-person 3D action roguelite about an exhausted software engineer trapped in a corporate nightmare. Satisfying combat, systemic satire, and a visually serious workplace are the direction. The current playable is one Office After Hours arena with the Combat Alpha encounter, not the narrative campaign.

## Project documentation

| Document | Owns |
| --- | --- |
| [Game vision](docs/vision.md) | Identity, audience, creative pillars, and decision status |
| [Game design](docs/game_design.md) | Combat philosophy, six circles, narrative, visual principles, candidate systems, and Incident 001 |
| [Roadmap](docs/roadmap.md) | Milestones, acceptance gates, open decisions, and next step |
| [Implemented architecture](docs/architecture.md) | Actual scenes, scripts, contracts, tuning, tools, and limitations |
| [Agent guidelines](AGENTS.md) | Development and validation rules |

The creative brief supplied on 10 October 2026 establishes long-term direction. It does not authorize implementing the six circles, abilities, progression, or narrative scenes now. Proposed experiments are labeled separately from implemented features.

## Play the Office After Hours

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
| Left click or F | Light attack; press again late in recovery to chain up to three hits |
| Q or right click | Dodge in movement direction; backward relative to camera when stationary |
| R | Restore both fighters, health, and camera; also works while paused or dead |
| Escape / left click | Pause and release cursor / resume |

Changing app focus also pauses the encounter. Approach the red Production Incident in the open center. Watch its orange ground arc, raised arms, and warning sound; move aside, then strike during recovery. Two complete combos deal enough damage to defeat it, if every hit connects. Dodge cancels attack wind-up or recovery, but cannot interrupt the active strike. Attacks and dodges are grounded. R offers a fast retry.

Explore the workstation beside the start, the desk clusters on the left, the glass conference room up the right-hand ramp, and the production wall ahead. The enemy follows baked routes around furniture and up the ramp. Test wall-adjacent camera angles and dodges beside the conference deck. Characters, animation, audio, and simplified furniture remain provisional; this pass is not final art approval. Keyboard/mouse is the only implemented control scheme.

## Current status

Implemented: camera-relative movement, sprint/jump, orbit/zoom and camera obstruction, a buffered three-hit grounded combo, directional dodge with brief invulnerability, one enemy with telegraph/attack/recovery, health, hit feedback, defeat, pause, and encounter reset.

Human acceptance of combat feel is pending. Waves, upgrades, progression, workstation/death fiction, post-incident reviews, bosses, and narrative scenes are not implemented. The office is an environment pass, not a narrative episode; the future narrative slice is **Incident 001: The Missing Transaction**.

Next: playtest the office lighting, combat readability, collision, and camera alongside attack and dodge feel. Refine this space from feedback before a narrative incident or progression experiment. See the [roadmap](docs/roadmap.md) for gates and deferred scope.

## Validation

```sh
python3 tools/validate.py
```

The existing Python 3 standard-library tool imports resources, parses scripts, and runs movement, combat, and Combat Alpha checks. It has timeouts and checks logged errors as well as exit codes. Logs are ignored under `logs/`. Headless tests skip audio playback; graphical inspection, listening, and human playtests remain necessary.

The Combat Alpha validation on 10 October 2026 passed 85 assertions (16 movement, 29 combat, 40 alpha), plus import/script checks. Alpha checks cover the buffered chain, cancellation, dodge timing/distance at 30/60/120 physics Hz, real input bindings, enemy evasion, hit-stop, death, and reset stability. Windows runtime testing and human feel/audio acceptance remain outstanding.

To capture a staged graphical preview:

```sh
sh tools/godot.sh --path . --script tests/capture_preview.gd -- --combat
```

The output is `builds/combat_preview.png`. This tests presentation, not normal encounter pacing.

Before the office pass, the Combat Alpha graphics run on the M2 Pro used Forward+/Metal at 1920×1080 with existing scene effects and MSAA 2×. A 25-second automated close-range fight (five-second warm-up excluded, elevated actor health) measured 120.0 average FPS, 8.31 ms median, 10.46 ms p95, and 11.95 ms maximum over 2,401 frames. Screenshot saving occurs after measurement. This short local run is not a long-duration or Windows performance guarantee.

To repeat it, run `sh tools/godot.sh --path . --resolution 1920x1080 --script tests/alpha_preview.gd` without `--fixed-fps`. It writes ignored `builds/alpha_performance.json`, `alpha_preview.png`, and `alpha_dodge.png`. Append `-- --capture-only` to skip measurement. Rendered attack/dodge images were inspected; human audio and combat-feel review remains pending.

Useful tuning starts in the three `game/player/*.tres` attack profiles (damage, timing, reach, hit-stop) and Player exports (0.24 s combo buffer, 3 m dodge, 0.18 s invulnerability, 0.32 s dodge recovery, camera impulse strength). Try changing one variable at a time.

## Office visual review

The environment adds a task-lit workstation, coworker desks, a glazed conference room,
server racks and incident dashboards, a window wall, and subtle static surreal details.
The original combat timing and damage values are unchanged. Native navigation handles
furniture; no new combat abilities or dependencies were added.

On 10 October 2026, the final office validation passed **94 assertions**: the existing
85 plus nine environment checks, including real pursuit around desks and through the
conference entrance. Import and script parsing also passed. Rendered starting, arena,
workstation, conference, operations, attack, and dodge views were inspected.

At 1920×1080 on the M2 Pro, Forward+/Metal with MSAA 2×, SSAO, glow, and fog measured
**119.36 average FPS**, **8.27 ms median**, **10.65 ms p95**, and **67.43 ms maximum**
over 2,388 frames. This was a 25-second automated combat run with elevated health,
excluding five seconds of warm-up and all screenshot saving. The final frame reported
298 draw calls. The isolated long frame is not explained by this measurement; it is
not a promise of hitch-free performance or a sustained/platform benchmark.

```sh
sh tools/godot.sh --path . --resolution 1920x1080 --script tests/office_preview.gd -- --measure
```

Omit `-- --measure` for just the five environment screenshots. Outputs are ignored under
`builds/office_*.png` and `builds/office_performance.json`. The regular game still launches
at 1280×720. Full controls above are unchanged.

For a short review: inspect the desk and 16:59 display, fight in the center, approach the
operations alerts, then explore the conference ramp and glass. Use R to retry. Check
whether the room feels too dark, whether the enemy warning remains obvious while moving,
and whether desks or camera obstruction frustrate the fight.

The native furniture is deliberately simplified; the next asset-quality gains would
come from a coherent licensed chair/workstation set, subtle PBR surface textures, and
representative rigged characters. Small clutter/chairs are visual-only, and furniture-top
pursuit is unsupported. Human visual/audio acceptance and Windows testing remain pending.
Asset origins and replacement priorities are in [environment provenance](assets/environment/README.md).
Reproducible scene authoring and navigation baking are documented in [architecture](docs/architecture.md#office-after-hours-environment).

## Development setup

Use Godot 4.7.2 standard, GDScript, Forward+, Git, and macOS. Windows remains the future release target. `tools/godot.sh` checks the engine version and searches the Applications folders, Downloads, and PATH; `GODOT_BIN` can specify an absolute executable. No .NET SDK or additional package installation is required for this prototype.

At the initial 10 October 2026 inspection, the machine was an arm64 MacBook Pro with M2 Pro, 16 GB memory, macOS 27.0.1, approximately 98 GiB free, Git 2.56.0, and Godot 4.7.2 in Downloads. Forward+ initialized through Metal. Godot's normal Application Support/cache writes require appropriate execution permissions. These are historical observations, not a current resource or performance guarantee.

Matching export templates and an export preset are needed for future distributions. No templates were found at the initial inspection. Git LFS was absent; add it before committing substantial binary asset libraries. The small synthesized test sounds have their provenance in [assets/audio/README.md](assets/audio/README.md).

No Godot MCP is installed. CLI editing/validation is sufficient for this checkpoint; the creator has authorized an integration if it materially improves live observation. Reassess compatibility and dependencies when needed. Do not add runtime AI services for narrative text or incident reports.

Git ignore and attribute files preserve LF text, omit caches/builds/credentials, and retain UIDs/import sidecars. Preserve the existing identity and signing configuration. Combat Alpha is committed on `main` at `74d1cb5`. Office development uses `codex/office-after-hours`. No remote is configured; local commits are not an off-machine backup.
