# README screenshots

Unmodified captures of the actual SEV-1 development build, selected and visually
reviewed on 11 October 2026. These are gameplay images, not promotional renders.
The root README labels them as development screenshots; presentation may differ
between versions. The title image includes the existing in-game SEV-1 wordmark.

| File | Local source capture | Capture date |
| --- | --- | --- |
| `title.png` | `builds/m12_720_op_title.png` | 10 October 2026 |
| `combat.png` | `builds/skill_circle_back.png` | 11 October 2026 |
| `conversation.png` | `builds/m12_720_talk_manager.png` | 10 October 2026 |

All three images are 1280 × 720 PNGs. Git LFS tracks them. `.gdignore` keeps this
promotional directory out of Godot's resource import pipeline.

Original game visuals and writing retain the creator's rights. Depicted models,
fonts, materials, and other third-party assets retain their existing licenses;
see the [asset inventory](../asset_licenses.md) and its source records.
No outside promotional art or new font was introduced.

## Ending PR captures — 11 October 2026

Unmodified staged in-engine captures of the initial memorial changes. The narrator
text shown in these six captures predates the subsequent dialogue refinement. The check
shot shows the engineer kneeling beside Morgan; the five memory captures show the
selected sketch art with the actual narrator captions. Captured in Godot 4.7.2
Forward+ / Metal on Apple M2 Pro. These establish framing and subtitle layout,
not measured performance, ordinary gameplay duration or listening acceptance.

| File | Local source | Resolution |
| --- | --- | --- |
| `ending_check_morgan.png` | `logs/finale_remember_1.png` | 1280 × 720 |
| `ending_memory_morgan.png` | `logs/finale_memory_0_5.png` | 1280 × 720 |
| `ending_memory_nadia.png` | `logs/finale_memory_1_5.png` | 1280 × 720 |
| `ending_memory_jun.png` | `logs/finale_memory_2_5.png` | 1280 × 720 |
| `ending_memory_jo.png` | `logs/finale_memory_3_5.png` | 1744 × 981 |
| `ending_memory_val.png` | `logs/finale_memory_4_5.png` | 1824 × 1026 |

Memory artwork is AI-generated from authored prompts; its source files, exact
prompts and review record are in [illustration provenance](../../assets/environment/memorial_illustrations/README.md).
Git LFS tracks these screenshots; this directory remains excluded from game imports.


## Departure refinement captures — 11 October 2026

Unmodified 1280 × 720 staged captures from Godot 4.7.2, Forward+ / Metal,
Apple M2 Pro. `tests/finale_preview.gd -- --departure` captures the ghost and
street; `--street` repeats the exterior and window. The camera sees Morgan facing
the walking lane, the subdued rainy frontage, and five rigged silhouettes without
living actors behind them. Existing licensed models/materials were reused; no new
outside assets were downloaded. These are visual checks, not performance measurements.

| File | Local source |
| --- | --- |
| `ending_ghost_facing.png` | `logs/finale_exit_3.png` |
| `ending_rainy_departure.png` | `logs/finale_street_8.png` |
| `ending_window.png` | `logs/finale_window_2.png` |
