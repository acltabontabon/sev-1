# Midnight street nightlife — implemented prototype, 11 October 2026

The creator requested a more vibrant exterior in the ending, including a strip club
and people. Incident 001 now stages a small nightlife frontage at the foot of the
existing office tower: Velvet (a signed strip club with a 21+ entrance, door host,
rope line and patrons), Blue Hour cocktail bar, and Midnight Noodles. Pink, cyan and
amber lighting, canopies, shop windows, pavement, a kerb and broken neon streaks on
wet asphalt give the rainy street a lived-in ground level.

Nine clothed rigged characters animate: six patrons/door staff and three pedestrians.
Pedestrians follow short deterministic paths separate from the engineer's departure.
A wide, signed Synergex vestibule separates the office departure from the club.
The exterior glass panels slide open before the engineer starts walking; he emerges,
turns onto the sidewalk and continues past the venues. The door closes behind him.
The venues have several metres of breathing room, and pedestrians use separate lanes.
The 12-second camera shot starts close to the opening doorway, then pulls back
to reveal the sidewalk and venues as he walks.
The sad original music, rain, carried belongings, narrator, departure corridor and
five silhouettes in the memorial window retain their roles. The nightlife leaves the shot
at the window cut. There is no club interior or new playable district.

## Implementation and provenance

[The local scene builder](../game/incidents/nightlife_street.gd) is instantiated by
[the ending](../game/incidents/all_hands.gd) only at the street beat. The ending owns
its lifetime, drives pedestrian travel and skeletal poses from the same cinematic
clock, hides it for the window
shot and removes it on finish/skip. Normal office play never instantiates it.

Storefront geometry, lettering and materials are original procedural project work.
The street uses the existing licensed Barlow font and CC0 Quaternius casual/suit
bodies, existing recolouring and retargeted animation library. Their source and
licenses are already recorded in [the asset register](asset_licenses.md) and
[character provenance](../assets/characters/README.md). No outside asset, new binary,
AI-generated artwork, audio recording or dependency was introduced. The coloured
road streaks are authored visual accents, not real planar reflections.

## Verification and human checkpoint

[Regression checks](../tests/nightlife_tests.gd) exercise the actual ending's street
cut, standing entry pose, clear door crossing and engineer route, actor spacing,
advancing skeletal walk cycles, venue spacing, pedestrian movement, memorial-window
visibility, cleanup on skip and removal on retry. The standard
`python3 tools/validate.py` includes these checks.

Double-click [nightlife_preview.command](../nightlife_preview.command) in Finder
to watch the revised street shot. It plays at actual frame time, closes after the shot and writes five images.
To run the same preview from the terminal:

```sh
sh tools/godot.sh --path . --script tests/nightlife_preview.gd
```

The images are written to `logs/nightlife_motion_0.png` through
`logs/nightlife_motion_4.png`, covering closed door, opening, emergence and walking. Double-click [departure_preview.command](../departure_preview.command) to watch the
continuous memory walk, the opening doors and the revised street in one sequence.
The full boss duel and ending remain available with:

```sh
sh tools/godot.sh --path . --script tests/ending_preview.gd
```

Creator acceptance remains open: judge whether the street feels alive, the engineer
stays readable, and the ordinary nightlife supports the sad ending. Render inspection
at 1280×720 on Apple M2 Pro/Forward+ is visual evidence, not a performance benchmark
or a claim about the final audio mix or emotional effect.
