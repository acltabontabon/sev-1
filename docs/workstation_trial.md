# Free office furnishing pass — 11 October 2026

## Implemented prototype

All eight workstations now use Poly Haven’s CC0 Metal Office Desk, with 2K textures
embedded in self-contained GLBs. The starting desk additionally uses Desk Lamp Arm
01, original keycaps, desk mat, notebook markings and a shadowed warm task-light pool.
Other desks share the detailed desk and mat with the existing lighter monitor/keyboard
geometry, keeping the close-up keycaps confined to the starting desk.

The dedicated `polished_workstation.tscn` retains the tabletop collision, chair origin,
monitor/display positions and existing story node paths. The imported desk is fitted
to the original 2.25 × 0.95 m footprint and 0.8225 m surface height. Tabletop and
drawer-pedestal boxes fit the imported geometry. The monitor and mug remain simplified;
this pass does not establish final art quality for the whole office.

`tools/office_details.py`, called by the office builder, adds a suspended acoustic
ceiling with tee runners and air returns, framed fabric desk dividers and pinboard
notes, three perimeter filing cabinets with binders, glass privacy bands, sliding-door
handles and conference-call equipment. The existing lighting is preserved. Ceiling
and small finish remain visual-only; perimeter filing cabinets now have
fitted world collision. Navigation is rebaked after furniture changes. The conference
display and its text now sit on the screen housing
instead of floating 1.25 metres in front of it. Many small props remain simplified.
No new downloaded assets were needed for the ceiling/storage extension.

The subsequent authorized chair pass replaces the shared native office chair with
Innerscene’s CC0 VECTOR ergonomic chair: upholstered seat/back, armrests, lumbar
support, gas lift and five twin-wheel casters. It is fitted to the established 0.56 m
seat height and desk-facing orientation. Desk, conference and pantry instances all
share the model; lounge seating is preserved. Source geometry (51,164 triangles) is
consolidated offline from 60 pieces to five material surfaces, with no runtime build.
[Source/license/build record](../assets/environment/innerscene_chair/README.md).

`sh tools/godot.sh --path . --script tests/capture_chairs.gd` writes four fixed views
under `builds/chair_*.png`; the desk fit, seated engineer, title backdrop and conference
table were visually inspected. Existing seated offsets and chair world origins are
preserved during the staged sitting pose. Gameplay now releases the engineer beside
the solid chair, with capsule clearance checked on skip and retry. Judge the upholstery,
proportions, character fit and camera readability
by starting a normal run and walking around the desk bays. R retries the incident.

[Source, license and retrieval records](../assets/environment/poly_haven_workstation/README.md).
`tools/build_office.py` owns the generated scenes. Generated scenes preserve existing story node paths. No purchased assets or new dependencies are required.

The collision/overlap refinement fits static boxes to chairs, desk drawers, filing
cabinets, lounge seating/table/shelf, the wing bench, supply boxes and window pots.
Tabletop plants/books/lamps now rest at the 0.8225 m desk surface, with lamps inside
their supporting desk footprint. Boxes move clear of drawer pedestals. Pantry cabinets
and appliances move inside the east wall; counter and fridge collision match the
imported corner pivots. Loose tabletop clutter and foliage remain non-solid.
The east lounge chair moves beside the sofa, clear of the structural column and
wing approach, with its nearby plant moved clear of the chair. The navigation mesh
is rebaked; walking into a chair/drawer stops the capsule, and
the existing enemy-pursuit and ramp checks cover the resulting routes. The conference
outbreak point moves from between the now-solid chairs to the open entrance area;
every outbreak site and its twelve surrounding spawn slots are checked for reachability.

## Review and retry

Launch with `sh tools/godot.sh --path .`. Inspect the starting desk on the title
screen, then start a run and walk around it. Judge the materials, lamp brightness,
chair/body fit, camera readability and whether the more detailed prop suits the
surrounding office. Retry normally; no special mode is required.

