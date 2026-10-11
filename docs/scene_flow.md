# Incident 001 scene flow

This is a bounded flow pass over the existing episode, not authorization for another
chapter. The player should always know the immediate action, its destination when
travel is needed, and whether a detour is optional.

| Beat | Connection and player action | Pacing role |
| --- | --- | --- |
| Title → Friday opening | Start Incident / Replay Stage One; TAB skips after the first full viewing | Establish the night shift and incident; first opening is 50.5 seconds, session retries use 3 seconds |
| Discrepancy | NEXT points to a strange employee and names their area; talk, approach or strike to expose the wave | Two authored waves teach combat and transformations; camera exit grants the existing retreat window |
| First change request | Last wave → kill cam → 0.6 real-second beat → upgrade choice | A clean combat break; choice applies only to this run |
| Delivery failure / Management | E answers remotely when no local interaction is in reach; call → ETA decision → containment | Explain why the next fight matters and preview the selected cost; TAB skips the call |
| Optional night-shift detours | Nearby E prompts still talk or use pantry appliances; E at the pantry birthday table or walk into Quick Sync before answering Management | Optional recovery, character conversations and fights; Quick Sync grants +30 health / −20 Burnout, [Kevin's birthday](pantry.md#kevins-birthday-implemented-prototype-11-october-2026) +30 health / −15 Burnout; both rejoin the call objective |
| Containment | Two waves; dependency response adds a Blocker | Escalate known threats; the five-minute ETA remains optional with no expiry penalty |
| Second change request → corridor | Upgrade → gate opens; NEXT leads to the corridor entrance, then inside the vault | Give the office fight a destination and connect the crew's charge to the boss |
| Vault arrival → The Variance | Walk beyond the arrival line; staged crew loss → Unpaid Overtime → playable boss | Existing dramatic climax; TAB skips to combat, with OPEN / shield cues |
| Defeat / victory | Played fall → report, or duel → narrated battle conclusion / golden form fades → casualty introduction → kneeling check → five narrated memories / silent casualty shots → departure and Monday → title | End the current run clearly; memories play automatically, TAB skips the finale; Stage One completion saves at the chapter boundary |

The compulsory path remains discrepancy → upgrade → management commitment → containment
→ upgrade → vault → boss → aftermath/report. Coffee, conversations, the birthday and Quick Sync do
not gate it. Quick Sync is available during investigation; answering Management ends
that detour window when the response starts containment. NEXT matches the nearest
local E prompt during investigation and previews the Quick Sync reward at its doorway.
It occupies the left objective lane so notification cards cannot cover the action.

## Acceptance checkpoint

The 12 October direction candidate adds a direct retry via
`friday_heart_preview.command`: one durable practice target, a full Force Rollback
meter, and the living crew. Press V, let the final slam finish, then keep attacking
to stamp the survey; compare leaving it unanswered. Clear the practice target to
talk to the crew. Personal conversations are reply 2; choose an invitation reply
to seed the corresponding casualty-shot callback on a full run. R retries normally.
The practice target has extra health only in this preview.

`friday_memory_preview.command` jumps directly to the memorial with one **staged**
promise to Morgan, “After this, lunch is on me.” It is a quick comparison fixture;
ordinary play records only replies the player actually chooses. TAB exits the
memorial. The other four coworkers keep their unvisited epitaphs in this fixture.

Judge whether the form's appearance after the spectacle is funny, whether its
stars visibly react to hits, and whether it leaves enough room to read attacks.
Listen to a complete conversation, then compare E to reveal / E to skip voice.
Check keyboard reply 4 as well as a mouse selection. On a full run, compare the
memorial with and without an accepted invitation. These are creative candidates;
automated state checks cannot establish comedy, emotional impact or ordinary
completion time. The opening staging is deliberately preserved in this worktree
because another workflow had uncommitted changes to it at task start.

Run `sh tools/godot.sh --path . --script tests/scene_flow_preview.gd -- --play` for a
quick investigation retry, or start from the title for the ordinary episode.

- In the pantry, press E at the coffee machine; it should serve coffee.
- Press E at the birthday table; the voiced party should play, Kevin should turn, and
  clearing the guests should restore health. TAB skips the party on a retry.
- Talk to a coworker, enter the optional Quick Sync, clear it, then answer Management
  away from a local E prompt. TAB should advance the call into the response choice.
- On a full run, follow NEXT through each outbreak, choose both upgrades, follow the
  corridor and vault markers, and confirm that arrival begins at the marked destination.
- Watch the full boss entrance once, then compare TAB on a retry. Record time to first
  control, time spent looking for the next action, total run time, and optional detours.
- Judge whether the crew feels established before the vault scene and whether the
  cinematic stretch delays combat too long. Preserve the authored scene until that
  feedback establishes a specific cut.

Automated input/transition checks and staged Forward+ captures establish connections
and visible guidance. They do not establish navigation by an unfamiliar player,
ordinary completion time, listening quality, emotional pacing or fun. The historic
5–10-minute slice target remains unverified for this expanded cinematic episode.

Verification on 11 October 2026: all 22 scene-flow checks and the complete
`python3 tools/validate.py` suite passed. Five staged checkpoints (outbreak, pantry,
Quick Sync doorway, corridor and vault) were rendered and inspected at 1280×720,
Godot 4.7.2 Forward+ / Metal on Apple M2 Pro. This is layout evidence, not a
performance measurement or ordinary-run duration test.

12 October direction-pass rendering evidence: the new survey, its automatic approval
and the personal two-shot were captured and inspected at 1280×720 with Godot 4.7.2
Forward+ / Metal on Apple M2 Pro. The rendered review caught and corrected a minimap
overlap and an excessively close wall conversation shot. No new external assets or
voice recordings were introduced.

The existing scripted `tests/performance_probe.gd` run at **1920×1080**, High
(SSAO, glow, MSAA 2×), VSync off, on **Apple M2 Pro**, sampled 9,047 frames excluding
startup: **127.3 mean FPS, 7.69 ms median, 10.43 ms p95, 46.59 ms maximum**, with
four frames over 33.3 ms. The six-second ultimate phase averaged 100.3 FPS,
12.92 ms p95 and no >33.3 ms hitch. This is one scripted run, not a before/after
comparison or a human playthrough. The GPU timer returned zero, so no GPU-time
claim is made. First-use hitches and human visual/audio/pacing acceptance remain open.

The final `python3 tools/validate.py` run passed, including imports, all script
parsing, movement/combat integration, the new real-hit survey and dialogue checks,
and the expanded memorial regressions. The promise casualty shot was also rendered
and inspected. This evidence does not accept the creative result on the director's
behalf or establish Windows runtime behavior.
