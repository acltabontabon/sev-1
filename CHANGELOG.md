# Changelog

Changes describe the implemented playable prototype. Creative acceptance and
ordinary hardware playtesting remain separate from automated checks.

## [0.2.51] — 2026-10-12

- Force Rollback now generates mandatory satisfaction paperwork. Subsequent hits
  stamp approval stars; ignoring the form counts as consent. The survey never
  captures combat input, hides during conversations/cinematics and clears on retry.
- Personal crew conversations are easier to find. All displayed replies have
  number shortcuts, speech finishes before choices appear, and E can explicitly
  reveal text or skip speech. Wider personal shots avoid crowded wall close-ups.
- Accept a coffee or lunch invitation and your actual chosen promise returns in
  that coworker's memorial. The ending includes five narrated illustrated memories,
  a clearer transition from battle into grief, and a continuous walk out through
  the office doors into the rainy street. Monday's postmortem closes the episode.
- The expanded production vault includes industrial equipment and breakable props
  that both the engineer and the boss can destroy. The crew's firefighting entrance
  uses fixed response stations, a connected hose and Destructive Feedback.
- Kevin's optional pantry birthday now becomes a voiced party, a transformation
  and an ambush. Clearing it restores health and reduces Burnout.
- Operations is rebuilt as an incident command station. Temporary power-ups are
  free, clearly described single-effect rewards; normal upgrade debt costs and
  pursuit penalties are retired. Burnout and Management decisions remain.
- The engineer has an on-call developer outfit; office NPCs have distinct authored
  hairstyles. Office/combat color grading is more restrained, with color separation
  confined to combat onset.
- The live title desk includes a coffee-drinking routine. Menus now use Play,
  Controls and Settings, show the six-circle campaign structure with later circles
  locked, and keep focused labels readable. Only Circle I is playable.
- Opening seating, hand placement, sword visibility and the cinematic reveal are
  corrected, with a direct source preview and regression coverage.
- Same delivery as the previous playtest: Windows x86-64 installer, Intel Mac
  x86-64 DMG, SHA-256 checksums and exact-source manifests. Builds remain unsigned
  and unnotarized. Human combat, comedy, pacing and audio acceptance remain open;
  local graphical probes still observe occasional frame-time hitches.

## [0.2.50] — 2026-10-11

