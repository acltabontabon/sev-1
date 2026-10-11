# One-coworker MakeHuman trial — 11 October 2026

## Implemented prototype

Drew, the Talent recruiter in the raised conference room, now uses a free MakeHuman
body with Margaret Toigo’s CC0 jacket-and-tie outfit. His existing identity, voice,
conversation choices, standing gestures, cowering, emergency aid and retry behavior
remain in place. Every other coworker, planted employee and the engineer keeps the
existing art. This is a comparison trial, not the accepted final cast style.

The initial 1.78 m export was smaller than the current cast. After creator feedback,
the engineer and original recruiter were measured at 2.06157 m in world-space bind
bounds. Drew now measures 2.06 m at the existing 0.62 runtime scale. The model retains
human proportions rather than the previous large head; matching overall height does
not make those silhouettes identical. He stands in the clear east aisle beside the
table, away from the previous chair overlap. His dialogue camera uses a 1.9 m eye
focus, while every other character keeps the existing focus height.

The model has 41,470 triangles, six mesh/material groups and 53 joints; texture
dimensions are capped at 2K. The MPFB body and outfit are rebound to a matching
T-pose, then the existing CC0 motion is baked onto that rig (11 native clips and
45 gestures). Skin and clothes write opaque depth; hair/brows use alpha cutout.
There is no runtime character generator, paid asset, paid inference or new engine
requirement. The cast’s mixed art styles and approximate hand/finger motion remain
visible trial limitations; facial animation/lip sync has not been added.

[Source, licenses, checksums and rebuild instructions](../assets/characters/makehuman_trial/README.md).
To restore the original body, remove only Drew’s `trial_body` entry from
`game/incidents/coworkers.gd`; the original source and motion library remain available.

## Creator checkpoint

Launch with `sh tools/godot.sh --path .`, start/replay Stage One, and use TAB to skip
the opening if desired. Go up the conference-room ramp and find Drew beside the east
end of the meeting table. Press E nearby to talk; use the normal dialogue choices,
ESC to leave, and R to retry.

Judge his size beside the engineer, table and chairs, face/material quality in the
conversation shots, hand gestures and cowering, and whether this direction suits
SEV-1. Do not replace the rest of the cast until this one-person comparison is accepted.

## Evidence

`tests/makehuman_tests.gd` checks one trial in the preserved cast, model-height
agreement within 2 cm, furniture clearance, visible idle/talking/cower changes,
planted gameplay root, original Drew dialogue reach/open/close and repeatable retry
without accumulated imported nodes. All 13 dedicated checks passed. The full `python3 tools/validate.py` suite passed
with separate log output under `logs/makehuman_trial/`, avoiding shared-log collisions
with concurrent weapon work. Import, script parsing and every integration suite passed.
An earlier shared-log run timed out at presentation; the isolated rerun resolved it.

Rendered inspection uses the actual incident scene and conference location:

```sh
sh tools/godot.sh --audio-driver Dummy --path . --script tests/makehuman_preview.gd
```

Local ignored captures: `builds/makehuman_idle.png`, `makehuman_talking.png`,
`makehuman_cower.png`, `makehuman_before.png` and `makehuman_dialogue.png`.
The before/after model captures share camera, placement and lighting; the dialogue
capture runs the actual conversation UI and camera. Audio is disabled in this probe.

Measured on Apple M2 Pro, Godot 4.7.2, Metal Forward+, 1920 × 1080, existing
SSAO/glow/fog, with 90 warm-up and 120 measured frames per capture: staged idle/talking/
cower mean approximately 8.3–8.4 ms; dialogue mean 8.40 ms, p95 8.59 ms. Measurements
include presentation/vsync and exclude active combat. They are a local review sample,
not a whole-run performance guarantee or proof that twelve replacements would fit.
Human appearance, animation and listening acceptance remain pending.
