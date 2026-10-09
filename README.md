# SEV-1

*The system is down. Management is watching. You're the only engineer online.*

A single-player, third-person 3D action roguelite about an exhausted software engineer trapped in a corporate nightmare. Satisfying combat, systemic satire, and a visually serious workplace are the direction. The default playable is **Incident 001 — The Missing Transaction**, a bounded narrative episode in the existing Office After Hours arena.

## Project documentation

| Document | Owns |
| --- | --- |
| [Game vision](docs/vision.md) | Identity, audience, creative pillars, and decision status |
| [Game design](docs/game_design.md) | Combat philosophy, six circles, narrative, visual principles, candidate systems, and Incident 001 |
| [Roadmap](docs/roadmap.md) | Milestones, acceptance gates, open decisions, and next step |
| [Implemented architecture](docs/architecture.md) | Actual scenes, scripts, contracts, tuning, tools, and limitations |
| [Agent guidelines](AGENTS.md) | Development and validation rules |

The creative brief supplied on 10 October 2026 establishes long-term direction. The subsequent Milestone 4 request authorizes this first incident; the six circles, extra abilities, and progression remain deferred. Proposed experiments are labeled separately from implemented features.

## Play Incident 001

Double-click `play.command` in Finder, or run from the repository:

```sh
sh tools/godot.sh --path .
```

Alternatively, open `project.godot` in Godot 4.7.2 and press F5. F6 runs the selected scene: `game/incidents/missing_transaction.tscn` is the episode; `game/main.tscn` retains the original single-opponent arena for regression work. Click the game window to capture the mouse. The first click only resumes; subsequent clicks attack. Close the game window to quit.

| Input | Action |
| --- | --- |
| WASD or arrow keys | Move relative to camera direction |
| Mouse / wheel | Orbit / zoom |
| Shift / Space | Sprint / jump |
| Left click or F | Light attack; press again late in recovery to chain up to three hits |
| Q or right click | Dodge in movement direction; backward relative to camera when stationary |
| E | Inspect the operations console when nearby |
| 1 / 2 / 3 | Select a system after inspecting evidence |
| R | Restart the entire incident, including health, camera, enemies, evidence, and lighting; works while paused or dead |
| Escape / left click | Pause and release cursor / resume |

Changing app focus also pauses. After clicking to begin, the short alert leaves movement available immediately. The first record materializes after about nine active seconds. Face the enemy with the camera, read its orange warning arc, dodge aside, and strike during recovery. Press LMB/F again late in recovery to chain up to three hits. Q/right mouse cancels wind-up or recovery, but cannot interrupt an active strike. Attacks and dodges are grounded.

Incident flow:

1. **The Discrepancy:** defeat two corrupted records arriving individually in the clear office lane.
2. **Investigation:** follow the cyan OPERATIONS marker to the far wall. Press E within four meters. Read three short statements, then choose 1, 2, or 3. Incorrect choices give a clue and allow immediate retry. Payment Processing (3) is missing the delivered record.
3. **Containment:** defeat three more records, one at a time. Their only combat variation is faster pursuit; attack timing remains familiar.
4. **The Variance:** evade during SHIELDED, then strike during the 3.5-second OPEN window. The genuine boss always carries a solid cyan diamond and VERIFIED ORIGINAL. At half health, two harmless hollow-marker projections appear. Follow the original, not the copies.
5. **Review:** victory restores the dashboards and subsides incident lighting; death provides a different handcrafted report. R returns to Friday, 4:59 PM. Click to resume after a report.

Explore the existing workstation, desk clusters, conference ramp/glass, and production wall. Keyboard/mouse is the only implemented control scheme. The original movement, combo, dodge, damage, navigation, and office geometry are preserved. No external art, runtime AI, persistence, upgrades, or new floor were added.

## Current status

