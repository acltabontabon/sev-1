# SEV-1 Implemented Architecture

This describes Office After Hours, Incident 001, the Milestone 5 presentation pass, Milestone 6 run progression, and Milestone 7 Burnout/corporate decisions, and Milestone 8 stabilization, implemented on 10 October 2026. Future story and systems belong in [game design](game_design.md), and sequencing belongs in the [roadmap](roadmap.md). There is no campaign, run-generation framework, saved run progression, or runtime AI service. Milestone 10 adds local device preferences only.

## Runtime composition

`project.godot` opens `game/release/front_end.tscn`; Start Incident instantiates `game/incidents/missing_transaction.tscn`, which inherits `game/main.tscn` and adds a local Incident controller. The base scene still launches the single-enemy regression arena. The project uses Godot 4.7.2 standard, GDScript, Forward+, a 1280×720 development viewport, physics interpolation, and the default 60 Hz physics tick. The launcher enforces the 4.7.2 stable version family. Graphics are configured in the main scene through sky/ambient lighting, directional shadows, local colored lights, SSAO, glow, and light fog.

```text
Incident001                incidents/missing_transaction.tscn (inherits Main)
  Incident                 incidents/missing_transaction.gd
    Spawned records/boss   existing enemy scene; variance.gd for boss
Main base                  game/main.tscn + main.gd
  WorldEnvironment/lights  scene-owned presentation
  OfficeAfterHours         rooms/office/office_after_hours.tscn
    Navigation             offline-baked NavigationMesh
  Player                   player/player.tscn + player.gd
    Visual/Melee           combat/melee_attack.gd
    Visual/Character       native engineer + keyboard presentation
    CameraRig              player/camera_rig.gd
      SpringArm3D/Camera3D
  Enemy                    enemies/incident.tscn + incident.gd
    Visual/Melee           same melee component, enemy tuning
    Visual/Telegraph       full-range warning arc
    ImpactSparks            reusable eight-piece impact effect
  HUD                      ui/playtest_hud.gd
```

## Responsibilities and contracts

| Owner | Implemented responsibility |
| --- | --- |
| [Main](../game/main.gd) | Connects capture, death, and reset signals. Delegates episode death/reset when Incident exists, otherwise restores both lab actors. Guards terminal and choice-modal capture. R works while paused. |
| [Player](../game/player/player.gd) | Camera-relative acceleration, braking, sprint, gravity, jump, visual facing, presentation handoff, health/invulnerability, attack request, damage/death, and reset. |
| [Camera](../game/player/camera_rig.gd) | Independent yaw, bounded pitch, wheel distance, capture/release, focus-loss release. Spring arm retracts against world geometry and excludes the player. |
| [Melee](../game/combat/melee_attack.gd) | Wind-up/active/recovery timing, one hit per target per swing, cone/range/elevation checks, obstruction ray, strike arc, and optional warning/swing audio. |
| [Enemy](../game/enemies/incident.gd) | Pursuit within detection distance, direction committed at attack start, telegraph/recovery, health, flash, short stagger, knockback, defeat, and reset. Native NavigationAgent3D follows the office mesh while approaching; attack timing/facing remains unchanged. |
| [HUD](../game/ui/playtest_hud.gd) | Capture prompt, fighter health, attack state, hit marker, damage flash, and defeat/retry text. Reads the known actors in the lab, or the local Incident controller for objectives, narrative, investigation, boss health, and reports. |
| [Room](../game/rooms/office/office_after_hours.tscn) | Authored office shell, workstation instances, glass conference room, operations hardware, practical lights, and baked navigation. |

There are no autoloads, dedicated health component, animation framework, or global event bus. Three typed AttackProfile Resources (`slash.tres`, `reverse_slash.tres`, `finisher.tres`) define player attacks. Other tuning lives in exported script properties and scene overrides. Health belongs to each actor; the only shared gameplay component is melee, justified by its two users.

Melee finds `Node3D` targets through the `players` or `enemies` group. Each must expose `receive_damage(amount, source_position) -> bool`. Accepted damage emits `hit_landed`; actors signal health changes and death, and the player signals hit confirmation, hurt, and reset requests. Calls and node paths assume this small fixed scene composition.

## Damage and timing

The player can start a grounded strike while alive and outside hurt/recovery lockout. Attack start aligns the visual with camera yaw. Facing stays fixed for the strike, movement slows throughout it, and jumping is unavailable during the attack. A press in the last 0.24 seconds queues one next attack. A 0.26-second link window after the first two swings also accepts the next step; the finisher ends the chain. Earlier presses are ignored, holding does not repeat, and damage/dodge/reset clears the queue.

Melee tests target centers at `global_position + Vector3.UP`, not blade-to-mesh collision. It filters planar range and angle, rejects more than one meter of vertical separation, and ray-tests world obstruction. Each target is recorded once per swing. This is a deliberate prototype approximation that needs revisiting if creature scale or elevation demands change.

| Current tuning | Player | Enemy |
| --- | --- | --- |
| Health | 100 | 180 |
| Damage | 25 / 30 / 45 | 20 |
| Wind-up / active / recovery | Slash: 0.12 / 0.12 / 0.28 s; reverse: 0.10 / 0.14 / 0.26 s; finisher: 0.20 / 0.16 / 0.40 s | 0.65 / 0.14 / 0.85 s |
| Reach / half-angle | 2.25 / 2.45 / 2.55 m; 65 / 65 / 75° | 1.85 m / 55° |
| Locomotion | Walk 5 m/s; sprint 8 m/s | Pursuit 2.4 m/s; detection 10 m; attack start within 1.65 m |

Player damage cancels the player's attack and grants 0.65 seconds of invulnerability with 0.16 seconds of hurt slowdown. Enemy damage produces a 0.12-second flash, 0.2-second stagger, and decaying knockback; it does not cancel an already committed attack. Enemy death cancels melee and removes its collision layer and settles its fractured slabs. Player death releases capture and pauses the encounter. These numbers are baseline tuning, not permanent design commitments.

