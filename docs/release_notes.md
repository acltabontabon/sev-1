# SEV-1: Friday Deployment — Playtest Build 0.2

## 0.2.1 — "This is an action game" (10 October 2026)

Answers the creator's review of 0.2.0: the engineer still looked like the old boring
box model and fights lacked spectacle. Combat timing, damage and balance are unchanged;
everything below is presentation.

- **A real, animated protagonist.** The engineer is now a rigged CC0 character
  (Quaternius) with run, roll, hit, death, sit and stand motion; the run/roll/death come
  from a CC0 knight pack retargeted onto the office body. He swings the oversized
  keyboard along big authored arcs (the arms follow it by IK), the third hit is a full
  spinning finisher, the dodge is a roll, and he dies on the carpet with the keyboard
  beside him. He keeps the headphones and the "ON CALL (FOREVER)" sticky note.
- **Elemental combo.** Hit 1 throws a wind crescent ("FORCE PUSH"), hit 2 forks violet
  lightning ("HOT RELOAD"), the finisher erupts in a ring of fire ("HOTFIX"). Hits get
  their own element bursts, and the keyboard leaves a colored swing trail.
- **Enemy magic.** Every enemy draws a spell circle under itself when it winds up (a
  readable warning) and throws shards and a glyph when it strikes: Corrupted Records cast
  red "NULL / 404" glitches, the Blocker an amber "AWAITING DEPENDENCY" circle and
  shield shockwave, the Meeting Invite violet calendar runes ("SYNC", "1:1") over your
  head, Scope Creep a sticky-note storm when it grows, and The Variance argues in red and
  green lightning whenever its shield opens or closes. Defeats burst apart.
- **Battle mode.** When an enemy engages, the screen hits: sting, flash, chromatic split
  and speed lines, then a held combat grade (vignette, hotter glow and color) while the
  fight lasts. The engineer's eyes glow and the keyboard edges cycle RGB.

Limits: retargeted knight motion on a chibi body is approximate (no fingers, some arm
clipping); effects are procedural particles and shaders, not hand-made VFX; whether the
new look and effects feel better is for the creator to judge in play. Performance on the
same M2 Pro: menu about 120 FPS, the full opening 119 FPS mean (max frame 24 ms), a
three-enemy battle-mode fight with continuous combos 119 FPS mean (p95 9.3 ms, max 16.7 ms)
at 1280×720 preview resolution. Validation: 636 assertions across 15 headless suites.

## 0.2.0

Version **0.2.0**, 10 October 2026 (Milestone 12, "Operation Corporate Hell"). Local
macOS tester build; not creator-accepted, not notarized. This build answers the first
external feedback on 0.1: plain presentation, a boring menu, no cinematic moments,
weak comedy delivery, flat notifications, a small map, one enemy type and encounters
that were really a series of duels. It improves Incident 001 only. No new chapter,
currency, progression system, online service or runtime AI was added.

## What changed since 0.1

**First impression**
- The title screen is the dark office at 16:59. The engineer works at a glowing
  monitor while chat notifications land ("All systems operational." … "Except three.")
  and they react. Menu entries carry corporate names with plain labels beside them:
  Acknowledge Incident, Corporate Policy, Onboarding Docs, Legal Has Reviewed This,
  Attempt to Log Off (one confirmation). Pause offers Resume Suffering.
- A 36-second in-engine opening: Friday chat, a cursor on Log Off at 16:59:58, the
  SEV-1 takeover at exactly 17:00, ETA and leadership messages, a held silence,
  "Tangina naman.", lights dying toward Operations and a corrupted record stepping out
  of the production dashboard. Skippable once this device has seen it in full; quick
  retries keep a three-second version.
- New typography (Barlow Condensed, Inter, JetBrains Mono) and a shared interface theme.

**A bigger office with reasons to explore**
- An east meeting wing (a corridor of drifting calendar invites, Meeting Room 3 and a
  pantry), and a restricted server corridor behind a security gate leading to the server
  vault, where The Variance now arrives once you walk in.
- Pantry: the coffee machine grants 40 s of Temporary Motivation (+15% damage and speed)
  and −10 Burnout once, then quotes the one-cup policy; the vending machine, microwave
  and wellness poster each react. Photographed CC0 materials replace flat surfaces, and a
  CC0 night-city panorama now sits outside the windows.

**Encounters**
- Several enemies at once in authored waves with a breather between them; at most two
  wind up at a time, and they spread out, circle while waiting, flank and back off.
