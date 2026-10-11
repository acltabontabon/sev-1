# Midnight street nightlife — implemented prototype, 11 October 2026

The creator requested a more vibrant exterior in the ending, including a strip club
and people. Incident 001 now stages a small nightlife frontage at the foot of the
existing office tower: Velvet (a signed strip club with a 21+ entrance, door host,
rope line and patrons), Blue Hour cocktail bar, and Midnight Noodles. Pink, cyan and
amber lighting, canopies, shop windows, pavement, a kerb and broken neon streaks on
wet asphalt give the rainy street a lived-in ground level.

Nine clothed rigged characters animate: six patrons/door staff and three pedestrians.
Pedestrians follow short deterministic paths separate from the engineer's departure.
A signed Synergex exit separates the office departure from the club entrance.
The street camera is higher and wider to include the pavement and storefronts.
The sad original music, rain, carried belongings, narrator, departure corridor and
five silhouettes in the memorial window retain their roles. The nightlife leaves the shot
at the window cut. There is no club interior or new playable district.

## Implementation and provenance

[The local scene builder](../game/incidents/nightlife_street.gd) is instantiated by
[the ending](../game/incidents/all_hands.gd) only at the street beat. The ending owns
its lifetime, ticks pedestrian travel on cinematic time, hides it for the window
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
cut, animated actors, clear engineer route, pedestrian movement, memorial-window
visibility, cleanup on skip and removal on retry. The standard
`python3 tools/validate.py` includes these checks.

Double-click [nightlife_preview.command](../nightlife_preview.command) in Finder
to watch the revised street shot. It closes after the shot and writes three images.
To run the same preview from the terminal:

```sh
sh tools/godot.sh --path . --script tests/nightlife_preview.gd
```

The images are written to `logs/nightlife_30.png`, `logs/nightlife_180.png` and
`logs/nightlife_410.png`. To watch the full boss duel and ending, run:

```sh
sh tools/godot.sh --path . --script tests/ending_preview.gd
```

Creator acceptance remains open: judge whether the street feels alive, the engineer
stays readable, and the ordinary nightlife supports the sad ending. Render inspection
at 1280×720 on Apple M2 Pro/Forward+ is visual evidence, not a performance benchmark
or a claim about the final audio mix or emotional effect.
