# SEV-1 Implemented Architecture

This describes Office After Hours and Incident 001, implemented on 10 October 2026. Future story and systems belong in [game design](game_design.md), and sequencing belongs in the [roadmap](roadmap.md). There is no campaign, run-generation framework, persistence layer, or runtime AI service.

## Runtime composition

`project.godot` opens `game/incidents/missing_transaction.tscn`, which inherits `game/main.tscn` and adds a local Incident controller. The base scene still launches the single-enemy regression arena. The project uses Godot 4.7.2 standard, GDScript, Forward+, a 1280×720 development viewport, physics interpolation, and the default 60 Hz physics tick. The launcher enforces the 4.7.2 stable version family. Graphics are configured in the main scene through sky/ambient lighting, directional shadows, local colored lights, SSAO, glow, and light fog.

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
    Visual/WeaponPivot     procedural baton pose
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
| [Main](../game/main.gd) | Connects capture, death, and reset signals. Delegates episode death/reset when Incident exists, otherwise restores both lab actors. Guards terminal capture. R works while paused. |
| [Player](../game/player/player.gd) | Camera-relative acceleration, braking, sprint, gravity, jump, visual facing, procedural limb motion, health/invulnerability, attack request, damage/death, and reset. |
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

Player damage cancels the player's attack and grants 0.65 seconds of invulnerability with 0.16 seconds of hurt slowdown. Enemy damage produces a 0.12-second flash, 0.2-second stagger, and decaying knockback; it does not cancel an already committed attack. Enemy death cancels melee and removes its collision layer. Player death releases capture and pauses the encounter. These numbers are baseline tuning, not permanent design commitments.

## Dodge and impact

Q/right mouse starts a grounded dodge in camera-relative movement direction; stationary input defaults backward. Travel is 3 m over 0.24 seconds, followed by 0.32 seconds recovery. Invulnerability is [0, 0.18) seconds and is independently configurable. World collisions shorten travel. During dodge and its recovery, attacks, jumping, and another dodge are unavailable. Dodge cannot bypass an active strike or hit-stop; it can cancel attack wind-up and recovery. The cyan aura marks invulnerability, not the whole dodge. Damage ends the dodge and restores the proxy pose.

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

Text `.tscn` scenes hold primitive meshes, materials, colliders, and lights. Limb/weapon motion is scripted; there is no imported rig or animation library. The arc is a small generated `ImmediateMesh`. Four synthesized WAV effects live in [assets/audio](../assets/audio/README.md), with committed import sidecars and documented provenance. Headless tests skip sound playback because the dummy audio path did not drain reliably on test exit. Sound quality still requires graphical listening and human feedback.

Keep `.uid` and asset `.import` sidecars with their sources. `.godot/`, builds, and logs are ignored. Git text files use LF; large binary asset intake should establish LFS and remote support before committing substantial art libraries. No such library, export preset, or CI configuration exists yet.

## Validation and limits

`python3 tools/validate.py` invokes the pinned launcher, imports resources, parses all game/test scripts, then runs `tests/run_tests.gd`, `tests/combat_tests.gd`, and `tests/alpha_tests.gd`, `tests/office_tests.gd`, and `tests/incident_tests.gd` at fixed 60 Hz without real-time waiting. Each command has a 120-second deadline; both exit status and recognized engine/script errors can fail the run. Logs are written under `logs/`.

The 10 October 2026 results report 138 assertions passing: 16 movement, 29 combat, 40 alpha, 9 office, and 44 incident. Import and all script checks also pass. Coverage includes actual attack bindings, timing, one hit per strike, obstruction/direction/elevation, invulnerability, enemy tells/evasion, death, pause, and repeated reset. Movement tests disable the opponent to isolate locomotion. Combat tests combine controlled actor placement with active enemy behavior; they are not full human play sessions.

`tests/capture_preview.gd -- --combat` stages a reproducible graphical shot and writes an ignored preview. It deliberately overrides capture-driven pause during setup, freezes the action, and cleans up paused audio on exit. That staged image is useful for visual inspection, not evidence of normal encounter pacing.

