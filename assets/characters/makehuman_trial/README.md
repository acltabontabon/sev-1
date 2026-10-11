# MakeHuman coworker trial — provenance

Authorized 11 October 2026 for one coworker only, using free assets.

- MakeHuman core body, rig, skin, eyes, brows, hair and shoes: MakeHuman Community system assets, CC0 1.0. https://static.makehumancommunity.org/assets/assetpacks/makehuman_system_assets.html
- Office clothing: Margaret Toigo (MRT), `toigo_male_suit_tie_and_jacket`, Suits 01, CC0 1.0. The selected `.mhclo` header explicitly says CC0. https://static.makehumancommunity.org/assets/assetpacks/suits01.html
- Authoring tool: MPFB2, https://github.com/makehumancommunity/mpfb2; code is GPL, generated/core assets are CC0 (bundled asset license). Official Blender 4.5.3 portable build is a development tool only.
- Downloads: official MakeHuman system and Suits 01 CC0 archives, retrieved 11 October 2026. Attribution is voluntary. Source archive checksums, output checksum and selected files are recorded in `provenance.json`.
- Modifications: assemble one male office coworker, remove hidden helper/under-clothing geometry, fit standing height to the measured 2.06 m existing cast, export GLB and retarget existing CC0 Quaternius clips at build time.

Neither MakeHuman nor Blender is required to run the exported game. No paid assets or runtime downloads. Only **Drew (Recruiter)** uses this model. The original suit body remains available
in `assets/characters/quaternius/`; removing the recruiter’s `trial_body` entry
restores it. The skin is a generated fictional person, not a scan or imitation.

The final model has 41,470 triangles, six mesh/material groups and 53 joints.
Textures are capped at 2K. Skin, clothes, shoes and eyes use opaque depth; hair and
brows use alpha cutout. Helpers and outfit-hidden skin are removed. The body and
clothes are rebound to the MPFB T-pose before retargeting, with the root pivot at
the pelvis and canonical bone names for existing head-turn/reset behavior.

Eleven native clips and 45 existing engineer-library gestures are retargeted at
30Hz into the two local `.res` libraries. These use Git LFS. Animation moves the
skeleton only; the ordinary coworker code still owns position, dialogue, aid and
restart. No facial animation or lip sync has been added.

Rebuild with portable Blender 4.5.3 and the source archives listed in provenance:

```sh
BLENDER_USER_RESOURCES=/tmp/sev1_blender_profile /path/to/blender --background --factory-startup --python tools/build_makehuman_coworker.py -- --mpfb-source /path/to/mpfb2/src --assets /path/to/unpacked_cc0_assets
sh tools/godot.sh --headless --path . --import
sh tools/godot.sh --headless --path . --script tools/retarget_makehuman_coworker.gd
```

`recruiter_preset.json` records the selected body parameters, skin and clothes.
The upstream build tools and full source archives are development inputs and do
not ship. Visual and animation acceptance remain pending; this is a one-person
trial alongside the existing stylized cast.