A repeatable static review is available with:

```sh
sh tools/godot.sh --path . --script tests/capture_workstation.gd
```

It writes `builds/workstation_after.png`. The pre-change capture is
`builds/workstation_before.png` in this local workspace; captures are ignored build
output. The camera and office lighting were identical for both captures apart from
the workstation’s own task-light replacement. The title backdrop was also inspected with the seated engineer. Human visual acceptance is pending.

Matching whole-office captures are available with:

```sh
sh tools/godot.sh --path . --script tests/capture_office_finish.gd
```

It writes `builds/office_finish_{desks,floor,conference,storage}_after.png`. Local
`_before.png` images now retain the same cameras with the previous native chairs.
All four office finish views were visually inspected. The earlier ceiling/storage
pass measured on Apple M2 Pro, Godot 4.7.2, Metal Forward+, 1920 × 1080, project
MSAA 2×/SSAO/glow/fog, 90 warm-up frames and 120 samples per view: after mean
8.33–8.34 ms, p95 8.48–8.51 ms; before mean 8.33 ms, p95 8.46–8.48 ms.
The desk view rises from 227 to 245 draw calls; the central floor from 212 to 240.
These static, actor-free measurements include vsync, which masks GPU headroom;
they do not establish combat performance. Human visual and moving-combat acceptance
remain pending.

Chair replacement measurement with the same cameras/settings: Apple M2 Pro,
1920 × 1080, Godot 4.7.2 Metal Forward+, MSAA 2×/SSAO/glow/fog, 90 warm-up frames
and 120 samples per view. Mean remains 8.33 ms; p95 8.44–8.55 ms. Desk/floor draw
calls are 254/244, versus 245/240 with the previous native chairs. This static test
includes vsync and no characters or combat; it is not evidence of unchanged whole-run
performance. The imported model increases geometry even after material consolidation.

Full `python3 tools/validate.py` passed, including import, script parsing and every
integration suite. Added office checks cover starting-desk collision height, imported
mesh alignment/footprint, all eight detailed desks, and visual clearance of the central
fighting lane. Chair checks cover floor alignment, bay dimensions and the established
seat reference. The collision refinement also passed the full suite, including
walking stops at chairs/drawers, opening/retry capsule clearance, tabletop support,
lounge prop separation, pantry wall clearance and every outbreak spawn route.
Final desk, pantry, storage, standing-handoff and lounge views were rendered and
visually inspected. Human snagging/flow acceptance remains pending. Existing
environment checks cover routes and camera clipping. The tiny notebook caption
was removed after the readability check rejected it; the notebook now uses markings.

## Free character candidates — current status

The creator set a free-only asset budget. These are candidates for a separate
single-character trial, not authorization to replace the cast.

- [Quaternius Universal Base Characters, Standard edition](https://quaternius.itch.io/universal-base-characters):
  free CC0 download, FBX/glTF, humanoid rigs, compatible with the Universal Animation
  Library already used here. The full kit advertises six body bases and twenty
  hairstyles, but the free Standard edition is a subset; confirm its contents before
  selecting a body. Office clothing needs authoring/fitting. The paid Source edition
  is not needed or authorized.
- [MakeHuman core assets](https://static.makehumancommunity.org/makehuman/faq/are_makehuman_files_free.html)
  plus [Suits 01](https://static.makehumancommunity.org/assets/assetpacks/suits01.html):
  core humans and Margaret Toigo’s formal clothing are CC0. A route to more realistic,
  distinct coworkers, with character assembly, material/export preparation and
  animation retargeting required. Community add-ons carry their own licenses; only
  individually verified assets qualify.

Source pages checked 11 October 2026. MakeHuman was subsequently selected for the
[single Drew trial](makehuman_trial.md),
with build-time export/retargeting and scale correction. Quaternius Universal Base
Characters remains unimported. Neither source establishes finished facial animation.