## Dodge and impact

Q/right mouse starts a grounded dodge in camera-relative movement direction; stationary input defaults backward. Travel is 3 m over 0.24 seconds, followed by 0.32 seconds recovery. Invulnerability is [0, 0.18) seconds and is independently configurable. World collisions shorten travel. During dodge and its recovery, attacks, jumping, and another dodge are unavailable. Dodge cannot bypass an active strike or hit-stop; it can cancel attack wind-up and recovery. The cyan foot ring marks invulnerability, not the whole dodge. Damage ends the dodge; the presentation returns from its crouch while the damage origin stays unscaled.

Impact freezes the two actors and their melee timers locally for 45/55/80 ms by combo step; it never changes Engine.time_scale. Camera feedback is a small decaying rotation, preserving spring-arm collision. Eight reusable spark meshes burst at the target; no per-hit nodes accumulate. The existing synthesized audio gains per-step swing pitch. Player exports allow disabling hit-stop, particles, or camera impulse (set strength to zero).

The enemy exposes IDLE, APPROACH, TELEGRAPH, ATTACK, RECOVER, REACT, and DEAD states. It commits direction at wind-up and shows the full warning reach throughout. Reaction does not interrupt a committed attack, preventing indefinite stun lock. Death cancels damage; player death also cancels the enemy swing before pausing.

## Base arena pause and reset

Main, HUD, and CameraRig process while paused; both fighters are explicitly pausable. Capture changes toggle tree pause. The initial click resumes and is consumed before it can trigger a strike. Escape or focus loss pauses combat and releases the cursor. Headless execution skips focus-loss release.

R restores existing actors' positions, health, attack timers, collision state, and camera, and clears HUD hit/hurt timers, combo buffers, dodge state/pose, local hit-stop, camera impulse, and sparks. It does not instantiate another opponent. A player falling below the safety threshold requests the same encounter reset; enemy fall recovery resets the enemy. There is no persistent run history. In the episode, Main instead resets the Incident controller and player; the controller removes dynamic actors and restores Friday, evidence, reports, dashboards, and lighting.

## Physics and assets

| Physics layer | Bit | Usage |
| --- | --- | --- |
| World | 1 | Static environment; melee obstruction and camera checks |
| Player | 2 | Player body; its mask is 5, world plus enemy |
| Enemy | 4 | Enemy body; its mask is 3, world plus player |

Text `.tscn` scenes hold primitive meshes, materials, colliders, and lights. Limb/weapon motion is scripted; there is no imported rig or animation library. The arc is a small generated `ImmediateMesh`. Eight synthesized WAV effects live in [assets/audio](../assets/audio/README.md), with committed import sidecars and documented provenance. Headless tests skip sound playback because the dummy audio path did not drain reliably on test exit. Sound quality still requires graphical listening and human feedback.

Keep `.uid` and asset `.import` sidecars with their sources. `.godot/`, builds, and logs are ignored. Git text files use LF; large binary asset intake should establish LFS and remote support before committing substantial art libraries. No such library or CI configuration exists yet.

## Validation and limits

`python3 tools/validate.py` invokes the pinned launcher, imports resources, parses all game/test scripts, then runs `tests/run_tests.gd`, `tests/combat_tests.gd`, and `tests/alpha_tests.gd`, `tests/office_tests.gd`, `tests/incident_tests.gd`, and `tests/presentation_tests.gd`, and `tests/progression_tests.gd`, and `tests/burnout_tests.gd` at fixed 60 Hz without real-time waiting. Each command has a 120-second deadline; both exit status and recognized engine/script errors can fail the run. Logs are written under `logs/`.

The final Milestone 5 results on 10 October 2026 report 155 assertions passing: 16 movement, 29 combat, 40 alpha, 9 office, 44 incident, and 17 presentation. Import and all script checks also pass. Coverage includes actual attack bindings, timing, one hit per strike, obstruction/direction/elevation, invulnerability, enemy tells/evasion, death, pause, and repeated reset. Movement tests disable the opponent to isolate locomotion. Combat tests combine controlled actor placement with active enemy behavior; they are not full human play sessions.

`tests/capture_preview.gd -- --combat` stages a reproducible graphical shot and writes an ignored preview. It deliberately overrides capture-driven pause during setup, freezes the action, and cleans up paused audio on exit. That staged image is useful for visual inspection, not evidence of normal encounter pacing.

Known limits: furniture and characters still use simplified native geometry; art/animation and sounds are provisional; no permanent progression, export validation, long-duration performance soak, or Windows runtime test is present. The office 1080p Forward+/Metal measurement on M2 Pro averaged 119.36 FPS, with median/p95/max frame times of 8.27/10.65/67.43 ms (2,388 samples, five-second warm-up excluded). The maximum includes an unexplained isolated hitch. `tests/office_preview.gd -- --measure` reproduces the 25-second elevated-health combat scenario and captures images outside measurement; see README. This is not a release performance guarantee. Preserve the current playable while addressing these through the roadmap's separate gates.

## Office After Hours environment

The 28×32 m shell and original ramp/deck slope preserve the movement foundation. The
central x=−4…4 circulation spine remains open for combat; workstations occupy the west
side, the spawn has a task-lit workstation, the east deck holds the glazed conference
room, and the north wall contains production dashboards and racks. Chairs and small
clutter are visual-only; desktops, partitions, architectural glass, ramp guards, and
major cabinets have simple world-layer box collision. The old movement lab remains
available as a reference scene but is no longer the main environment.

`tools/build_office.py` deterministically authors the static `.tscn` layout, reusable
`workstation.tscn`, `chair.tscn`, `server_rack.tscn`, and shared material `.tres` files.
Edit the authoring source before regeneration; direct generated-file edits will be
overwritten. No runtime prop generation or new dependencies are required. All props
are visible and editable in the Godot editor. Original asset provenance and replacement
priorities live in [assets/environment/README.md](../assets/environment/README.md).

