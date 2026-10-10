# SEV-1: Friday Deployment — Playtest Build 0.2

## Source update — Gossip has a whole office (11 October 2026)

Four gossip performances now cover Migs’ fake dentist appointment and CEO parking
space, Gab’s copied holiday reply, and Bea’s argument with the printer. JO retains
Kevin, the ancient fridge yogurt with a retention bonus. This replaces the all-Kevin
pass below; coffee and lunch takes, choices, recall and cinematic timing are preserved.
The revised lines use existing local stock voices with updated provenance; human
listening acceptance remains pending.

## Source update — Monday starts again (11 October 2026)

- Removed the legacy victory speech queued after the finale, including “Great
  teamwork” and the repeated postmortem. Resolved reports are silent, including
  headless lifecycle paths; defeat dialogue is preserved.
- The engineer answers the final on-call assignment with a newly prerecorded
  “Fucking great.” He leaves the meeting, crosses the office, gradually sits at his
  desk and starts typing. “END OF INCIDENT 001 — MONDAY, 9:05 AM” closes this slice.
- The night exit covers about 60% more distance in the same voice-dependent time,
  making the walk faster while keeping the full memory lines. Memories spread along
  the longer route. All five gossip takes now share Kevin, the ancient fridge yogurt
  with a better career trajectory than the night shift.
- Six replacement voice performances use the existing local stock Kokoro profiles;
  provenance is preserved. Closing shots and gait remain candidates for human review.
  `tests/finale_preview.gd -- --closing` renders the return-to-work checkpoints.
  The existing packaged build predates this source change.

## Source update — The things they left behind (11 October 2026)

- After the memorial, a last look at JO leads to a held face close-up with a tear.
  The original sad theme starts earlier, during the memorial, and continues outside.
- At his workstation, the engineer sets down his sword and collects his laptop, mug
  and JO's “MONDAY LUNCH?” reminder in a box. The sword remains at his station.
- Five faint memories recall ordinary coffee, lunch and gossip, including the exact
  conversation heard this run. Fifteen new coworker takes and three engineer replies
  are locally generated stock Kokoro voices, with provenance in `talk/provenance.json`.
  They are also playable through “Tell me something normal” in living conversations.
- Sequential complete memory clips, subtitle preferences, blended hand contacts and
  stand-up motion; the carried box stays upright. Cinematic travel now drives a
  matching walk cycle, fixing slow-exit idle sliding and airborne-pose freezes;
  starts and stops ease over 0.6 seconds. TAB and R clean up all added props.
- `tests/finale_tests.gd` checks the aftermath; `tests/finale_preview.gd` renders its
  checkpoints. Human pacing, animation and listening acceptance remain open. The
  packaged 0.2.45 build predates this source refinement.

## Source update — The AI backfill pitch (11 October 2026)

Creator feedback: make the postmortem dialogue funnier and more unhinged, with someone
suggesting AI replacements for the fallen crew.

- The AI diagnoses the root cause as trying to go home: "Home is a competitor.
  We do not work for competitors." The document records the same diagnosis.
- The VP explicitly pitches replacing them: "No salaries. No funerals. Just a
  subscription we can expense." The engineer names all five and objects; the AI
  note-taker records his protest as enthusiasm and unanimous consent.
- Only after approval do the five replacement tiles join. JO.ai greets the call as
  "alive within the meaning of the service agreement." Leadership crops the survivor
  out of its LinkedIn photo, assigns him accountability for the agents, and puts him
  on call forever. He asks whether AI can replace him so he can finally leave.
- Nine rewritten and four new locally prerecorded lines retain stock voice/model
  provenance. The document and replacement tile statuses match the new exchange.
- The night, memorial and combat are preserved. Human acceptance of acting and joke
  timing remains open. Replay just the meeting with
  `sh tools/godot.sh --path . --script tests/postmortem_preview.gd`.

## Source update — Unpaid Overtime buildup (11 October 2026)

Creator feedback: the gold transformation was too abrupt; give the loss time to become
rage, with a cinematic flashback, a shouted power-up and a changed hairstyle.

- After "They were my team", three warm, vignetted memories show NADIA, JO and the
  intact night shift at the office, with fading fragments of their conversations.
  These are separately staged bodies; the actual casualties stay in the vault.
- Back at the engineer's bloody feet, the camera rises to his face. He lowers his
  sword, trembles, and the hair, eyes, light and aura build with an uneven gold charge
  over 3.8 seconds. Nine original, faceted hair tufts sweep upward into golden spikes,
  attached to his animated head over a full gold hair base. They stay raised through combat and lower as his
  overtime burns out at the ending.
- A new local, wordless power-up shout swells with the charge; the existing spoken
  rage line lands with the blast. Low booms and a music dip give the memory and voice
  room. Only the roar completes the form and throws The Variance back; the reply
  eases into the gameplay camera. Audio provenance is in `talk/provenance.json`.
- About 12 seconds added before combat; TAB still skips into the finished form.
  Restart clears memories, partial hair/aura and both vocal tracks.
- `tests/rage_tests.gd` checks staged memories, delayed form/knockback, raised hair,
  control handoff, skip and restart. `tests/rage_preview.gd` is the quick graphical
  checkpoint. Human acceptance of pacing, sound and emotional payoff remains open;
  the packaged 0.2.45 build is unchanged.

## 0.2.45 — Blameless (11 October 2026)

Creator feedback: the Monday all-hands still sucked; make it the postmortem meeting, and
have one of its suggestions be replacing the fallen with AI.

