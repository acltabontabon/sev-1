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

## Rigged engineer (Quaternius, CC0)

After the creator rejected the native engineer as still too plain for an action game,
the playable engineer became a rigged, animated character on 10 October 2026. The
earlier evaluation (Kenney: idle/run/jump only; Quaternius' newer library behind an
itch.io purchase flow) is superseded by these two direct, account-free CC0 downloads:

| File in `quaternius/` | Source | License |
| --- | --- | --- |
| `casual_male.fbx` (used), `casual2_male.fbx`, `casual3_male.fbx`, `worker_male.fbx`, `suit_male.fbx` (candidates) | Quaternius, "Ultimate Animated Character Pack", [OpenGameArt](https://opengameart.org/content/animated-characters-pack) | CC0 1.0 |
| `casual_female.fbx`, `casual2_female.fbx`, `suit_female.fbx`, `worker_female.fbx` (0.2.38; the pack's `Casual_Female.fbx` etc., renamed) | Same pack, same page; the zip `ultimate_animated_character_pack_by_quaternius.zip` downloaded 11 October 2026 without an account | CC0 1.0 |
| `knight_animations.fbx` (the pack's `KnightCharacter.fbx`, renamed) | Quaternius, "Lowpoly Animated Knight", [OpenGameArt](https://opengameart.org/content/lowpoly-animated-knight) | CC0 1.0 |

Files are unmodified FBX stored with Git LFS; attribution is voluntary
([THIRD_PARTY_NOTICES.txt](../../THIRD_PARTY_NOTICES.txt)). The four unused body
candidates stay for future cast members and cost nothing at runtime.

**Motion.** The office pack has idle, walk, sit, stand, hit, victory and defeat but no
run, roll or weapon motion. The knight shares the same bone names with a taller body,
so `tools/build_engineer_rig.gd` bakes `game/player/engineer_animations.res`: each
knight rotation key is re-expressed relative to the office body's rest pose, position
keys are scaled to the shorter body, scale keys are dropped and run/roll/attack clips
are kept in place (the controller moves the body). Rerun it after reimporting either FBX.

**Look.** `rigged_engineer.gd` swaps in the [developer outfit](hero_outfit/README.md)
(hoodie, gloves, joggers, light-up sneakers, dyed streak) and builds his kit on bone
attachments: glasses, LED headphones, hood and open zip front, `</>` back print, the
"ON CALL (FOREVER)" sticky note, badge reel, smartwatch and a rubber duck. The weapon is
the [Heavy Greatsword](heavy_greatsword/README.md).

**Contract.** `Player/Visual/Character` keeps `reset_pose()`, `defeat()`,
`story_pose`, `sit`, `crouch` and `weapon`. Clips are chosen and scrubbed from
controller state (speed, airborne, dodge elapsed, hurt time, death); nothing uses root
motion. Between swings the keyboard rides in the right fist. During a swing it follows
an authored arc phased on the melee wind-up/active/recovery windows, and two-bone IK
(`TwoBoneIK3D`) pulls the arm onto its grip, so the visible strike matches the damage
window and hit-stop freezes both. The finisher is a full spin. Seated menu/opening
poses hold the end of `SitDown` with IK hands on the desk keyboard.

**Fallback.** `engineer_visual.tscn` and `character_presentation.gd` remain intact;
swapping the `Character` instance in `player.tscn` and `menu_backdrop.tscn` restores
the native look.

**Limits.** Retargeted knight motion on a chibi body is approximate (no finger rig,
some arm interpenetration). There is no foot IK on slopes. The keyboard is oversized
on purpose. Creative acceptance needs a human run.

## Milestone 12 identity pass

Original native geometry from `tools/build_characters.py`, no imports. The engineer
entry now describes the fallback scene; the playable engineer is the rig above.

- **Engineer (fallback):** charcoal open hoodie over the shirt and loose tie, hood bunched behind
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

## Animation libraries (0.2.24)

`animations/ual1_standard.glb` and `animations/ual2_standard.glb` are Quaternius' Universal
Animation Library 1 and 2, Standard editions (CC0 1.0; `License_UAL1.txt`, `License_UAL2.txt`),
from OpenGameArt without an account. They use a different (UE-style / Rigify) skeleton;
`tools/build_engineer_rig.gd` retargets the clips it lists onto the office rig by world-space
rotation from each library's A_TPose, and bakes them into `game/player/engineer_animations.res`.


## Drew restoration (11 October 2026)

Drew (Recruiter) again uses the original Quaternius suit body and shared coworker
motion. The creator requested removal of the human-model trial; its exported art,
scene and build tools are removed. [Restoration checkpoint](../../docs/drew_restoration.md).

## Female office outfits (11 October 2026)

The existing female bodies now use original fitted skirts, blouses/skirt suits and
small earrings. Marie alone has a shorter skirt and lower-cut blouse; Nadia and the
female planted employees retain ordinary office outfits. Original FBX rigs and
hairstyles are preserved. [Source, edits and review](office_outfits/README.md).
