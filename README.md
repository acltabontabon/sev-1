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

The creative brief supplied on 10 October 2026 establishes long-term direction. The subsequent Milestone 4 request authorizes this first incident and Milestone 5 authorizes character/combat presentation; Milestone 6 adds temporary run upgrades and Technical Debt. The six circles, extra abilities, and permanent progression remain deferred. Proposed experiments are labeled separately from implemented features.

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
| 1 / 2 / 3 | Choose an upgrade while its screen is open; otherwise select a system after inspecting evidence |
| R | Restart the entire incident, including health, camera, enemies, evidence, and lighting; works while paused or dead |
| Escape / left click | Pause and release cursor / resume |

Changing app focus also pauses. After clicking to begin, the short alert leaves movement available immediately. The first record materializes after about nine active seconds. Face the enemy with the camera, read its orange warning arc, dodge aside, and strike during recovery. Press LMB/F again late in recovery to chain up to three hits. Q/right mouse cancels wind-up or recovery, but cannot interrupt an active strike. Attacks and dodges are grounded.

Incident flow:

1. **The Discrepancy:** defeat two corrupted records arriving individually in the clear office lane. Choose one of three upgrades; combat pauses until selection.
2. **Investigation:** follow the cyan OPERATIONS marker to the far wall. Press E within four meters. Read three short statements, then choose 1, 2, or 3. Incorrect choices give a clue and allow immediate retry. Payment Processing (3) is missing the delivered record.
3. **Containment:** defeat three more records, one at a time. Their combat variation is faster pursuit, including any debt bonus; attack timing remains familiar. Choose a second upgrade before The Variance.
4. **The Variance:** evade during SHIELDED, then strike during the 3.5-second OPEN window. The genuine boss always carries a solid cyan diamond and VERIFIED ORIGINAL. At half health, two harmless hollow-marker projections appear. Follow the original, not the copies.
5. **Review:** victory restores the dashboards and subsides incident lighting; death provides a different handcrafted report. R returns to Friday, 4:59 PM. Click to resume after a report.

Explore the existing workstation, desk clusters, conference ramp/glass, and production wall. Keyboard/mouse is the only implemented control scheme. The original movement, combo, dodge, damage, navigation, and office geometry are preserved. No external art, runtime AI, persistence, or new floor was added. Two temporary upgrade choices now make the episode a run.

## Current status

Incident 001 is implemented as a technical playtest candidate. Its 5–10-minute duration is a **human pacing target, not a measured or accepted result**; experienced players may finish faster. Combat feel, difficulty across a full run, audio, and artistic quality still need the creator's review. Milestone 5 adds an office-worker design, keyboard Escalation Blade, articulated procedural poses, fragmented-record enemies, and additional sound cues. Models, animation, and translucent boss copies remain provisional native geometry.

First playtest: can you explain why the payment record is missing, read the boss's diamond and opening without guessing, and complete the episode without repeated frustrating deaths? Record total run time and the point where pacing drags or becomes unfair. See the [roadmap](docs/roadmap.md) for acceptance gates.

## Validation

```sh
python3 tools/validate.py
```

The existing Python 3 standard-library tool imports resources, parses scripts, and runs movement, combat, Combat Alpha, office, and incident lifecycle checks. It has timeouts and checks logged errors as well as exit codes. Logs are ignored under `logs/`. Headless tests skip audio playback; graphical inspection, listening, and human playtests remain necessary.

The pre-Milestone 6 baseline passed **155 assertions**: 16 movement, 29 combat, 40 alpha, 9 office, 44 incident, and 17 presentation, plus import and every script parse. Current progression results are recorded below. The incident checks cover real E/number/F/R input, boss damage windows and copies, reports, repeated resets, and scene reload.

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

Git ignore and attribute files preserve LF text, omit caches/builds/credentials, and retain UIDs/import sidecars. Preserve the existing identity and signing configuration. Combat Alpha is checkpointed at `74d1cb5`, Office After Hours at `65d2f3b`; Milestone 5 work uses `codex/character-presentation`. No remote is configured; local commits are not an off-machine backup.


## Milestone 5 presentation playtest

The engineer now wears a rolled-sleeve shirt, loosened tie, glasses, ID badge, and
practical shoes, carrying the keyboard **Escalation Blade**. Distance-driven limb
motion, visible anticipation/sweep/recovery, hand-to-grip posing, a crouched dodge,
and settled defeat poses replace the earlier rigid proxy motion. The cyan foot ring
marks actual dodge invulnerability. Corrupted records have separated ledger slabs,
status rows, shoulder-driven attacks, recoil, and extinguished defeat indicators.
Existing hit-stop/camera impulses remain; the bounded spark burst is directional.
Footsteps, dodge, defeat, and incident alert join the existing combat sounds.

This is an implemented **native fallback presentation pass**, ready for human review.
It is not a finished rigged human model or imported animation set. There is no terrain
foot IK, finger rig, or animated death fall. Fast turns/slopes can still slide. Attack
cone damage is still an approximation rather than weapon-mesh collision. No combat
profile, damage, reach, dodge timing, controller, or incident progression was redesigned.

All new art and audio are original procedural authoring; no third-party assets were
imported. See [character provenance, source evaluation, and rig integration](assets/characters/README.md)
and [sound provenance](assets/audio/README.md). A selected rigged office worker and a
coherent locomotion/melee set are the next visual priorities after director feedback.

On 10 October 2026, import, all script checks, and **155 assertions passed**. The
additional 17 checks cover anticipation before damage, interrupted attacks, pose
recovery, hit-stop, dodge stance/ring, death, and reset. Staged identity, attack, run,
dodge, defeat, and boss/copies views were inspected in Forward+. Playback ran without
engine errors; listening, ordinary full-run pacing, and creative acceptance remain
human checkpoints. Windows and long-duration performance testing remain outstanding.

