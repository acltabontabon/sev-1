# Office After Hours — asset provenance

All environment geometry, layout, signage, materials, and skyline silhouettes in
`game/rooms/office/` were authored for SEV-1 in this milestone using Godot-native
primitives and text resources. `tools/build_office.py` is the deterministic authoring
source. No downloaded meshes, textures, fonts, generated AI images, or third-party
asset packs were added. There are no new third-party attribution obligations.
The project has not declared an overall distribution license; these files do not
assert that the game or its original assets are public domain.

Carpet, fabric, plaster, and wood use 128×128 Godot FastNoiseLite/NoiseTexture2D
resources with a fixed seed. Other materials use native roughness/metallic controls.
Signage uses Godot's built-in font through Label3D. The city and repeated service-door
frames are original abstract geometry, not photographs or a traversable extra level.
Existing placeholder audio retains its separate provenance in `assets/audio/README.md`.

Replacement priorities after visual feedback: a cohesive licensed office chair and
workstation prop set, subtle tileable carpet/wood/paint PBR textures, and representative
rigged characters. Record source URL, author, license, and attribution requirements
before importing any replacements. Keep the tested simplified collision envelopes.
