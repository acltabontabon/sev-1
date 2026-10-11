# Abyssal Reaper vault comparison — rejected, 11 October 2026

Creator authorized accepting the Fab agreement, downloading the free model, and
trying it in the server vault. This is an isolated visual comparison, not a
replacement for The Variance or a combat-ready boss.

Source: [Abyssal Reaper — Free Demonic Wraith Boss (Idle Animation)](https://www.fab.com/listings/3bc87444-d244-47c6-96d0-1528b3321214)
by PolyReady, under the [Fab Standard License](https://www.fab.com/eula), accepted
with explicit creator approval on 11 October 2026. No attribution is required;
commercial project use is allowed, standalone asset redistribution is prohibited.
Do not publish the raw asset in a public repository. Listing discloses AI-enhanced
texture details and claims handmade model, rig and animation.

Archive: `idle_blend.zip`, downloaded directly through Fab.
SHA-256: `0e9263c8af1c6675a7997b679c5bd20d74ff828bc607ecb1033c70c7248bde05`.
The source ZIP remains outside the project in Downloads.

**Unresolved provenance:** the source armature is named `alu_galiark_body.nx3`
and unused image paths reference `RappelzReleesseeas/dds/galiark_diff.dds`.
This conflicts with the listing's origin claim and warrants clarification from
the seller before adopting or shipping the asset. This local trial does not
establish ownership or clean rights to the underlying design.

Only the supplied idle animation is used. No paid clips are downloaded. Conversion
relinks the supplied PNGs, constructs glTF-compatible PBR materials, and exports
the supplied mesh/skeleton/animation to GLB. The preview normalizes its height,
preserves its textures, and stages it with the current engineer and demon in the
actual vault. Preview assets are excluded from normal exports.

## Review outcome

The creator rejected the Reaper and requested alternatives coherent with the current
art. It was never connected to normal encounters. The isolated GLB imported and the
supplied 10.083-second idle played successfully in the vault; comparison and close-up
captures were produced on Apple M2 Pro, Godot 4.7.2, Metal Forward+, 1920×1080.
No combat integration, full gameplay validation or performance benchmark is claimed.

To revisit locally: `sh tools/godot.sh --path . --script tests/reaper_preview.gd`.
1 compares bodies, 2 frames the Reaper, Space orbits and Esc exits. Add
`-- --capture` to save ignored screenshots. Rebuild from the authorized archive with
Blender and `tools/build_reaper_trial.py -- --source /path/to/extracted/archive`.
The GLB and Godot-extracted texture sidecars remain local and ignored by Git.
