# KayKit skeleton visual trial — 11 October 2026

Skeleton Minion from **KayKit Character Pack: Skeletons 1.0**, created by
**Kay Lousberg**. Free tier from the creator’s
[official repository](https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0),
revision `15b62b9bad122f72926c10fb14d622c73819fa54`.
[Pack page](https://kaylousberg.itch.io/kaykit-skeletons).

Licensed **CC0 1.0 Universal**: [bundled source license](license.txt).
Attribution is optional; credit to Kay Lousberg is retained in the notices.
Source paths, retrieval date and SHA-256 hashes: [provenance.json](provenance.json).
Only one free character is included; no paid extras, accessories or plugins.
The GLB embeds its gradient atlas, rig and original animations and is unmodified.
Godot extracts that atlas to `skeleton_minion_skeleton_texture.png` during import;
the generated sidecar's hash is also recorded in provenance.

## Visual review

Double-click `kaykit_trial.command` in the repository root, or run:

```sh
sh tools/godot.sh --path . game/art_trials/kaykit_comparison.tscn
```

The trial shows the actual engineer and one Skeleton Minion in the office lounge,
using the existing office environment and lights. It starts with both bodies at
matching bind-pose height; toggle **Original size** to see the author’s model scale.
Use the buttons (or 1–3) for idle/walk/attack and F/S/B for front/side/back.
Escape closes the viewer. Append `-- --capture` for an ignored 1080p screenshot.

This is a visual comparison, not an enemy-roster replacement or approved art direction.
Original KayKit materials are preserved without the monster flesh shader.
The skeleton’s attack is its own unarmed punch animation; damage, AI and physical
slicing are not connected. The engineer retains the current body, sword and idle
presentation, including the local sword trial when present.

Creator checkpoint: compare proportions, skull silhouette and material brightness
beside the engineer; inspect the walk and punch before accepting a combat trial.

## Rendered evidence

Idle, side-view walk and punch were inspected in the actual office renderer on
Apple M2 Pro, Godot 4.7.2, Metal Forward+, 1920×1080 with existing SSAO/glow/fog.
Bind mesh bounds measure 2.128 m for the engineer and 2.166 m for the minion;
matched-height mode uses uniform scale 0.982, retaining its original proportions.
After 90 warm-up frames, 120 sampled staged frames averaged 8.34 ms with p95
8.54 ms in the final gameplay-idle comparison (presentation/vsync included).
This measures an isolated two-character review, not moving gameplay performance.
Audio was disabled; combat damage, deaths and human visual acceptance remain open.
Ignored captures: `builds/kaykit_comparison.png`, `kaykit_comparison_walk_side.png`
and `kaykit_comparison_punch.png`.
`python3 tools/validate.py` passed the complete import, script parsing and gameplay
integration suite on 11 October 2026 with the concurrent local sword trial present.
The final comparison script also passed its separate `--check-only` run and rendered
smoke runs after the protagonist was switched to its normal gameplay idle stance.
