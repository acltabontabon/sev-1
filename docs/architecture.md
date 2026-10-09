# SEV-1 Implemented Architecture

This describes the combat-lab implementation inspected on 10 October 2026. Future story and systems belong in [game design](game_design.md), and sequencing belongs in the [roadmap](roadmap.md). There is no campaign, run-generation framework, persistence layer, or runtime AI service.

## Runtime composition

`project.godot` opens `game/main.tscn`. The project uses Godot 4.7.2 standard, GDScript, Forward+, a 1280×720 development viewport, physics interpolation, and the default 60 Hz physics tick. The launcher enforces the 4.7.2 stable version family. Graphics are configured in the main scene through sky/ambient lighting, directional shadows, local colored lights, SSAO, glow, and light fog.

```text
Main                       game/main.tscn + main.gd
  WorldEnvironment/lights  scene-owned presentation
  MovementLab              rooms/movement_lab.tscn
  Player                   player/player.tscn + player.gd
    Visual/Melee           combat/melee_attack.gd
    Visual/WeaponPivot     procedural baton pose
    CameraRig              player/camera_rig.gd
      SpringArm3D/Camera3D
  Enemy                    enemies/incident.tscn + incident.gd
    Visual/Melee           same melee component, enemy tuning
    Visual/Telegraph       ground arc reuses generated strike mesh
  HUD                      ui/playtest_hud.gd
```

## Responsibilities and contracts

| Owner | Implemented responsibility |
| --- | --- |
| [Main](../game/main.gd) | Connects capture, death, and reset signals. Pauses/resumes the tree and restores both actors in place. R is handled here, including while paused. |
| [Player](../game/player/player.gd) | Camera-relative acceleration, braking, sprint, gravity, jump, visual facing, procedural limb motion, health/invulnerability, attack request, damage/death, and reset. |
| [Camera](../game/player/camera_rig.gd) | Independent yaw, bounded pitch, wheel distance, capture/release, focus-loss release. Spring arm retracts against world geometry and excludes the player. |
| [Melee](../game/combat/melee_attack.gd) | Wind-up/active/recovery timing, one hit per target per swing, cone/range/elevation checks, obstruction ray, strike arc, and optional warning/swing audio. |
| [Enemy](../game/enemies/incident.gd) | Direct pursuit within detection distance, direction committed at attack start, telegraph/recovery, health, flash, short stagger, knockback, defeat, and reset. No navigation agent. |
| [HUD](../game/ui/playtest_hud.gd) | Capture prompt, fighter health, attack state, hit marker, damage flash, and defeat/retry text. Reads the two known actors rather than a general UI data layer. |
| [Room](../game/rooms/movement_lab.tscn) | Authored text scene with static floor/walls, ramp/deck, cabinets, structural props, floor markings, and signage. |

There are no autoloads, custom Resource data files, dedicated health component, animation state machine, or global event bus. Tuning lives in exported script properties and scene overrides. Health belongs to each actor; the only shared gameplay component is melee, justified by its two users.

Melee finds `Node3D` targets through the `players` or `enemies` group. Each must expose `receive_damage(amount, source_position) -> bool`. Accepted damage emits `hit_landed`; actors signal health changes and death, and the player signals hit confirmation, hurt, and reset requests. Calls and node paths assume this small fixed scene composition.

## Damage and timing

The player can start a grounded strike while alive and outside hurt/recovery lockout. Attack start aligns the visual with camera yaw. Facing stays fixed for the strike, movement slows throughout it, and jumping is unavailable during the attack. A second press during recovery is rejected; there is no combo or input queue.

Melee tests target centers at `global_position + Vector3.UP`, not blade-to-mesh collision. It filters planar range and angle, rejects more than one meter of vertical separation, and ray-tests world obstruction. Each target is recorded once per swing. This is a deliberate prototype approximation that needs revisiting if creature scale or elevation demands change.

| Current tuning | Player | Enemy |
| --- | --- | --- |
| Health | 100 | 100 |
| Damage | 25 | 20 |
| Wind-up / active / recovery | 0.12 / 0.12 / 0.28 s | 0.65 / 0.14 / 0.85 s |
| Reach / half-angle | 2.25 m / 65° | 1.85 m / 55° |
| Locomotion | Walk 5 m/s; sprint 8 m/s | Pursuit 2.4 m/s; detection 10 m; attack start within 1.65 m |

Player damage cancels the player's attack and grants 0.65 seconds of invulnerability with 0.16 seconds of hurt slowdown. Enemy damage produces a 0.12-second flash, 0.2-second stagger, and decaying knockback; it does not cancel an already committed attack. Enemy death cancels melee and removes its collision layer. Player death releases capture and pauses the encounter. These numbers are baseline tuning, not permanent design commitments.

## Pause and reset

Main, HUD, and CameraRig process while paused; both fighters are explicitly pausable. Capture changes toggle tree pause. The initial click resumes and is consumed before it can trigger a strike. Escape or focus loss pauses combat and releases the cursor. Headless execution skips focus-loss release.

R restores existing actors' positions, health, attack timers, collision state, and camera, and clears HUD hit/hurt timers. It does not instantiate another opponent. A player falling below the safety threshold requests the same encounter reset; enemy fall recovery resets the enemy. There is no persistent run history. The workstation loop and postmortem are not implemented by this reset code.

## Physics and assets

| Physics layer | Bit | Usage |
| --- | --- | --- |
| World | 1 | Static environment; melee obstruction and camera checks |
| Player | 2 | Player body; its mask is 5, world plus enemy |
| Enemy | 4 | Enemy body; its mask is 3, world plus player |

Text `.tscn` scenes hold primitive meshes, materials, colliders, and lights. Limb/weapon motion is scripted; there is no imported rig or animation library. The arc is a small generated `ImmediateMesh`. Four synthesized WAV effects live in [assets/audio](../assets/audio/README.md), with committed import sidecars and documented provenance. Headless tests skip sound playback because the dummy audio path did not drain reliably on test exit. Sound quality still requires graphical listening and human feedback.

Keep `.uid` and asset `.import` sidecars with their sources. `.godot/`, builds, and logs are ignored. Git text files use LF; large binary asset intake should establish LFS and remote support before committing substantial art libraries. No such library, export preset, or CI configuration exists yet.

## Validation and limits

`python3 tools/validate.py` invokes the pinned launcher, imports resources, parses all game/test scripts, then runs `tests/run_tests.gd` and `tests/combat_tests.gd` at fixed 60 Hz without real-time waiting. Each command has a 120-second deadline; both exit status and recognized engine/script errors can fail the run. Logs are written under `logs/`.

The last existing results from 10 October 2026 report 16 movement and 29 combat assertions passing. Coverage includes actual attack bindings, timing, one hit per strike, obstruction/direction/elevation, invulnerability, enemy tells/evasion, death, pause, and repeated reset. Movement tests disable the opponent to isolate locomotion. Combat tests combine controlled actor placement with active enemy behavior; they are not full human play sessions.

`tests/capture_preview.gd -- --combat` stages a reproducible graphical shot and writes an ignored preview. It deliberately overrides capture-driven pause during setup, freezes the action, and cleans up paused audio on exit. That staged image is useful for visual inspection, not evidence of normal encounter pacing.

Known limits: direct enemy pursuit can stick on obstacles; art/animation and sounds are placeholders; no dodge, combos, progression, narrative sequence, export validation, sustained performance benchmark, or Windows runtime test is present. The provisional 60 fps at 1080p aspiration is not a measured release guarantee. Preserve the current playable while addressing these through the roadmap's separate gates.