The M2 Pro boss/copies run at **1920×1080**, Forward+/Metal, MSAA 2×, SSAO, glow, and
fog measured **139.41 average FPS**, **7.10 ms median**, **9.54 ms p95**, and **17.41 ms
maximum**, over 2,790 frames. Final sampled draw calls: 417. The 25-second elevated-health
scenario excludes five seconds of warm-up and screenshot saving. This is a short local
measurement, not a controlled before/after speedup claim or a full-episode guarantee.
The previous 119.95 FPS result above is historical; neither run isolates presentation
cost from display scheduling/system conditions. No rigged-mesh cost was measured.

```sh
sh tools/godot.sh --path . --resolution 1920x1080 --script tests/character_preview.gd
sh tools/godot.sh --path . --resolution 1920x1080 --script tests/incident_preview.gd -- --measure
```

Outputs are ignored under `builds/character_*.png`, `builds/incident_*.png`, and
`builds/incident_performance.json`. The close-view script uses a staged camera and
poses; ordinary gameplay still uses the existing free camera and 1280×720 default.

For a five-minute presentation check, launch `play.command`, click to begin, walk and
sprint past the workstation, then chain all three attacks and dodge sideways/backward.
Watch the keyboard grip and whether contact feels synchronized with the hit sound and
freeze. Compare enemy warning with recovery, follow the boss's solid diamond, and retry
with R after death and victory. Controls remain WASD/arrows, Shift sprint, Space jump,
LMB/F combo, Q/RMB dodge, mouse/wheel camera, E inspect, 1–3 choice, Escape pause, R retry.
Report whether the engineer reads as an exhausted employee, whether the keyboard feels
weighty, where feet or hands distract, and which sounds are too quiet, harsh, or repetitive.


## Milestone 6 Technical Debt playtest

Two upgrade screens appear after clearing each record encounter. Press **1 / 2 / 3**,
click a card, or use arrows and Enter. Each card previews the resulting debt band and
enemy pursuit increase. Combat and run time pause during selection; choosing resumes
play. R restarts even from this screen. Upgrades last until restart, with no saves.

| Upgrade | Benefit per selection | Debt |
| --- | --- | --- |
| Ship It Friday | +35% base outgoing damage | +30 |
| Add More Tests | −20% base incoming damage | 0 |
| Temporary Workaround | −25% base dodge recovery | +15 |

Repeated bonuses add against the base: two damage choices give +70%, two defensive
choices give −40%, and two mobility choices give −50% recovery. Integer damage rounds
to nearest (first upgraded slash: 34 instead of 25). Dodge travel and invulnerability
remain unchanged. There is no healing.

Debt is bounded to 0–100: Stable 0–24, Fragile 25–49, Unstable 50–74, Critical 75–100.
Upcoming enemies pursue 0/5/10/15% faster respectively, including the boss while
shielded. Warning, attack, recovery, and boss OPEN timings stay unchanged. Dashboards,
warning-strip color, and smoothly raised incident spill show escalating debt without
flashes. The HUD reports debt and pursuit; reports record choices. R resets all of it.
With two default choices, the maximum is 60: Critical is a tested tuning band, not
reachable in the normal episode. A single Workaround stays Stable; two reach Fragile.

Human checkpoint: try one defensive run and one shortcut run. Does the damage benefit
feel worth faster pursuit? Does faster dodge recovery change your options? Can you
explain the debt consequence before choosing? Are office warnings readable without
hiding attacks? Record deaths and total duration. Balance, fun, audio, Windows, and
full-run performance acceptance remain outstanding.

Capture the two choice screens, applied warning, boss, and reports:

```sh
sh tools/godot.sh --path . --resolution 1280x720 --script tests/incident_preview.gd -- --debt
```

Add `--measure` and use `--resolution 1920x1080` for the 25-second elevated-health
boss/copies measurement. Outputs are ignored under `builds/debt_*.png` and
`builds/debt_performance.json`. Omit `--debt` for the zero-debt reference scenario.
Staged captures and automated combat do not constitute a normal human playthrough.

On 10 October 2026, final Milestone 6 validation passed **208 assertions**: 16 movement,
29 combat, 40 alpha, 9 office, 48 incident, 17 presentation, and 49 progression, plus
import and all script parsing. An initial sandbox-only import failed on macOS settings/
certificate access; the authorized run passed. A pointer-test coordinate failure was
corrected to use viewport-local coordinates after layout; the full rerun passed.

Rendered choice screens, debt-applied dashboards, boss/copies, and both reports were
inspected. These are scripted scenes, not a completed human playthrough. Native desktop
control was unavailable because Computer Use permissions were not enabled.

On Apple M2 Pro, 1920×1080, Forward+/Metal, MSAA 2×, SSAO, glow, and fog:

| Current-build boss scenario | Average FPS | Median / p95 / max frame (ms) | Samples | Final draw calls |
| --- | --- | --- | --- | --- |
| Zero debt | 123.18 | 8.10 / 10.39 / 29.83 | 2,464 | 423 |
| 60 debt, two Ship It Friday choices | 120.01 | 8.33 / 10.39 / 12.23 | 2,401 | 421 |

Each scenario ran 25 seconds with elevated health and two projections; five seconds of
warm-up and screenshot saving were excluded. The similar p95 suggests no material
steady-state cost from debt in this short sample. These sequential runs do not isolate
all system variance, establish a pre-change benchmark, or rule out transition hitches.
Normal full-run pacing, sound, long-duration performance, and Windows remain unverified.
