# Combat smoke (CC0)

- Creator: Kenney Vleugels / Kenney.nl.
- Source: https://kenney.nl/assets/smoke-particles
- Official archive: https://kenney.nl/media/pages/assets/smoke-particles/23249a0d35-1677695171/kenney_smoke-particles.zip
- Retrieved: 11 October 2026.
- License: CC0; personal and commercial use allowed; attribution optional. Original
  license is retained in [license.txt](license.txt), with line endings normalized.
- Runtime texture: `smoke_puff.png`, an unmodified copy of
  `PNG/White puff/whitePuff10.png`. Only this selected texture is imported.
- Texture SHA256: `615585e00afc6b0f3126d9755397ad343756811d599f1d0a758afa63a420dd4d`.
- Archive SHA256: `97a1d09c66e4fd6c247c8ea87f84c0cc59caaeceae19414c995afb1616a1e1c9`.

`ElementFx.dust()` tints this white texture warm charcoal, uses ordinary lighting
and alpha blending, and expands/rotates the puffs while fading them out. Earthquakes
keep their existing debris, cracks and timing. Outside art is tracked with Git LFS.

The separate shockwave shader is adapted from mrsir8433's CC0 shader:
https://godotshaders.com/shader/distortion/ (4.1.1 revision). That page explicitly
licenses shader code as CC0; its preview artwork is not imported. SEV-1 corrects
aspect and UV displacement, avoids division by zero, caps overlapping pulses at
four in one viewport pass, and reduces distortion/chromatic splitting. Credit is
optional; recorded here for provenance. No AI-generated art is used.

Implementation and review instructions: [combat effects](../../../docs/combat_effects.md).