Lighting uses subdued cool ambient fill, six ceiling spot pools (two shadow-casting),
a warm workstation lamp, restrained incident spill, window bounce, and conference fill.
Existing Forward+, SSAO, MSAA 2×, glow, and fog remain; glow was reduced. Roughness and
metallic values distinguish stone, wood, plastic, fabric, metal, and glass. Four small
seeded noise textures supply surface grain. There is no flashing effect or expensive
custom shader. The negative uptime and nested frames on a sealed service door are
static surreal details, not a reality-shifting mechanic or additional playable area.

Furniture required routing beyond the previous straight-line chase. The enemy now
uses a native NavigationAgent3D only for approach direction. Damage, detection range,
attack range, timings, reactions, dodge, and player controls are unchanged. The baked
mesh uses static world collision, 0.75 m clearance, 2 m agent height, and a 0.5 m path
height offset matching the voxelized floor. Ramp rails block invalid side entry.
Rebake after collision changes:

```sh
python3 tools/build_office.py
sh tools/godot.sh --headless --path . --script tools/bake_office_navigation.gd
python3 tools/validate.py
```

This uses Godot's [static collision navigation bake](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationmeshes.html)
and saves `navigation.tres`; no runtime bake occurs. Encounters activate one damaging enemy at a time, so no crowd avoidance is introduced. Furniture-top pursuit is not supported; the intended encounter uses the
floor and ramp-connected conference deck.

Office integration tests check the clear floor lane, workstation collision, dodge and
camera near the conference boundary, real enemy pursuit around desks and up the ramp,
and repeated-reset stability. Rendered views and frame-time measurements are produced
by `tests/office_preview.gd`; see README for the command and measured results.


## Incident 001 orchestration

`game/incidents/missing_transaction.gd` owns the explicit sequence ALERT → ENCOUNTER_ONE → INVESTIGATION → ENCOUNTER_TWO → BOSS → RESOLVED, with FAILED reachable from every live stage. Invalid skips and repeated terminal transitions are ignored. No autoload, quest framework, asynchronous gameplay timer, external asset, or runtime service was added. Main's existing signal subscriptions are connected once and never reconnected on restart.

The inherited lab enemy is hidden, disabled, and removed from the melee target group. The original combat tuning, enemy/melee behavior, office geometry and navigation are preserved. Milestone 9 adds only a short presentation hold to the player and an independent opening camera. Milestone 9 replaces the seven-second alert with a 24-active-second opening; a two-second arrival delay puts the first enemy in play around 26 seconds. Seen session retries shorten the opening to three seconds. Tab skips it. See the narrative presentation section below. Exported counts default to two first-encounter records and three second-encounter records, arriving one at a time. The second encounter changes pursuit speed from 2.4 to 3.4 m/s before the run debt multiplier. Arrivals use the farthest of three clear floor sites, a short delay, and existing spark effects. Defeated records retain a non-colliding collapsed pose; their total is bounded by authored counts and all are freed on reset.

Investigation requires the player within four meters of the operations marker at (−1.7, 0, −12.5). E exposes three evidence lines; physical keys 1/2/3 select a system. Incorrect selections increment a report counter and provide an additional plain-language clue, without damage or progression. Payment Processing (3) advances the incident. Input is blocked while paused and key echoes are ignored. No financial calculation is required.

`game/incidents/variance.gd` extends only the existing enemy implementation. The Variance has 700 health, the original telegraph/attack timing, and an eight-second repeating pattern: 4.5 seconds pursuing/attacking while shielded, then 3.5 seconds stationary and OPEN. Opening cancels its swing and accepts normal player damage; shielding rejects it. Milestone 8 freezes the phase clock during actor hit-stop, so an impact cannot consume the remaining OPEN time while motion is frozen. Its solid physical diamond, solid text diamond, and VERIFIED ORIGINAL marker remain consistent. On first reaching half health, exactly two non-colliding, non-attacking translucent silhouette projections appear, marked with hollow diamonds. They are visual decoys, not additional melee targets, and never multiply. This deliberately simple cue/decoy experiment needs human acceptance. Boss defeat retains a settled fractured pose and removes projections; there is no imported boss animation.

The incident controller processes while paused only to settle environmental light changes. Gameplay elapsed time, spawn delays, and transitions stop while paused. All gameplay timing is local elapsed state, not scheduled callbacks. Terminal states cancel melee, release capture, show a deterministic report, and block resumption until R resets. The whole tree remains paused on the report; incident spill settles smoothly, and recovered dashboard signage/strip changes toward green. Restart resets that light immediately to its opening value, clears reports/evidence/counters, removes every spawned actor/projection, and restores the player at the workstation with the gameplay camera. A fresh scene load also resets everything. Milestone 9 retains only opening/boss seen flags across R within the same scene session; gameplay state never persists between runs.

`tests/incident_tests.gd` exercises actual E/number/F/R input plus controlled damage to traverse lifecycle cases quickly: early combat, illegal transitions, completion, duplicate death, wrong/correct evidence, speed escalation, shielded/open boss damage, actual player melee against the boss, bounded copies, victory/death cleanup, terminal capture, repeated restart node/signal counts, environmental reset, and fresh scene reload. Controlled damage is test staging, not proof of full-run balance. `tests/incident_preview.gd` captures staged intro/evidence/boss/reports and optionally measures a 25-second high-health boss/copies scenario. README records settings and measured frame times. Headless validation does not establish audio quality, ordinary run duration, or fun.

Known episode limits: the 5–10-minute target is unverified by a human run; expert runs may be shorter. Only one damaging enemy is active at a time. Copies are harmless projections. Health carries through the full episode with temporary upgrades but no healing system. Characters, effects, sound, and report presentation remain prototype assets. No full Circle I boss, persistent progression, additional floor or Windows runtime test is included. Milestone 10 adds the macOS release build described below.


## Milestone 5 character presentation

`game/player/engineer_visual.tscn` is instanced under `Player/Visual/Character`.
`character_presentation.gd` reads the completed actor/melee physics tick at priority
10. It never invokes damage or changes movement. The original attack resources,
cone/elevation/obstruction tests, timing, reach, dodge travel, and invulnerability
remain unchanged. Camera-directed attack facing is unchanged.

