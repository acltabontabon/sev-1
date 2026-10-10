# Enemy bodies (CC0)

Retrieved 10 October 2026 from OpenGameArt without an account. All are CC0 1.0
(public domain dedication); attribution is voluntary
([THIRD_PARTY_NOTICES.txt](../../THIRD_PARTY_NOTICES.txt)). Files are unmodified apart
from lowercase names; textures embedded in the GLB files are extracted by Godot's
importer next to them. Everything is stored with Git LFS.

| File | Source | Worn by |
| --- | --- | --- |
| `quaternius/skeleton.fbx` | Quaternius, "LowPoly Animated Monsters", [OpenGameArt](https://opengameart.org/content/lowpoly-animated-monsters) | Corrupted Record (a zombie transaction that claws out of the floor) |
| `quaternius/brute.glb` (`Enemy Large`) | Quaternius, "Ultimate Space Kit", [OpenGameArt](https://opengameart.org/node/155017) | The Blocker (carries the BLOCKED sign) |
| `quaternius/bat.fbx` | "LowPoly Animated Monsters" | The Meeting Invite (invite card overhead) |
| `quaternius/slime.fbx` | "LowPoly Animated Monsters" | Scope Creep (sticky notes plastered on it; grows) |
| `quaternius/dragon.fbx` | "LowPoly Animated Monsters" | The Variance (3.4 m, crown of status screens) |
| `bug/bug.glb` | CDmir, "Alien Bug Animated", [OpenGameArt](https://opengameart.org/content/alien-bug-animated) | BUG minions (one-hit swarms) |

History: 0.2.2 used four mechs from Quaternius' "Animated Mech Pack". The creator
said some enemies did not read as monsters, so 0.2.4 replaced them with the bodies
above; the mech files left the tree. Also evaluated and not used: the "Textured Cute
Monster Pack" (toy-like), the 2018 "Animated LowPoly Robot", and Quaternius' "Ultimate
Monsters" (its Google Drive download was over quota on the day).

**How they are used.** `game/enemies/monster_rig.gd` (`MonsterRig`) instances the model
under each enemy's `Visual`, scales it to a set height (flying kinds hover), keeps the
model's own materials and adds `corruption.gdshader` as an additive overlay pass: a
faint rim in the archetype's colour, a bright charge while the attack winds up, a hit
flash and a glow as the corpse sinks. Clips are played from the enemy's state: the
skeleton's spawn while manifesting, locomotion from pursuit speed, the attack scrubbed
so its impact frame lands at the end of the melee wind-up, hit on stagger, a cast
clip for spells, then death (or, for a bug, a squash) and a sink through the floor.
Nothing uses root motion and the rig never moves the body or deals damage. Setting
`rig_kind = ""` on an enemy restores the native box geometry, kept as a fallback.

**Limits.** Attack clips are stock bites, punches and swipes, so limbs do not trace
the telegraph arc exactly. The slime, skeleton and bug have no hit-reaction clip.
