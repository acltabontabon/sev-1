# Blood material refinement — 11 October 2026

Implemented prototype in the current Incident 001 slice, following the creator's
request for blood that reads as blood rather than chocolate. Gore remains part of
the established [visual direction](vision.md#tone-established-direction-10-october-2026).

The hero's aftermath coating uses the original procedural
`game/combat/blood_coating.gdshader`: distinct crimson splashes, smaller satellite
drops and elongated runs, with exposed skin and clothing between stains. Patterns
are anchored to the mesh and scaled to its local bounds, including the imported
FBX body's small local coordinates. Existing aftermath ownership removes the
overlay on skip/retry. It adds no external assets or dependencies.

Spray is brighter crimson. Floor decals retain their existing cap, lifetime and
cleanup, with an ORM texture that gives the pool a wet, nonmetallic surface rather
than inheriting the floor's material. The monster flesh shader uses a source-color
blood uniform to retain saturated red under the vault lighting; its existing
health-driven coverage remains unchanged. Decal material behavior follows the
[Godot 4.7 Decal documentation](https://docs.godotengine.org/en/4.7/classes/class_decal.html).

Human checkpoint: slice an enemy, fight The Variance, then inspect the hero in the
aftermath face close-up and office departure. Judge red versus brown, wetness,
splash shape and whether the eyes and silhouette remain readable. Use R to retry;
TAB can skip the closing presentation. Graphical review does not establish fun,
performance or final creative acceptance.