Incident 001 is implemented as a technical playtest candidate. Its 5–10-minute duration is a **human pacing target, not a measured or accepted result**; experienced players may finish faster. Combat feel, difficulty across a full run, audio, and artistic quality still need the creator's review. Characters, procedural limb motion, corrupted-record markers, and translucent boss copies remain provisional native geometry.

First playtest: can you explain why the payment record is missing, read the boss's diamond and opening without guessing, and complete the episode without repeated frustrating deaths? Record total run time and the point where pacing drags or becomes unfair. See the [roadmap](docs/roadmap.md) for acceptance gates.

## Validation

```sh
python3 tools/validate.py
```

The existing Python 3 standard-library tool imports resources, parses scripts, and runs movement, combat, Combat Alpha, office, and incident lifecycle checks. It has timeouts and checks logged errors as well as exit codes. Logs are ignored under `logs/`. Headless tests skip audio playback; graphical inspection, listening, and human playtests remain necessary.

The current Incident 001 validation passed **138 assertions**: 16 movement, 29 combat, 40 alpha, 9 office, and 44 incident, plus import and every script parse. The incident checks cover real E/number/F/R input, boss damage windows and copies, reports, repeated resets, and scene reload.

The earlier Combat Alpha validation on 10 October 2026 passed 85 assertions (16 movement, 29 combat, 40 alpha), plus import/script checks. Alpha checks cover the buffered chain, cancellation, dodge timing/distance at 30/60/120 physics Hz, real input bindings, enemy evasion, hit-stop, death, and reset stability. Windows runtime testing and human feel/audio acceptance remain outstanding.

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

## Incident visual and performance review

Staged introduction, investigation, boss/copies, victory, and failure views were inspected at 1280×720 and 1920×1080. These captures verify layout, not ordinary play pacing. The original arena's historical measurements above remain separate.

```sh
sh tools/godot.sh --path . --resolution 1920x1080 --script tests/incident_preview.gd -- --measure
```

Omit `-- --measure` for screenshots only. Outputs are ignored under `builds/incident_*.png` and `builds/incident_performance.json`. On the M2 Pro with Forward+/Metal, MSAA 2×, SSAO, glow, and fog, the 25-second boss/copies scenario measured **119.95 average FPS**, **8.29 ms median**, **11.19 ms p95**, and **19.70 ms maximum**, over 2,400 frames after five seconds of warm-up. Actor health was elevated; screenshot saving was excluded. This short local measurement does not establish full-episode performance, spawn-transition hitch behavior, Windows performance, or a long-duration soak result.

## Development setup

Use Godot 4.7.2 standard, GDScript, Forward+, Git, and macOS. Windows remains the future release target. `tools/godot.sh` checks the engine version and searches the Applications folders, Downloads, and PATH; `GODOT_BIN` can specify an absolute executable. No .NET SDK or additional package installation is required for this prototype.

At the initial 10 October 2026 inspection, the machine was an arm64 MacBook Pro with M2 Pro, 16 GB memory, macOS 27.0.1, approximately 98 GiB free, Git 2.56.0, and Godot 4.7.2 in Downloads. Forward+ initialized through Metal. Godot's normal Application Support/cache writes require appropriate execution permissions. These are historical observations, not a current resource or performance guarantee.

Matching export templates and an export preset are needed for future distributions. No templates were found at the initial inspection. Git LFS was absent; add it before committing substantial binary asset libraries. The small synthesized test sounds have their provenance in [assets/audio/README.md](assets/audio/README.md).

No Godot MCP is installed. CLI editing/validation is sufficient for this checkpoint; the creator has authorized an integration if it materially improves live observation. Reassess compatibility and dependencies when needed. Do not add runtime AI services for narrative text or incident reports.

Git ignore and attribute files preserve LF text, omit caches/builds/credentials, and retain UIDs/import sidecars. Preserve the existing identity and signing configuration. Combat Alpha is checkpointed at `74d1cb5`, Office After Hours at `65d2f3b`, and Incident 001 work uses `codex/incident-001`. No remote is configured; local commits are not an off-machine backup.
