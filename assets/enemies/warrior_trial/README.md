# Skeleton Warrior vault trial — 11 October 2026

Creator authorized a bigger Skeleton Warrior with darker armor beside the engineer
in the actual server vault. Isolated visual trial; normal boss/encounter behavior
is unchanged.

Source: Kay Lousberg's [KayKit Character Pack: Skeletons 1.0](https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0),
revision `15b62b9bad122f72926c10fb14d622c73819fa54`,
`addons/kaykit_character_pack_skeletons/Characters/gltf/Skeleton_Warrior.glb`.
Licensed [CC0 1.0](license.txt), free commercial use; attribution optional.
Original GLB retained, Git LFS. Runtime presentation only: uniform scaling to
3.6 m (helmet included), darker neutral armor palette under a local shader,
original bone/cloth colors, supplied idle/walk/attack animations. No new combat,
AI, statistics, hit timing, progression or save writes.

## Review

Double-click [warrior_vault_trial.command](../../../warrior_vault_trial.command),
or run `sh tools/godot.sh --path . --script tests/warrior_vault_preview.gd`.
1 compares with the current engineer; 2 frames the boss. I/W/A play idle/walk/axe
chop, D toggles the dark/original armor palette, Space orbits and Esc closes.
Animation is displayed in place; movement, attack damage and boss mechanics are
not connected. Axe and large shield are the matching CC0 accessories from the same
pack, attached to its hand slots. No new story crown or effects are added.

`-- --capture` saves ignored idle, close-up, walk, chop and original-palette PNGs
under `builds/`. Godot imports and rendered captures passed on Apple M2 Pro,
Godot 4.7.2, Metal Forward+, 1920×1080. Visuals were inspected in those views;
this is not a gameplay performance benchmark or human acceptance. Full gameplay
validation is not claimed because this trial changes no gameplay scripts.

The unscaled bound height is 2.590 m; uniform scale 1.390 gives a 3.600 m bind
height including the helmet. Motion can change the visible height. The local
armor shader identifies neutral atlas colors and darkens them to charcoal;
it preserves the yellow bone/red cloth ramps and original emissive eyes.
The shader also darkens neutral colors on the axe/shield. D is a palette comparison
under that shader, not an exact copy of the original material's lighting response.

Creator checkpoint: judge size beside the engineer, armor visibility in the vault,
axe/shield silhouette, and whether the stylized skull feels threatening enough.
Adopting this as the actual boss is a separate creative decision.

## Selection update

The creator explored a free golem-style modification of the Warrior, then chose
on 11 October 2026 to keep the KayKit skeleton family for regular monsters and
search for a separate free boss asset. This preview is not selected for the boss.
Normal encounters have not been changed by this work.

The optional G toggle shows original AI-assisted armor geometry authored locally:
chamfered shoulder/forearm/chest/boot plates, broader/deeper proportions, smaller
skull, and a larger axe. Source Warrior geometry and supplied clips are unchanged.
Added armor follows bone attachments; the smaller head is a local presentation
pose adjustment after animation. It is a prototype, not the paid KayKit Golem.
Idle, walk and axe-chop captures completed in Godot 4.7.2, Metal Forward+, 1920×1080
on Apple M2 Pro. Breastplate/scarf contact and attached shoulder motion still need
human inspection in continuous motion. Golem mode starts disabled and no version
of this preview is connected to The Variance's gameplay.
