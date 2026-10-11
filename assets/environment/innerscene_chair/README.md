# Realistic office chair — source and license

Selected 11 October 2026 for the authorized office-chair replacement.

- Asset: VECTOR — Ergonomic Office Chair, original model by Innerscene.
- Source: https://www.innerscene.com/tools/library/3d-parts/vector-ergonomic-office-chair-ae299d68
- Direct GLB: https://www.innerscene.com/api/library/vector-ergonomic-office-chair-ae299d68/download
- License: CC0 1.0 Universal, https://creativecommons.org/publicdomain/zero/1.0/
- Publisher terms: https://www.innerscene.com/tools/library/terms
- Commercial use, modification and redistribution permitted; attribution optional.
- Publisher describes a real-scale, 73 × 70 × 117 cm swivel chair with embedded
  PBR textures, contoured upholstery, adjustable arms, gas lift and twin-wheel base.

License and original-model status verified on the publisher's asset page and library
terms before intake. The binary uses the existing environment Git LFS rule.
`vector_office_chair_source.glb` retains the original download. SHA-256 hashes and
conversion details are recorded in `provenance.json`. `tools/build_office_chair.gd`
combines the 60 mesh pieces into five material surfaces without decimation: 51,164
triangles per chair, preserving geometry, UVs and imported PBR materials. Godot exports
the consolidated `vector_office_chair.glb` with PNG texture encoding; the extracted PNGs
and `.import` sidecars are retained for reproducible imports.

The shared `chair.tscn` rotates the model 180° to face the existing desks, and scales
only its vertical axis to 0.90615. Seat top: 0.56 m; fitted bounds: approximately
0.731 × 0.701 × 1.058 m. Wheels sit at floor zero. All office/meeting/pantry chairs
reuse it; lounge armchairs and the sofa retain their established art. No new world
collision or runtime generation. Seated-character offsets remain unchanged.

Rebuild after import:

```sh
sh tools/godot.sh --headless --path . --script tools/build_office_chair.gd
python3 tools/build_office.py
sh tools/godot.sh --headless --path . --import
```

Rendered fit review: `sh tools/godot.sh --path . --script tests/capture_chairs.gd`.
Images in `builds/chair_*.png` cover the desk, seated engineer, title backdrop and
conference table. Human visual acceptance remains pending.
