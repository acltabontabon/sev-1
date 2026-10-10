# Character presentation provenance and replacement

Milestone 5, 10 October 2026: all shipped character/weapon geometry is original,
AI-assisted procedural authoring for SEV-1 in `tools/build_characters.py`. No model,
texture, motion-capture file, or commercial-game asset was downloaded. No third-party
art license or attribution obligation has been introduced. These native primitives
are **provisional models, not finished human artwork or a skeletal animation set**.

Regenerate only the two authored visual scenes with:

```sh
python3 tools/build_characters.py
```

The engineer uses a blue-gray rolled-sleeve shirt, loose tie, glasses, ID badge,
dark trousers/shoes, and an oversized keyboard with a metal casing and restrained
cyan edges. The corrupted record consists of misregistered ledger slabs, status
rows, an offset head, and long arms. Shared materials and geometry are text resources.
The generator owns `game/player/engineer_visual.tscn` and
`game/enemies/record_visual.tscn`; edit the generator before regenerating them.
No new renderer, light, shader, particle system, or runtime asset download is required.

## Sources evaluated, not imported

- [Kenney Animated Characters Protagonists](https://kenney.nl/assets/animated-characters-protagonists)
  lists eight 3D files under CC0. It is a practical rig/locomotion evaluation source,
  but its skater/cyborg/criminal direction is not the selected office employee.
  Inspect one candidate and its bundled license before bringing it into the project.
  Kenney's [support page](https://kenney.nl/support) says attribution is optional for
  its CC0 game assets.
- [Adobe Mixamo FAQ](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html)
  permits royalty-free character/animation use in games and requires an Adobe ID.
  Human selection/login is needed for a coherent set: idle, walk, run, two horizontal
  melee swings, a heavier finisher, dodge, hit reaction, and death on the same biped.
  No account access or download was performed. Review the actual asset/license terms
  before intake; royalty-free does not mean CC0 or unrestricted standalone resale.
- Enemy models and effects: the original fractured-record geometry and existing
  eight-mesh impact pool are more specific to this incident than an unrelated monster
  pack. Keep them until a commissioned or clearly licensed coherent replacement is
  selected. No third-party effect dependency is needed.
- Audio: the current eight effects are original synthesis; see
  [audio provenance](../audio/README.md). Recorded office footsteps, key rattle, and
  layered metal/plastic impacts are the next sound-quality priority after listening.

Source pages checked on 10 October 2026. Recommendations are asset candidates, not
claims of successful import, rig compatibility, or completed animations.

## Integration contract for a selected rig

1. Establish Git LFS before substantial binary intake. Record author, source URL,
   exact license, attribution, modifications, and retrieval date with the files.
2. Import one self-contained GLB character at meter scale, feet at origin, forward −Z.
   Keep textures together and preserve `.import` sidecars. Inspect materials in this
   office, not only in a separate viewer.
3. Wrap the selected model under `Player/Visual/Character`. Keep the current native
   scene as the default fallback until the replacement parses and passes validation.
   The wrapper must expose `reset_pose()` and `defeat()`; replace the internal native pose implementation together with its scene. No optional external file is
   currently required, and there is no runtime downloading or missing-file loader.
4. Drive in-place animation from actual displacement, grounded state, dodge elapsed
   time, hurt state, and `Melee.elapsed`/phase durations. The controller retains all
   movement and damage authority. Do not enable root motion or animation damage calls.
5. Map the three attack clips to the existing wind-up/active/recovery windows and
   attach the weapon to the hand bone. Preserve camera-directed facing, cone reach,
   interruption, one hit per target, and actor-local hit-stop. Match weapon pose and
   visible reach before removing the readable strike arc.
6. Exercise idle/walk/run/turn, wall contact, jump, all combo transitions, canceled
   anticipation, dodge travel/recovery, hit-stop, hurt/death, and repeated R. Run
   `python3 tools/validate.py`, inspect actual frames, listen, and rerun the 1080p
   incident benchmark. Keep the native scene if any required imported asset is missing.

## Known art and motion limits

Geometry remains simple and facial detail minimal. The gait has distance-driven
stance and two-segment limb placement, but no floor sampling, planted-foot turning,
terrain IK, skeletal retargeting, or root motion. Fast turns, slopes, and attack
movement can still slide. Arms follow a procedural grip with approximate joints;
there is no finger rig. Death sets a settled pose immediately because incident reports
pause immediately; there is no animated fall. No heavy-attack input was introduced;
the existing third combo step is the finisher. Creative acceptance needs a human run.

## Milestone 12 rig evaluation (10 October 2026)

The creator approved trying a CC0 rigged character in Phase F. Evaluated, not imported:

- Kenney Animated Characters (Protagonists), CC0, direct download: one `characterMedium`
  rig with only `idle`, `run` and `jump` clips. No attacks, dodge, hit, death or
  seated/typing motion, so combat, the menu desk and the opening would all still need
  the native procedural poses on a body that no longer matches them.
- Quaternius Universal Animation Library and modular characters, CC0: distributed only
  through an itch.io purchase flow, which was not automated.
- Mixamo: excluded; it requires an account.

Decision: keep the native engineer. Milestone 12 instead added authored full-body
holds to `character_presentation.gd` (seated typing, relaxed, frozen alert, slump, sip,
glance, armed) that the menu and the opening stage. A coherent office-worker rig with
combat and seated clips remains the recommended future upgrade behind the existing
wrapper contract.

## Milestone 12 identity pass

Still original native geometry from `tools/build_characters.py`, no imports:

- **Engineer:** charcoal open hoodie over the shirt and loose tie, hood bunched behind
  the neck, over-ear headphones around the neck with glowing cups, bed-hair tufts, a
  coffee stain, sneakers with orange soles, and a sticky note on his back reading
  "ON CALL (FOREVER)" that the gameplay camera sees all run. The keyboard weapon gains a
  red Esc key and a dangling cable.
- **Corrupted Record:** a loading halo that never finishes, its own ledger pages
  orbiting it, glowing fractures and a receipt hanging from its mouth.
- **The Blocker, The Meeting Invite, Scope Creep:** new generated silhouettes
  (`blocker_visual.tscn`, `meeting_invite_visual.tscn`, `scope_creep_visual.tscn`).
- **The Variance:** a crown of three orbiting status screens (SUCCESS, FAILED,
  NOT FOUND) and a split cyan/red body, built by `variance.gd` on the record rig.
