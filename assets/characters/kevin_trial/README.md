# Local free sword animation trial

Kevin Iglesias, **Human Melee Animations FREE**, Godot/Unreal edition.
Retrieved 11 October 2026 from the creator's [itch.io page](https://kevdev.itch.io/human-melee-animatons-free), using the no-donation download.
Archive: `Human Melee Animations FREE.zip`, SHA-256
`bcd47d323e40419d4dda188d51bd5d91021e6ca42d8dc0c30f1e5053401244f5`.

The creator's [license](https://keviniglesias.com/#license), updated 3 October 2026,
permits royalty-free commercial game use, including free downloads. Credit is
appreciated, not required. It restricts standalone asset redistribution and access
outside the licensed individual/entity. This is **not CC0**. Source FBX files and
derived `.res` motion stay Git-ignored because this repository is public. They can
be incorporated in a substantial compiled game, subject to those license terms.

Selected source files:

- `Animations/Male/Combat/2H/HumanM@Attack2H01.fbx` → `attack_2h.fbx`

Selected FBX SHA-256:
`d9214c38a8de94ba7199832ca024e5adda5bcb7ff5ec6a19ab4e4ff9c9712c19`.

After obtaining your own free copy, place that file here, import with
`sh tools/godot.sh --headless --path . --import`, then bake with
`sh tools/godot.sh --headless --path . --script tools/build_sword_trial.gd`.
The resulting `sword_trial.res` is loaded only when present. Otherwise combat
uses the existing CC0 Quaternius clips. Bone rotations are retargeted to the
engineer; horizontal root travel is removed because the controller owns movement.
Source models, weapons, other motions and Blender files are not shipped. The
export presets exclude the source FBX; only the derived attack library is needed.

Human acceptance remains pending: check stance, footwork, grip, visible contact,
and recovery in the combo and specials. No damage or input tuning is implied.
