# Friday Deployment — tester guide

## Start

Unzip the macOS package and open **SEV-1 Friday Deployment.app**. No editor or
programming tools are needed. This is an ad-hoc signed local test build, not notarized;
macOS may require the recipient's explicit approval in Privacy & Security. Only
approve a build received from the creator. Do not disable Gatekeeper system-wide.
If macOS refuses it, report the exact message to the creator.

Apple Silicon is the tested platform; Intel is included in the universal bundle but
unverified. The app declares macOS 14+, but only macOS 27.0.1 on M2 Pro has been
measured. Keyboard and mouse are required. No controller mapping is implemented.

Choose **Controls** or **Settings**, then **Start Incident**. Aim for one ordinary
run; the 5–10-minute target has not yet been measured with human testers. Tab skips
the opening and boss arrival. Nothing is saved except device preferences.

## Play the incident

1. Move with WASD/arrows and look with the mouse. Left mouse/F attacks; press again
   late in recovery to chain up to three hits. Q/right mouse dodges. Space jumps;
   Shift sprints. Watch the orange warning arc, move aside, then counterattack.
2. Clear two waves (Corrupted Records, then Scope Creep). Enemies start unaware; a hit
   before they notice you deals double. Approve a change request with mouse,
   arrows/Enter, or 1/2/3: read its benefit and Technical Debt cost.
3. Follow OPERATIONS to the far wall. Press E nearby: the evidence board shows three
   systems; press the number of the one that never received the payment (if stuck:
   3, Payment Processing). Optional before that: the east wing. Press E at the pantry's
   coffee machine; walk into Meeting Room 3 if you want the Quick Sync ambush.
4. Reply to Leadership's DM. Contain two waves: hit The Blocker mid-cast or kill it
   first; step out of Meeting Invite circles before they start; don't ignore Scope Creep.
5. Walk through the lifted gate and the server corridor into the vault. Fight The
   Variance: evade during SHIELDED, attack during OPEN, trust the solid diamond.
6. Read the postmortem. **Restart Incident** or R retries with neutral health and
   modifiers. **Back to Desk** returns to the title.

Escape pauses, including during decision screens. Resume returns to the pending
choice. Pause offers settings, controls, restart, menu and quit. Losing app focus
pauses ordinary gameplay. R is ignored inside settings/controls so it cannot reset
the run while adjusting preferences. Use Quit or the window close action to exit.

## Report a bug

Include version **0.2.3**, Mac model/chip, macOS version, resolution, graphics setting,
the incident stage, choices made, what you expected, what happened, and repeat steps.
A screenshot or short clip is useful. Note whether retry fixed it. Local logs and
`settings.cfg` live in `~/Library/Application Support/SEV-1/`. Share logs only after
checking them for information you do not want to disclose. There is no telemetry.

## Two-minute feedback

Answer briefly; use 1 (poor) to 5 (strong) where helpful.

1. Did you understand what was happening and what to do next?
2. Did movement, camera and combat respond as expected?
3. Were enemy warnings and hits fair and readable?
4. Could you explain the upgrade tradeoffs?
5. Did Technical Debt and Burnout affect your choices?
6. Did the corporate humor work? Which line landed or missed?
7. Did the office, characters and UI look coherent?
8. What confused or frustrated you? Any bug or uncomfortable effect?
9. Would you play another run? Why?
10. What was the most memorable moment? How long did your run take?
11. Did the title screen and the opening make you want to start? Was 36 seconds right?
12. Could you tell the four enemy types apart, and what each wanted you to do?
13. Did the chat cards, change-request tickets and Leadership DM read easily in a fight?
14. Did you visit the pantry or the Quick Sync room? Why or why not?

Creator acceptance should include a normal win, a defeat/retry, all three management
choices across runs, settings across a fresh launch, and a copied ZIP on another Mac.
Automated staged combat does not establish difficulty, ordinary duration, sound
quality, camera comfort, or whether the slice is fun.

## Voice candidate listening test

The Milestone 11 candidate adds a Voice volume slider and Subtitles toggle. Follow the [voice listening route](voices.md#validation-and-human-listening-route), especially opening timing, boss spatial speech, choice/pause suspension and terminal reports. Candidate performances have not received human listening acceptance. Existing gameplay and platform acceptance gates remain open.
