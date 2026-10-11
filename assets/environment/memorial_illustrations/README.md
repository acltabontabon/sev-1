# Illustrated memories — provenance

Five original sketch memory vignettes created on 11 October 2026 with the
built-in OpenAI image-generation tool from authored SEV-1 prompts. No artist style,
third-party illustration, actor voice, or reference recording was supplied.

The final prompts, generated source paths, selected image checksums and review notes
are recorded in [provenance.json](provenance.json). These are candidate cinematic illustrations,
with creator acceptance still pending. PNGs are tracked with Git LFS.

- [Morgan](morgan_sketch.png): she engineers a conspiratorial coffee escape through the elevator doors.
- [Nadia](nadia_sketch.png): the saved mug and a smothered pager during a long operations shift.
- [Jun](jun_sketch.png): rooftop lunch, a closed laptop, and a surrendered phone.
- [Jo](jo_sketch.png): the cheap-noodle route and a pinky promise that never becomes Monday lunch.
- [Val](val_sketch.png): the engineer's pencil drum solo and the printer's paper-spitting encore.

Each image captures a distinct shared action. The in-engine presentation supplies
slow framing drift, light memory grain, gentle fades and accessible narrator captions.
No runtime generation or paid runtime service is used.

The final selection uses edited graphite/ink sketches with sparse watercolor washes.
Both generation and final edit prompts are preserved; original generated variants remain
at their source paths and are not runtime dependencies.

## Quick listening checkpoint

Run from the repository root:

```sh
sh tools/godot.sh --path . --script tests/finale_preview.gd -- --play-memorial
```

This plays all five narrated memories, their silent casualty shots and the grief beat,
then closes the preview. TAB can skip. In an ordinary run, the sequence begins
automatically after The Variance's duel and the golden form fading.

The selected sources and ten in-game framing checkpoints were visually inspected
with Godot 4.7.2 Forward+ / Metal on Apple M2 Pro. This is layout evidence, not a
frame-time measurement or proof of acting, sound mix, comedic timing or emotional impact.
The director's listening and pacing review remains open.

To replay the full aftermath through departure and Monday, use `--play-ending`
in place of `--play-memorial`.
