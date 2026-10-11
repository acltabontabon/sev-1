# Heavy Greatsword — Lucian Pavel

Selected by the creator on 11 October 2026 for a playable weapon trial.

- Author and source: [Lucian Pavel, Heavy Greatsword](https://opengameart.org/content/heavy-greatsword).
- License: [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/), as listed on the asset page. Attribution is optional; voluntary credit is retained here.
- Original download: https://opengameart.org/sites/default/files/Heavy%20Sword.zip
- Retrieved: 11 October 2026. Archive SHA-256: `38ca37c5b59e784d84b831baf879dfdb4cd319d9ad23cd1e3ac1b2f813c57753`.
- The author describes inspiration from the Dark Souls Ultra Greatsword. This is the uploader's authored asset, not a claim of independently verified provenance.
- Runtime file: `heavy_greatsword.glb`, using the archive's `Heavy Sword` mesh (2,338 triangles), with original 2K color, metal, normal and AO textures embedded. Roughness is a locally chosen constant of 0.62; no roughness map was supplied.
- Conversion rotates and uniformly scales the sword to 2.35 m, centered on X/Y, pommel at local Z +0.03 and tip at Z -2.32. No baking copies, presentation pedestal, collision or animation is imported.
- Rebuild with Blender 4.5.3: `Blender -b --python tools/build_heavy_greatsword.py -- /path/to/Heavy\ Sword.zip`. The original archive stays outside the runtime repository; its download and checksum make conversion reproducible.
- Existing Git LFS rules cover this directory's GLB. Godot runs entirely locally; no paid assets or runtime dependencies were added.
- Godot's extracted texture PNGs and import sidecars are retained, with lowercase names and the existing character-texture LFS rules.

The rigged engineer uses `heavy_greatsword_weapon.tscn`, including duplicated story
props. The original `keyboard_weapon.tscn` and fallback engineer remain available.
The shoulder contact offset fits the narrower blade. Combat timings,
damage, reach, trail offsets and hand targets stay unchanged. Visual acceptance is
pending the creator's playtest.

## Verification and playtest

`python3 tools/validate.py` passed after correcting Blender's Z-up to Godot's Y-up
conversion. Presentation regression checks verify the actual imported blade bounds
against the existing grip/trail envelope; existing combat and finale outcomes pass.
`tests/greatsword_preview.gd` also passed its Godot parse check and graphical run.
After normalizing texture metadata, import and presentation checks passed again.

Rendered review on Apple M2 Pro, Godot 4.7.2, Metal Forward+, 1920 × 1080:
`builds/greatsword_shoulder.png` shows the full shoulder carry; `builds/rig_states.png`
captures run, all three combo steps, dodge, hurt and defeat. `tests/finale_preview.gd`
completed with the imported sword in the existing desk/ending sequence. No engine
errors were logged in these graphical probes. Captures are ignored review output;
no performance claim or human acceptance is implied.

Launch `sh tools/godot.sh --path .`, start or replay Stage One, and compare the
shoulder carry, metallic finish and blade readability during attacks. The creator
should judge whether its proportions and detail fit the current characters and
whether the swing effects leave enough of the blade visible. Retry with R.
For the wider static review: `sh tools/godot.sh --path . --script tests/greatsword_preview.gd`.