- Corrupted Records now use the free KayKit Skeleton Minion instead of the realistic
  demon trials, at their original imported size. Original cartoon materials and supplied animation clips retain
  existing combat behavior, voices, hit timing and physical deaths. See
  [integration and playtest checkpoint](https://github.com/acltabontabon/sev-1/blob/v0.2.50/assets/enemies/kaykit_trial/README.md).

- Sword attacks now use full-body combat clips, two-handed grips, a distinct dash
  pose and counter guard. Kevin Iglesias' free two-handed attack is an optional
  local trial; public checkouts use the existing CC0 Quaternius fallback. See
  [trial and playtest checkpoint](https://github.com/acltabontabon/sev-1/blob/v0.2.50/docs/sword_motion_trial.md).
- Other monster bodies are 10% larger, with matching label clearance, hover offsets and death
  effect sizing. Collision, attack reach and movement tuning remain unchanged.

- The engineer carries the CC0 Heavy Greatsword, with refined sword trails, smoke,
  sparks and restrained shockwave refraction. The Variance gains a pulsing violet
  aura with curling trails, and the finishing duel gains a reciprocal sword/trident
  exchange before the existing finisher.
- Detailed CC0 desks now fill all workstation bays. Acoustic ceiling finish,
  filing storage and conference details make the office more cohesive.
- Fitted CC0 ergonomic office chairs replace the native desk, conference and
  pantry chairs. Chairs, desk drawers, storage and lounge furniture now have solid
  collision; tabletop props, pantry cabinets and floor boxes clear their supports.
- Enemy navigation is rebaked around furniture. Opening and retry control resumes
  clear of the starting chair, and conference/lounge outbreaks use clear floor areas.
- Drew's original Quaternius suit model and coworker motion are restored. The
  human-model trial and its art/build assets are removed. His standing position
  leaves room for the chairs and dialogue camera.
- Removed the stone column and base blocking the lounge-side hallway doorway;
  the passage has a real walking regression check.
- Female office NPCs now wear fitted skirts, blouses or skirt suits, with their
  original female rigs/hairstyles and small earrings. Nadia has a longer skirt;
  adult director Marie has a shorter skirt and lower neckline. Sitting/walking
  motion, conversations and retry are checked with the new outfits.
- Same GitHub prerelease delivery as 0.2.49: Windows x86-64 setup installer,
  Intel Mac x86-64 DMG, SHA-256 checksums and source manifests. Ordinary graphical
  and audio playtesting on those target machines remains pending.

## [0.2.49] — 2026-10-11

First tagged GitHub release of **SEV-1: Friday Deployment**, a personal project.

### Playable now

- Incident 001: an expanded nighttime office, staged Friday opening, authored
  outbreaks, server corridor, The Variance boss fight, and the Monday aftermath.
- Rigged engineer and monsters, three-hit elemental melee combo, dodge, Reply All,
  Blame Shift, Circle Back, Works On My Machine counter, and Force Rollback ultimate.
- Physical sliced deaths, blood effects, voiced monster barks, kill streaks,
  finisher cameras and battle grades.
- Patrolling enemies, sight cones, squad tactics, outbreak transformations,
  objective compass and floor minimap.
- Voiced overtime crew conversations with replay variations and occasional
  emergency healing; Technical Debt upgrades and run-scoped Burnout.
- Consequential Operations call, expanded Quick Sync stand-up encounter and floor
  hazards, pantry hauntings and proximity snoring.
- Grief-to-rage transformation, revised boss duel and ending, grounded office
  departure and a To Be Continued screen.
- Settings, pause/menu/retry flow, Stage One completion saves, preserved replay
  progress and a completion unlock for earlier testers. Stage Two is unavailable.
- Polished starting workstation with CC0 desk props and locally authored screen/light staging.
- Camera obstruction, seating/floor support, HUD updates and idle/background
  rendering refinements.

### Distribution

- Version tags now trigger GitHub Actions validation and native Windows/Intel Mac
  exports with pinned Godot 4.7.2 and verified official downloads.
- Windows x86-64 setup installer (per-user, optional desktop shortcut, uninstall)
  and Intel Mac x86-64 DMG (drag to Applications).
- Packaged headless gameplay smoke checks, Windows install/uninstall checks,
  SHA-256 checksums and source-revision manifests.
- Clean-checkout asset bootstrap prevents loading the startup theme before fonts
  are imported; normal theme-enabled validation and export follow.
- No signing certificates or notarization. Installation instructions and asset/
  engine notices are included with both packages.

### Install

Windows: download the `windows-x86_64-setup.exe` asset and run it.
Intel Mac: download the `macos-x86_64.dmg` asset and drag the app to Applications.
No Godot editor is required. See [installation instructions](https://github.com/acltabontabon/sev-1/blob/main/docs/install.md)
for unsigned-app prompts, requirements and controls.

### Known limits

- Prototype, keyboard/mouse only, one playable stage. No online services or paid
  runtime AI. Stage Two and later circles are deferred.
- Windows 10+ with a Vulkan-capable GPU; Intel macOS 14+ with a Metal-capable GPU.
  Actual graphical performance and audio on those machines need human testing.
- First-use hitches, combat balance, pacing, comedy, voices and music still need
  creator playtest acceptance. Automated checks do not prove those outcomes.

## [0.2.48] — 2026-10-11

Both native source validators and the Windows installer checks passed. Mac packaging
was blocked because the official template contains only a universal executable.
No complete cross-platform release was published; 0.2.49 exports and thins that
executable to Intel before testing and packaging.

## [0.2.47] — 2026-10-11

Initial CI tag. Cold-checkout font import failed before packaging, so no installers
or GitHub release were published. Superseded by 0.2.49.

## Earlier untagged development — 2026-10-10 to 2026-10-11

- 0.1: movement/combat prototype, office/Incident 001, upgrades, Burnout,
  narrative presentation and a local Mac tester release gate.
- 0.2 through 0.2.46: offline voiced dialogue, CC0 art and animations, expanded
  office/encounters, special moves, revised cinematics and ending, saves/replay,
  and rendering improvements summarized in the first tagged release above.
- Detailed historical validation and acceptance records remain in
  [release engineering](docs/release.md) and [release notes](docs/release_notes.md).