The native engineer has rolled sleeves, glasses, a loose tie, ID badge, dark trousers
and shoes, and a keyboard Escalation Blade. A distance-driven gait uses linear stance
travel and lifted return with two-segment limb placement. Idle breathing is restrained;
the torso counter-rotates during gait. Arms track the weapon grip. Attack anticipation,
sweep, and return read the three existing phase durations; the finisher adds a pitched
sweep. Local hit-stop freezes presentation. Dodge bends the legs and lowers the torso
without scaling the actor or damage origin; a small cyan foot ring marks only the
actual invulnerable interval. Hurt adds torso recoil. Death applies a settled kneel
before the immediately pausing report, not an animated fall. R resets pose and phase.

`record_visual.tscn` adds misregistered ledger slabs, status rows, offset head, and legs.
`record_presentation.gd` runs after enemy combat and reads explicit states: quiet drift,
pursuit arm motion, shoulder-based wind-up/strike/recovery, slab flash/recoil, and an
extinguished fractured defeat pose. Shape/motion, existing warning arc, and state text
remain available alongside color. It does not cancel committed attacks. The Variance's
two harmless projections now copy all visual meshes except attack/telegraph effects;
solid-original versus hollow-copy markers and boss timing remain unchanged.

Directional impact sparks reuse the same eight meshes, biased by existing knockback.
No damage comes from effects. Original synthesized step, dodge, defeat, and incident
alert cues supplement swing/impact/hurt/warning. Playback is bounded, headless-skipped,
and reset-stopped. Alert begins once after active capture, not during the start pause.
Per-actor status materials prevent one enemy's state changing another's appearance.

`tools/build_characters.py` deterministically authors only the two native visual scenes;
`tools/build_presentation_audio.py` authors the four new small sounds. Provenance,
source evaluation, model replacement instructions, and honest asset limits are in
[characters](../assets/characters/README.md) and [audio](../assets/audio/README.md).
There is no Skeleton3D, AnimationTree, external model dependency, runtime asset loader,
root motion, terrain foot IK, new attack input, or additional gameplay content.

The extended validator adds `tests/presentation_tests.gd`: 17 assertions covering
native fallback loading, floor clearance, anticipation before damage, recovery,
interruption, hit-stop, crouch/aura, defeat/collision cleanup, sound reset, and retry.
All 155 assertions pass (138 existing + 17 presentation), plus import and script parsing.
The existing incident suite still checks despawn, copies, duplicate events, reset,
and reload. `tests/character_preview.gd` captures identity/anticipation/strike/dodge/
defeat at 1080p with a staged camera; `tests/incident_preview.gd -- --measure` retains
the existing boss/copies measurement. See README for measured results and human gates.


## Technical Debt run progression

Incident owns one `run_progression.gd` Node and one `upgrade_selection.gd` CanvasLayer,
created once in `_ready`. No autoload, new global signal bus, save data, or dependency
was added. `_on_record_died` opens a choice when a record wave reaches zero, retaining
the current stage and a pending next stage. Only the first valid selection consumes
the pending decision and advances. Capture cannot resume while pending; the modal
processes while paused. Number keys are consumed in `_input` before investigation or
combat can interpret them. Buttons support pointer and native keyboard focus. Reset
and terminal transitions close the modal; reset clears run state and actor modifiers.

Run exports own damage/defense/recovery bonuses, debt costs, debt limit (default 100),
and pursuit increase per band (default .05). Choices add against the base: damage
`1 + .35 * count`, incoming `max(.4, 1 - .2 * count)`, dodge recovery
`max(.5, 1 - .25 * count)`. Existing AttackProfile resources stay unchanged. Melee
rounds effective damage at the existing valid-hit call; Player scales accepted incoming
damage after invulnerability checks, and scales only dodge recovery duration. Resets
restore multiplier 1. The original combat lab uses those same neutral defaults.

Debt bands are Stable 0–24, Fragile 25–49, Unstable 50–74, Critical 75–100. Each newly
spawned actor receives its base pursuit speed times 1/1.05/1.10/1.15. Spawn guards
prevent duplicate actors or spawns while choosing. Boss shield/open timing, attack
telegraphs, active frames, recovery, collision, and projection rules remain intact.
This is one gameplay consequence, with no damage hazard or random failures.

The existing Critical, Impossible, ETA, IncidentStrip, and IncidentSpill nodes provide
environmental feedback. Only the local strip override material changes, on stage/
choice updates. Spill adds .35 energy per debt band and settles through the existing
light update. There is no new shader, per-frame material creation, or flashing. Victory
retains the existing recovered presentation. Reset restores the opening labels, material,
and .6 spill exactly. HUD reports debt/severity/pursuit; choice cards preview the next
state; the incident message shows debt gained; both reports summarize choices and debt.

There are two fixed decision points: after the first record wave (before investigation)
and after containment (before boss). Maximum normal debt is 60. Critical remains a
tested tuning band; reaching it would require changed costs or additional decisions,
which are future proposals. Two free defense choices may dominate for some players;
one mobility choice costs debt without crossing a threshold. Those are explicit balance
questions, not claims of an optimized economy. No healing or permanent unlock exists.

