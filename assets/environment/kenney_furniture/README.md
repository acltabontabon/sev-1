# Pantry props (Kenney Furniture Kit, CC0)

Retrieved 10 October 2026 from `kenney.nl/assets/furniture-kit` (CC0 1.0,
[LICENSE_kenney.txt](LICENSE_kenney.txt)); attribution optional and given voluntarily.
Unmodified GLB files, renamed to snake_case, stored with Git LFS.

Used: `kitchen_cabinet`, `kitchen_sink`, `kitchen_coffee_machine`, `kitchen_microwave`,
`toaster`, `kitchen_fridge_large`, `potted_plant`, `trashcan`.

The kit is authored at roughly half scale and bright; `tools/build_office.py` scales
each instance and `game/rooms/office/prop_tint.gd` darkens and desaturates their
materials at load so they sit in the after-hours palette. Collision uses simplified
generator boxes, not the meshes. The kit's chair and round table were evaluated and
rejected as visually toy-like; the pantry uses the native office chair and a native
table instead.
