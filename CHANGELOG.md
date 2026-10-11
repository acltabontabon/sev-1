# Changelog

Changes describe the implemented playable prototype. Creative acceptance and
ordinary hardware playtesting remain separate from automated checks.

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
