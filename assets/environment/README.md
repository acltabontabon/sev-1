# Office After Hours — asset provenance

The architectural shell, layout, signage and skyline silhouettes in
`game/rooms/office/` are original Godot-native geometry and text resources.
`tools/build_office.py` is the deterministic authoring source, with focused finish
in `tools/office_details.py` and pantry layout in `tools/pantry_layout.py`.
The current office also uses verified free CC0 assets:

- [PBR materials and night sky](textures/README.md) from ambientCG and Poly Haven.
- [Furniture and plants](kenney_furniture/README.md) from Kenney.
- [Photographic culture prints](posters/README.md) from Poly Haven.
- [Detailed desks and starting-desk lamp](poly_haven_workstation/README.md) from Poly Haven.
- [Realistic ergonomic office chair](innerscene_chair/README.md) from Innerscene.

See those records for authors, sources and license details. All eight workstations
now reuse the detailed desk. New ceiling runners, vents, divider hardware, filing
cabinets and conference details are original native geometry. No new external assets
were introduced by that extension; its [review record](../../docs/workstation_trial.md)
includes captures and performance limitations.
The project has not declared an overall distribution license; these files do not
assert that the game or its original assets are public domain.

Large surfaces and the imported chair use the recorded PBR materials; native fabric
on desk mats and dividers retains a seeded Godot NoiseTexture2D. Other materials use native roughness/metallic controls.
Signage uses Label3D with project fonts (see [font licenses](../fonts/README.md)). The city and repeated service-door
frames are original abstract geometry, not photographs or a traversable extra level.
Existing placeholder audio retains its separate provenance in `assets/audio/README.md`.

The current free desk/chair pair replaces the original native furniture fallback.
Monitors, small clutter and the broader environment still need visual refinement.
Record source URL, author, license, and attribution requirements before importing
replacements. Keep the tested simplified collision envelopes.

Incident 001 adds original procedural transaction labels, a solid boss diamond, translucent
false-copy silhouettes reusing the existing enemy mesh parts, dashboard color/text
changes, and handcrafted report text. These are authored locally in the incident
scripts; no external meshes, images, fonts, or sounds were introduced. Their rendered
appearance was inspected; the mannequin and copy silhouettes remain placeholders.