Known limits: furniture and characters still use simplified native geometry; art/animation and sounds are provisional; no progression, export validation, long-duration performance soak, or Windows runtime test is present. The office 1080p Forward+/Metal measurement on M2 Pro averaged 119.36 FPS, with median/p95/max frame times of 8.27/10.65/67.43 ms (2,388 samples, five-second warm-up excluded). The maximum includes an unexplained isolated hitch. `tests/office_preview.gd -- --measure` reproduces the 25-second elevated-health combat scenario and captures images outside measurement; see README. This is not a release performance guarantee. Preserve the current playable while addressing these through the roadmap's separate gates.

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

The inherited lab enemy is hidden, disabled, and removed from the melee target group. Original player, enemy, melee, camera, office geometry, navigation, and tuning files are unchanged. A seven-second alert runs only during active play; a two-second arrival delay puts the first enemy in play around nine seconds. Exported counts default to two first-encounter records and three second-encounter records, arriving one at a time. The second encounter changes only pursuit speed from 2.4 to 3.4 m/s. Arrivals use the farthest of three clear floor sites, a short delay, and existing spark effects. Defeated records retain a non-colliding collapsed pose; their total is bounded by authored counts and all are freed on reset.

Investigation requires the player within four meters of the operations marker at (−1.7, 0, −12.5). E exposes three evidence lines; physical keys 1/2/3 select a system. Incorrect selections increment a report counter and provide an additional plain-language clue, without damage or progression. Payment Processing (3) advances the incident. Input is blocked while paused and key echoes are ignored. No financial calculation is required.

`game/incidents/variance.gd` extends only the existing enemy implementation. The Variance has 700 health, the original telegraph/attack timing, and an eight-second repeating pattern: 4.5 seconds pursuing/attacking while shielded, then 3.5 seconds stationary and OPEN. Opening cancels its swing and accepts normal player damage; shielding rejects it. Its solid physical diamond, solid text diamond, and VERIFIED ORIGINAL marker remain consistent. On first reaching half health, exactly two non-colliding, non-attacking translucent silhouette projections appear, marked with hollow diamonds. They are visual decoys, not additional melee targets, and never multiply. This deliberately simple cue/decoy experiment needs human acceptance. Boss defeat retains the existing collapse pose and removes projections; there is no imported boss animation.

The incident controller processes while paused only to settle environmental light changes. Gameplay elapsed time, spawn delays, and transitions stop while paused. All gameplay timing is local elapsed state, not scheduled callbacks. Terminal states cancel melee, release capture, show a deterministic report, and block resumption until R resets. The whole tree remains paused on the report; incident spill settles smoothly, and recovered dashboard signage/strip changes toward green. Restart resets that light immediately to its opening value, clears reports/evidence/counters, removes every spawned actor/projection, and restores the player and camera. A fresh scene load also resets everything; nothing persists between runs.

`tests/incident_tests.gd` exercises actual E/number/F/R input plus controlled damage to traverse lifecycle cases quickly: early combat, illegal transitions, completion, duplicate death, wrong/correct evidence, speed escalation, shielded/open boss damage, actual player melee against the boss, bounded copies, victory/death cleanup, terminal capture, repeated restart node/signal counts, environmental reset, and fresh scene reload. Controlled damage is test staging, not proof of full-run balance. `tests/incident_preview.gd` captures staged intro/evidence/boss/reports and optionally measures a 25-second high-health boss/copies scenario. README records settings and measured frame times. Headless validation does not establish audio quality, ordinary run duration, or fun.

Known episode limits: the 5–10-minute target is unverified by a human run; expert runs may be shorter. Only one damaging enemy is active at a time. Copies are harmless projections. Health carries through the full episode with no upgrades or healing system. Characters, effects, sound, and report presentation remain prototype assets. No full Circle I boss, persistent progression, additional floor, Windows runtime test, or release build is included.
