# Enemy bodies (Quaternius, CC0)

Retrieved 10 October 2026 from OpenGameArt without an account, after the creator said
the enemies "still look like boxes". All are CC0 1.0 (public domain dedication;
`License.txt` in each archive); attribution is voluntary
([THIRD_PARTY_NOTICES.txt](../../THIRD_PARTY_NOTICES.txt)). FBX and textures are
unmodified apart from lowercase file names, stored with Git LFS.

| File in `quaternius/` | Source | Worn by |
| --- | --- | --- |
| `stan.fbx`, `stan_texture.png` | "Animated Mech Pack" (March 2021), [OpenGameArt](https://opengameart.org/node/126992) | Corrupted Record |
| `leela.fbx`, `leela_texture.png` | same pack | The Blocker (carries the BLOCKED sign) |
| `george.fbx`, `george_texture.png` | same pack | The Meeting Invite (the invite card hovers above it) |
| `mike.fbx`, `mike_texture.png` | same pack | The Variance (3.1 m, crown of status screens) |
| `slime.fbx` | "LowPoly Animated Monsters", [OpenGameArt](https://opengameart.org/content/lowpoly-animated-monsters) | Scope Creep (sticky notes plastered on it; grows) |

Also evaluated in the office and not imported: the pack's skeleton, bat and dragon,
the "Textured Cute Monster Pack" (too toy-like next to the mechs) and the 2018
"Animated LowPoly Robot".

**How they are used.** `game/enemies/monster_rig.gd` (`MonsterRig`) instances the
model under each enemy's `Visual`, scales it to a set height and plays its own clips
from the enemy's state: idle/walk/run from pursuit speed, the attack clip scrubbed so
its impact frame lands at the end of the melee wind-up, hit on stagger, a raised-arm
clip for casts, and death (then a dissolve) on defeat. Nothing uses root motion and the
rig never moves the body or deals damage. `corruption.gdshader` keeps the original
texture and adds a rim, crawling glitch bands in the archetype's spell colour, a hit
flash and a bright charge during the telegraph. Setting `rig_kind = ""` on an enemy
restores the native box geometry, which is kept as a fallback.

**Limits.** The mech clips (sword slash, punch, kick) are generic; they read as
attacks but were not authored for these jokes. Arc reach and damage are unchanged, so
the visible limb does not exactly trace the telegraph arc. The Slime has no hit clip.
