# Free workstation fidelity trial — 11 October 2026

## Implemented prototype

Only the engineer’s starting workstation uses Poly Haven’s CC0 Metal Office Desk
and Desk Lamp Arm 01, with 2K textures embedded in self-contained GLBs. Original
keycaps, desk mat, notebook markings and a shadowed warm task-light pool complete
the trial. The shared workstation scene remains the art for every other desk.

The dedicated `polished_workstation.tscn` retains the tabletop collision, chair,
monitor/display positions and existing story node paths. The imported desk is fitted
to the original 2.25 × 0.95 m footprint and 0.8225 m surface height. It adds no
collision or navigation obstacles. The chair, monitor and mug remain simplified;
this trial does not establish final art quality for the whole office.

[Source, license and retrieval records](../assets/environment/poly_haven_workstation/README.md).
`tools/build_office.py` owns the generated scenes. Regeneration preserves unrelated
resource IDs. No purchased assets or new dependencies are required.

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

Static rendered review: Apple M2 Pro, Godot 4.7.2, Metal Forward+, 1920 × 1080,
project environment with SSAO/glow/fog, 90 warm-up frames and 120 measured frames:
mean 8.47 ms, p95 8.61 ms. This includes presentation/vsync and has no actors or
combat; it is not a whole-run performance claim or a before/after benchmark.

Full `python3 tools/validate.py` passed, including import, script parsing and every
integration suite. Added office checks cover starting-desk collision height, imported
mesh alignment/footprint and limiting the trial to one desk. The tiny notebook caption
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
