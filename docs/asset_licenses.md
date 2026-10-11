# Release asset and license inventory

The current 0.2.49 release includes the outside assets and speech listed in the
later sections. The 0.1.0 inventory below is historical, preceding those imports.
Each source/license record stays with its owning asset directory. Making the
repository public does not assign an open-source license to original game code
or art; the original-content rights remain with the creator.

## Historical 0.1.0 baseline

Inspected 10 October 2026. No outside art, sample, font, animation or model pack is
included. The existing source and import sidecars are preserved.

| Shipped content | Source / rights record | Release status |
| --- | --- | --- |
| Office geometry, materials, signs and skyline | Original Godot-native procedural work; [provenance](../assets/environment/README.md) | Usable native fallback; furniture/material fidelity remains provisional |
| Engineer, keyboard blade, records and boss copies | Original AI-assisted procedural geometry; [provenance](../assets/characters/README.md) | Usable temporary art, not finished rigged characters |
| Twelve WAV effects / office ambience | Original oscillator/noise synthesis; [provenance](../assets/audio/README.md) | Redistributable original work; listening/mix acceptance pending |
| GARY's snoring (11 October 2026) | Original oscillator/noise synthesis; [provenance and behavior](snoring.md) | Implemented proximity loop; creator listening/mix acceptance pending |
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

`assets/audio/voices/talk/*.ogg` (0.2.9): the night shift's conversation lines from `assets/audio/voices/talk.json`, synthesized the same way from weighted blends of those six stock voices with pitch/speed processing; per-clip provenance in [talk provenance](../assets/audio/voices/talk/provenance.json). Candidates awaiting human listening approval.

## Milestone 12 outside assets

Git LFS tracks these new binaries (see `.gitattributes`). Each source was retrieved
without an account on 10 October 2026 and reviewed in the running game.

