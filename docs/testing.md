# Friday Deployment — tester guide

## Start

Install the Windows x86-64 setup package, or open the Intel Mac DMG and drag
**SEV-1 Friday Deployment.app** to Applications. No editor or programming tools
are needed. These GitHub playtest packages are unsigned and unnotarized; follow
the included [installation instructions](install.md) for system prompts.

The release targets Windows 10+ with Vulkan-capable graphics and Intel Macs with
macOS 14+ and Metal-capable graphics. Local graphical measurements use an Apple
M2 Pro source build; they do not establish performance on these release targets.
Keyboard and mouse are required. No controller mapping is implemented.

Choose **Controls** or **Settings**, then **Play** → **The Reconciliation Abyss**. Aim for one ordinary
run; the 5–10-minute target has not yet been measured with human testers. Tab skips
the opening and boss arrival. Circle I (Stage One) completion saves separately from device preferences. After
completion, the campaign marks it CLEARED and choosing it again replays without erasing it. Earlier testers can
choose **Play** → **Cleared Circle I in an older build?** → **Mark Circle I Cleared**.
Check the CLEARED tag after quitting and reopening; Circles II–VI are listed but not built yet.

## Play the incident

1. Move with WASD/arrows and look with the mouse. Left mouse/F attacks; press again
   late in recovery to chain up to three hits. Q/right mouse dodges. Space jumps;
   Shift sprints. Watch the orange warning arc, move aside, then counterattack.
2. Clear two waves (Corrupted Records, then Scope Creep). Enemies start unaware; a hit
   before they notice you deals double. Take a free power-up with mouse,
   arrows/Enter, or 1/2/3: read its one combat benefit; the power-up is free and lasts this run.
3. After the first encounter, press E to answer Management from wherever you are
   (step away from nearby coworkers or appliances if E offers their interaction).
   Hear the call or skip it with Tab. Optional before that: the east wing. Press E at the pantry's
   coffee machine; press E at the birthday table to sing for Kevin; walk into Meeting Room 3
   if you want the Quick Sync ambush.
4. Reply to Leadership's DM. Contain two waves: hit The Blocker mid-cast or kill it
   first; step out of Meeting Invite circles before they start; don't ignore Scope Creep.
5. Walk through the lifted gate and the server corridor into the vault. Fight The
   Variance: evade during SHIELDED, attack during OPEN, trust the solid diamond.
6. A victory leads through the duel, the crew's memorial, departure and Monday's
   postmortem call, then returns to the title. TAB skips the finale. A defeat offers
   the incident report and retry. R restarts with neutral health and modifiers;
   replay from the campaign keeps saved completion.

For 0.2.51, fill Focus and press V for Force Rollback. Continue landing hits to
stamp the satisfaction survey, or ignore it and watch what the company records.
During a breather, talk to a coworker and choose “Tell me something normal.”
Accept an invitation, then look for your chosen promise in that coworker's memorial.
Number keys select every displayed reply; E reveals text, then skips remaining speech.

Escape pauses, including during decision screens. Resume returns to the pending
choice. Pause offers settings, controls, restart, menu and quit. Losing app focus
pauses ordinary gameplay. R is ignored inside settings/controls so it cannot reset
the run while adjusting preferences. Use Quit or the window close action to exit.

## Report a bug

Include version **0.2.51**, computer model/CPU/GPU, operating system, resolution, graphics setting,
the incident stage, choices made, what you expected, what happened, and repeat steps.
A screenshot or short clip is useful. Note whether retry fixed it. Local logs and
`settings.cfg` live in `~/Library/Application Support/SEV-1/` on macOS or
`%APPDATA%/SEV-1/` on Windows. Share logs only after
checking them for information you do not want to disclose. There is no telemetry.

## Two-minute feedback

Answer briefly; use 1 (poor) to 5 (strong) where helpful.

1. Did you understand what was happening and what to do next?
2. Did movement, camera and combat respond as expected?
3. Were enemy warnings and hits fair and readable?
4. Could you immediately explain what your chosen power-up does?
5. Were the free power-ups immediately understandable? Did Burnout affect your management reply?
6. Did the corporate humor work? Which event or line landed or missed? Did the rollback survey get in the way?
7. Did the office, characters and UI look coherent?
8. What confused or frustrated you? Any bug or uncomfortable effect?
9. Would you play another run? Why?
10. What was the most memorable moment? Did an accepted invitation change how the memorial felt? How long did your run take?
11. Did the title screen and the opening make you want to start? Was the 50-second narrated opening right, or too long? Was the reveal scary and funny?
12. Could you tell the four enemy types apart, and what each wanted you to do?
13. Did the chat cards, change-request tickets and Leadership DM read easily in a fight?
14. Did you visit the pantry birthday or the Quick Sync room? Why or why not?

Creator acceptance should include a normal win, a defeat/retry, all three management
choices across runs, settings across a fresh launch, and a copied ZIP on another Mac.
Automated staged combat does not establish difficulty, ordinary duration, sound
quality, camera comfort, or whether the slice is fun.

## Voice candidate listening test

The Milestone 11 candidate adds a Voice volume slider and Subtitles toggle. Follow the [voice listening route](voices.md#validation-and-human-listening-route), especially opening timing, boss spatial speech, choice/pause suspension and terminal reports. Candidate performances have not received human listening acceptance. Existing gameplay and platform acceptance gates remain open.

## Opening head-turn regression

The missing-transaction reveal now turns the coworkers' neck and head bones with a
limited horizontal glance; their body roots and lower-body poses remain anchored to
their chairs or standing positions. Skip, natural completion and restart clear the
reveal poses. `tests/opening_stare_tests.gd` checks the actual reveal event on all twelve
coworkers, unchanged hips/leg/foot transforms, visible head turns and pose cleanup; it
runs through `python3 tools/validate.py`.

Human checkpoint: start a fresh incident and watch the night shift when the monitors
ask “WHERE IS IT?” (about 40 seconds in). The seated coworkers should glance toward
the engineer while their hips and legs stay on their chairs, with no body swing through
the desks. Check the return to ordinary routines after the opening; repeat with Tab
skipping after the glance. Rendered inspection checks furniture support, but the
creator still accepts the head-turn timing and horror beat.
