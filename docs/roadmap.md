# SEV-1 Development Roadmap

Advance through playable evidence, not calendar promises. Each milestone has an acceptance gate; completion of an automated check does not establish that combat is fun or the art is finished. The human director accepts creative outcomes. The six-circle vision is long-term scope that can be reduced if production cost exceeds what this indie project can sustain.

The 11 October [office furnishing pass](workstation_trial.md) extends the existing
free detailed desk to all eight workstations and adds acoustic ceiling finish, storage
and meeting-room details. The subsequent chair pass adds a fitted CC0 ergonomic chair
across desk, conference and pantry seating. The overlap/collision refinement fits
solid furniture envelopes, clears pantry wall/desk-prop intersections, releases the
engineer beside the chair, and rebakes navigation. It is an implemented visual candidate; director acceptance
and moving-combat performance remain open under the Office After Hours gate.

## Milestones

| Milestone | Scope and current status | Gate before expansion |
| --- | --- | --- |
| 1. First playable prototype | Technical core implemented: movement, camera, one melee attack, one enemy, HUD, health, pause, death/reset. Human acceptance pending. | Director can play and retry reliably, understand attacks, and identify specific feel problems. Existing regression checks remain green. |
| 2. Combat Alpha | Technical implementation ready for playtest: buffered three-hit combo, directional dodge, hit-stop/impulse/sparks, explicit enemy states, and clean resets. Human acceptance pending. | Fighting one enemy is rewarding without jokes or rewards; threats and defensive outcomes are fair and repeatable. |
| 3. The Office After Hours | Implemented environment pass: workstations, glazed conference room, operations wall, after-hours lighting, shared materials, and baked enemy routes. Visual acceptance remains pending; characters and furniture remain simplified. | Director accepts the visual standard; moving combat remains readable; record frame times, resolution, and settings on the M2 Pro. Establish a Windows build check before major content expansion. |
| 4. First narrative incident | Implemented playtest candidate: [Incident 001: The Missing Transaction](game_design.md#incident-001-the-missing-transaction), with two record encounters, a containment handoff with a consequential Management reply, The Variance, and deterministic reports. Human duration, difficulty, and feel acceptance remain pending. | A replayable 5–10-minute experience teaches its true/false cue, supports resolution and death/review/retry, and works for a non-developer. It is enjoyable without progression. |
| 5. Character, animation & combat presentation | Implemented native fallback pass: office-worker identity, Escalation Blade, distance-driven gait, phase-coordinated attacks, crouched dodge, fragmented records, directional sparks, and four additional synthesized cues. 155 assertions pass; finished models/rigs and human visual/audio acceptance remain outstanding. | Director accepts identity and moving combat readability; validate full Incident 001 and restart; record 1080p performance. No claim of finished skeletal animation. |
| 6. Roguelite progression prototype | Implemented playtest candidate by explicit Milestone 6 authorization: two three-option decisions, additive run bonuses, bounded Technical Debt, pursuit pressure, office warnings, and report summaries. Earlier human acceptance gates remain open. | The player understands the tradeoff, can recognize its later consequence, and wants to try another choice. Do not add Burnout and Reputation simultaneously. |
| 7. Burnout & Corporate Decisions | Implemented playtest candidate by explicit authorization: immediate risk/reward bands, meaningful-hit pressure, limited recovery, one three-option management decision, optional containment ETA, and dependency consequence. | Director can distinguish Burnout from debt, understand every tradeoff, and complete/retry all paths. Balance, audio, and Windows acceptance remain open. |
| 8. The Great Stabilization | Implemented technical playtest candidate: boss hit-stop timing, clearer choice previews and encounter progress, comfort toggles, bounded real-melee run coverage, and graphical transition measurements. See [verification and remaining gates](stabilization.md). | Director accepts movement/combo/dodge feel, true-form readability, tradeoffs, audio, and ordinary run duration; complete Windows runtime validation before content expansion. |
| 9. Friday, 4:59 PM | Implemented narrative playtest candidate: 24-second opening, skippable staged camera, reactive captions/corporate messages, environmental states, six-second boss arrival, shorter retries and truthful expanded reports. 341 assertions pass; human story/audio acceptance remains open. | Director accepts pacing, personality, camera handoff, readable messages, and convenient retries; preserve previous combat and platform gates. |
| 10. Friday Deployment | Version 0.1.0 application interface, saved preferences, explicit lifecycle navigation, macOS export automation and tester documentation implemented. Local tester candidate; see [release evidence](release.md). | Full validation/export/packaged smoke must pass; creator must accept ordinary play, audio and remaining first-use hitches. Ad-hoc signing is not public notarized distribution. |
| 11. The Voices of Production | Implemented audio candidate: 22 local Kokoro clips, six stock voice profiles, prioritized playback, synchronized subtitles and saved Voice/Subtitles settings. See [voice guide](voices.md). | Human listening acceptance for casting, intelligibility, timing and mix; full validation and packaged resource checks. |
| 12. Operation Corporate Hell | In progress (authorized 10 October 2026 after first external feedback: plain presentation, no cinematics, weak comedy delivery, small map, one enemy type). Phase B implemented: themed typography, a live 3D title desk with ambient notifications, a 36-second in-engine opening skippable after first viewing, and three new voiced opening lines. Phase C implemented: the office roughly doubles with a meeting wing (corridor, Quick Sync room, pantry with coffee/vending/microwave/poster interactions), a gated restricted server corridor and a server vault where The Variance now arrives, CC0 PBR materials and props. Phase D implemented: encounters run several enemies at once in authored waves with turn-taking telegraphs; three new archetypes (The Blocker shields allies, The Meeting Invite books slowing zones, Scope Creep grows when ignored) join the Corrupted Record; the optional Quick Sync meeting-room trap; escalating the dependency returns as a Blocker. Phase E implemented: spoken lines arrive as "Synergize" chat cards from their senders' channels (the engineer's are said out loud), a ticket-style HUD with health/Burnout bars and a boss bar, change-request and leadership-DM choice cards, and a 14-line writing pass (status page contradiction, management replies, victory thanks, blameless postmortem, protagonist barks). Phase F implemented: an evidence camera push, a staged vault arrival (lights fail, letterbox, ledger glitch) without taking control, a slow ending shot behind a postmortem document with stamps, first-sighting slow motion, original music beds on a ducked Music bus, and enemy awareness (arrivals idle until they see, hear or are alerted; they circle when waiting their turn, flank, back off after swinging, search when they lose you; surprise hits land double). After creator feedback ("this is an action game") the engineer became a rigged CC0 Quaternius character with retargeted run/roll/death motion, IK-driven keyboard swings and a spinning finisher; the combo gained elements (wind, lightning, fire), every enemy archetype casts its own spell visuals, and fights trigger a battle-mode grade. The enemies then traded their box bodies for CC0 Quaternius mechs and a slime, animated from their AI state under a corrupted-data shader, and their strikes now land as slashes, ground quakes, splats, beam drops and the boss's cataclysm with screen tremor. 0.2.4 swapped the mechs for monsters (skeleton, alien brute, bat, slime, dragon), added one-hit BUG minion swarms, freeze-frames, a reworked combo (lunge slash, spinning backhand, leaping slam), combat camera framing and four overtime coworkers. 0.2.5 moved every enemy onto Quaternius' "Ultimate Monsters" pack for one consistent art style. 0.2.6 spreads waves across the office (named outbreak sites with a through-wall marker, never in the engineer's face) and makes monsters chase only on sight or when hit. 0.2.7 fixes a stranded-spawn bug, adds patrols with visible sight cones, a decorated office with neon and a lounge, nine coworkers and a compact stats card. 0.2.8 adds squad tactics (surround, sidestep, lunge, regroup), outline sight cones and a NEXT compass with matching waypoints. 0.2.9 introduces waves as employees who transform in a short cutscene, a floor minimap, voiced RPG-style conversations with the night shift, and fixes the opening's chair clipping. 0.2.10 voices the engineer's replies, rewrites the crew's lines harder, fixes pronunciation, and stages talks with shot/reverse-shot cameras and gestures. 0.2.11 lets the engineer set waves off (talk, hover, hit, or they snap after 45 s), widens the outbreak camera, and adds two specials: Hotfix Wave and the Force Rollback ultimate. 0.2.12 adds the Hot Swap dash slash (also from a dodge) and the Merge Conflict whirlwind. 0.2.13 makes the dash cut on contact and has the engineer shout every move with an anime cut-in. 0.2.14 makes the calls louder. 0.2.15 renames the moves (Reply All, Blame Shift, Circle Back) with matching twists and puts a whoosh under every call. 0.2.16 adds the Works On My Machine counter, physical deaths (waist slices, tumbling bodies, data chunks), finisher kill cams, and kill stamps with streaks. 0.2.17 adds blood to slices. 0.2.18 reskins the monsters as dark, bleeding flesh (no neon) under the creator's new tone: a satirical, funny, gory dark RPG. 0.2.19 gives every monster voiced, unhinged overwork barks. 0.2.21 brings the Legacy Monolith broadsword carried on the shoulder, three-beat hero kill cams and clearer monster voices. 0.2.22 softens the lightning; 0.2.23 makes Force Rollback an omnislash. 0.2.24 retargets Quaternius' CC0 Universal Animation Libraries onto every office body, adds the hero pose, and redesigns the dialogue box and talk prompt. 0.2.25 smooths animation, progression and pacing: layered slow motion, a run end that plays out before the report, real-time change-request timing, guarded choice cards, matched employee transformations, a played death fall and blended kill-cam exits. 0.2.26 keeps the camera out of walls, ceilings and door headers (sphere-swept spring arm, camera-only collision for large architecture, eased pull-back, close-up fade). 0.2.27 shows the special moves as an icon bar with cooldown sweeps instead of text. 0.2.28 fits every wall text inside its frame. 0.2.29 frames the culture deck as motivational prints with CC0 photographs, gives notices real paper, and adds the SYNERGEX logo. 0.2.30 makes the finisher kill cam a slow-motion swing through the kill. 0.2.31 turns status notices into one-line toasts. 0.2.32 trims the objective, status and NEXT lines. 0.2.33 measures a whole run and pre-draws text styles to remove first-use stutters. 0.2.34 makes every wall joke readable and centres the SYNERGEX logo. 0.2.35 replaces the opening with a narrated cold open: drone shots, a freeze-frame night-shift montage, the red monitor wave, a notification storm and a title slam. 0.2.36 opens on a night fly-in through the tower window and fixes the translucent engineer. 0.2.37 rebuilds the missing-transaction reveal as a scary-funny power-down, staring night shift, flicker stalk and jump scare. 0.2.38 adds NADIA, VAL and JUN to the night shift, gives the planted women female bodies, seats sitters on real furniture, and darkens the city. 0.2.39 sends the night shift into the vault first: a massacre with casualty cams and epitaphs, then the hero entrance. 0.2.40 has The Variance take them one at a time while the rest run panicked laps, gives each a turn to speak, and pins the casualty stamp to the name card. 0.2.41 swaps their apologies for unhinged last words. 0.2.42 gives The Variance a named moveset of corporate euphemisms done literally (each coworker dies to their own, somewhere else in the vault) and makes the engineer's entrance a rage transformation, Unpaid Overtime, whose blast throws it back. 0.2.43 turns the moveset on the engineer in the fight, cuts the killing blow to a duel, and ends the incident on a cinematic finale. 0.2.44 dismembers it through the duel's last words and remakes the finale: the walk out at midnight past fading memories of the five to an original sad theme, the rainy street and the five in the lit window. 0.2.45 replaces Monday's scene with a blameless postmortem call that backfills the night shift with AI. | Creator review of each playable phase; human playtests for fun, comedy and readability. Phase G implemented: 0.2.0 tester build; 0.2.1 adds the rigged engineer, elements, enemy spells and battle mode. Creator review (10 October 2026): the opening, comedy, new enemies and dialogs land. External playtests, balance and run length remain open. |
| Tester acceptance and platform hardening | External playtests, measured balance/pacing feedback, first-use hitch investigation and Windows runtime testing remain open. | Resolve or explicitly accept P1 issues before declaring release ready; preserve this bounded slice. |
| Later circles | Deferred, conditional long-term work. | A distinct mechanic must earn expansion after the current slice is accepted. |

The intended Windows release target is preserved. Native Windows runtime testing remains outstanding; exporting an executable alone will not satisfy that gate. No dates or final content counts are committed.

The 11 October source aftermath refinement adds the tear, sword left at the workstation,
personal-effects pickup and ordinary voiced memories. The departure now uses a
dedicated empty exit corridor to clear lounge furniture from the hero/camera route.
Normal walking legs alternate with remembered lines, followed by a visible door opening
and full threshold crossing beneath the SYNERGEX mark; see the
[Incident 001 aftermath](game_design.md#incident-001-aftermath-implemented-prototype-11-october-2026).
Human emotional, animation and listening acceptance remain pending.

The 11 October outbreak pacing refinement stages a collision-limited step back to
3.8 m for close talk/hover reveals and the Quick Sync. Revealed monsters and BUGs
stay planted through the camera sequence, then give the engineer two playable
seconds before pursuit or attack; TAB preserves that window. Hitting first still
lands the surprise strike without a camera cut, with the same retreat window.
Human checkpoint: trigger a strange employee at close range, watch the full body
change, then run/dodge away; repeat beside furniture and in the Quick Sync.
Accept only if the staging reads clearly and the retreat feels fair.

The 11 October Quick Sync refinement expands the room and adds projector action-item
circles; see the [meeting encounter](game_design.md#emergency-alignment-meeting-implemented-prototype-11-october-2026).
Human space, challenge, comedy and readability acceptance remain pending.

## Next acceptance increment

The 11 October [scene-flow pass](scene_flow.md) connects outbreak guidance, the
optional investigation detours and the corridor/vault route. Its checkpoint verifies
nearby E prompts and reaching the actual boss trigger. Human run time, clarity and
cinematic pacing acceptance remain open; it adds no compulsory encounter.

The 11 October [pantry refinement](pantry.md) expands the recovery room and doorway,
moves dining furniture out of the central lane, and adds repeat appliance hauntings:
Sam's mug tribunal, Casey's organised leftovers, a vending receipt and mandatory
wellness breathing. Coffee keeps its existing benefit. Full validation passed;
new appliance replies are text, with human comedy/layout/audio acceptance pending.
The linked checkpoint starts beside the pantry for a quick playtest.

Run the packaged Friday Deployment slice with the creator and a few external testers.
Use the [tester guide](testing.md) and record ordinary completion time, unfair hits,
confusing choices, readability, humor and desire to replay. Compare all management
paths and damage/defense/mobility upgrades. Earlier human gates are still open;
automated completion does not retroactively accept feel, art, sound or balance.

First-use frame hitches remain a P1 performance gate; diagnose them with measured
profiles before speculative optimization. Obtain explicit creator acceptance or resolve
them. Test the copied ZIP on another Mac. Developer ID/notarization and Windows runtime
validation remain separate distribution/platform work; do not claim them from export.

Milestone 10 was explicitly authorized on 10 October 2026. It supersedes the old
"additional circles" milestone numbering and generic polish/release plan. No new
chapter, boss, progression system or balance redesign was authorized or implemented.
The native art/audio remain usable temporary assets. See [release notes](release_notes.md)
for severity-classified limitations and [architecture](architecture.md) for actual rules.

## Open creative decisions

| Decision | When it matters |
| --- | --- |
| Keep camera-directed melee, use movement direction, or add assistance? | Combat refinement; judge current aiming before changing it. |
| Dodge travel, invulnerability, and attack-cancel rules; eventual combo depth? | Separate combat experiments, one question at a time. |
| Accept the exhausted office-worker design and keyboard Escalation Blade? Voice and loop memory remain open. | Review the provisional native model in Milestone 5; finished asset selection follows feedback. |
| Realistic versus stylized-realistic materials, animation/asset sourcing, audio tone? | Visual slice; artistic seriousness and combat readability are already required. |
| Does The Variance's solid diamond and explicit OPEN cue teach its true form well enough? | Incident playtest; solid versus hollow shape and text are implemented, with two harmless projections and no multiplication penalty. |
| What persists, what debt costs, whether Burnout earns its place and whether to explore Reputation, and whether the ending changes? | Progression and later narrative playtests; do not prebuild storage or frameworks. |

## Planning corrections from vision alignment

- The old first-playable proposal combined a 3–5-minute wave encounter with an upgrade choice. It is superseded: the current one-opponent lab is milestone 1; the 5–10-minute narrative incident is milestone 4; temporary progression is implemented in milestone 6 following the explicitly requested presentation milestone.
- The Friday Deployment title now launches by default and starts Incident 001 in the Office After Hours. The original single-opponent arena remains available for regression tests.
- Dodge and combos remain Combat Alpha experiments. Handcrafted reports and Friday incident reset fiction are implemented; the six circles and progression beyond chapter completion remain deferred.
- The old proposed folder tree included progression/UI/data concepts that do not exist. [Architecture](architecture.md) now describes only the inspected implementation.
- The old movement lab has been replaced in the main scene by Office After Hours. Characters and simplified furniture remain provisional; the director has not yet accepted the final visual standard.

Office After Hours preserves Combat Alpha tuning, the free camera, and the existing movement baseline. Automated results do not replace the pending human playtest.

Milestone 11 was explicitly authorized as The Voices of Production on 10 October 2026. It adds authored prerecorded speech only. Milestone 12 was authorized the same day as a creative revitalization of Incident 001 only; it does not authorize Circle II, new currencies or progression systems. External playtest and platform gates remain open; generated content does not establish creative acceptance.

## Stage One completion saves

Implemented on 11 October 2026 by explicit creator request: [chapter boundary saves](chapter_saves.md),
a saved-progress / Stage Two coming soon message, Replay Stage One that preserves completion,
and an earlier tester unlock. Stage Two content and carry-over upgrade rules remain deferred.
Gate: verify completion/unlock → quit/reopen → replay/restart → quit/reopen on the
creator's device. Headless lifecycle and graphical menu checks support that checkpoint;
Windows runtime acceptance remains open.


The 11 October [free workstation fidelity trial](workstation_trial.md) upgrades only
the engineer’s starting desk with CC0 Poly Haven props. It preserves the existing
collision and screen staging. Creator visual acceptance remains pending; this is
not a whole-office or character replacement. Further asset selection is free-only.

The creator accepted the [free CC0 KayKit Skeleton Minion](../assets/enemies/kaykit_trial/README.md)
comparison on 11 October and authorized replacing the realistic demon variants on
Corrupted Records. Their existing combat behavior, stats, voices and physical deaths
remain. The supplied animations replace provisional demon motion; moving-combat
readability and death presentation remain human playtest checkpoints. This supersedes
the earlier Night/Chained Demon trial and adds no enemy archetype.

The creator selected a [CC0 Heavy Greatsword trial](../assets/characters/heavy_greatsword/README.md)
on 11 October 2026. The rigged engineer carries the imported sword with the existing
combat and story poses; the original native Monolith stays available. Gate: creator
accepts the materials, grip, shoulder carry, swing readability and parked story prop.

The creator-authorized [free sword motion trial](sword_motion_trial.md) follows that
weapon trial: full-body cuts, two-handed grips, dash and counter poses, using existing
CC0 clips and an optional locally licensed Kevin Iglesias attack. Human weight,
readability, combo recovery and skill-contact acceptance remain pending. No new
abilities, character replacement or published release are implied.


Drew's original Quaternius suit model is restored at the creator's request. The
human-model trial, its exported art, scene and build tools have been removed.
[Restoration and playtest checkpoint](drew_restoration.md). The subsequent creator
request adds feminine office silhouettes through fitted skirts, blouses/skirt suits
and earrings, with one lower-neckline outfit for adult director Marie.
[Outfit source and review](../assets/characters/office_outfits/README.md).

The 11 October [finishing-duel choreography](game_design.md#stage-one-finishing-duel-implemented-prototype-11-october-2026)
adds a reciprocal sword/trident lock, duck, riposte, block and knockback exchange before the existing
boss finisher. Gate: creator accepts contact, weight, camera continuity, pacing and
sound, including TAB skip and retry. It uses existing CC0 motion and adds no boss
mechanic, new episode or release build.


The revised 11 October Operations pass replaces the first wall framing with an incident
command console, detailed racks and CC0 industrial pendants. The creator rejected the
previous presentation and requested a bolder redesign. Power-ups are now free, funny
single-effect rewards; normal upgrade debt costs and pursuit penalties are retired.
[Implementation and playtest checkpoint](architecture.md#operations-and-choice-clarity-11-october-2026).
Creator visual and comprehension acceptance remains open.
