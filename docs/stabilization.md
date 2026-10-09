# Milestone 8 — stabilization verification

Implementation checkpoint, 10 October 2026. This is ready for creator playtesting;
subjective polish, strategic balance and the 5–10-minute target are not accepted yet.
[README](../README.md) owns launch/controls, [architecture](architecture.md) owns runtime
contracts, and [roadmap](roadmap.md) owns the remaining gates.

## Baseline and scope

Inspection began on clean `main`. Godot 4.7.2 standard, Forward+/Metal, the office,
movement/camera, three-hit combo, dodge, two record encounters, investigation, upgrades,
Technical Debt, Burnout, management choices, The Variance, deterministic victory/death
reports and R restart were present and integrated. Baseline import, all script checks
and **286 assertions** passed after granting normal Godot user-directory access.
The first restricted attempt failed on macOS certificates/editor-settings access;
this was an execution-environment failure, not a gameplay regression.

| Status | Finding |
| --- | --- |
| Implemented and passing technical checks | Full incident lifecycle, combat outcomes, one-shot decisions, additive modifiers, thresholds, reports, repeated reset/reload, navigation around desks and onto the conference deck |
| Implemented but incomplete | Native character/furniture geometry, procedural poses, approximate melee cones, synthesized audio, harmless boss copies; human quality, ordinary pacing and balance remain unverified |
| Reproduced defect | Boss shielding could resume during impact freeze because its phase clock advanced while actor motion stopped |
| UX inconsistencies | Choice copy did not show combined modifiers or clamped relief; encounter arrival/count feedback was absent; pause/reports competed with gameplay HUD; no player-facing shake/flash controls |
| Proposed/deferred | Additional circles, abilities, Reputation, permanent progression, finished rigs, cinematic return sequence, persistence, distributable Windows build/runtime validation |

No missing narrative beat or normal-default softlock was reproduced. The existing
single-opponent lab and movement/combat baseline remain available. No outside assets,
new encounter, resource system, engine upgrade, dependency or framework was introduced.

## Implemented fixes and refinements

- **Boss timing:** hit-stop now freezes the shield/open phase clock. A targeted test on
  the original code rejected damage near the end of OPEN; the fixed code accepts it
  while frozen, then correctly rejects damage after the window expires.
- **Reset cleanup:** spawned enemy collision is disabled immediately before deferred
  deletion. Regression checks inspect the old actor in that exact reset frame.
- **Decision clarity:** cards preview total damage, damage taken and dodge recovery
  against base values. They show the future pursuit/debt band or immediate clamped
  Burnout/band. Zero-pressure dependency escalation explicitly previews zero relief.
  Native arrow/Enter and pointer navigation remain; keyboard focus has a teal border.
- **Progress/HUD:** remaining records and scheduled arrivals make inter-enemy pauses
  explicit. Combined active modifiers appear beside separate debt/Burnout information.
  Pause, decision and report screens hide underlying gameplay text; the pause card
  retains the latest Burnout source. Dark teal surfaces and restrained accents continue
  the existing visual direction.
- **Comfort:** pause-screen switches disable camera shake and the full-screen damage
  flash independently. They survive R in the scene session. Health, hurt audio, threat
  arcs/text, dodge ring and hit-stop remain available; fresh launches use defaults.
- **Regression:** bounded complete simulations now use real F attacks, normal boss
  windows and live enemy AI through all three management paths and two upgrade moments.
  Elevated player health and staged positions make these reliability checks, not
  evidence of a fair or enjoyable fight.

No movement, combo buffer, reach, dodge travel/invulnerability, enemy attack timing,
upgrade value, debt threshold or corporate tradeoff was retuned. Mathematical bounds
and repeated technical completion do not justify broad difficulty changes.

## Validation and graphical evidence

Final `python3 tools/validate.py`: resource import, every script parse and **320
assertions passed** (16 movement, 29 combat, 40 alpha, 9 office, 49 incident,
17 presentation, 49 progression, 77 Burnout, 34 stabilization). The deliberate original-
code boss regression failed once as expected; its fixed-code test and full suite pass.

The suite includes the original movement/combat/alpha/office/presentation checks,
incident lifecycle and progression/Burnout checks, plus stabilization coverage for
OPEN timing, pointer comfort switches, feedback outcomes, arrow navigation, previews,
viewport layout, progress text, modal/report occlusion and immediate collider cleanup.
Three bounded real-melee runs each reached victory, created/cleaned copies, recorded
the correct commitment result, then returned to neutral modifiers and stable node
counts with R. Existing tests separately cover defeat, expiry, duplicate events,
restart from either decision modal, repeated mid-fight resets and fresh scene loads.

Actual Forward+ scenes were rendered and screenshots inspected at 1280×720 and
1920×1080: start/comfort controls, both upgrade screens, investigation, management,
containment, original/copies, victory and defeat. Graphical runs exercise audio playback
without proving its mix or impact. The measured boss preview stalled on a subsequent
paused report capture, after writing performance results; its process was closed.
`incident_preview.gd` now forces a render for screenshots instead of awaiting a draw
signal indefinitely. This does not affect gameplay or the recorded benchmark. Live
Computer Use inspection was attempted but permissions were unavailable; engine-rendered
images provide the equivalent visual inspection. There was no human graphical playthrough or listening
acceptance. The screenshots are staged, not measurements of ordinary gameplay pacing.

## Performance evidence

