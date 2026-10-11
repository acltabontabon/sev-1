# Enemy bodies

The creator-authorized [free demon variation trial](demon_trials/README.md) now
alternates Night Demon and Chained Demon on Corrupted Records. Both use CC BY 3.0
with required attribution, original textures, and provisional local motion clips.
The Quaternius bodies below remain the other archetypes and the record fallback.

## Quaternius "Ultimate Monsters", CC0

The original consistent roster uses Quaternius' **Ultimate Monsters** pack (50 animated
monsters, glTF), CC0 1.0. The pack's official download is a public Google Drive folder
linked from [quaternius.com](https://quaternius.com/packs/ultimatemonsters.html). On 10
October 2026 that folder answered every request with "quota exceeded", so the files
were retrieved without an account from a public GitHub repository that vendors the
complete pack unchanged: [mika314/KitchenSink](https://github.com/mika314/KitchenSink)
(`Assets/Ultimate Monsters/`, 50 glTF files plus the author's `License.txt`). That
`License.txt` is copied here. It states CC0 1.0 Universal; its header names a different
Quaternius pack ("Ultimate Platformer Pack"), apparently a reused template, and the
pack page itself also states CC0. Attribution is voluntary
([THIRD_PARTY_NOTICES.txt](../../THIRD_PARTY_NOTICES.txt)). Files are unmodified apart
from lowercase names, and are stored with Git LFS.

| File in `ultimate_monsters/` | Pack file | Worn by |
| --- | --- | --- |
| `orc_skull.gltf` | `Big/glTF/Orc_Skull.gltf` | Corrupted Record (skull-faced, spiked club) |
| `yeti.gltf` | `Big/glTF/Yeti.gltf` | The Blocker (carries the BLOCKED sign) |
| `dragon.gltf` | `Flying/glTF/Dragon_Evolved.gltf` | The Meeting Invite (invite card overhead) |
| `spiky_blob.gltf` | `Blob/glTF/GreenSpikyBlob.gltf` | Scope Creep (sticky notes on it; grows) |
| `demon.gltf` | `Big/glTF/Demon.gltf` | The Variance (halo and horns: two truths at once; trident) |
| `squidle.gltf` | `Flying/glTF/Squidle.gltf` | Quick Sync stand-up facilitator (winged, bone-horned; dark palette) |
| `armabee.gltf` | `Flying/glTF/Armabee_Evolved.gltf` | BUG minions (one-hit swarms; a literal bug) |

History: 0.2.2 used Quaternius mechs; 0.2.4 used a mix of smaller CC0 packs (skeleton,
alien brute, bat, slime, dragon, CDmir's alien bug) while this pack was unreachable.
0.2.5 replaced all of them with this single pack so the cast shares one art style; the
earlier files left the tree.

**How they are used.** `game/enemies/monster_rig.gd` (`MonsterRig`) instances the model
under each enemy's `Visual` at a fixed scale (this pack shares one authoring scale, and
skinned bounds understate the flyers), replaces the pack's flat colours with a dark
flesh skin (`monster_flesh.gdshader`, palette in `MonsterRig.PALETTE`; blood spreads as
they are hurt) and adds `corruption.gdshader` as an additive overlay pass: a charge in the
archetype's colour while the attack winds up, a hit flash and an ember as the corpse
dissolves. The models themselves are unchanged CC0 files.
Clips play from the enemy's state: locomotion from pursuit speed, the attack scrubbed so
its impact frame lands at the end of the melee wind-up, hit on stagger, a cast clip for
spells, then death and a sink through the floor. Nothing uses root motion; the rig never
moves the body or deals damage. Setting `rig_kind = ""` on an enemy restores the native
box geometry, kept as a fallback.

**Limits.** Attack clips are the pack's generic weapon swings, punches, bites and
headbutts, so limbs do not trace the telegraph arc exactly.

The stand-up facilitator was retrieved from the same public pack mirror on 11 October
2026. The embedded-buffer glTF is unchanged; its material palette and scale are applied
in `MonsterRig` at runtime. The existing CC0 license and voluntary credit cover it.
