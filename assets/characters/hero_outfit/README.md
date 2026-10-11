# Engineer developer outfit — 11 October 2026

The playable engineer now dresses like the on-call developer he is. Original mesh edit
of the existing Quaternius Ultimate Animated Character Pack `Casual_Male`, CC0 1.0
([existing source/license record](../README.md#rigged-engineer-quaternius-cc0)). No new
third-party downloads; the source FBX, skin, bind poses and retargeted clips are unchanged.

`tools/build_hero_outfit.gd` writes `dev_hoodie.res`. It adds no geometry: each source
triangle moves to a clothing surface by its dominant bone and rest-pose height, turning
the T-shirt and shorts into a hoodie with sleeves shoved past the elbow, ribbed hem,
fingerless gloves, joggers with ribbed cuffs, high-top sneakers with separate soles and
one dyed fringe streak. `rigged_engineer.gd` swaps the mesh in at load and colours it.

The rest of the kit is built at load on bone attachments, placed in rest-pose character
space (`_rest_attach`), so it follows every clip:

- thick black glasses with faint lenses that glow in battle mode;
- over-ear headphones with a gunmetal band and cyan LED rings;
- hood bunched behind the neck, ribbed collar, white tee showing between metal zip
  tapes with a `>_` prompt print, drawstrings with metal aglets, zip pull;
- a glowing `</>` and `git push --force` across the back, plus the existing "ON CALL
  (FOREVER)" sticky note (hidden while seated so they never show through the chair);
- an SRE badge on a red retractable reel, a smartwatch blinking a red pager alert on
  the left wrist and a rubber debugging duck on the belt;
- light-up sneaker soles.

Rebuild: `sh tools/godot.sh --headless --path . --script tools/build_hero_outfit.gd`.
`tests/hero_outfit_tests.gd` checks the clothed legs, floor contact, gear staying on the
head through a real swing, battle glow and the seated back print.
`tests/hero_preview.gd` renders `builds/hero_sheet.png` (front, three-quarter, side,
gameplay back, face, battle mode). Source/output SHA-256 values are in `provenance.json`;
the derived mesh uses Git LFS. The native `engineer_visual.tscn` fallback is untouched.

Review renders in the office lighting: [look sheet](review_sheet.png) (front,
three-quarter, side, gameplay back, face, battle mode) and [seated at the desk](review_desk.png).

Limits: the low-poly source sets where clothing edges fall; the open front and its tee
are separate rigid panels on the torso and abdomen, so extreme twists can show a small
gap. Creative acceptance needs a human run.