- New archetypes: **The Blocker** shields nearby allies after a telegraphed cast (hit it
  mid-cast or kill it); **The Meeting Invite** keeps its distance and books slowing,
  draining meeting zones (step out before it starts); **Scope Creep** grows in reach,
  damage and health every six seconds you ignore it (any hit resets it; a grown one is
  "descoped" for Burnout relief).
- Enemies arrive unaware and busy ("reconciling…", "in a meeting"); they notice you by
  sight, by the noise of fighting or sprinting, or when a colleague flags you, and lose
  you if you break line of sight. Hitting an unaware enemy is a Surprise Review (double
  damage).
- Optional **Quick Sync**: walk into Meeting Room 3 during the investigation and the
  doors shut on "Can we take this offline?"; survive it for +30 health and −20 Burnout.
- Escalating the dependency now returns it as a labeled Blocker.

**Comedy and personality**
- Speech arrives as cards in "Synergize", a fictional internal chat app: each sender has
  a channel and small print; the engineer's lines are said out loud. 53 voiced lines
  (31 new or rewritten), all subtitled.
- A ticket-style HUD (status, open timer, objective) that slides in when the incident
  changes status, health/Burnout/Debt bars that pulse on change, a boss bar, a
  full-width alert banner at key moments (SEV-1 declared, containment, escalation) and
  an evidence board of three system cards at the console. Corporate chat cards collect
  reactions live while you read them.
- Dialogs were redesigned to be read at a glance: upgrades are tilted change-request
  tickets at an emergency Change Advisory Board (risk tag, one big benefit, a debt meter,
  an "APPROVE?" stamp on focus); the management decision is a chat window with
  Leadership's message and three reply bubbles with a Burnout meter; menus and dialogs
  sit on frosted glass; Onboarding Docs shows keycaps and field notes; log off is a
  proper warning dialog. The postmortem adds impact meters and an incident timeline
  recorded from your run (coffee, Quick Sync, what you told Leadership, the vault).
- Writing pass: the status page stays green; "That would be reassuring if the money
  wasn't missing"; leadership replies to each choice; "Special thanks to leadership." /
  "I was the only one here."; a blameless postmortem assigned to you.

**Characters**
- The engineer now reads as a person: open charcoal hoodie, headphones around the neck,
  bed hair, orange-soled sneakers and an "ON CALL (FOREVER)" sticky note on his back.
  The Corrupted Record carries a loading halo that never finishes and orbiting ledger
  pages; The Variance wears a crown of three status screens. Each new archetype has its
  own silhouette.

**Cinematics and audio**
- Evidence push-in, a staged vault arrival that never takes control, slow motion on the
  first sighting of each new archetype, and an ending camera behind a postmortem
  document whose stamps land in sequence.
- Original music beds (title, incident, boss) on a Music bus ducked under voice, with a
  Music volume setting; CC0 interface and effect sounds.

## Known issues and testing limits

- **P0:** none reproduced across the automated incident, encounter, interface and
  release lifecycle suites. Not a claim that every player action was tested.
