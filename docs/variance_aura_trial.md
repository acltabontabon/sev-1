# The Variance aura review

The creator selected the existing red Quaternius Demon on 11 October 2026,
with its supplied Weapon attack, and requested a subtle violet silhouette aura
with motion trails that lag behind movement and fade. This is an isolated
visual preview; normal gameplay has not adopted this palette or aura yet.

Launch `variance_vault_trial.command`. Press 1 for comparison, 2 for close-up,
A for looping attack, I for idle, F for front, B for back, Space to orbit,
and Esc to close. The engineer stands alongside in the server vault.

The preview restores the model's original red materials and turns its front
toward the camera. Faint expanded silhouette passes feather outward; bone
history ribbons remain in world space and fade over 0.95 seconds. Original
procedural aura code was authored with Codex assistance; no generated bitmap
assets were introduced. The ribbons reuse the CC0 Kenney soft trace texture
added by the soft effects session, with cropped U coordinates and mipmaps.
See [texture provenance](../assets/effects/kenney_particles/README.md) and
[monster provenance](../assets/enemies/README.md).

Godot 4.7.2 Metal/Forward+ captures at 1920×1080 on Apple M2 Pro were inspected.
Preview parsing and rendering passed. No gameplay changes were made; full
combat validation and performance acceptance do not follow from this preview.
The scary-aura iteration uses deep violet shadow haze, an uneven slow pulse,
and curling smoke-like trails with a faint violet emission.
The remaining creative checkpoint is the aura's visibility during motion.
