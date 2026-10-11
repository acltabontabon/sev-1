# Pantry: appliance hauntings

Authored refinement requested by the creator on 11 October 2026. Human comedy,
layout and sound acceptance remains pending. This stays inside Incident 001.

Sam, the facilities worker, has become the microwave's unofficial legal counsel.
Casey, still waiting on a burrito, witnesses the organised leftovers. Their existing
voiced conversations remain available. New appliance replies are readable text;
they do not have new recorded dialogue.

Press E near an appliance. The microwave summons three floating, nodding mugs as a
lunch tribunal. The vending machine shakes briefly and prints a disappointment
receipt. The fridge levitates three lunch containers with a union placard. The
wellness poster gently pulses the pantry light during mandatory breathing. Each
has three authored replies, advancing on repeat visits and holding the third
punchline afterward. One active vignette replaces the previous one, settling after
seven playable seconds. Pause freezes it; retry clears the props and visit counts.
These events cause no damage, currency/debt charge, or encounter progression.
Coffee keeps its existing once-per-run motivation and Burnout relief.

The pantry spans z=2–15.5 instead of z=3.5–13, roughly 40% more floor area within
the existing wing. Its doorway grows from 3 m to 4.5 m; dining furniture moves to
the north edge and vending to the back wall. A concrete floor and a second warm
light distinguish the recovery room. Navigation is rebaked offline for this layout.

`game/rooms/office/pantry_antics.gd` owns the local visual state. The incident owns
input, distance checks, coffee and progression. Props are reused on every press;
there is no runtime navigation bake or spawning of combatants. The receipt remains
until retry. Native mugs, food containers and paper use the existing office
materials. The error chime reuses Kenney's CC0 `ui_error.ogg`; see
[sound provenance](../assets/audio/sfx/README.md). Existing kitchen art remains
[Kenney CC0](../assets/environment/kenney_furniture/README.md).

Validation: the full `python3 tools/validate.py` suite passed after integration,
including pantry, movement/combat, environment and encounter checks.
`tests/pantry_tests.gd` exercises real E interactions,
escalation, harmless outcomes, pause, expiry and restart. Run the full
`python3 tools/validate.py` suite after integration. `tests/pantry_preview.gd`
captures the room and all four visual responses into the ignored `builds/` folder.
The direct `--play` checkpoint also passed a graphical launch smoke check.
On Apple M2 Pro at 1600×900, Forward+ with project settings, a 180-frame warm
fixed-camera sample measured 8.28 ms mean, 8.50 ms p95, and 8.71 ms maximum.
This short room sample does not close the ordinary-run performance gate.
Graphical screenshots establish that the scene renders; they do not establish fun,
ordinary-run performance or human listening acceptance.

Human checkpoint: enter the pantry from the wing, dodge through its open centre,
talk to Sam and Casey, and try each appliance three times. Check that E selects the
intended object/person, the jokes are readable, and the antics remain visible during
ordinary camera movement. Retry with R and confirm everything starts cleanly.

For a quick pantry-only starting checkpoint, run
`sh tools/godot.sh --path . --script tests/pantry_preview.gd -- --play`.
It starts during investigation beside the appliances with ordinary controls.
R retries the full incident; rerunning the command returns straight to the pantry.