- The night is unchanged (the duel, the receipts, In Memoriam, the walk out past their
  memories, the street, the window). **Monday, 9:00 AM** is now the **blameless
  postmortem** in the Quick Sync room: him alone at the table, everyone else on its wall
  screen, a live call: the Chief Synergy Officer joining from Cabo (sunset, sun, teal
  tie), the VP of Alignment with her camera off, the Head of People on a Peloton, the
  AI note-taker, and his own self-view. The postmortem types itself out as the AI reads
  it: ROOT CAUSE, an engineer was present; CONTRIBUTING FACTOR, the engineer continued to
  be present; IMPACT, $0.01 (recovered) and 5 resource attrition events; WHAT WENT WELL,
  leadership; WHAT WENT WRONG, the engineer. Leadership congratulates itself over the
  call. CORRECTIVE ACTION 3: backfill the night shift with AI, and MORGAN.ai
  ("Escalating… 100%"), NADIA.ai ("On call 24/7/365 · no pager required"), JUN.ai
  ("Generated 400 logos"), JO.ai ("Unpaid. Forever. Thrilled!") and VAL.ai ("Deck
  ready: 2,000 slides") join one by one. A close-up on him. "Everyone say… synergy!": the
  gallery screenshot, his tile blacked out, posted from Cabo. On call this weekend.
  "…Of course I am." Meeting ended; next: Quick Sync, recurring daily, forever. NEXT:
  INCIDENT 002.
- The statue unveiling is gone. Three new postmortem AI lines (root cause, impact,
  backfill), all local.
- New checks: the postmortem backfills the night shift with five AI agents; the call
  leaves nothing behind.

## 0.2.44 — The walk out (11 October 2026)

Creator requests: dismember the boss through the final standoff and improve its camera;
management only congratulates afterwards (they sleep through the night); the ending is
the hero leaving the building at midnight, wrecked and bloody, a bleak night, the fallen
remembered, with a sad sound and fading memories of them at work; replace the weak
all-hands with something funnier; he is clean by then; the receipt looked ugly.

- **The duel** now takes The Variance apart a word at a time: "CLOSED!" an arm, "AS!"
  the other arm, "WON'T!" the head, "FIX!" the leaping slam that splits what is left.
  The limbs fly, bleed and stay where they land through the finale; the real Variance
  dies missing them too. New angles: a wide standoff, a close-up on his face, two-shots
  for every clash, and an angle on each word that shows what comes off.
- **The night, in order:** it comes apart into receipts; the gold burns out; the receipt
  (now a real thermal receipt: TXN 000001, STATUS FOUND, AMOUNT $0.01, COST 5 STAFF,
  THANK YOU FOR YOUR SACRIFICE); In Memoriam; his desk and a SEV-2. Then **he walks
  out**, bloody, across the dark floor to an original sad theme, the motion lights
  clicking off behind him, and the five come back as pale memories at desks along his
  way (MORGAN on the phone, NADIA typing, JUN giving notes, JO bouncing, VAL on a call),
  each a fading whisper of the first thing they said to him tonight. Then **the street
  at midnight**: rain, a sodium lamp, the tower going up into the dark, him walking out
  of frame; and, from across the city, **the one lit window** with five silhouettes in
  it. The narrator: "By Monday, the cent was reconciled. The night shift was not."
  INCIDENT 001 — RESOLVED.
- **Monday, 9:00 AM: a statue unveiling, attendance mandatory.** Him, showered, unslept,
  the entire audience. "Incredible work, everyone. And by everyone… I mean leadership."
  The velvet drops: a bronze Chief Synergy Officer, larger than life, arms raised over
  the slain Variance. The plaque: IN HONOUR OF BRENT FAIRWEATHER, CHIEF SYNERGY OFFICER,
  WHO SLEW THE VARIANCE, FRIDAY, 11:58 PM (FROM HOME, ON MUTE). Confetti. Self-thanks,
  the mandatory fun day, "synergy!", the LinkedIn post ("I personally resolved a SEV-1…
  thank you to everyone who made this possible (me)") with him cropped out, on call this
  weekend, STREAM ENDED, and him under the statue. NEXT: INCIDENT 002, MONDAY, 9:05 AM.
- Management's "Great teamwork, everyone! Special thanks to leadership." and the
  postmortem lines no longer talk over the boss's death; they play over the report.
- `mourning.wav`: an original 32-second theme from `tools/build_music.py` (slow minor
  pads, a falling bell-like line, a hall echo). No new voices.

## 0.2.43 — Closed as won't fix (11 October 2026)

Creator requests: the boss's moveset should be creative against the engineer too; the
killing blow should be a toe-to-toe duel and an unhinged, cinematic kill; the ending
should be a dramatic cutscene, not text: the gold fading slowly, the sacrifices
remembered, and management thanking itself, unhinged and satirical.

- **The Variance fights with its moveset.** Once per shield cycle it uses one of the
  moves it used on the night shift, named in its red strip with the way out:
  DELAYERING (a shadow follows you, then slams: step out; hit, you are briefly
  flattened), MAKE IT POP (three feedback bubbles lobbed at you: stay clear),
  DECOMMISSION (an end-of-life ring rolls out at knee height: roll through it), PAID IN
  EXPOSURE (three flashes count down, then a big one: look away or be blinded), and
  DOWNSIZING (a tracking beam locks and fires: get out of the spot, or fight at half size
  for four seconds). It says each one aloud the first time.
- **The duel.** What would kill it cuts to a cutscene: a standoff across the vault, a
  charge, four clashes with hard cuts and sparks, a shove; then "CLOSED! AS! WON'T!
  FIX!" in the rage voice, a slash on each word, and a leaping slam that cuts it in
  half.
- **The finale** (TAB skips it):
  - It comes apart in slow motion into a storm of receipts while the ledger reconciles
    to SUCCESS; paper snows over the vault.
  - A low orbit round the engineer among his colleagues as Unpaid Overtime slowly burns
    out; one gold receipt drifts down to him: TXN 000001, $0.01, FOUND. The narrator:
    "And there it was. The missing transaction. One cent."
  - In Memoriam: a glide past each of the five where they fell (MORGAN: "His calendar
    is still full." JO: "Never got a badge photo.").
  - 11:58 PM, a mandatory all-hands in the lobby under the SYNERGEX logo, lit like a
    keynote (spotlight, LIVE · 3,411 ON MUTE), an audience of one in the dark.
    Leadership walks on in single file: "Incredible work, everyone. And by everyone… I
    mean leadership." "I just want to thank myself. For my vision." "To honor the fallen,
    we're doing a mandatory fun day. Unpaid." "Everyone say… synergy!" Confetti, a flash,
    a freeze, and the LinkedIn post, whose photo is the actual frame, cropped to leave
    him out ("1 engineer cropped out"). "Oh, and you're on call this weekend." The
    spotlight clunks off. "…Of course I am."
  - Back at his desk: SEV-2, coffee machine down, owner: you. Head down. The camera flies
    back out of the tower window into the night, the opening in reverse: "By Monday, the
    cent was reconciled. The night shift was not." INCIDENT 001 — RESOLVED. NEXT:
    INCIDENT 002, MONDAY, 9:00 AM. Then the report.
- New voices: the executive (a third management voice, from an installed stock voice),
  six all-hands lines, two narrator lines and the kill line, all local.
- New checks: every fight move hurts if stood in and misses if escaped; Downsizing
  resizes and a restart restores; the killing blow cuts to the duel and ends in the
  slice; the finale opens before the report, the overtime burns out and the dead are
  remembered; TAB ends it; a restart leaves nothing of it.

## 0.2.42 — Corporate euphemisms, done literally (11 October 2026)

Creator requests: the butchering was repetitive and in one spot; make each kill unique
and satirically funny, give the boss a creative moveset, and have the engineer arrive
enraged, transform like a super-powered anime hero over the blood of his colleagues, with
an enraged voice, an aura that pushes the boss back, and nothing on screen but him.

- **The Variance has a named moveset**, announced in a red strip and in its own voice,
  and it uses one on each of the night shift, each somewhere else in the vault. It leaps
  across the room to each scene; the wide shot watches side-on; the rest run panicked
  laps away from wherever it is going.
  - **DELAYERING** (mid-vault, "removing one layer of management"): a shadow grows under
    MORGAN, who shakes his head at it; flattened into the floor. Stamp: DELAYERED.
  - **DECOMMISSION** (at the server racks, mid-rollback): an end-of-life scan, then in
    half; the pager on the upper half keeps ringing. Stamp: DECOMMISSIONED.
  - **MAKE IT POP** (at the ledger, giving the monster notes): JUN inflates, wobbling,
    and pops in brand colours. Stamp: MADE IT POP.
  - **PAID IN EXPOSURE** (the intern, bouncing by the west racks): paparazzi flashes,
    +EXPOSURE with every one, JO posing and going whiter, until one flash too many leaves
    a pair of smoking legs, which still ask whether this counts for college credit.
    Stamp: OVEREXPOSED.
  - **DOWNSIZING** (VAL, on the phone at the exit): a beam shrinks her to a rounding
    error; her last words come out squeaky; then it steps on her. Stamp: DOWNSIZED.
- **Unpaid Overtime.** Their blood runs to the engineer's shoes. Close on him: "They were
  my team." Then he snaps — a distorted, octave-doubled roar ("YOU LAID OFF MY TEAM… ON A
  FRIDAY?!") — and goes gold: glowing hair and eyes, a gold flame aura, crackling arcs,
  the floor cracking and debris floating up. The blast throws The Variance back across
  the vault. It is unmoved: "Your team… was never in the budget." Then the fight, still
  gold. No chat cards or banners over any of this.
- Seven new lines in The Variance's and the engineer's voices and a new rage voice chain,
  all local. The fight itself is unchanged in this build; its moveset is next.
- New checks: each of them dies to their own move, in a different place; the engineer is
  in Unpaid Overtime when the fight starts and out of it after a restart.

## 0.2.41 — No apologies (11 October 2026)

Creator feedback: the apologetic last words don't land; make them unhinged and funny.

- The night shift no longer apologise or lean on the engineer as they die. Their last
  words are denial, branding and paperwork to the very end:
  - MORGAN: "Mark it GREEN on the status report! It's GREEN! IT'S GREEN!"
  - NADIA: "Not dead! Just… degraded performance! All systems operational!"
  - JUN: "Is my blood on brand?! TELL ME IT'S ON BRAND!"
  - JO: "Does this count… for college credit?!"
  - VAL: "Put my death in the deck! Make it a HOCKEY STICK!"
- Five lines re-recorded in each coworker's existing voice blend; the old apology clips
  are gone.

## 0.2.40 — One at a time (11 October 2026)

Creator requests: in the vault, the night shift should be butchered one at a time while
the rest run around, so they are not all talking at once; a "RIGHT-SIZED" stamp was
misplaced.

- **The Variance takes them one at a time.** Whoever is up fights it close, on the side
  the camera sees, and it turns to face them; everyone else runs panicked laps round the
  vault, changing direction. Before the engineer walks in, the runners beg for help in
  the gaps ("It's not in the runbook! HELP!"), the first time those lines are heard.
- **One voice at a time.** Battle cries go in turn; pain cries and pleas wait for
  silence; only last words cut anyone off. Each victim screams through their beating,
  then goes down, then apologises; the next one is hit the moment the floor is theirs.
  The massacre now runs on those turns (about 28 seconds to the fight, up from about 21)
  instead of a fixed clock, with a five-second limit per victim.
- **The casualty stamp** (OFFBOARDED, RIGHT-SIZED…) is stamped beside the name on the
  card instead of floating mid-screen, and the casualty camera keeps clear of the
  monster for the whole shot.
- New checks: never two of them talking at once, and the rest stay out of reach while
  one is being taken apart.

## 0.2.39 — The night shift goes in first (11 October 2026)

Creator requests: the coworkers should fight the boss first and lose (some dismembered,
calling for help, sounding beaten), with dramatic casualty shots and unhinged epitaphs,
apologising and leaning on the engineer; then his hero entrance over their bodies.

- **The gate opens and the night shift sprints past you** down the server corridor to take
  on The Variance themselves (MORGAN, NADIA, JUN, JO and VAL, each with a battle cry).
  Walking the corridor you hear it going badly: punches, impacts and voiced pain cries
  ("OW! Is this HR?!", "OW! OW! I'm MANAGEMENT!").
- **Walk into the vault and they fall in front of you**, one by one: sliced in half at the
  waist with blood, or thrown across the room. Each gets a **casualty cam**: a nearly
  frozen low dutch angle, a red-drained frame, and their HR record slammed on screen with
  a stamp (MORGAN, ESCALATED ONE LAST TIME, SURVIVED BY 14 RECURRING INVITES: OFFBOARDED;
  JO, TENURE: ONE DAY, EXIT INTERVIEW: MONDAY, 9:00: RESTRUCTURED). Their last words
  are apologies, and it's all on you now ("Sorry! I'm just the intern! Please… you do it!").
- **Hero entrance.** Over the monster's shoulder, the engineer walks in over his
  colleagues with the Monolith; THE VARIANCE titles up; the real fight starts. The first
  arrival only (retries and TAB skip straight to the fight, with the bodies already down).
- 25 new voiced lines (battle cries, pain, apologies) from the coworkers' own voice
  blends. Restarting brings everyone back. Presentation only: the boss fight itself is
  unchanged.

## 0.2.38 — More of the night shift, sitting properly (11 October 2026)

Creator requests: more inclusive cast (women, a gay coworker) with unhinged voices,
backgrounds and work; NPCs placed properly on their furniture; fewer lights in the city.

- **New coworkers, voiced** (local Kokoro blends of the installed voices):
  - **NADIA**, SRE, on call since 2019, at her desk: "I'm not on call. I AM the call."
    The pager doesn't ring any more; it lives in her skull. Rent-free.
  - **VAL**, VP of Synergy, promoted for a deck nobody read, pacing: the outage is a
    feature, it's on slide forty-seven, the rocket is on fire, the board loved it.
  - **JUN**, product design, at the whiteboard: "My husband thinks I'm at the gym.
    Technically this is cardio." He gave the error page a gradient so production dies
    on brand. The satire aims at the work, never at who anyone is.
- **The planted employees** DANA, KIM, GRETA and PRIYA now have women's bodies (CC0
  Quaternius, the same pack and rig as everyone else).
- **The crew montage** introduces NADIA, MORGAN, JUN and GARY.
- **Seated people sit on the furniture.** Sitters snap to the nearest office chair or the
  lounge sofa, facing the way it faces, lifted onto the cushion and forward off the
  backrest (GARY was sitting on air in front of his chair, RIO in front of the sofa).
- **The city at night is nearly dark.** Everyone else went home: a handful of lonely lit
  windows, and one glowing floor.

## 0.2.37 — The missing transaction is here (11 October 2026)

Creator request: the reveal before SEV-1 was a good idea, plainly executed; make it
scary and funny, all out.

- **Power down.** Rows of lights die with relay thunks; the floor sinks into the dark.
- **Every screen in the office** goes black and asks the same thing: WHERE IS IT?
- **The night shift turns.** In the dark, every coworker snaps round to stare at the
  camera at once, and nobody moves again. The narrator, unbothered: "The missing
  transaction. Rarely seen. Never reconciled." The screens answer: IT'S HERE.
- **Lights-out flicker.** From behind his chair, the floor is seen only in flashes, and
  The Variance is closer in every one: the far wall, mid-floor, two rows away.
- **Behind you.** Close on his frozen face; in the dark behind him it rises over his
  shoulder, red-lit, and screams "ANOTHER TICKET?! I'LL RECONCILE YOU!" Black. Silence.
  The narrator: "…Fascinating."
- Emergency lights slam on red, he stands with the Monolith, title. The opening is now
  50.5 s (skippable after the first viewing). Two new narration lines replace the old
  premise line.

## 0.2.36 — The tower at night (11 October 2026)

Creator request: start with a dramatic shot of a building in the middle of the night,
smooth.

- **Fly-in.** The opening now starts outside: a night city of curtain-wall towers, ours
  dark but for a few stubborn lights and one glowing floor. One continuous spline move
  descends the tower, passes through the window and glides over the desks into the crew
  montage, under the narrator's first line. The tower, the city (46 towers) and their
  windows come from one procedural shader (`game/rooms/office/facade.gdshader`); the
  window view from inside the office is now that city too.
- **Smooth.** Measured at 1080p on the M2 Pro: the fly-in runs at about 11 ms p95 and the
  rest of the opening about 7 ms p95, with no frame over 35 ms after loading. Exterior
  geometry casts no shadows; the montage's freeze shader compiles under the fade-in; the
  text warm-up only warms capitals at display sizes and spreads over the fade-in (the
  first frame had grown to seven seconds).
- **Fix: the engineer looked translucent.** The close-camera fade ran during cutscenes;
  it now applies only to the gameplay camera, and later (within 1.9 m).

## 0.2.35 — A cold open like a film (11 October 2026)

Creator requests: tell the setup with cinema instead of text, unhinged; introduce the
night shift and their misery; open like a movie with a documentary-style narrator.

- **Narrated cold open (47 s, skippable after the first viewing).** A wry
  nature-documentary narrator (the existing narrator voice, slower and drier; not an
  impression of any real person) over drone shots of the dark office: "This is the
  open-plan office. At four fifty-nine on a Friday, it is the most dangerous place on
  Earth."
- **Meet the night shift.** The camera whips to DREW (culture fit enforcement), MORGAN
  (on a call about the call), GARY (on call, technically) and JO (intern, day one, on
  call); each time the world freezes, drains of colour and a name card slams in.
- **Then it goes wrong.** He clicks Log Off; smash cut to SEV-1; every monitor in the
  office turns red in a wave under a red strobe; a dolly zoom closes on his face while
  the chat floods faster than anyone could read; "Tangina naman."; a beat of black; the
  lights die row by row while the narrator sets the premise and something climbs out of
  the dashboard; he stands with the Monolith; the title slams on "quietly".
- **Less text.** No running timecode, no speaker labels on subtitles (one clean line),
  and the title card is just SEV-1 and its tagline.
- The establishing shots render the whole office first, which also removed the
  ~140 ms freeze when play began (it now compiles under the fade-in).

## 0.2.34 — Wall jokes you can read; the logo stands alone (11 October 2026)

Creator requests: make the wall text readable so the unhinged lines land; remove
"SEV / 01" beside the company logo.

- Measured every wall text's letter height from the nearest spot the engineer can stand
  (1080p, gameplay camera). The sticky notes read at 3 px, the coffee/microwave notices,
  wellness flyer, footnote and vending error at 4–12 px. Same words, now readable:
  the sticky notes are three oversized notes on the desk-aisle column (20–24 px); the
  coffee and microwave notices are bigger taped sheets with shorter lines; the vending
  error is an LED strip across the glass; screen details, captions, the logo small print
  and wall signs are re-broken and enlarged (punchlines now 20–27 px). A regression
  check keeps every wall joke at 15 px or more.
- "SEV / 01 · ENGINEERING · AFTER HOURS" is gone; SYNERGEX takes the centre of the
  south wall.

## 0.2.33 — Fewer stutters (11 October 2026)

Creator request: check performance and smoothness.

- Measured a whole scripted run at 1080p on the M2 Pro (`tests/performance_probe.gd`):
  about 109 FPS average, 9 ms median, 12.6 ms p95. Steady play was fine; the problem was
  6–8 stutters of 40–73 ms per run, each when text first appeared (the HUD after the
  opening, the outbreak title, the first kill stamp).
- Text styles are now pre-drawn invisibly at load, so those stutters are gone (two
  remain per run, down from up to eight). One known first-view freeze (~140 ms, GPU
  pipelines for the whole office) is next, folded into the new opening. Details and
  numbers in [stabilization](stabilization.md#0233-whole-run-probe-11-october-2026).

## 0.2.32 — A quieter top-left (11 October 2026)

Creator request: trim the top-left text too.

- The ticket header drops SEV-1 and OPEN (`INC-001 · TRIAGE · 02:14`); objectives are
  the stage name (`1/3 · The Discrepancy`, `Investigate at OPERATIONS`); the status
  line is a short tally (`2 acting strange · 22 m · snap in 43s`, `3 threats · nearest
  22 m`, `6 left · wave 1/2 · next in 3s`, `Area clear`, `Gate open · head north`).
- The NEXT line is shorter too, so it no longer runs under the chat cards.

## 0.2.31 — Notices are one line (11 October 2026)

Creator report: the "night shift is not okay…" box at the start is too big, a wall of
text.

- That box is the HUD notice (not a cutscene): it shows the incident's latest status
  message. Its opening tutorial repeated what the NEXT line and the objective already
  say. Notices are now one short line each (the joke plus, at most, one new rule: hit
  first for double damage, the boss's solid ◆, breaking the Blocker), in a slim toast
  that hugs its text above the skill bar and fades out after five seconds.
- The new office textures are now imported as compressed GPU textures, like the rest.

## 0.2.30 — Finishers swing (11 October 2026)

Creator request: the finisher should be the sword swinging, not a pose.

- The kill cam's hero shot now shows the engineer squared up to the kill, swinging the
  Legacy Monolith through it in slow motion from a low side angle: a diagonal cleave or
  a spinning backhand (the same authored strikes as the combo, trail and all), and the
  leaping overhead slam for the boss. The swing finishes as the camera heads home, then
  he turns back and shoulders the blade. The folded-arms hero pose is gone.

## 0.2.29 — Framed prints and a company (10 October 2026)

Creator request: make the wall signs look good (keep the unhinged text), get assets
online if useful, and add a stupid company logo.

- **The culture deck is framed.** The four posters are now motivational prints: satin
  black frame and glass, black mat, a CC0 photograph with a white border, the first
  line as a Cinzel title and the punchline as the caption. WE ARE A FAMILY* over a
  wholesome sunrise field, FAIL FAST over a sky on fire, YOUR WELLBEING over an alpine
  meadow, IT WORKED ON MY MACHINE over a burnt-out warehouse.
- **Paper that looks like paper.** Notices, flyers and the whiteboard use a CC0 paper
  texture. The coffee notice is taped up crooked; the BURNOUT IS A MINDSET flyer has a
  purple People & Culture header, a calming stock sky and four red pins; the
  ALL SYSTEMS OPERATIONAL* printout is framed like an award with a green status dot;
  sticky notes are sticky-note yellow, pink and green and sit slightly askew.
- **SYNERGEX.** A lobby logo on the south wall: an arrow that only circles back to
  itself, "WE PUT THE 'I' IN TEAM™", small print "Now with 30% fewer employees."
- Sources: five Poly Haven photographs, ambientCG Paper001, Cinzel (OFL); provenance in
  [asset licences](asset_licenses.md). The office generator (`tools/build_office.py`) now
  owns every wall-text size and the camera-blocker script, so regenerating keeps them.

## 0.2.28 — Wall text fits its frames (10 October 2026)

Creator report: the wall texts are good but overlap their frames.

- A probe measured every wall text against the panel it is printed on: 25 spilled
  over, the four motivational posters by up to a metre each side. Each now scales to
  fit with a margin: posters, the status-page poster, wellness poster, coffee notice,
  sticky notes, vending machine, Quick Sync display, deployment board, vault gate sign
  and the drifting calendar cards. A regression check keeps every wall text inside its
  panel.

## 0.2.27 — Skill icons (10 October 2026)

Creator request: show the skills as icons so cooldowns are easy to notice, with less
text on screen.

- **A skill bar, bottom centre.** One tile per move with its key: Reply All (reply-all
  arrow, C), Blame Shift (dash, X), Circle Back (loop, Z), Works On My Machine (laptop
  with a check, G) and Force Rollback (rewind, V). Ready moves light up in their colour;
  cooling moves go dark with a clockwise sweep and the seconds left; a move coming back
  flashes. The ultimate's tile fills with FOCUS and pulses when it is ready.
- **Less text.** The second controls line (move names) and the cooldown list next to
  FOCUS are gone; the controls hint is one quieter line; tutorial notices sit above the
  bar instead of over it.

## 0.2.26 — The camera stays out of the walls (10 October 2026)

Creator report: moving around, the camera passes through walls and the view is lost.

- **Measured, then fixed.** Across 24,000 sampled camera placements on the floor, about
  half put the lens inside or behind something drawn. The spring arm checked a thin ray,
  so at glancing angles the lens still sliced into walls and the ceiling; and door
  headers (Pantry, Quick Sync, the wing), ceiling beams, ducts, cable trays and
  whiteboards had no collision at all.
- **The camera sweeps a sphere.** It keeps clear of walls and ceilings from any angle,
  and also stops at the office's large architecture, which now gets camera-only
  collision (bodies, enemies, navigation and sight lines ignore it). Small props such as
  plants, lamps and monitors stay see-through so the view doesn't jerk around them.
- **No popping.** A wall pulls the camera in at once; once it clears, the camera eases
  back out instead of snapping.
- **See past him in tight spots.** When a wall forces the camera right behind the
  engineer, he fades so the room ahead stays visible.
- A regression check samples real camera placements across the office: 0% now clip,
  22% with the old camera.

## 0.2.25 — Smoother animation, progression and pacing (10 October 2026)

Creator request: make sure animation, progression and pacing are smooth. An audit of
the run and the rigs found these, now fixed:

- **Slow motion no longer fights itself.** Freeze-frames, kill cams, Force Rollback and
  first-sighting slow motion each set the game speed and each reset it to full on its
  own timer, so a hit during the omnislash snapped the "world crawls" back to normal
  after the first cut. They are now layers: the slowest wins and each one ending hands
  back to the rest.
- **The run's end plays out.** Killing The Variance or dying used to pause the game the
  same frame, so the boss's finisher kill cam and the slow ending shot never played and
  the engineer died by snapping to his corpse. The game now runs for two more seconds
  after the kill cam (the fall plays, the keyboard drops to the carpet), then the report
  opens; the fall keeps playing behind it.
- **The change request arrives on cue.** It used to come about 1.6 s after the last kill
  cam ended (slow motion stretched its timer) while the HUD claimed "the next wave is
  coming". It now comes 0.6 s after the kill cam, and the HUD says the area is clear.
- **No accidental choices.** Change-request and leadership cards ignore input for
  0.45 s after they appear, so a jump (Space) or an attack click on the middle card
  cannot sign anything mid-fight.
- **The right monster comes out.** Setting off any employee but the wave's first could
  pair the wrong monster with them (talk to Scope Creep's host, get a Corrupted Record).
  Each employee now turns into their own.
- **Loose ends.** Stray bugs close as WONTFIX when each wave clears (they kept the floor
  "in battle" and blocked talking to the next wave's employees); a skipped Quick Sync's
  attendees go home when containment starts instead of twitching like a due wave;
  restarting mid-conversation no longer sets the wave off on the way out.
- **Animation.** Run playback matches the clip's planted feet (less skating) and step
  sounds land on the footfalls instead of eight times a second; attacks and specials no
  longer flip the body in one frame (it whips round over a few frames while the hitbox
  aims at once); the kill cam's exit turns him back and lifts the blade while the camera
  blends home instead of snapping both under the gameplay camera; the omnislash shows
  each cut landed rather than seven wind-ups; monsters staggered by specials play their
  hit reaction instead of freezing on its first frame, turn toward the engineer instead
  of popping, and no longer flicker between walk and run near the threshold; the
  kneeling Facilities coworker keeps repairing instead of freezing after one pass;
  talking gestures return to idle or the phone; cowering is not replayed every cycle.

Not changed: the 45 s set-off fallback and the first-run 36 s opening (creator
decisions); R still restarts instantly. Feel, timing and fun need a human playtest.

## 0.2.24 — Better motion, a hero pose, a smaller dialogue (10 October 2026)

Creator direction: get better assets (upgrade within free CC0 packs); the dialogue box was
too big; the "talk" prompt should be creative and pretty.

- **Quaternius Universal Animation Libraries 1 and 2 (CC0).** Downloaded from
  OpenGameArt (no account) and retargeted onto the Quaternius office rig with a new
  world-space retargeter in `tools/build_engineer_rig.gd` (each library's T-pose to the
  body's rest, hips/spine damped on attacks so the big-headed body does not face-plant).
  29 new clips: greatsword strikes and combo, sword block and dash, knockback, folded
  arms, phone call, talking, sitting talk, kneeling repair, head-shake and nod, zombie
  walk and scratch, sprint, jog, roll, death. All five office bodies share the rig, so
  one library animates the engineer and everyone else.
- **Life in the office.** Coworkers now talk with their hands while you talk to them
  (and shake their heads at "No…"), the Manager takes calls between laps, Facilities
  kneels at the microwave, Standup gestures at nobody, and every employee a wave is
  hiding inside is on the phone until the P1 lands (then a head-shake, then the turn).
- **Hero pose.** The finisher kill cam now shows the engineer arms folded, the Legacy
  Monolith planted point-down beside him, while the kill falls apart behind him.
- **Smaller dialogue.** The talk box is about a third smaller (narrower, tighter type,
  compact reply rows with a slim highlight) and sits lower.
- **A prettier talk prompt.** "E — TALK" is now a chat bubble over the person's head with
  a cyan E keycap and a corporate verb plus their name ("SYNC UP WITH MORGAN", "TOUCH
  BASE WITH", "CIRCLE BACK WITH", "GRAB 5 MIN WITH", "INTERRUPT"; "CHECK ON DANA" for the
  ones about to turn), popping in and bobbing, gone the moment a fight starts.

## 0.2.23 — Force Rollback, omnislash (10 October 2026)

Creator request: build the ultimate after Cloud's Omnislash.

- **FORCE ROLLBACK (V) is now an omnislash.** "FORCE… ROLLBACK!" and the world crawls
  (the engineer does not: the sequence runs on unscaled time). He blinks between the
  enemies within 9 m, seven times, each time appearing at a new angle around a target
  and cutting through it (30 damage, stagger, crossed light slashes, a rising whoosh), a
  streak of light marking every blink; with one enemy all seven cuts land on it from
  seven directions. Every blink is a hard camera cut to a fresh tilted angle that
  avoids walls and bystanders, letterboxed. Then he snaps back to where he started,
  "git reset… HARD!", and slams (110 to everything within 7.5 m, shields dropped) into
  the hero kill cam. Invulnerable throughout. Rolling back seven commits.
- Coworker remarks hide during cutscenes and kill cams; the slam's particle cloud is
  lighter so the hero shot reads.

## 0.2.22 — Softer lightning (10 October 2026)

Creator feedback: the lightning effect was too edgy; make it soft and smooth.

- Every lightning bolt (the HOT RELOAD combo hit, slash marks, the boss's strikes) is
  now a smooth arc with a few gentle bends that drift slowly instead of a jagged
  zigzag re-randomised every frame: tapered ends, three feathered layers (a wide tinted
  haze, a coloured body, a bright core) and a smooth fade with no flicker.

## 0.2.21 — The Legacy Monolith, hero finishers, clearer monsters (10 October 2026)

Creator feedback on 0.2.20: the finishers were too fast; make them dramatic and
cinematic with better angles and a cool protagonist (Cloud's Omnislash noted for the
ultimate); a broadsword carried like Guts', resting edge-on on the shoulder without
clipping; funny unhinged last words; monster voices too distorted to understand.

- **The Legacy Monolith.** The keyboard grew into a slab of a broadsword taller than the
  engineer (dark iron, two rows of keys down the flat, a red Esc near the tip, the cable
  wrapped round the grip, faint cyan edges that flare in battle). Out of a swing he
  carries it Guts-style: edge-on, the lower edge resting on the outer right shoulder,
  flat facing out, grip low in front of the chest. Checked from front, sides, back and
  above for clipping against the oversized head. The swing trail follows the longer
  blade. Combat reach and damage are unchanged.
- **Hero finishers.** The kill cam is now ~1.9 s in three beats on real time: an instant
  of near-freeze on a tilted angle of the kill with a flash and a boom; then the hero
  shot, a low angle in front of the engineer, who has turned his back on it, sword on
  his shoulder, while it comes apart behind him in slow motion (sound slows with time);
  then a smooth blend back into the gameplay camera. The boss gets 2.8 s and plays over
  the ending; the ultimate's slam 2.4 s. Waypoints hide during cutscenes.
- **Last words.** Every monster now speaks as it dies (mass kills let them out one at a
  time), from a bigger pool: "Don't… cc me… in hell…", "I never… even got… the pizza
  party…", "Sorry… I have… a hard stop…", "Let's… circle back… in the afterlife…", "Was
  I… ever… in the roadmap…", "Fine… merge it… I don't care anymore…".
- **Readable monsters.** The bark chain is gentler: a slight warble, the growl a fifth
  below kept well under the words, mild saturation, no bit crusher, less pitch drop.
  59 lines regenerated; still unheard candidates.

## 0.2.20 — Monsters losing it (10 October 2026)

Creator feedback on 0.2.19: the monsters should sound like monsters losing their minds.

- Every bark was re-voiced deeper (records −7, the Blocker −9 semitones) through a nastier
  chain: a crazed warble, a growling sub-voice a fifth below mixed under every line,
  overdrive, bit-crushed grit and a short ugly room, mastered at −15 LUFS so they cut
  through a fight. Manic laughter joins several lines ("OVERTIME! OVERTIME! HA HA HA HA!",
  "CHANGE REQUEST… DENIED! HA HA HA!", "Small ask… small ask… heh heh heh… SMALL ASK!")
  plus three new ones (45 barks in all). Still unheard candidates.

## 0.2.19 — The monsters talk (10 October 2026)

Creator request: the monsters should say funny things, like they lost their minds from
too much work.

- **Overworked and unhinged.** Every monster type now talks, voiced in its own distorted
  monster voice (a grit, doubled-throat, short-room chain on pitched-down voice blends)
  with a speech bubble over its head: lines when it spots you ("ANOTHER TICKET?! I'LL
  RECONCILE YOU!", "YOU SHALL NOT DEPLOY!", "ACCEPT! ACCEPT! ACCEPT!", "ONE MORE THING!"),
  muttering on patrol when you are within earshot ("My kids call me 'Status: Away'.",
  "Form 27-B. In triplicate. Signed in blood."), on attacks ("PER MY LAST EMAIL!"), when
  hurt ("That's not in my KPIs!") and last words ("Finally… PTO…", "This meeting… could
  have been… an email…"). Bugs squeak "IT'S A FEATURE!". One monster speaks at a time
  across the floor (last words may interrupt), with a pause per monster.
- 42 new lines, 200 voiced lines in all; unheard candidates.

## 0.2.18 — Monsters, not toys (10 October 2026)

Creator direction: make the enemies more monster, not neon; the game is a satirical,
funny, gory dark RPG (recorded in [vision](vision.md#tone-established-direction-10-october-2026)).

- **Flesh, not candy.** Every monster's flat pack colours are replaced by a new skin
  (`monster_flesh.gdshader`): a dark per-material palette (rotting orc flesh, matted grey
  fur, charred demon skin, black chitin, bile-green slime, yellowed teeth, dimly glowing
  eyes) with mottling, bruises, darkened silhouettes and a wet sheen. The neon rim at rest
  is gone; the archetype colour now only shows as the attack wind-up tell and hit flash.
- **They bleed as they are hurt.** Blood soaks across the body as health drops; the dead
  are drenched. Death chunks are meat, blood and bone instead of neon cubes.
- Scope Creep's sticky notes are stale, damp paper, and its spell colours are a sickly
  bile rather than lime.

Performance (M2 Pro, 1280×720 preview): 119.8 FPS mean in a five-enemy fight (p95 9.6 ms,
max 12.8 ms). Validation: 742 assertions across 15 headless suites.

## 0.2.17 — Blood (10 October 2026)

Creator request: blood splatter when enemies get sliced.

- **Slices bleed.** A cut sprays a burst of dark droplets that arc and fall, both halves
  spurt as the top one flies, and a pool splashes on the floor at the cut with streaks
  thrown along the swing; the severed half leaves a second pool where it lands. Splat
  shapes are generated once (irregular pools, satellite drops, streaks), at most 24 lie
  on the floor at a time (oldest go first), each fades after about 10 s, and a restart
  mops them all up. Visual only (`game/combat/blood.gd`).

## 0.2.16 — Works On My Machine, sliced in half, and kill cams (10 October 2026)

Creator requests: add the "Works On My Machine" counter move; ragdolls or enemies getting
dismembered for better battle feedback; mini cutscenes for the finishers; make killing
enemies satisfying.

- **Every kill lands.** The body's label slams in as a red corporate death notice
  (CLOSED, WONTFIX, DEPRECATED, OFFBOARDED, SUNSET, RIGHT-SIZED…; bugs get FIXED,
  SQUASHED, NOT A BUG), with a shock ring, a flash, a layered impact, a short freeze-frame
  and a camera punch. Kills pay FOCUS (6, bugs 2), and quick kills chain into a streak
  banner (DOUBLE MERGE, TRIPLE MERGE, QUAD DEPLOY, MASS LAYOFF, RESTRUCTURING ×N) worth
  +3 FOCUS per extra kill.

- **Physical deaths.** Kills now come apart (rendered game; visual only). A heavy blade
  kill (35+ damage: the finisher, Reply All, Blame Shift, the counter, any surprise
  double) slices a humanoid (Corrupted Record, Blocker, The Variance) in half at the
  waist: the legs stay and buckle while the upper half flies off spinning. Lighter kills,
  and bodies that cannot be cut (flyers, the blob), launch the whole body tumbling as a
  physics object; Force Rollback launches them high. Every kill sprays bouncing data
  chunks in the monster's colours. Pieces settle, then dissolve. (The models are single
  skinned meshes: the cut hides the other half's bones on each copy rather than splitting
  geometry.)
- **Finisher kill cams.** A cut to a low side angle with a beat of slow motion, letterbox
  and a white flash, then straight back: on the last kill of every wave (the change
  request waits a second for it), the Quick Sync's last attendee, The Variance, the Force
  Rollback slam, and big slicing kills at most every 7 s.

Performance (M2 Pro, 1280×720 preview): a five-enemy fight held 120.3 FPS mean (p95
9.6 ms, max 11.7 ms). Validation: 739 assertions across 15 headless suites, plus the
talk-voice manifest check.

- **WORKS ON MY MACHINE (G).** A 0.6 s counter stance inside a green "localhost:3000"
  dome. Any hit that lands in the window does nothing; the engineer shouts "Works… on my
  MACHINE!!" and the attacker takes the blame: 60 damage, knocked back, staggered,
  CANNOT REPRODUCE, while the engineer spins into a riposte. A clean counter refunds most
  of the 3 s cooldown and adds 20 FOCUS. A whiff ("…works on my machine?") leaves a short,
  rooted recovery with no attacks. Read the orange arc, raise it late.
- The HUD key strip is two short lines between the vitals card and the minimap.

## 0.2.15 — Reply All, Blame Shift, Circle Back (10 October 2026)

Creator feedback on 0.2.14: put a whoosh under each call; "Hot Swap" is cringe; a
funnier alternative, maybe a better move set.

- **The moves are corporate jargon now, each with a twist that fits the joke:**
  - **REPLY ALL** (C): the crescent that hits everyone in line; each victim gets a
    "RE: RE: RE:".
  - **BLAME SHIFT** (X, or attack out of a dodge): the dash slash; everyone it passes
    is BLAMED and takes 30% more from every hit for 4 s. Dash in, then punish.
  - **CIRCLE BACK** (Z, "Let's circle… BACK!!"): the whirlwind; its last pulse sends
    survivors to the PARKING LOT, stunned for 1.2 s.
  - **FORCE ROLLBACK** (V) stays: "git reset… HARD!".
- **Whooshes.** Original synthesized whooshes (filtered noise sweeps from
  `tools/build_whoosh.py`) play under each call: a slice, a dash pass, a wobbling spin,
  and a rising swell into the ultimate, with a heavy impact under its slam.
- New calls voiced with the hype chain; old ones removed.

## 0.2.14 — Louder calls (10 October 2026)

Creator feedback on 0.2.13: make the shouts louder and more hype.

- The five move calls were re-voiced faster and a little higher, with exclamation-heavy
  reads, then run through a new "hype" chain: presence boost, exciter, hard compression,
  a doubled-voice chorus, an arena echo and soft saturation, mastered at −14 LUFS (talk
  stays at −20). In game they play +4 dB with slight pitch variety per call, so they sit
  on top of the fight. Still unheard candidates; tell us if they need more.

## 0.2.13 — Called out loud (10 October 2026)

Creator feedback on 0.2.12: the dash's damage should land as you pass through; and the
engineer should shout each move's name when using it, like in Japanese anime.

- **Hot Swap cuts on contact.** Each enemy is cut (crossed white slashes, shards, a
  flash) the instant the dash passes it; arrival keeps the white flash of the path, the
  spin flourish and a freeze-frame if anything fell.
- **Move callouts.** The engineer shouts every special in his own voice with a touch of
  echo: "Hotfix… WAVE!", "Hot… SWAP!", "Merge… CONFLICT!", and the ultimate twice:
  "FORCE… ROLLBACK!" on the leap and "git reset… HARD!" on the slam. Each call slides
  a cut-in across the screen: a slanted purple strip for the ultimate, a quick slash of
  text for the rest (real-time, so it plays through the slow motion).
- 5 new lines; 157 talk/callout lines in all, unheard candidates.

Validation: 718 assertions across 15 headless suites (new: cut-on-contact timing and
every move's callout).

## 0.2.12 — A dash slash and a whirlwind (10 October 2026)

Creator feedback on 0.2.11: more special moves, like a dash slash.

- **HOT SWAP (X, or attack during a dodge).** A 7 m dash straight through enemies
  (invulnerable, through bodies, stopped short of walls). In 0.2.12 everything passed
  was cut together a beat after arrival (55 damage each); 0.2.13 cuts on contact. A
  gold wall of light traces the path and flashes white on arrival. 2.5 s cooldown. Dodge-into-attack makes it a combo tool.
- **MERGE CONFLICT (Z).** A steerable fire whirlwind for 1.4 s: the spinning backhand on
  repeat, four pulses that hit everything within 3 m and drag it inward. 6 s cooldown.
- The FOCUS line in the vitals card now shows all three cooldowns (C · X · Z); the
  controls page, key hints and README list every move.

Validation: 713 assertions across 15 headless suites (new checks: the dash goes through
and cuts on arrival, its cooldown, dodge-into-dash, and the whirlwind's repeated hits).

## 0.2.11 — Set them off yourself, and two special moves (10 October 2026)

Creator feedback on 0.2.10: the outbreak camera was too close; monsters should be
introduced by something the engineer does (going close, irritating them), not the
moment the game starts; and the engineer needs fancy moves and strong specials.

- **You set them off.** A due wave now waits inside its employees, who act strange
  (NEXT points at the nearest with a ??? marker; the HUD says how many and when they
  snap). Talk to one and the conversation ends with them turning (there is now a
  deliberately provoking reply); hover within 2.8 m for 5 s and you get a voiced
  "…can I help you? … breathing. Loudly." before they snap; hit one and the whole wave
  turns on the spot with no cutscene, your blow landing as the surprise double. Ignore
  them for 45 s and they snap anyway. Swinging at an employee who isn't due gets you a
  voiced "I'm telling HR." The cutscene's lower third says what set them off.
- **Wider outbreak camera.** The cutscene frames from about 5 m, slightly high, pulled
  in only by walls; it usually shows the room, the employee and the engineer.
- **HOTFIX WAVE (C / middle mouse).** The overhead cut throws an upright crescent blade
  13 m ahead that pierces every enemy in its path (45 damage each, surprise doubles
  apply), breaks on walls, scars the floor and trails sparks. 3.5 s cooldown.
- **FORCE ROLLBACK (V).** The ultimate: combo and wave hits fill the FOCUS bar (new, in
  the vitals card, with the wave cooldown). At 100 the engineer leaps in slow motion
  and slams: 110 damage to everything within 7.5 m, shields dropped, rings, cracks,
  "git reset --hard" and a camera punch.
- **Voices.** 25 more lines (the provoking reply, each employee's snap, hover and HR
  remarks): 152 talk lines in all, unheard candidates.

Performance (M2 Pro, 1280×720 preview): a five-enemy fight held 120.0 FPS mean (p95
12.5 ms, max 15.6 ms). Validation: 705 assertions across 15 headless suites plus the
talk-voice manifest check.

## 0.2.10 — The night shift talks properly (10 October 2026)

Creator feedback on 0.2.9: a sleepy "mmm" was read out as "em em em"; NPCs kept walking
while talking; conversations needed better camera angles; the engineer should speak
too; and the writing could go all out.

- **Unhinged rewrite.** Every conversation was rewritten and pushed further (Gary is a
  load balancer now; the incidents are unionizing; the burrito holds Casey's will to
  live; Uncle Layoffs). Satire still aims at corporate systems, not professions.
- **Pronunciation.** Lines keep their written form in subtitles, but speech goes through
  a spoken-form table (ETA, VPN, HR, KPIs, Q3, INC-000, VLOOKUP, DISRUPT, 9:15, …), and
  the sleepy hum was rewritten as words. No line is spelled out letter by letter.
- **The engineer answers out loud.** Picking a reply now plays it in the protagonist's
  own voice (52 recorded replies; actions in parentheses stay silent), then the other
  person responds. E skips ahead.
- **They stop and act.** The crew now pauses with the rest of the game (the incident
  node runs always; the crew no longer inherits that), the person you talk to faces you
  and gestures with the line (arms up for an exclamation, a point for a question), and
  the engineer lowers the keyboard while talking.
- **Camera.** Each talk opens on a side two-shot, then cuts shot/reverse-shot from the
  same side of the pair: over the engineer's shoulder or a close single on the speaker,
  and a reverse over their shoulder while the engineer answers, each drifting in.

127 talk lines are voiced now (75 crew, 52 engineer), all unheard candidates.

## 0.2.9 — Outbreaks, a minimap and the night shift talks back (10 October 2026)

Creator feedback on 0.2.8: show where the enemies are; introduce them more creatively
(regular employees who transform in a cutscene); the engineer clipped through the chair
in the opening; interact with NPCs RPG-style with unhinged dialogue, voiced; the
floating cards in the hallway by the pantry blocked the view.

- **Outbreaks.** Every wave member now starts as an ordinary overtime employee planted
  around the floor ahead of time (well away from you). When the wave is due, a short
  cutscene cuts to one of them: a lower third (*DANA · Accounts Receivable — Reconciling
  since Tuesday*), a "P1 ASSIGNED" ping, a red convulsion, then a burst into the monster
  with its own title card. The rest of the wave turns at the same moment wherever they
  are, and the bugs pour out of the first one. TAB skips to the burst. Hitting a planted
  employee's incident early forces it out. The Quick Sync attendees are already standing
  in Meeting Room 3 during the investigation, and turn when you walk in. Planted
  employees twitch red every few seconds, for the attentive.
- **Minimap.** Bottom right: the walkable floor, turned with the camera. Red dots hunt
  you, orange dots patrol (with their sight drawn at true scale), grey dots are people,
  the cyan diamond is the NEXT step; anything past the edge is pinned to the rim.
- **Talk to the night shift.** Walk up to any coworker (or an employee who is about to
  turn) and press E: the incident pauses, the camera frames the pair, and a dialogue box
  types out the line in their own voice with up to three replies (1·2·3, click, E to
  continue, Esc to leave). Nine coworkers have branching satirical conversations and a
  different opener on a second visit; a few replies nudge Burnout. Nobody chats while
  something is hunting you.
- **Voices.** 74 new lines, voiced locally with Kokoro: 25 profiles blended from the six
  installed stock voices with their own speed and pitch (no new downloads). Text types
  at the pace of the voice.
- **Chair clipping fixed.** Seated, the engineer now sits up on the cushion and forward
  of the backrest (the sitting clip was authored for a lower stool); hands and the
  keyboard stay on the desk, and the opening close-ups were re-framed to match.
- **Hallway invites.** The calendar invites drifting down the east corridor float under
  the ceiling at 72% size and step aside (hide) when the camera comes close.

Performance (M2 Pro, 1280×720 preview): a five-enemy fight held 118.4 FPS mean (p95
13.1 ms, max 17.0 ms; 0.2.8 measured p95 9.7 ms in a different spot, so the minimap's
per-frame drawing is a suspect to watch). Validation: 687 assertions across 15 headless
suites, plus the talk-voice manifest check. The 74 new voice lines are unheard
candidates: human listening is pending.

## 0.2.8 — Smarter enemies and a clear next step (10 October 2026)

Creator feedback on 0.2.7: enemies still felt dumb; "cardboard" stuck out in the hallway
by the pantry; and it was not obvious what to do next.

- **Smarter enemies.** A wave now fights as a squad: while waiting for a turn, enemies
  spread around you (behind you first, then the sides) instead of queueing in front.
  They read your wind-up when it is aimed at them and sometimes sidestep it (the Blocker
  never does; bugs rarely), lunge to close the last couple of metres instead of walking
  in, and a badly hurt one falls back once to let the others press. Damage, telegraphs
  and the two-attackers cap are unchanged.
- **The "cardboard" was the sight cones.** Their cream fill looked like flattened boxes
  on the blue carpet. They are now red, additive outlines (edges and rim) over a faint
  haze: a line to stay outside of, not a patch of floor. Bugs see less (6 m, 90°).
- **What next.** A "NEXT" line at the top centre always says what to do, with a compass
  arrow and the distance when there is somewhere to go: hunt the threats, fight, inspect
  the console in Operations, go north into the vault, strike The Variance while it is
  OPEN. The through-wall marker follows the same step (THREAT, CONSOLE, VAULT).

Performance (M2 Pro, 1280×720 preview): a five-enemy fight held 119.3 FPS mean (p95
9.7 ms, max 17.1 ms). Validation: 665 assertions across 15 headless suites.

## 0.2.7 — Patrols, sight cones and the night shift (10 October 2026)

Creator feedback on 0.2.6: a monster got stuck in a room where it could not be hit; the
office needed more life; the stats panel was too big; more NPCs doing office nonsense;
and enemies should roam with visible sight instead of grouping at one spot.

- **Stuck-monster fix.** The copy room in the meeting wing is sealed, and its navigation
  mesh was an island; monsters spawned there could not be reached. That site is gone
  (replaced by the east corridor), and every spawn position is now path-checked from
  the main floor, with an automated check over every site and spawn slot.
- **Patrols and sight cones.** Each wave member breaks out at its own site and then
  patrols the office, pausing to look around. Every unaware enemy shows what it can see
  as a cone on the floor, cut off by walls and furniture: pale when unaware, orange
  when it is noticing you, amber while searching. Stay out of the cone, hit first. The
  marker now follows the nearest threat that is not already chasing you, and the HUD
  reads "4 threats roaming the floor • nearest 17 m". Sight is 11 m over 110°.
- **A livelier office.** A lounge with rug, sofa, armchairs, coffee table, lamp, TV,
  speakers and plants; plants and floor lamps along the windows; desk plants, books,
  unpacked boxes and warm desk lamps; neon signs ("MOVE FAST", "SHIP IT", "THINK
  DIFFERENT. DEPLOY THE SAME.") with coloured light; culture-deck posters ("WE ARE A
  FAMILY* *terms apply", "FAIL FAST (NOT IN PROD)", "YOUR WELLBEING IS A KPI", "IT
  WORKED ON MY MACHINE"); a bench and plants in the wing. Decorative only: no collision,
  combat lanes untouched.
- **More coworkers (nine).** New: a one-person standup ("Yesterday: meetings. Today:
  meetings. Blockers: meetings."), a day-one intern hauling boxes ("Is it normal to be
  on call on day one?"), someone "working from home" on the lounge sofa, a man waiting
  forty minutes at the microwave, and a recruiter on the deck ("We're like a family
  here. A family with KPIs.").
- **Compact stats.** The lower-left card is about a third of its old size; the debt and
  Burnout effect lines appear only once they say something.

Performance (M2 Pro, 1280×720 preview): a five-enemy fight held 119.5 FPS mean (p95
9.5 ms, max 17.2 ms). Validation: 658 assertions across 15 headless suites.

## 0.2.6 — Roam the floor (10 October 2026)

Creator feedback: monsters always spawned in your face, and they should only chase you
if they spot you or you hit them.

- **Outbreaks around the office.** Each wave now breaks out at a named spot: the desks,
  the pantry, Operations, the copy room, the conference deck, the lounge or the meeting
  wing. It is always at least 14 m from you and never the same spot twice in a row. A
  light column and a "▼ INCIDENT · 25 m" marker (visible through walls) show the way,
  and the HUD reads "Incident reported at the pantry • 25 m". Bug swarms come with them.
- **Sight or hit only.** Monsters chase only when they see you (their view cone, with
  line of sight) or when you hit them. Noise, sprinting and waiting no longer pull them
  in. One that spots you sends nearby colleagues to look where you were; they join only
  if they see you too. Sneaking up still lands a double-damage Surprise Review.
- **Onboarding Docs** fits on one page again (keys in two columns) and explains the
  marker, the sight rule and bugs.

Validation: 654 assertions across 15 headless suites (roaming sites, beacon, sight-only
awareness, investigation, hit-to-chase).

## 0.2.5 — One monster pack (10 October 2026)

Creator ask: retry Quaternius' "Ultimate Monsters". Its official Drive link was still
over quota, so the unchanged CC0 pack was taken from a public GitHub mirror (see
[enemy provenance](../assets/enemies/README.md)). Every enemy now comes from that one
pack, so the cast finally shares an art style:

- **Corrupted Record:** a skull-faced orc with a spiked club.
- **The Blocker:** a Yeti holding up the BLOCKED sign.
- **The Meeting Invite:** an orange winged dragon with the invite overhead.
- **Scope Creep:** a spiky green blob covered in sticky notes.
- **The Variance:** a red demon with both a halo and horns, and a trident.
- **BUG minions:** armoured bees (still one hit each).

Behaviour, effects, freeze-frames and balance are unchanged from 0.2.4. Performance (M2
Pro, 1280×720 preview): a five-enemy fight held 120.2 FPS mean (p95 9.5 ms, max 11.1 ms).
Validation: 650 assertions across 15 headless suites.

## 0.2.4 — Monsters, minions, moves and the night shift (10 October 2026)

Creator feedback on 0.2.3: freeze-frames on big impacts; monster effects that add
nothing; monsters that do not look like monsters; one-hit minions; a crisper, fancier
combo; a more coherent camera; and coworkers to bring the office to life.

- **Real monsters.** Corrupted Records are skeletons ("zombie transactions") that claw
  up out of the floor; the Blocker is a hulking alien brute with its BLOCKED sign; the
  Meeting Invite is a purple bat; Scope Creep stays a note-covered slime; The Variance
  is a red dragon wearing its crown of status screens. Each keeps its original colours
  with only a faint rim, a bright wind-up glow and a hit flash; corpses sink away.
- **BUG minions.** Swarms of small, fast alien bugs rush in with every wave (3–5). Any
  hit fixes one. They never hold up a wave; when the stage clears, the survivors are
  closed as WONTFIX (and the postmortem timeline says how many).
- **Less noise.** Enemy strikes no longer throw floating words, shards and motes; the
  telegraph circle and the impact itself remain.
- **Freeze-frames.** The Blocker's quake, The Variance's cataclysm, your finisher
  connecting and the boss's defeat stop the fight for a beat.
- **A new combo.** Hit 1 snaps the keyboard overhead and cuts down diagonally as you
  lunge forward; hit 2 is a full spinning backhand; hit 3 leaps into the air and slams
  down two-handed into the fire ring, cracking the floor. Same damage windows; the
  swing ribbon only draws the cut itself.
- **Camera.** It pulls back a little during fights and, if you leave the mouse alone for
  a second, eases toward the fight; moving the mouse hands control straight back.
- **The night shift.** Four coworkers on overtime: one asleep on his keyboard ("zZz…
  LGTM… zZz"), one insisting he is on a different incident, a manager pacing on a call
  ("Yes, someone's on it. No, I don't know who."), and Facilities finally closing the
  vending-machine ticket from 2019. They cower during fights, and when one ends the
  manager announces "Great teamwork, everyone!"

Performance (M2 Pro, 1280×720 preview): a five-enemy fight held 120.1 FPS mean (p95
9.4 ms, max 13.8 ms); a battle-mode fight with continuous combos 119.8 FPS (max 16.8
ms). Validation: 650 assertions across 15 headless suites. Feel, camera assist and
the coworker jokes need a human run.

## 0.2.3 — Enemy attacks hit the ground (10 October 2026)

Creator ask: flashier enemy attacks, "like earthquake or something". Damage, reach,
timing and AI are unchanged; every effect fires on the existing strike frame.

- **Corrupted Record:** a red crescent slash with a crack racing across the floor toward
  you, kicking up debris.
- **The Blocker:** a ground-pound quake: twin shockwaves, glowing cracks splitting
  outward, flying floor chunks, rolling dust and a screen tremor. The floor already
  rumbles while it winds up.
- **Scope Creep:** a goo splat that sprays sticky notes.
- **The Meeting Invite:** booking a meeting now drops a violet beam over your spot that
  slams down with a small quake as the zone opens.
- **The Variance:** a cataclysm: red and green quakes, three fissures erupting rocks
  across the vault, lightning from its crown and the strongest tremor.
- **Screen tremor** is rotation-only and scales with the existing Camera shake setting
  (0 turns it off).

Performance (M2 Pro, 1280×720 preview): a five-enemy fight held 119.3 FPS mean (p95
9.7 ms, max 16.7 ms). Validation: 641 assertions across 15 headless suites. Whether the
tremor is too much in a long fight needs a human run.

## 0.2.2 — Enemies that are not boxes (10 October 2026)

Creator feedback on 0.2.1: the enemies still looked like boxes. Combat rules, AI,
timing and balance are unchanged; this is presentation.

- **New bodies.** Every enemy is now a rigged, animated CC0 Quaternius model wearing a
  "corrupted production" skin: its original texture under a glowing rim and glitch
  bands that crawl up the body in the enemy's spell colour.
  - **Corrupted Record:** a lean, rust-streaked mech with the loading halo still
    spinning over its head.
  - **The Blocker:** a hazard-striped boxy mech carrying the BLOCKED sign as a riot shield.
  - **The Meeting Invite:** a tall antenna mech with the MANDATORY invite hovering above it.
  - **Scope Creep:** a slime with sticky notes plastered over it, which visibly swells as
    requirements are added.
  - **The Variance:** a 3-metre mech wearing its crown of SUCCESS / FAILED / NOT FOUND
    screens; its false-positive copies are ghostly projections of the same body.
- **Animated from the AI.** They idle, walk and run while pursuing, flare bright and
  wind up during the telegraph (the blow lands on the existing damage frame), stagger
  when hit, raise an arm to cast, and die with their own death animation before
  dissolving.

Limits: the mech attack animations are stock slashes, punches and kicks, so the limb
does not trace the telegraph arc exactly; the slime has no hit reaction. Performance
(M2 Pro, 1280×720 preview): five rigged enemies held 119.9 FPS mean (p95 9.6 ms, max
13.4 ms). Validation: 639 assertions across 15 headless suites.

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
