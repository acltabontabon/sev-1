# Drew restoration — 11 October 2026

The creator requested removal of the earlier human-model trial and restoration of
Drew's original art. Drew again uses the existing CC0 Quaternius `suit_male.fbx`,
shared coworker motion and ordinary dialogue framing. His identity, recorded voice,
conversation choices are retained. He stands at the open front of the conference
table, clear of the solid chairs and with room for the original dialogue framing.
The trial export, textures, animation libraries, scene and build tools are removed.
No other original character assets are removed.

`tests/coworker_restoration_tests.gd` checks the restored body, visible talking/cower
poses, furniture clearance, Drew's real dialogue and repeated retry. Render with
`sh tools/godot.sh --path . --script tests/drew_preview.gd`; local captures are
`builds/drew_{idle,talking,cower,dialogue}.png`.

Human checkpoint: start a run, go up the conference ramp, find Drew at the front
of the table, press E to talk, then leave with Escape and retry with R. Check
his appearance, dialogue framing and movement around the chairs.

Validation: the full `python3 tools/validate.py` suite passed after restoration,
wardrobe updates and doorway removal. The original Drew model and real dialogue
framing were rendered and inspected. Human playtest acceptance remains separate.