Measured on Mac14,9 / Apple M2 Pro, 16 GiB, macOS 27.0.1, Godot 4.7.2,
Forward+/Metal, 1920×1080, MSAA 2×, SSAO, glow and fog. Validation was not running
during measurement. Two independent graphical launches each sampled 4,140 frames
across three staged lifecycles (about 34.8 and 29.8 seconds, respectively).

| Lifecycle measurement | Average FPS | Median / p95 / p99 / max (ms) | Frames >16.667 ms |
| --- | --- | --- | --- |
| First launch | 118.99 | 8.32 / 10.68 / 11.31 / 167.92 | 7 |
| Repeat launch | 138.97 | 6.96 / 9.27 / 12.18 / 165.67 | 9 |

Startup/first rendering reproduced at about 166–168 ms. The first management screen
reproduced at 43.20 / 35.66 ms, and the first boss arrival at 21.85 / 32.32 ms. Those
phases did not exceed 16.667 ms on the later two cycles within either launch. Other
isolated slow frames occurred at record defeat/spawn or boss combat. This supports
first-use work as an investigation lead, not proof of a shader, font, audio or AI cause.
Hitches remain unresolved; no claim of smooth 60 FPS throughout the slice is made.

Synchronous scene creation took 136.80 / 133.74 ms; record/boss spawn calls ranged
0.60–2.69 ms, copy creation 0.37–1.16 ms, and R reset calls 1.17–2.24 ms. The first-use
frame hitches therefore cannot be attributed to spawn-call CPU time alone. Scene reuse
and later transitions were stable in these short probes; no pooling or speculative
renderer rewrite was introduced. Deeper editor/GPU profiling of first-use work remains
a production hardening follow-up.

Native process peaks were 34.78 / 35.06 ms, physics peaks 169.19 / 166.13 ms, tracked
static memory peaks 79.97 / 79.56 MiB, video memory peaks 327.92 / 336.02 MiB, and peak
draw calls 547 / 493. Startup catch-up is included in those CPU peaks; monitor sampling
is not attribution to an individual frame or subsystem. Different frame pacing and
final visible scene state prevent interpreting the two runs as a causal optimization.

The separate 25-second overloaded boss/two-projection probe (60 debt, 100 Burnout,
elevated actor health, five seconds warm-up excluded) measured **132.76 average
FPS**, **7.61 ms median**, **9.67 ms p95**, **43.67 ms maximum**,
2,656 frames and 417 final-frame draw calls. This also contains a hitch;
it does not prove sustained 60 FPS. Screenshot saving occurred after measurement.

Repeat with:

```sh
sh tools/godot.sh --path . --resolution 1920x1080 --script tests/stabilization_preview.gd
sh tools/godot.sh --path . --resolution 1920x1080 --script tests/incident_preview.gd -- --burnout --measure
python3 tools/validate.py
```

The transition probe writes ignored `builds/stabilization_performance.json` including
slow-frame phase labels and synchronous spawn/copy/reset CPU times. Native Performance
monitors provide total process/physics and tracked static/video memory, not OS resident
memory or per-script AI/render cost. No editor profiler attribution, GPU capture,
long-duration soak or Windows benchmark is claimed. The steady boss probe excludes
five seconds of warm-up and screenshot saving; the lifecycle probe includes initial
scene creation/first rendering and paused UI. Both are synthetic scenarios.

## Remaining limits and human gate

The full ordinary run has no measured human duration. One enemy is damaging at a time;
furniture-top pursuit is unsupported. Corpses remain as non-colliding poses bounded by
authored counts and are freed on restart. Harmless projections teach a cue but do not
establish the future Circle I boss design. Combat still uses cone/center hit detection.
Native models, locomotion/slopes, sound and lighting need creative acceptance. Settings
have no saved preferences or extensive scaling framework; existing canvas stretching
was reviewed at the two stated resolutions. No new binary distribution is supplied;
the existing Finder launcher and pinned Godot project are the playable delivery.

Balance questions remain explicit: two free defensive upgrades can be a strong default;
a single mobility choice incurs debt without crossing a pursuit threshold. The five-minute
commitment adds immediate risk and its bonus mostly offsets the pressure it creates on a clean
run; its timer may be generous. Dependency relief has no immediate benefit at zero
Burnout but still adds a record, now visible before selection. Preserve current values
until ordinary runs establish whether those situational costs are worthwhile.

Creator checkpoint:

1. Launch with `play.command`, click to begin, and complete a run. Does movement stop
   promptly, does camera aiming help attacks, and can the three-hit chain be intentional?
2. Dodge a warning and punish recovery. Does travel/recovery feel fair; do any hits
   arrive outside what the warning communicated? Try shake/flash off from Escape.
3. At OPERATIONS, deliberately choose a wrong system once, then 3. Can a non-developer
   explain the discrepancy and understand the next objective?
4. Compare damage/defense/mobility upgrades and all three management choices over R
   retries. Do previews match observed effects, and is any choice an automatic default?
5. Identify the solid original and strike during OPEN. Are markers readable while
   moving, and do copies distract fairly? Record unfair deaths or camera obstruction.
6. Read victory/defeat reports and retry from both decisions and reports. Record total
   ordinary run time, slow/repetitive moments, audio levels and desire to replay.

Recommended next milestone: director-led balance/usability acceptance and Windows
runtime/build validation of this same slice. Resolve those gates before expanding
content or replacing the native presentation with a larger asset pipeline.
