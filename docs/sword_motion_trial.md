# Free sword motion trial — 11 October 2026

Implemented local playtest candidate by creator request. The engineer's sword
cuts now sample skeletal combat motion rather than playing locomotion beneath
procedural arm poses. This refines the existing combo and skills; it adds no moves.

| Move | Body motion |
| --- | --- |
| First combo cut, Reply All, matching ultimate cuts | Kevin Iglesias `Attack2H01` when locally installed; Quaternius `Sword_Regular_A` otherwise |
| Spinning backhand, Circle Back, counter riposte | Quaternius `Sword_Regular_A` under the existing full-body turn |
| Blame Shift during travel | Quaternius `Sword_Dash_RM`, with horizontal source travel removed |
| Leaping finisher and ultimate slam | Existing retargeted Quaternius Knight `swordAttackJump` |
| Works On My Machine anticipation | Quaternius `Sword_Block`, held with a two-handed guard |

Wind-up, strike and recovery map to source clip phases on the existing melee clock.
Hit-stop freezes that sampling. Immediate skill contact finishes the animation
blend before the impact hold. Authored sword arcs and two-bone hand IK still place
the blade on its damage window; both hands now grip the regular cuts. The clips
supply body weight transfer, with smaller procedural torso/drop corrections.
Controller movement, damage, cooldowns, combo buffering and dodge are unchanged.
The finisher camera samples the same motions without restarting idle every frame.

Visual review rejected Quaternius Sword B for the spin: its forward dive read as
a face-plant on the short engineer. Sword A gives the turn a more upright stance.
The third attack retains its stylized leap and deep landing; creator review decides
whether that reads as weight or excessive folding. This is still the current CC0
engineer body, not a character replacement.

## Source rights and local installation

Kevin's free attack is royalty-free for game use, **not CC0**. This repository is
public, so its original FBX and derived animation resource stay local and ignored
by Git. A fresh checkout uses the CC0 fallback without requiring that download.
The original FBX is excluded from both platform exports; an installed derived
resource can be incorporated in the compiled game. See the
[source, license, checksum and rebuild steps](../assets/characters/kevin_trial/README.md).
Existing Quaternius assets retain their [CC0 records](asset_licenses.md).

## Verification and creator checkpoint

`python3 tools/validate.py` includes `tests/sword_motion_tests.gd`: real-controller
checks for torso motion, stationary controller root, both hands at contact,
hit-stop, damage cancellation, counter guard and reset, with and without Kevin.
The existing skill-impact suite verifies actual damage timing and no extra hits.
Headless tests cannot establish feel, audio, performance or visual quality.

Validation on 11 October 2026: the full `tools/validate.py` suite passed, including
the new sword-motion checks and existing movement, combo, skill-impact, incident,
finisher, story and retry coverage. The graphical rig probe and skill-impact probe
also completed without failures; their rendered poses were inspected. No performance
measurement, ordinary listening acceptance, packaged build or Windows run was done.

Graphical probes:

```sh
sh tools/godot.sh --path . --script tests/rig_preview.gd
sh tools/godot.sh --path . --fixed-fps 60 --script tests/skill_impact_tests.gd -- --preview
```

Their ignored `builds/rig_states.png` and `builds/skill_*.png` show rendered poses.
They are staged verification, not a normal run or a performance measurement.

Launch the source game with `sh tools/godot.sh --path .`, choose Acknowledge Incident,
and try left-click/F for the combo, C for Reply All, X for Blame Shift, Z for Circle
Back, G for the counter, and V for Force Rollback once FOCUS fills. Dodge with right
mouse/Q, and use R for a quick retry. Check whether the sword feels heavier, the spin
stays readable, the leap lands convincingly, and recovery into dodge/run feels smooth.
Human acceptance and Windows runtime review remain open. No release was rebuilt.