- **P1 — first-use hitches:** the cold first render reaches about 360–400 ms (hidden by
  the opening's fade from black). In the real flow (opening, then the first wave) the
  worst first-wave frame measured about 28–35 ms; drawing enemy looks early during the
  opening was tried and measured no improvement, so it was not kept. Steady play holds
  the 120 Hz display cap. See performance below.
- **P1 — distribution:** ad-hoc signed, not notarized; recipient Macs may block launch.
- **P2 — unverified by humans:** whether the opening pacing, jokes, chat cards and new
  enemies are fun or funny; difficulty and balance with waves; the "Tangina naman."
  pronunciation (English TTS with a phonetic override); the synthesized music mix.
- **P2 — art:** the engineer and enemies remain native procedural models; a CC0 rig was
  evaluated and declined (see asset inventory). Kenney props are tinted to fit.
- **P3:** controller support, Windows runtime validation, remapping, later chapters.

Performance (Apple M2 Pro / 16 GB, macOS 27, Godot 4.7.2, Forward+/Metal, MSAA 2×,
SSAO, glow, fog, vsync on a 120 Hz display): menu, opening, every area and a five-enemy
fight held about 120 FPS at 1920×1080 (p95 ≤ 10.8 ms). The staged three-path lifecycle probe at 1920×1080 sampled 5,940 frames: mean 128.2 FPS,
median/p95/p99 7.57/9.33/10.59 ms, 15 frames over 16.7 ms (worst 365.7 ms at cold first
render), peak 753 draw calls, tracked static/video memory 115/440 MiB. 0.1 measured
133.5 FPS mean and a 176.5 ms worst frame on the same machine; the larger map and
materials raise the cold-start and video-memory cost.

Validation: 633 assertions across 15 headless suites plus import, every script parse and
the voice manifest. Automated runs stage positions and sometimes raise health; they do
not establish balance or fun.

## Previous: Vertical Slice v0.1 (0.1.0)

Version **0.1.0**, 10 October 2026. Local macOS tester candidate; creator acceptance
and trusted public distribution are not complete. See the accompanying TESTING.md.

### Playable

Incident 001: The Missing Transaction combines Office After Hours, a skippable Friday
opening, two authored encounters, console investigation, two temporary upgrades,
Technical Debt, hit-driven Burnout, a corporate decision, The Variance, and contextual
victory/defeat postmortems. Repeated runs reset all gameplay modifiers.

### That release

- Title screen: SEV-1 / Works on My Machine; Start Incident, Controls, Settings, Quit,
  and credits. Existing mechanics and combat balance are preserved.
- Explicit pause/resume, restart and return-to-menu actions. Decisions survive pause
  and settings; postmortems provide visible retry/menu/quit actions.
- Saved master/effects volume, sensitivity, shake intensity, damage-flash toggle,
  fullscreen and standard/reduced effects. No music track exists, so none is advertised.
- macOS universal app, versioned ZIP, engine notices, release manifest and repeatable
  validation/export/signature/smoke workflow. Windows preset is preparation only.
- Ten application lifecycle checks supplement existing full incident/combat tests.

### Known issues at 0.1

- **P0:** none reproduced in automated incident/lifecycle coverage. This is not a
  claim that every possible player action has been tested.
- **P1 — performance gate open:** reproducible first-use frame hitches remain. A
  1080p M2 Pro lifecycle probe averaged 133.54 FPS but peaked at 176.51 ms; management
  first use reached 49.33 ms and boss arrival 29.36 ms. Steady speed does not prove
  consistently smooth play. Creator acceptance of the remaining hitch is pending.
- **P1 — distribution limitation:** ad-hoc signed, no Developer ID signature or
  notarization. Recipient Macs may block launch pending explicit approval. Public
  trusted distribution and another-Mac testing are outstanding.
- **P2:** native characters/furniture and procedural motion remain temporary; sound
  is synthesized and lacks human mix acceptance. Default Godot application icon.
  Camera-directed cone hit detection and furniture-top pursuit have known limits.
- **P2:** ordinary pacing, difficulty, tradeoff balance, humor and desire to replay
  require human testing. No claim of a measured 5–10-minute human run.
- **P3:** controller support, Intel/Windows runtime validation, more extensive
  accessibility/remapping, finished rigs/sound, and further chapters are deferred.

Performance evidence: Apple M2 Pro / 16 GiB, macOS 27.0.1, Godot 4.7.2,
Forward+/Metal, 1920×1080, MSAA 2×, SSAO, glow and fog. The three staged lifecycles
sampled 4,140 frames (about 31 seconds), including cold first render and UI pauses;
median/p95/p99 were 7.12/9.75/11.56 ms. Twelve frames exceeded 16.667 ms. Tracked
static/video memory peaked at 81.41/340.81 MiB (not OS resident memory). This is a
synthetic source-project probe, not a packaged long-duration or Windows benchmark.

Validation passed 487 assertions plus resource import and every script parse. The
macOS export, ad-hoc signature verification, packaged headless and graphical
combat-to-victory/restart/defeat probes passed. Ten application lifecycle cycles passed.

Automated checks use staged positions and sometimes elevated health/controlled
damage. Graphical rendering is inspected separately; human gameplay/audio acceptance
remains open. No new floor, boss, progression, online service or runtime AI was added.

### Milestone 11 voice candidate

Adds 22 prerecorded local Kokoro candidate clips, authored subtitles, separate Voice volume and saved subtitle preference. No runtime network or AI credentials. Voice candidate artifacts are isolated under `builds/releases/0.1.0-voices`; the previous tester package is preserved. Human casting, pronunciation, mixing and positional listening acceptance remain pending. See [voice evidence and listening route](voices.md).
