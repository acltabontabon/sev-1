# SEV-1 development conventions

## Direction and scope

- Read [vision](docs/vision.md), the relevant [design](docs/game_design.md) section, and the current [roadmap](docs/roadmap.md) gate before proposing broad work. [Architecture](docs/architecture.md) describes the implementation; README owns launch and controls.
- The human creator is final creative decision-maker and playtester. Deliver a fun action game accessible to non-developers; satire targets systemic incentives rather than entire professions.
- Current playable scope includes movement, a three-hit melee combo, special moves (Reply All, Blame Shift dash slash, Circle Back whirlwind, Works On My Machine counter, Force Rollback ultimate) called out loud, physical enemy deaths with blood on slices, voiced monster barks, kill stamps and streaks, and finisher kill cams, one dodge, an expanded Office After Hours (desks, operations, meeting wing with Quick Sync, pantry, server corridor and vault), Incident 001 with authored waves of four regular archetypes (Corrupted Record, Blocker, Meeting Invite, Scope Creep) and The Variance, roaming outbreak sites, patrolling enemies with visible sight cones and squad tactics, a NEXT objective compass, a floor minimap, outbreak cutscenes where planted employees turn into each wave once the engineer sets one off, voiced RPG-style conversations with the overtime crew, sight-or-hit enemy awareness, a rigged CC0 engineer, rigged CC0 monster bodies, one-hit BUG minion swarms, overtime coworkers, with elemental combo effects, enemy spell visuals and a battle-mode grade, two free temporary combat power-up decisions, run-scoped Burnout, one management decision before containment, pantry interactions, an optional pantry birthday where Kevin turns mid-party, a live title desk, a staged opening, prerecorded local speech with chat-card notifications, and original music. Future circles, bosses, abilities, progression, and narrative scenes in design documents are not automatic implementation authorization.
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
- Work and commit directly on `main`, including focused Git checkpoints, unless the creator explicitly requests another branch. Preserve identity/signing settings; never commit caches, credentials, or build output. Establish LFS before substantial binary asset intake.

## Art and documentation

- Treat cinematic corporate environments seriously: believable materials, cohesive lighting, strong silhouettes, readable threats, deliberate motion and sound. Blockouts are temporary; prioritize one polished small space over broad inconsistent content.
- Record asset source, license, and required attribution before introducing outside art/audio. AI-generated assets still need provenance and visual review. Avoid unnecessary dependencies.
- Use handcrafted, deterministic, event-based postmortem templates when that feature is authorized; no paid AI inference is needed.
- Distinguish established direction, implemented prototype, proposed experiment, and deferred work. Keep each decision in its owning document and link to it. Update affected documentation when implementation or accepted direction changes; remove superseded plans instead of accumulating contradictions.
