# Release asset and license inventory — 0.1.0

Inspected 10 October 2026. No outside art, sample, font, animation or model pack is
included. The existing source and import sidecars are preserved.

| Shipped content | Source / rights record | Release status |
| --- | --- | --- |
| Office geometry, materials, signs and skyline | Original Godot-native procedural work; [provenance](../assets/environment/README.md) | Usable native fallback; furniture/material fidelity remains provisional |
| Engineer, keyboard blade, records and boss copies | Original AI-assisted procedural geometry; [provenance](../assets/characters/README.md) | Usable temporary art, not finished rigged characters |
| Twelve WAV effects / office ambience | Original oscillator/noise synthesis; [provenance](../assets/audio/README.md) | Redistributable original work; listening/mix acceptance pending |
| UI, narrative, report text | Original project work | Implemented; creator editorial acceptance pending |
| Engine, default font and default application icon | Official Godot 4.7.2 standard export templates | MIT engine and bundled library/font notices in [THIRD_PARTY_NOTICES.txt](../THIRD_PARTY_NOTICES.txt) |

No suitable original application icon existed; the export retains Godot's default
icon. Replacing it is a P2 branding improvement. Referenced Kenney/Mixamo candidates
were never imported and are not part of the distribution. No attribution to those
candidate sources is required for this build.

`tools/write_engine_notices.gd` extracts the actual pinned engine's copyright and
license data, including bundled libraries. The release includes these notices both
in the resource package and beside the application. Do not remove them from a shared
ZIP. Export templates were retrieved from the official Godot download service; their
archive `version.txt` identifies `4.7.2.stable`. The manifest records the installed
macOS template's SHA-256.

The creator retains the project's original-content rights; no open-source license
for the whole game is assigned by this milestone. This inventory supports sharing
the authorized tester build; it does not grant recipients permission to redistribute
source/assets under a new license. No asset with identified unclear third-party
rights was found. No substantial new binary art was introduced; Git LFS remains
required before future binary asset intake.

## Milestone 11 speech

`assets/audio/voices/*.ogg`: original SEV-1 script synthesized locally with the publisher's Apache-2.0 Kokoro-82M model and six stock English voices. Model revision, source license link, voice, processing, generation date and checksum are recorded per clip in [provenance](../assets/audio/voices/provenance.json). No voice cloning or real-person imitation was used. These are candidate performances awaiting human listening approval. Model weights and development dependencies do not ship. See [voice source and rights](voices.md#provenance-and-rights).