| Content | Source and license | Record |
| --- | --- | --- |
| Barlow Condensed, Inter, JetBrains Mono, Cinzel typefaces | Official Google Fonts repository; SIL Open Font License 1.1, license text bundled | [assets/fonts](../assets/fonts/README.md), [THIRD_PARTY_NOTICES.txt](../THIRD_PARTY_NOTICES.txt) |
| 16 interface/effect sounds | Kenney Interface Sounds, Impact Sounds, UI Audio, Sci-Fi Sounds; CC0 1.0 | [assets/audio/sfx](../assets/audio/sfx/README.md) |
| 4 whoosh effects (0.2.15) | Original, synthesized by `tools/build_whoosh.py`; no third-party material | [assets/audio/sfx](../assets/audio/sfx/README.md) |
| 8 PBR material sets (1K) | ambientCG and Poly Haven; CC0 1.0 (paper added in 0.2.29) | [assets/environment/textures](../assets/environment/textures/README.md) |
| 4 female office bodies (0.2.38) | Quaternius "Ultimate Animated Character Pack", OpenGameArt; CC0 1.0 | [assets/characters](../assets/characters/README.md) |
| 5 culture-print photographs (0.2.29) | Poly Haven HDRI tonemapped previews, cropped and downscaled; CC0 1.0 | [assets/environment/posters](../assets/environment/posters/README.md) |
| Night-city sky (2K HDRI) | Poly Haven "Hansaplatz", Greg Zaal; CC0 1.0 | [assets/environment/textures](../assets/environment/textures/README.md#night-sky-hdri) |
| 8 pantry props | Kenney Furniture Kit; CC0 1.0, tinted at load | [assets/environment/kenney_furniture](../assets/environment/kenney_furniture/README.md) |
| 3 music beds | Original synthesis (`tools/build_music.py`) | [assets/audio/music](../assets/audio/music/README.md) |

Kenney's furniture chair and round table were evaluated and rejected as toy-like. Mixamo and Freesound remain excluded because they require accounts.

| Rigged engineer body and office clips | Quaternius "Ultimate Animated Character Pack" (`Casual_Male`), OpenGameArt; CC0 1.0 | [assets/characters](../assets/characters/README.md#rigged-engineer-quaternius-cc0) |
| Action clips (run, roll, death, jump, sword idles) | Quaternius "Lowpoly Animated Knight", OpenGameArt; CC0 1.0, retargeted at build time | [assets/characters](../assets/characters/README.md#rigged-engineer-quaternius-cc0) |

| Enemy bodies (original monster roster) | Quaternius "Ultimate Monsters" (retrieved from a public GitHub mirror while the official Drive link was over quota); CC0 1.0 | [assets/enemies](../assets/enemies/README.md) |
| Corrupted Record skeleton (11 October 2026) | Kay Lousberg, KayKit Character Pack: Skeletons 1.0, free Skeleton Minion; CC0 1.0 | [source revision, checksums and combat integration](../assets/enemies/kaykit_trial/README.md) |
| Superseded demon body trial (sources and historical viewer retained) | Night Demon by Morgan Strauss (nubux); Chained Demon by Tor Halle-McIntyre (Mophs); both used under CC BY 3.0 with required attribution | [sources, archive checksums and modifications](../assets/enemies/demon_trials/README.md) |

The rigged engineer replaced the native procedural engineer after creator feedback;
the native scene and generator remain as a fallback. Elemental effects, enemy spells
and the battle-mode grade are original procedural work (shaders and particles in code).

`assets/characters/animations/ual1_standard.glb`, `ual2_standard.glb` (0.2.24): Quaternius, Universal Animation Library and Universal Animation Library 2, Standard editions; CC0 1.0 (licence files kept beside them). Downloaded 10 October 2026 from OpenGameArt (`opengameart.org/content/universal-animation-library-2`, `opengameart.org/node/174563`), no account. Retargeted at build time by `tools/build_engineer_rig.gd` into `game/player/engineer_animations.res`.

## Free office furnishing pass — 11 October 2026

All eight workstations use Poly Haven’s **Metal Office Desk** (Ulan Cabanilla).
The starting desk also uses **Desk Lamp Arm 01** (Kuutti Siitonen; rigging by Yann
Kervran); both assets are CC0 1.0.
Official 2K glTF downloads were checksum-verified and packed into self-contained GLBs
without changing mesh or texture content. Attribution is voluntary. Records and exact
URLs: [workstation provenance](../assets/environment/poly_haven_workstation/README.md).
These binaries use the established Git LFS rules. Original desk mat, keycaps and notebook
markings add no outside rights. See [implementation and review checkpoint](workstation_trial.md).
Character selection and subsequent trial status are recorded in that document.

The shared office chair now uses Innerscene’s **VECTOR — Ergonomic Office Chair**,
an original model released under CC0 1.0. Commercial use, modification and
redistribution are permitted; attribution is voluntary. The original download,
SHA-256 records, fitted dimensions, conversion and build instructions are preserved
in [chair provenance](../assets/environment/innerscene_chair/README.md). Existing
Git LFS rules cover both GLBs and texture PNGs. Consolidation changes mesh grouping
without reducing the original geometry; no paid assets or runtime downloads.

## Heavy Greatsword trial — 11 October 2026

The rigged engineer now carries Lucian Pavel's **Heavy Greatsword**, released as
CC0 1.0 on OpenGameArt. The original mesh and 2K textures are converted to an embedded
GLB using the existing character Git LFS rules. Voluntary attribution, exact download,
archive checksum and rebuild instructions: [weapon provenance](../assets/characters/heavy_greatsword/README.md).
The original native Monolith remains available as a fallback. Creator visual acceptance
is pending; this trial adds no new combat mechanics.

## Optional local sword motion trial — 11 October 2026

Kevin Iglesias' **Human Melee Animations FREE**, Godot/Unreal edition, provides the
engineer's first two-handed cut in the local source playable. The creator's direct
itch.io/Gumroad license permits royalty-free commercial game use and optional
credit, but restricts standalone redistribution. It is not CC0. Because this repo
is public, both the source FBX and derived `sword_trial.res` stay Git-ignored. Both
export presets exclude the source FBX. No published release has been rebuilt with
this trial. A checkout without the optional library uses Quaternius CC0 motion.
See [source, archive checksum and installation](../assets/characters/kevin_trial/README.md)
and the [motion/playtest details](sword_motion_trial.md).

The isolated [Skeleton Warrior vault trial](../assets/enemies/warrior_trial/README.md)
uses Kay Lousberg's CC0 Skeleton Warrior, axe, shield and atlas from the same official
Skeletons pack as the regular skeleton. Source revision and hashes are recorded in
[provenance](../assets/enemies/warrior_trial/provenance.json). Runtime scale and dark
armor presentation are local changes; attribution is optional. No paid assets are used.

## Female office outfits — 11 October 2026

Original skirt/blouse and earring mesh edits to the existing Quaternius CC0 female
models. The unchanged source rigs and animation libraries are reused; generated
ArrayMeshes use Git LFS. [Source, modifications and hashes](../assets/characters/office_outfits/README.md).


## Operations command station — 11 October 2026

Two instances of Poly Haven **Caged Hanging Light** by Ulan Cabanilla, CC0 1.0.
The official 1K glTF buffers and JPEG maps were verified and embedded into a GLB;
[source URLs, hashes and license](../assets/environment/operations/README.md).
Original console/rack geometry and power-up SVG icons add no outside rights.

## Illustrated memorial memories (11 October 2026)

Five original PNGs were created with the built-in OpenAI image-generation tool from
SEV-1's authored prompts, with no supplied reference images or artist imitation.
They depict distinct shared moments with Morgan, Nadia, Jun, Jo and Val.
[The asset record](../assets/environment/memorial_illustrations/README.md) links their
full prompt set, original generated paths, selected-file checksums and visual review.
These are AI-generated candidate illustrations; creator acceptance remains pending.
Git LFS tracks the PNGs. Narration retains the existing stock Kokoro documentary
profile and its recorded provenance; no runtime generation or paid runtime AI.

## Corporate firefighting cutscene — 11 October 2026

`game/incidents/vault_response.gd`, `vault_flame.gdshader` and `vault_spell.gdshader`
are original AI-assisted Godot geometry/shaders: extinguisher, nozzle, hose, fan,
bucket, clipboard, damaged equipment, flame silhouettes and cutting crescents.
No outside models or textures were added. Sparse smoke reuses the existing
[Kenney Smoke Pack CC0 texture](../assets/effects/kenney_smoke/README.md), and
casualty pools reuse the game's generated blood textures. Crew bodies and motion
reuse the licensed Quaternius assets above. Ten revised crew recordings and
all eight Variance lines use the existing local voice pipeline; exact text, profiles and output
hashes remain in `assets/audio/voices/talk/provenance.json` and `provenance.json`.
Rendered creator review remains a separate gate from automated validation.
