# Pantry: appliance hauntings and Kevin's birthday

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

The pantry spans x=18.5–31.25 and z=2–15.5. The birthday pass added a four-metre east
annex (matching the Quick Sync annex), so the room is about 50% larger than the
earlier 8.5 m-wide layout. The doorway is 4.5 m; dining furniture sits at the north
edge and vending at the back wall. A concrete floor and a second warm light
distinguish the recovery room. Navigation is rebaked offline for this layout.

The cabinet run and its countertop appliances sit inside the annex's east wall,
moved four metres east with their notices, interaction markers, the mug tribunal and
the leftovers. Casey keeps his place in front of the microwave. Counter and fridge
collision match the imported corner pivots and visible footprints. Chairs use the
shared fitted World-layer box. The centre and appliance approaches stay open.

Strange employees resolve their standing height against physical floor collision,
with the existing 5 cm body clearance, rather than the elevated navigation voxels.
This applies at every outbreak site and is checked again when a transformation
reparents an employee onto a monster. Regular coworkers retain their authored
floor, raised-deck and furniture placements. `tests/encounter_tests.gd` checks
physical support at all seven outbreak sites and for every non-seated coworker;
its existing seating checks cover the sofa sitter. Human checkpoint: approach a
strange employee in the pantry, watch their feet while idle and talking, then
trigger their transformation and confirm they do not rise off the floor.

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

## Kevin's birthday (implemented prototype, 11 October 2026)

This change was requested by the creator: a vibrant, unhinged office birthday in the pantry
that sets up a transformation, like the Quick Sync stand-up. It stays an optional
investigation detour inside Incident 001. Its comedy, pacing, sound and fun still
need human acceptance.

**Set dressing.** The back wall is painted coral, with a mail-merge banner that reads
`HAPPY BIRTHDAY {FIRST_NAME}!`. Bunting, fairy lights, crepe streamers, helium
balloons on the ceiling and balloon bunches dress the room. A pink-clothed table holds
a sheet cake iced `HAPPY BIRTHDAY KELVIN` with six candles, plus pizza boxes, cupcakes,
sprinkle donuts and soda. There is also a card ("Dear Kelvin… (Legal declined to sign)")
and a gift tagged "FROM: LEADERSHIP (it's a mug)". Confetti covers the table and floor,
and a deflated "41" balloon lies on the floor. A Culture Committee flyer by the door
announces the party ("Cake contribution: $10 (auto-deducted) · Attendance is
tracked"). A pink sign under the pantry header and a balloon bunch in the corridor
draw players in. Pink and cyan party lights warm the back half of the room. The
remaining props are generated primitives in `tools/pantry_layout.py`. The food is
Kenney's CC0 [Food Kit](../assets/environment/kenney_food/README.md).

**Who is there.** During the investigation KEVIN (Billing Integrations, arms folded,
"Please don't sing"), BRENDA (Culture Committee) and MARCO (Accounts Payable, "Who
is Kelvin?") stand around the table in party hats. They are planted employees with
the usual tell, defined in `talk.json` `party.cast`. Swinging at them only notifies HR.

**The scene.** Press E in front of the table (**E — SING HAPPY BIRTHDAY**). The
engineer steps up to the table end and a voiced, TAB-skippable scene of about 30
seconds plays. A party horn sounds, then Brenda's cake is "funded by everyone's
annual raise". Marco notes that the cake says Kelvin and sings flatly, Brenda reminds
everyone that attendance counts toward calibration, and the engineer asks Kevin to blow
the candles out so everyone can go home. Kevin wishes for one weekend without the pager.
The trick candles relight ("REOPENED") over a deflating horn, and Kevin starts to
turn.

**The fight.** Kevin becomes Scope Creep and keeps his party hat as he grows. Brenda
and Marco become Corrupted Records, and the cake bursts into four BUGs ("THE CAKE WAS
A BACKLOG") as the outbreak cutscene ends. All three are aware ambushers. The HUD reads
`Birthday · N left`, and NEXT says to keep hitting Kevin. Management waits until the
party is over, and Quick Sync cannot start in the middle of it. Clearing the three
guests closes the leftover bugs as WONTFIX and grants **+30 health and Burnout −15**.
The party never retriggers. If the player answers Management without singing, the
guests go home when containment starts and the cake stays on the table. Retry restores
the guests, cake and candles.

**Ownership.** `missing_transaction.gd` plants the guests (`_plant_party`), owns the
E point, the party state (`idle → cake → active → done`), the spawn, the cake burst
and the reward. `game/incidents/birthday_party.gd` owns the scene: authored camera per
line, staging, captions, horn cues, candles and party hats (`party_hat()`).
`employee_host.gd` gained per-host idle and gesture clips. The voiced lines and the
guests' HR barks are local Kokoro candidates; see [voices](voices.md). The horns are
original synthesis from `tools/build_party_horn.py`.

Validation: `tests/birthday_tests.gd` (38 checks, part of `tools/validate.py`)
covers the wider room's navigation and moved appliances, planting, hats, NEXT, the E
prompt, HR, the headless transformation, the bug swarm, ambush awareness, the
Management and Quick Sync locks, the reward, no retrigger, the rendered scene's steps
(candles out and relit), TAB, natural handoff, restart mid-scene, and an ignored party.
`tests/birthday_preview.gd` renders the room, table, cake, door, every scene line, the
outbreak and the fight into `builds/`; five of them are kept as
`docs/screenshots/pantry_birthday_*.jpg` for review. These renders were inspected at 1600×900 on an
Apple M2 Pro, Forward+/Metal. They are layout evidence, not performance or fun
measurements.

Human checkpoint: run
`sh tools/godot.sh --path . --script tests/birthday_preview.gd -- --play`, walk
in, and press E at the table. Watch the whole scene once, then retry with R and
skip it with TAB. Report whether the jokes land, whether the scene is too long, whether
the horns and the voices are funny or grating, whether the room reads as vibrant
without hurting the after-hours mood, and whether the fight (a growing Kevin plus bugs)
is fair.

For a quick pantry-only starting checkpoint, run
`sh tools/godot.sh --path . --script tests/pantry_preview.gd -- --play`.
It starts during investigation beside the appliances with ordinary controls.
R retries the full incident; rerunning the command returns straight to the pantry.