`tests/progression_tests.gd` exercises actual F/number/R and mouse events, one-shot
selection, applied melee damage, defense/invulnerability, dodge duration, threshold
edges, resource preservation, pursuit limits, environmental updates, victory/defeat
summaries, modal reset, repeated-run node/subscription counts, and fresh scene load.
The existing incident suite now traverses both upgrade moments and still tests boss
windows, copies, reports, and lifecycle. Staged preview flags and measurements are in
[README](../README.md#validation). Human pacing, readability,
audio, creative acceptance, and Windows testing remain open.

Final Milestone 6 validation: 208 assertions (155 baseline, four added incident checks,
49 progression checks), with successful imports and all script parses. Current-build
zero/60-debt 1080p measurements on M2 Pro were 123.18/120.01 average FPS with both p95
frame times at 10.39 ms; this short sequential comparison does not establish full-run
or Windows performance. See README for the complete measurement conditions and limits.

## Burnout and corporate pressure

Milestone 7 extends the existing local RunProgression, Incident, and choice modal;
there are no new managers, assets, or external dependencies. Player emits
`damage_accepted(base_amount)` once after invulnerability checks and damage, before
death. Incident subscribes once: accepted base hits of at least 10 add 8 Burnout.
This uses the attack's base size so defensive upgrades do not hide stressful hits.
The triggering hit uses the old band; the new band affects subsequent damage.
Time alone, rejected hits, and minor hits do not add Burnout.

RunProgression exports the 0–100 bound, event amounts, and band modifiers. Composed
(0–29) is neutral; Pressured (30–69) adds .10 to base outgoing and incoming damage;
Overloaded (70–100) adds .25 to each. These add to upgrade modifiers in the existing
single calculation, with final outgoing clamped 1–2 and incoming .4–1.25. With two
Ship upgrades plus overload, outgoing is 1.95; two defensive upgrades plus overload
produce .85 incoming. Rounding happens once at the existing damage boundary.
Debt still affects only upcoming pursuit. Attack resources, input, hit windows,
movement, dodge travel/invulnerability, and enemy tells are unchanged.

After correct investigation, `decision_pending` blocks capture, spawns, and stage
transitions until a valid choice. The existing persistent upgrade modal displays
three corporate cards; its single subscription routes to the pending interaction.
This follows the first upgrade and precedes containment and the second upgrade.
Reset/terminal transitions close either interaction, and R remains available.

- Commit: +35 Burnout and an optional 300-active-second containment challenge.
  Clearing containment before expiry grants 20 bonus relief. Expiry has no penalty.
- Realistic estimate: +8 Burnout, no encounter modifier.
- Dependency escalation: −20 Burnout, with one extra sequential containment record,
  labeled DEPENDENCY RETURNED. There is still only one damaging enemy at a time.

Containment completion gives 15 relief once, plus any earned challenge bonus.
The existing active-enemy death guard prevents duplicate completion/recovery.
Countdown uses the existing incident active delta, including arrival delays, and
stops on modal, Escape, or focus pause. Defeat interrupts it. Restart clears all
Burnout, notices, decisions, and countdown state. No health recovery is introduced.
HUD displays value, band, Burnout's own contribution, combined active modifiers,
and optional timer/outcome; the pause card retains the latest change/source. Color supplements text; no new distortion or flashing.
Reports retain the decision, final Burnout, and challenge outcome.

`tests/burnout_tests.gd` covers accepted/rejected/minor hits, threshold edges, actual
combined melee and defense outcomes, bounds, all three decision paths to victory,
single recovery, pause/expiry, defeat, repeated reset/subscription counts, and reload.
`tests/incident_preview.gd -- --burnout` captures management, overloaded HUD, and
reports; append `--measure` for the boss scenario. `--debt --composed --measure`
uses the same debt with hit-driven Burnout disabled only in the measurement fixture.
See README for results and remaining human acceptance gates.

Final Milestone 7 validation passed **286 assertions** (16 movement, 29 combat,
40 alpha, 9 office, 49 incident, 17 presentation, 49 progression, 77 Burnout),
plus resource import and all script parses. Coverage includes actual number-key,
pointer, and Enter selection; all three corporate paths through victory; defeat;
thresholds; single-hit damage; recovery; expiry/pause; and reset/reload cleanup.
The initial sandbox-only baseline failed on macOS settings access; rerunning with
normal Godot user-directory access passed. No automated failures remain.


## Milestone 8 stabilization

The existing architecture and combat tuning remain in place. `Variance._physics_process`
now drains hit-stop before advancing its shield/open clock. A regression reproduces
rejected damage near the end of OPEN on the original code and accepts it with the fix;
shielding still resumes once impact and the remaining window expire. Reset immediately
removes spawned enemy collision before deferred deletion, avoiding a stale collider in
the reset frame. Existing corpse retention stays bounded by authored encounter counts.

`RunProgression` accepts optional hypothetical choice/Burnout values in the same bounded
modifier functions used by live damage. Previewing never selects an upgrade or mutates
run state. Cards show benefits, run duration, actual clamped Burnout changes, resulting
band, combined damage/taken/recovery totals, and future pursuit. Thus an escalation at
zero Burnout visibly removes zero, and a defense choice under overload shows its true
net cost. Base values, additive stacking, all thresholds and corporate consequences
are unchanged; their strategic balance remains a human gate.

The existing modal has dark teal cards and a thick cyan keyboard focus outline. Shared
opening behavior is local to the modal. Number keys, pointer, arrows/Enter and R remain
supported. The HUD adds remaining-record/arrival feedback and combined modifier totals;
its gameplay text hides beneath pause, choices and reports. The pause card exposes two
native CheckButtons for camera shake and the full-screen damage flash. Their preferences
survive R for the current scene session; a fresh launch uses defaults. Shake changes
only the existing rotation amplitude, and flash disablement leaves health, hurt audio,
state text and hit-stop available. There is no settings framework or persistence.
Canvas stretching remains configured in `project.godot`.

`tests/stabilization_tests.gd` extends existing input/test helpers. Besides the boss
regression, it verifies rendered feedback toggles, pointer handling without resumption,
arrow navigation, preview clarity/layout, active modifier/progress text, modal/report
occlusion, immediate reset collision cleanup, and three bounded complete simulated runs.
Each run uses real F attacks, normal boss windows and live enemy AI; position staging
and elevated player health make it a lifecycle check rather than a difficulty test.
Both upgrade moments, all three management paths, copies, victory and neutral stable
restart are exercised. The validator includes it alongside all existing suites.

`tests/stabilization_preview.gd` records frame intervals, slow-frame phase labels, native
process/physics peaks, static/video memory monitors, draw calls and CPU times for scene
creation, spawns, copies and resets. Three graphical lifecycles use controlled deaths
and short real boss fights; first rendering and paused UI are included, screenshot
saving is excluded. This is not an ordinary complete gameplay benchmark or a per-script
profiler. Screenshot capture in `incident_preview.gd` forces a render after settling frames rather
than waiting indefinitely for a paused/background draw signal. Results, QA evidence,
unresolved balance questions and limits live in
[the stabilization verification](stabilization.md); README owns commands and controls.


## Milestone 9 narrative presentation

`game/incidents/incident_presentation.gd` is one local CanvasLayer owned by Incident.
It has an explicit Incident 001 timeline and a bounded queue of authored captions,
not a general cutscene/dialogue engine. Incident still owns the seven stages, spawns,
choices, deaths, and reset. Stage changes call `stage_changed`; arrival, paid upgrades,
accepted hits reaching critical Burnout, and false positives request named one-shot
lines. A maximum three queued lines prevents backlog; urgent protagonist/alert lines
preempt the current card. Stage changes discard stale pending messages. Text is held
in one dictionary and passed through `tr`, ready for later localization without a
translation asset or localization framework. Timed messages last 4.5 active seconds.
Modal/terminal/pause states hide captions and titles, and freeze their countdown.

The full opening has weekend notification (0s), clock-check relief (5s), incident
alert/dashboard change (10s), management ETA (15s), and protagonist response (20s).
At 24s the existing encounter begins, with its unchanged two-second arrival delay.
The first nine seconds use one Camera3D near the existing workstation, with a final
one-second transform blend to the spring-arm camera. `Player.narrative_hold` gates
movement, attack and dodge only during that shot. Pause/reset input remains live.
`CharacterPresentation.story_pose` lowers the weapon and adds head/arm gestures; it
never changes attack timing or damage. Release/skip/stage/reset restores the gameplay
camera and clears hold/pose. No combat occurs during the held shot.

Boss arrival uses six seconds of active time (1.5 on subsequent session encounters),
a title/subtitle, and eight preallocated native fragments converging at the existing
safe arrival site. The player retains control. Tab sets arrival delay to zero and
spawns through the existing guarded function. Boss mechanics and phase durations
are unchanged; health appears on the title briefly, then in the normal HUD.
Opening/boss seen flags survive only R in the same loaded scene; a fresh launch
shows full introductions. No timers, autoload, storage, or delayed callbacks exist.

Workstation code rows share a local unshaded material, independent of existing shared
assets: healthy teal, critical red, containment orange, boss magenta, recovered teal.
Existing operations labels and strip retain the debt indicators. Only emergency spill
energy has a brief smooth sag during declaration; ambient combat lighting stays intact.
No extra real-time lights, shaders or navigation work are introduced. Victory subsides
the existing spill, restores production/clock text, and hides hostile fragments/copies.
Four small original synthesized sounds are authored by `tools/build_narrative_audio.py`;
the air loop uses its preserved import setting. All playback skips headless mode.

The original deterministic reports now include Incident's live enemy-death counter and
boss-spawn flag, plus RunProgression's peak Burnout, recorded inside `change_burnout`
before any later relief. Duplicate death guards still prevent double counts. Time is
active incident time including introductions/arrivals, excluding pauses/decisions;
enemy count includes The Variance. R clears these values. Reports use 17px text at the
720p canvas reference to fit the existing pause panel, with the restart action visible.

`tests/narrative_tests.gd` adds 21 outcome checks for healthy monitoring, staging,
input gates, pause, real Tab/R events, guarded spawns, one-shot lines, modal suppression,
recorded peak/final pressure, accurate reports, and shortened repeated runs. Existing
incident timing and progression reset expectations now match the authorized new opening.
All 341 assertions plus imports/parsing pass. `tests/narrative_preview.gd` captures the
rendered opening and terminal states. Human pacing, humor, listening, camera comfort,
and Windows validation remain separate gates; native art/poses and synthesized audio
are still placeholders. README owns launch, controls, preview commands and performance.


## Milestone 10 application and release boundary

`game/release/front_end.tscn` is the application root. Its local script owns title,
controls, settings, credits, pause and postmortem screens, and at most one Incident001
child. No autoload or general scene-management framework is introduced. Start creates
the incident and captures input; menu removes/frees its entire subtree, including
signals, actor groups and audio owners. Restart delegates to the existing reset path.
Standalone incident/lab tests retain their original capture/comfort interface.

The front end sets HUD `external_menu` to suppress its old capture card. Gameplay HUD
still reads Incident. Active play is represented by an empty application page; incident
modal flags remain the authority for choices. Escape can cover a decision with pause,
hiding/disabling its input until Resume restores its original focus and pending state.
Camera unhandled input is disabled on application screens. R is consumed in settings/
controls. Terminal states are detected once and shown as actionable reports. No other
screen can resume a terminal state. Focus loss still releases capture and opens pause.

`preferences.gd` is a local RefCounted object with a fixed allowlist. ConfigFile stores
only master/effects volume, sensitivity, shake, flash, fullscreen and quality in
`user://settings.cfg`, under the explicit SEV-1 user directory. Invalid types/ranges
fall back or clamp. Save errors appear in the settings UI. Changes apply immediately,
and new incidents receive the same preferences. Reduced quality disables SSAO/glow/MSAA;
it preserves fog, lighting and gameplay. Default settings retain the scene effects.
No music control is shown because there is no music track.

`default_bus_layout.tres` adds an Effects bus feeding Master. All authored/dynamic
players use it; existing per-cue gain and event timing are unchanged. Master and Effects
both default to 80%. No new audio asset or mixer framework is added.

`tests/release_tests.gd` adds persisted-setting validation and ten UI/input-driven
application lifecycle cycles. The existing full melee simulations remain in stabilization.
`release_smoke.gd` runs only with an explicit `--release-smoke` user argument because
release templates cannot load an external `--script` harness. It is bounded, uses
staged positions/elevated health, verifies packaged resources through real combat and
terminal cleanup, and exits. It never participates in ordinary play.

`tools/release.sh` / `release.py` own version/resource/template checks, validation,
macOS export, plist/PCK/signature verification, packaged headless launch and smoke,
ZIP creation and manifest hashes. Presets exclude development resources. Engine notices
are generated from the pinned engine's native license APIs and included in the package.
See [release engineering](release.md), [asset inventory](asset_licenses.md), and
[release notes](release_notes.md) for verified results and open gates. Earlier milestone
sections above describe their historical implementation; saved preferences and macOS
packaging supersede their former persistence/export limitations.

## Milestone 11 authored voice candidate

Incident now owns a local voice controller with a single active line, three pending requests, two audio players and a four-stream cache. The 22-entry JSON manifest supplies speech text and subtitles. Existing presentation triggers delegate to this controller; gameplay timing and camera staging remain unchanged. Variance speech follows the boss in 3D; other roles use flat playback with baked Production filtering. The Voice bus is independent of Effects and feeds Master.

Saved preferences add Voice volume and Subtitles with backward-compatible defaults. Application page state suspends speech except on the terminal report, whose dedicated subtitle slot displays victory/defeat and postmortem speech while gameplay remains paused. Restart and scene removal stop all speech. Development-only Kokoro generation and import tooling, lifecycle behavior, provenance and validation are described in [the voice guide](voices.md). This supersedes Milestone 9's fixed 4.5-second caption queue; no runtime AI or autoload is introduced.

## Milestone 12 creative revitalization

No autoloads or frameworks were added; new behavior lives with its owners.

- **Interface identity.** `tools/build_ui_theme.gd` writes `game/ui/sev1_theme.tres` and
  three font variations; `project.godot` sets it as the project theme. Type variations
  (DisplayTitle, Headline, Subhead, Eyebrow, Caption, MonoLabel, Card, MenuEntry,
  MenuSub) carry the styling. `game/ui/frosted.gdshader` blurs the scene behind menus
  and dialogs.
- **Front end.** `game/release/front_end.gd` keeps its page model. The title page lays a
  left column over `game/release/menu_backdrop.tscn` (office instance, seated engineer,
  monitor screen, notification bag, music). The backdrop leaves the tree before an
  incident is instanced and returns on Back to Desk. `preferences.gd` adds `music` and
  `opening_seen` (device-only; it unlocks skipping the opening).
- **Desk screen.** `game/ui/desk_screen.gd` renders a SubViewport interface onto the
  engineer's monitor (chat, log-off dialog, SEV-1 takeover). It updates live while on
  camera and freezes afterwards.
- **Opening and beats.** `incident_presentation.gd` stages the opening from `SHOTS` and
  `BEATS` tables (36 s; 3 s on retry), the evidence push-in, the vault arrival (no
  control loss), first-sighting slow motion and the terminal ending shot. A
  `sequence` queue plays lines that belong together through the bounded voice queue;
  stage changes clear it. A small music director cross-fades `assets/audio/music` beds on
  the `Music` bus, which a sidechain compressor ducks under `Voice`.
- **Notifications.** `voice_controller.gd` emits `line_started`; `game/ui/notification_feed.gd`
  turns gameplay lines into sender cards (max three, expiring). ALERT-stage lines use
  film subtitles instead.
- **HUD and dialogs.** `playtest_hud.gd` restyles its labels into a ticket header and adds
  a vitals card, boss bar, notice and evidence board. `upgrade_selection.gd` builds
  change-request tickets or a leadership DM inside its three buttons and stores each
  card's plain summary in meta `summary`; closing clears card contents.
- **Office.** `tools/build_office.py` adds the meeting wing, pantry, gate, corridor, vault,
  `SpawnPoints` markers, PBR materials (triplanar), Kenney props (tinted by
  `prop_tint.gd`) and `calendar_drift.gd`. `tools/bake_office_navigation.gd` bakes the
  larger footprint. The gate and Quick Sync doors are generated without collision so
  navigation bakes through them; the incident enables collision while they are shut.
- **Interactions.** `game/incidents/interaction_point.gd` is a distance-checked prompt;
  `missing_transaction.gd` owns what each pantry object does. Coffee adds
  `run.motivation` (outgoing damage) and `player.move_multiplier` for 40 s.
- **Encounters.** `missing_transaction.gd` keeps `active_enemy` as a computed view (boss,
  else first live enemy). `WAVES` authors each stage; `alive`/`sync_alive` track foes;
  `request_attack()` caps simultaneous telegraphs; corpses free after three seconds.
  Archetypes extend `game/enemies/incident.gd` via `set_script` like The Variance:
  `blocker.gd`, `meeting_invite.gd` (with `meeting_zone.gd`) and `scope_creep.gd`, each
  with a generated visual. Meeting zones slow through `player.zone_multiplier`.
- **Awareness.** `incident.gd` adds MANIFESTING / UNAWARE / NOTICING / ENGAGED /
  SEARCHING. `starts_aware` keeps the lab opponent, boss and Quick Sync ambush always
  hunting; incident waves (and bugs) start unaware. Since 0.2.6 only sight (forward cone
  with line of sight, or a bump within 1 m) or being hit starts a chase; noise and time
  never do. A noticing enemy sends colleagues within 10 m to `investigate()` the spot
  (SEARCHING), and they chase only if they then see the engineer.
  Engaged foes flank, orbit when waiting for a turn, back off after swinging and search
  the last known position. Damage while unaware is doubled.
- **Rigged engineer (0.2.1).** `game/player/rigged_engineer.tscn` replaces the native
  visual under `Player/Visual/Character` and on the menu desk, behind the same contract
  (`reset_pose()`, `defeat()`, `story_pose`, `sit`, `crouch`, `weapon`). It instances the
  Quaternius CC0 body and plays `engineer_animations.res` (baked by
  `tools/build_engineer_rig.gd`, which retargets the CC0 knight's run/roll/death onto it)
  through a manually advanced AnimationPlayer at physics priority 10, after the
  controller. Clips are picked or scrubbed from controller state. Swings drive the
  keyboard along authored arcs phased on `Melee` windows and `TwoBoneIK3D` modifiers
  (manual skeleton update) put the hands on its grip; between swings the keyboard
  follows the right fist. `weapon_trail.gd` draws the swing ribbon. The native scene
  stays as a fallback; provenance in `assets/characters/README.md`.
- **Elements and spells.** `game/combat/element_fx.gd` (`ElementFx`) spawns transient,
  top-level effects under their emitter (sigils from `magic_circle.gdshader`,
  shockwaves, motes, shards, glyph words, light flashes, wind crescents, lightning
  bolts, flame rings) and frees them itself; emitters clear them on reset with
  `ElementFx.clear_from()`. The engineer's three combo steps release wind, lightning and
  fire on their active window and on hits. `incident.gd` gives every enemy a spell
  identity (`magic_color`, `magic_accent`, `magic_words`, `magic_radius`): a sigil on
  telegraph, shards and a glyph on the strike, a burst on defeat; archetypes override
  it and add their own (Blocker cast and shield, Meeting Invite booking, Scope Creep
  growth, Variance phase lightning). Effects never deal damage or change timing.
- **Enemy bodies.** `incident.gd` creates a `MonsterRig` (`game/enemies/monster_rig.gd`)
  for its `rig_kind` (record, blocker, invite, scope, variance, bug; archetypes set it
  before `super._ready()`) and hides the native boxes, keeping the record's loading halo
  and each archetype's prop (BLOCKED sign, invite card, sticky notes, status crown). The
  rig (models from Quaternius' "Ultimate Monsters", fixed per-kind scale) plays the
  CC0 model's clips from AI state with a manually advanced
  AnimationPlayer (spawn, locomotion, attack scrubbed to the melee windows, hit, cast,
  death, sink) and keeps the model's materials with `corruption.gdshader` as an
  additive `next_pass`. Scope Creep scales the rig with its growth; The Variance's
  false positives are `projection()` copies of its rig. Provenance in
  `assets/enemies/README.md`.
- **Roaming outbreaks and patrols.** `missing_transaction.gd` gives each wave member its
  own site from `SITES` (desks, pantry, Operations, east corridor, conference deck,
  lounge, meeting wing) in rotation, skipping any within `ROAM_DISTANCE` (14 m) of the
  engineer, the last one used, and any point a walking path from the main floor cannot
  reach (`reachable()`; sealed rooms bake their own navigation islands). Unaware enemies
  then patrol: `patrol_point()` picks a reachable spot near another site, they stroll
  there, pause and look around, and move on. The `IncidentBeacon` (light column plus a
  through-wall "▼ THREAT · N m" marker) follows `nearest_threat()`, the closest member
  not yet chasing; `encounter_status()` reports how many roam and the nearest distance.
- **Sight cones.** `game/enemies/sight_cone.gd` paints each enemy's real field of view
  (`sight_range` 11 m, `sight_fov` 110°) on the floor as a fan of 22 rays clipped by
  world collision, rebuilt every 0.15 s with staggered starts. It is pale while UNAWARE,
  orange while NOTICING, amber while SEARCHING, and hidden when ENGAGED or dead.
- **Minions.** `game/enemies/bug.gd` is a one-hit archetype (any accepted hit kills).
  `missing_transaction.gd` releases `SWARMS` of bugs with each wave; they live in `bugs`,
  never count toward `remaining` or wave completion, bypass the telegraph cap, and
  `_close_bugs()` kills survivors (WONTFIX, logged to the timeline) when a stage's waves
  are done.
- **Overtime crew.** `game/incidents/coworkers.gd` (owned by the incident) poses nine
  recoloured CC0 office workers from `assets/characters/quaternius/` from a `CAST` table
  on routines (asleep, sit, pace, carry, fix, stand with a periodic gesture). No collision. Each
  has one line shown when the engineer walks past; they cower while `battle_mode` is
  engaged and the manager claims credit when a fight ends. `reset()` restores them.
- **Freeze-frames and framing.** `ElementFx.freeze()` drops `Engine.time_scale` for a
  beat on big impacts (Blocker quake, Variance cataclysm, the engineer's finisher hit,
  the boss's defeat) and a real-time timer restores it; the newest freeze owns the
  restore, `release_freeze()` runs on reset, and headless suites skip it unless a test
  opts in. `camera_rig.gd` pulls back slightly with `battle` and, once the mouse has
  rested `assist_delay` seconds mid-fight, eases toward `focus` (the battle director's
  weighted centre of nearby engaged enemies) outside a dead zone; any orbit input
  cancels it.
- **Enemy strikes.** `incident.gd` picks the strike effect from `attack_style` (slash,
  quake, splat, cataclysm; archetypes set it) when the melee window opens: crescent and
  floor fissure, ground slam (`ElementFx.quake`: shockwaves, cracks, debris, dust,
  flash), goo splat, or the boss's twin quakes and fissures. The Meeting Invite drops
  `ElementFx.pillar` onto each booked zone. `ElementFx.tremor` adds rotation-only jitter
  through `camera_rig.add_tremor()`, scaled by the Camera shake preference via
  `impulse_degrees`; `reset_view()` clears it.
- **Battle mode.** `game/incidents/battle_mode.gd`, owned by the incident, watches for an
  ENGAGED enemy. Onset: sting, flash, chromatic split and speed lines from
  `battle_overlay.gdshader` (a CanvasLayer at layer -1, under the HUD). Held: vignette
  and a hotter environment grade (glow, saturation, contrast; `main.tscn` enables
  adjustments), and `Character.battle` lights the engineer's eyes and RGB keyboard
  edges. `reset()` restores the grade on every incident reset.
- **Tests.** New suites: `environment_tests.gd`, `encounter_tests.gd`,
  `interface_tests.gd`. `tests/m12_preview.gd` captures the menu, opening, areas, battle mode,
  roster, UI, finale and cast for visual review.
