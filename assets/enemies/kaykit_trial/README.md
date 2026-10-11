# KayKit Skeleton Minion — 11 October 2026

Skeleton Minion from **KayKit Character Pack: Skeletons 1.0**, created by
**Kay Lousberg**. Free tier from the creator’s
[official repository](https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0),
revision `15b62b9bad122f72926c10fb14d622c73819fa54`.
[Pack page](https://kaylousberg.itch.io/kaykit-skeletons).

Licensed **CC0 1.0 Universal**: [bundled source license](license.txt).
Attribution is optional; credit to Kay Lousberg is retained in the notices.
Source paths, retrieval date and SHA-256 hashes: [provenance.json](provenance.json).
Only one free character is included; no paid extras, accessories or plugins.
The GLB embeds its gradient atlas, rig and original animations and is unmodified.
Godot extracts that atlas to `skeleton_minion_skeleton_texture.png` during import;
the generated sidecar's hash is also recorded in provenance.

## Visual review

Double-click `kaykit_trial.command` in the repository root, or run:

```sh
sh tools/godot.sh --path . game/art_trials/kaykit_comparison.tscn
```

The trial shows the actual engineer and one Skeleton Minion in the office lounge,
using the existing office environment and lights. It starts at the author’s original
model size; the optional height-matching toggle remains available for comparison.
Use the buttons (or 1–3) for idle/walk/attack and F/S/B for front/side/back.
Escape closes the viewer. Append `-- --capture` for an ignored 1080p screenshot.

The creator accepted this comparison and authorized replacing the two realistic
demon variants on Corrupted Records. The comparison viewer remains isolated; the
normal game now uses this body through `MonsterRig.KINDS.record`.

Original KayKit materials (atlas and emissive eyes) are preserved without the
monster flesh shader. The additive combat overlay retains telegraph charge, hit
flash and corpse glow; external blood sprays/pools and waist slices/tumbles remain.
The clean cartoon skin does not receive the old procedural flesh/blood staining.
The punch, walk/run, hit and death clips are supplied by KayKit. Punch contact is
sampled at approximately 0.54 seconds (37% of the source clip) and scrubbed to the
existing melee windup/active/recovery windows. No damage, reach, movement, awareness,
AI, dialogue, wave or input tuning changes. The record uses original imported scale
1.0, without height matching or the shared 10% presentation increase. Its standing
height metadata is 2.166 m; collision dimensions are unchanged.
Waist cuts use the imported `spine` and `upperleg.l/r` hierarchy.

The engineer retains the current body, sword and idle presentation, including the
local sword trial when present.

Creator checkpoint: compare proportions, skull silhouette and material brightness
beside the engineer; inspect the walk and punch in a normal encounter.

## Rendered evidence

Idle, side-view walk and punch were inspected in the actual office renderer on
Apple M2 Pro, Godot 4.7.2, Metal Forward+, 1920×1080 with existing SSAO/glow/fog.
Bind mesh bounds measure 2.128 m for the engineer and 2.166 m for the minion;
the optional matched-height mode uses uniform scale 0.982. The accepted default
now retains the original imported size in both gameplay and this viewer.
After 90 warm-up frames, 120 sampled staged frames averaged 8.34 ms with p95
8.54 ms in the final gameplay-idle comparison (presentation/vsync included).
This measures an isolated two-character review, not moving gameplay performance.
Audio was disabled in the staged comparison; current combat checks are listed below.
Human moving-combat and death-presentation acceptance remains open.
Ignored captures: `builds/kaykit_comparison.png`, `kaykit_comparison_walk_side.png`
and `kaykit_comparison_punch.png`.
`python3 tools/validate.py` passed the complete import, script parsing and gameplay
integration suite on 11 October 2026 with the concurrent local sword trial present.
The final comparison script also passed its separate `--check-only` run and rendered
smoke runs after the protagonist was switched to its normal gameplay idle stance.

## Combat checkpoint

Launch the normal game with `sh tools/godot.sh --path .` (or `play.command`), start
Stage One, and use TAB to skip the opening if desired. Corrupted Record waves now
show skeletons; the other enemy archetypes are unchanged. Check chase footwork,
punch/telegraph contact, stagger, waist cuts and tumbles. R retries the incident.

Regression: `sh tools/godot.sh --headless --path . --script tests/skeleton_tests.gd`.
Outcome checks cover real wave spawning, retained materials and bark identity,
windup safety, one active hit, misses outside reach, incoming damage, physical
cuts and individual/full retry cleanup. `tests/skeleton_preview.gd` captures the
actual gameplay rig in office light; `-- --pose=attack` or `-- --pose=gore` select
contact and physical death. Ignored evidence: `builds/skeleton_combat_attack.png`
and `builds/skeleton_combat_gore.png`. Headless and staged renders do not establish
fun, ordinary moving-combat performance or human acceptance.

The full `python3 tools/validate.py` suite passed after the replacement on
11 October 2026. The final focused skeleton checks passed separately, including
the real melee clock driving the contact pose. One earlier test fixture paused
itself by clearing its last enemy; retaining a spare enemy corrected that fixture
without changing runtime behavior. Contact and physical cut captures were reviewed
on Apple M2 Pro, Godot 4.7.2, Metal Forward+, 1920×1080 with the existing office
SSAO/glow/fog. These renders do not measure ordinary moving-combat performance.

Original-size follow-up: rendered the runtime punch beside the engineer at scale
1.0 and passed all 54 focused skeleton assertions, including spawn/retry size.
The full validation run passed `skeleton_bodies`, then failed `sword_motion` with
player sword-trail errors (`emitting`/`sample` on MeshInstance3D) during concurrent
weapon-trail work. The separate focused run also logged those player errors; its
skeleton assertions passed, but the current whole-game suite is not clean.
