# Chapter completion saves

Implemented on 11 October 2026 at the creator's request. Stage One means the whole
Incident 001 episode, not its internal encounter states. Stage Two is not playable.
The title presents Stage One as Circle I, The Reconciliation Abyss, of the six
[design circles](game_design.md#six-circles-of-corporate-hell); chapter IDs are unchanged.

## Player behavior

- Resolving Incident 001 automatically saves Stage One completion before its finale
  returns to the title. The victory report says “Circle I cleared. Progress saved.”
  and Play → Campaign tags Circle I “Incident 001 · Cleared”.
- The campaign lists all six circles. Only Circle I is a button; Circles II–VI are
  dimmed, unfocusable and captioned as not built yet, never as locked rewards.
- Choosing Circle I again replays the same incident; replay, death, R restart, and
  returning to the title never erase completion.
- Earlier testers choose “Cleared Circle I in an older build?” on the campaign, then
  “Mark Circle I Cleared.” Back/Escape cancels without saving. This trusts
  the tester's claim; older builds did not record completion.
- Save failures show a warning and a Retry Save action on the title and campaign; they never claim
  progress was saved. Unsupported or damaged files are preserved rather than replaced.

## Storage and future integration

`game/release/chapter_progress.gd` owns `user://chapter_progress.json`, separately
from preferences. Schema version 1 stores `completed_chapters: ["incident_001"]`
and `next_chapter: "stage_two"`. No health, upgrades, Technical Debt, Burnout, combat
positions, or online account is serialized. A temporary write replaces the destination
only after a successful write. This is local device progress, not cloud synchronization.

`front_end.gd` checks resolution while processing, and before returning to the menu,
restarting, or quitting. It attempts once per run and offers an explicit retry on
failure. Tests/previews using alternate preference paths use separate chapter files.

Future Stage Two work must keep these chapter IDs and the existing Godot user data
directory stable. Do not version the save path with the application release. Add a
Continue action that reads `next_chapter` only when its playable scene exists, and
turn that circle's campaign row into a button; keep Circle I replayable. Extend/migrate the schema explicitly if new chapters or carried
choices require it. This increment does not establish carry-over upgrade rules.

## Validation and human checkpoint

`tests/chapter_progress_tests.gd` covers save/reload, version and damaged-data handling,
failed writes, tester unlock/cancel, completed title, replay/death/restart, and fresh
application load. `tests/release_tests.gd` checks actual incident resolution saves
completion across the existing lifecycle cases, including the finale return to title.
Both are included in `python3 tools/validate.py`.

Verification on 11 October 2026: 17 chapter-save checks and the release lifecycle
suite passed. Fresh, unlock, and completed menus were rendered and inspected at
1280×720, Forward+, Apple M2 Pro. This is menu layout evidence, not a performance
measurement. The two stale Operations HUD assertions have since been corrected:
the anywhere management call has no destination arrow, the vault keeps its arrow and
distance, and the incident header reads UPDATE REQUESTED. Full validation passed for the frozen 0.2.46 build snapshot.
The 0.2.46 Mac rebuild includes packaged smoke checks for tester unlock, victory save,
the saved-progress title, and replay preserving completion on disk. Packaged headless
combat and graphical menu checks passed; see [release evidence](release.md#0246--stage-one-saves-and-replay-11-october-2026).

Human checkpoint: finish Stage One (or use the earlier tester unlock), quit and reopen,
check Circle I's CLEARED tag and replay it, then replay/restart and reopen again.
Confirm the menu stays readable at your normal resolution and the ending still plays.
Headless checks do not establish visual quality or human acceptance.

See [game design](game_design.md), [architecture](architecture.md), and
[launch and controls](../README.md).
