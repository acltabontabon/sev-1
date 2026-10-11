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

### 0.2.33 whole-run probe (11 October 2026)

`tests/performance_probe.gd` plays a scripted Incident 001 at 1920×1080 (Apple M2 Pro,
macOS, Forward+/Metal, High quality: SSAO, glow, MSAA 2x; VSync off): walking the
office, the first outbreak cutscene, melee with specials and kill cams, the second
encounter, the omnislash, the vault arrival and the boss. It writes ignored
`builds/performance_probe.json` with per-phase percentiles, pipeline compilations and
what changed on screen in every frame over 33 ms.

| Build | Avg FPS | Median / p95 / p99 (ms) | Frames >16.7 ms | Frames >33 ms (ex. startup) |
| --- | --- | --- | --- | --- |
| 0.2.32 (three runs) | 102–110 | 8.9–9.2 / 12.1–13.8 / 14.3–15.9 | 30–45 | 6–8, up to 73 ms |
| 0.2.33 (two runs) | 109–110 | 8.8–9.0 / 12.5–12.7 / 14.5–15.2 | 30–31 | 2 + one first-view freeze |

The 0.2.32 stutters (40–73 ms) coincided with text appearing for the first time (the HUD
after the opening, the outbreak lower-third, the first kill's stamp) while CPU process and
render times stayed low: glyphs rasterised on first use per font, size and outline. The
HUD now draws every 2D text style and the runtime 3D text styles once, all but
invisibly, at load. MSDF fonts also removed the stutters but changed every outlined 3D
sign's look, so they were rejected. Remaining: a single 135–145 ms freeze the first
time the gameplay camera sees the whole office (74 GPU pipelines compiled in one
frame), and one or two 37–53 ms frames in fights without a text cause. Steady play is
well above 60 FPS here; a 120 Hz display with VSync will still drop frames around the
p95. Windows and lower-end hardware remain unmeasured.

### HUD efficiency audit — 11 October 2026

The HUD no longer reapplies unchanged focus colors, Burnout bar styles or pause/report
font sizes every frame. Objective, enemy health, Burnout and pause/report labels are
assembled before assignment, avoiding a base-text replacement followed by appends on
every refresh. Visual contents and gameplay timing are preserved.

`tests/hud_efficiency_tests.gd` checks stable styling and immediate health, ultimate and
ETA updates. In the same fixture, the previous refresh function emitted **360** theme/style
invalidations over 120 unchanged refreshes; the revised function emitted **zero**.
Run it with `sh tools/godot.sh --headless --fixed-fps 60 --path . --script tests/hud_efficiency_tests.gd`.
The full `python3 tools/validate.py` suite also passed. A rendered 1080p capture confirmed
that the HUD, vitals, special icons and floor map still display.

Sequential rendered samples used Apple M2 Pro, macOS, Godot 4.7.2, Forward+/Metal,
1920×1080, High (SSAO, glow, MSAA 2x), VSync off. The baseline injected the previous
HUD refresh function into the current scene, preserving other working-tree changes.
The revised run used the current HUD. Startup is excluded below:

| Sample | Mean FPS | Median / p95 / p99 ms | Frames >16.7 ms | Frames >33.3 ms | Worst ms |
| --- | --- | --- | --- | --- | --- |
| Previous HUD | 120.21 | 8.24 / 11.29 / 12.83 | 22 | 5 | 170.96 |
| Revised HUD | 119.64 | 8.24 / 11.28 / 14.63 | 20 | 4 | 46.21 |

These samples establish no overall FPS improvement. The reduced worst hitch cannot be
attributed to the HUD alone: first-use caches, randomized encounters and another running
packaged game affect comparability. GPU timing returned zero, so it is unavailable rather
than evidence of zero GPU cost. One earlier sample overlapped validation and is excluded.
The probe uses scripted teleports, elevated player health and forced stage transitions;
it does not establish ordinary run pacing or cover every wave/finale. First-use stalls and
Windows performance remain open. The confirmed gain is removing recurring UI invalidation.
Raw samples and the screenshot are ignored build artifacts, not shipped assets.

Playtest the source with `play.command`: move and aim during a crowded outbreak, chain
melee and specials, use Force Rollback, then visit the vault and retry. Report the exact
moment of any pause, especially whether it happens only on first use or repeats, and
confirm health/readiness/countdown text still changes promptly.

### Fan/load investigation and frame budgets — 11 October 2026

A live process snapshot showed Apple's `MTLCompilerService` at 810.4% CPU while a
packaged test launched from a temporary build. It disappeared from the high-load
process list in the next snapshot roughly half a minute later. This is evidence of a
transient Metal compilation burst, plausibly contributing to fan noise; it does not
identify the compiler's client or establish that every fan event has the same cause.
`pmset -g therm` reported no thermal or performance warning in both snapshots. That is
not a temperature or fan-speed measurement. Another snapshot showed the regular
packaged game at 48.6% CPU. No unrelated processes were stopped.

The application now limits rendering to **60 FPS** during focused gameplay, **30 FPS**
on title/menu/pause/report screens, and **15 FPS** when unfocused. Settings
includes a saved **120 FPS** gameplay option, with its higher power-use tradeoff.
Existing settings files acquire the 60 FPS default; invalid frame-limit values fall back
to it. Physics remains 60 ticks/second; focus loss retains the existing automatic pause.
Headless validation bypasses wall-clock frame caps. The standalone uncapped combat
performance probe is unchanged. The application restores its previous cap on unload.
This uses Godot's [Engine.max_fps](https://docs.godotengine.org/en/latest/classes/class_engine.html#class-engine-property-max-fps),
which is documented to reduce power use through frame limiting; actual watts and fan
RPM were not measured.

`tests/frame_budget_tests.gd` passed seven checks covering menu/background limits,
default gameplay, saved 120 FPS, pause/resume timing, unchanged physics/game speed,
and corrupt settings. Run with `sh tools/godot.sh --headless --fixed-fps 60 --path . --script tests/frame_budget_tests.gd`.
`tests/frame_budget_probe.gd` renders the same animated title scene under three budgets,
with two seconds settling and six seconds measurement each: **114.03 FPS** at a 120
cap, **30.00 FPS** at 30, and **15.00 FPS** at 15. Conditions: Apple M2 Pro, 16 GB,
macOS, Godot 4.7.2 Forward+/Metal, 1920×1080, VSync disabled to isolate the cap, another
packaged game running. Lower caps rendered roughly 74% and 87% fewer frames, not
measured equivalent power reductions. The settings screen was visually inspected. A separate rendered integration check
confirmed that the front end applied 15 FPS while unfocused. The full
`python3 tools/validate.py` suite passed after these changes.

Use the updated source launcher `play.command`; an already-running packaged executable
keeps its old code. Try five minutes of combat at 60 FPS, pause for a minute, then switch
to another app. Report whether fan noise settles and whether mouse/combo response feels
acceptable. Shader compilation and automated import/export work can still briefly raise
CPU load; capped rendering cannot prevent that. Windows energy behavior remains unmeasured.

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
