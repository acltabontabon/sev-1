# SEV-1 development conventions

## Direction and scope

- Read [vision](docs/vision.md), the relevant [design](docs/game_design.md) section, and the current [roadmap](docs/roadmap.md) gate before proposing broad work. [Architecture](docs/architecture.md) describes the implementation; README owns launch and controls.
- The human creator is final creative decision-maker and playtester. Deliver a fun action game accessible to non-developers; satire targets systemic incentives rather than entire professions.
- Current playable scope is movement, a three-hit melee combo, one dodge, and one enemy. Future circles, bosses, abilities, progression, and narrative scenes in design documents are not automatic implementation authorization.
- Preserve the existing playable. Follow the current user request and accepted feedback; refine combat before expanding content. Keep each increment independently playable with concrete acceptance criteria and a quick retry.
- Avoid multiplayer, open worlds, large procedural systems, elaborate inventory/skill trees, custom engine frameworks, databases, authentication, paid runtime AI, and complex cinematic pipelines at this stage.

## Implementation

- Keep Godot 4.7.2 standard, typed GDScript, Forward+, macOS development, and the future Windows target. Do not upgrade the engine casually.
- Run Godot with `sh tools/godot.sh`; `GODOT_BIN` overrides executable discovery. Godot may require access to normal user cache directories.
- Prefer text `.tscn` scenes and `.tres` Resources where needed. Co-locate scripts with their owning scenes. Keep tuning in exported properties or small typed Resources when justified; do not create speculative data layers.
- Use composition and local signals. Introduce shared abstractions/autoloads only for demonstrated needs. Reuse existing components before inventing frameworks.
- Use lowercase snake_case paths, exact resource-path casing, typed GDScript, tabs, UTF-8, and LF. Preserve `.uid` and asset `.import` sidecars.
- Verify uncertain APIs against Godot 4.7 documentation and validate generated code/scenes. Do not assume plausible-looking code is correct.
- Inspect current files/status before editing. If another workflow changes an overlapping file, defer that edit or coordinate; do not overwrite it or stop a running implementation to apply planning changes.

## Validation and delivery

- Run `python3 tools/validate.py` after gameplay changes. It covers import, script parsing, and movement/combat integration. Add meaningful regression checks for new behavior; do not substitute mirrored implementation tests for outcome checks.
- Headless tests skip audio and do not prove visual quality, sound, performance, or fun. Inspect the actual rendered scene and provide a human playtest checkpoint. Measure performance with stated hardware, resolution, and settings.
- After gameplay changes, report what changed, what actually passed/failed, known limits, how to play, and the feedback needed. Preserve the working movement/camera/combat baseline.
- For documentation-only changes, verify links, status claims, consistency, and preservation of runtime files. Do not launch/restart the game or rerun imports merely to validate prose.
- Use `codex/` branches for implementation and focused Git checkpoints. Preserve identity/signing settings; never commit caches, credentials, or build output. Establish LFS before substantial binary asset intake.

## Art and documentation

- Treat cinematic corporate environments seriously: believable materials, cohesive lighting, strong silhouettes, readable threats, deliberate motion and sound. Blockouts are temporary; prioritize one polished small space over broad inconsistent content.
- Record asset source, license, and required attribution before introducing outside art/audio. AI-generated assets still need provenance and visual review. Avoid unnecessary dependencies.
- Use handcrafted, deterministic, event-based postmortem templates when that feature is authorized; no paid AI inference is needed.
- Distinguish established direction, implemented prototype, proposed experiment, and deferred work. Keep each decision in its owning document and link to it. Update affected documentation when implementation or accepted direction changes; remove superseded plans instead of accumulating contradictions.
