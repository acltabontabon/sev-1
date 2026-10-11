# Female office outfits — 11 October 2026

Original clothing edits to the existing Quaternius Ultimate Animated Character Pack
female models, CC0 1.0. [Existing source/license record](../README.md#rigged-engineer-quaternius-cc0).
No new third-party downloads, generators or runtime clothing simulation are required.
The original source FBXs remain intact; the generated ArrayMeshes use their existing
skins, named skeleton binds and coworker animation libraries.

Nadia wears a blouse and longer pleated skirt, with the pack's long tied-back hairstyle. Other
female office employees wear skirts or skirt suits with their own haircuts
([office haircuts](../README.md#office-haircuts-11-october-2026)).
Marie, the adult director, has a shorter skirt and open V-neck blouse inside her
jacket, showing upper chest and bare legs. Only her outfit uses this neckline.
The remote fitness avatar retains its athletic clothing. Identities, dialogue,
voices, collision and movement remain unchanged.

`tools/build_office_outfits.gd` authors the clothing offline. Skirts blend hip and
thigh weights; exposed lower-leg triangles retain the original skinning. The director
blouse subdivides the existing shirt surface and assigns a V-shaped skin area; its
necktie/collar surfaces are recoloured into the open blouse. Small gold hoop earrings
are fitted to the source head and follow its bone. Surface palettes are applied per character by `coworkers.gd`.
Source/output SHA-256 values are in `provenance.json`. Derived meshes use Git LFS.

Rebuild: `sh tools/godot.sh --headless --path . --script tools/build_office_outfits.gd`.
`tests/female_outfit_tests.gd` checks world-scale clothing bounds, sitting/walking
deformation, actual conversations and retry. `tests/female_outfit_preview.gd` renders
`builds/outfit_{nadia,marie,marie_walk,nadia_seated}.png`.

Review seated Nadia, walking Marie, talking/phone gestures, and death/retry in the
actual office. Animation fit and appearance require creator review.

The complete validator passed, including the clothing pose/conversation/retry checks.
Rendered standing, walking and seated views were inspected in office lighting.
Materials are saved inside each generated mesh for clean-checkout imports.
Human visual acceptance and target-hardware graphical performance remain open.
