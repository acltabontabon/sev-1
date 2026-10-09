# SEV-1 Development Roadmap

Advance through playable evidence, not calendar promises. Each milestone has an acceptance gate; completion of an automated check does not establish that combat is fun or the art is finished. The human director accepts creative outcomes. The six-circle vision is long-term scope that can be reduced if production cost exceeds what this indie project can sustain.

## Milestones

| Milestone | Scope and current status | Gate before expansion |
| --- | --- | --- |
| 1. First playable prototype | Technical core implemented: movement, camera, one melee attack, one enemy, HUD, health, pause, death/reset. Human acceptance pending. | Director can play and retry reliably, understand attacks, and identify specific feel problems. Existing regression checks remain green. |
| 2. Combat Alpha | Technical implementation ready for playtest: buffered three-hit combo, directional dodge, hit-stop/impulse/sparks, explicit enemy states, and clean resets. Human acceptance pending. | Fighting one enemy is rewarding without jokes or rewards; threats and defensive outcomes are fair and repeatable. |
| 3. The Office After Hours | Implemented environment pass: workstations, glazed conference room, operations wall, after-hours lighting, shared materials, and baked enemy routes. Visual acceptance remains pending; characters and furniture remain simplified. | Director accepts the visual standard; moving combat remains readable; record frame times, resolution, and settings on the M2 Pro. Establish a Windows build check before major content expansion. |
| 4. First narrative incident | Implemented playtest candidate: [Incident 001: The Missing Transaction](game_design.md#incident-001-the-missing-transaction), with two record encounters, console investigation, The Variance, and deterministic reports. Human duration, difficulty, and feel acceptance remain pending. | A replayable 5–10-minute experience teaches its true/false cue, supports resolution and death/review/retry, and works for a non-developer. It is enjoyable without progression. |
| 5. Character, animation & combat presentation | Implemented native fallback pass: office-worker identity, Escalation Blade, distance-driven gait, phase-coordinated attacks, crouched dodge, fragmented records, directional sparks, and four additional synthesized cues. 155 assertions pass; finished models/rigs and human visual/audio acceptance remain outstanding. | Director accepts identity and moving combat readability; validate full Incident 001 and restart; record 1080p performance. No claim of finished skeletal animation. |
| 6. Roguelite progression prototype | Implemented playtest candidate by explicit Milestone 6 authorization: two three-option decisions, additive run bonuses, bounded Technical Debt, pursuit pressure, office warnings, and report summaries. Earlier human acceptance gates remain open. | The player understands the tradeoff, can recognize its later consequence, and wants to try another choice. Do not add Burnout and Reputation simultaneously. |
| 7. Burnout & Corporate Decisions | Implemented playtest candidate by explicit authorization: immediate risk/reward bands, meaningful-hit pressure, limited recovery, one three-option management decision, optional containment ETA, and dependency consequence. | Director can distinguish Burnout from debt, understand every tradeoff, and complete/retry all paths. Balance, audio, and Windows acceptance remain open. |
| 8. Additional circles | Conditional long-term work. Prototype one new circle's distinct mechanic before producing its environment or boss. | Its mechanic is fair, its theme has a recognizable visual identity, and its contribution to the systemic incident is clear. Reassess campaign scope after each. |
| 9. Polish and release | Release scope determined by evidence. Controls, accessibility, performance, usability, audio, packaging, credits/licenses, and final platform testing. Save migration/testing only if persistence is adopted. | Supported builds behave correctly on target hardware; no critical blockers; director accepts the bounded release scope. |

The intended Windows release target is preserved. Native Windows runtime testing remains outstanding; exporting an executable alone will not satisfy that gate. No dates or final content counts are committed.

## Next development increment

Playtest Milestone 7 before expanding content: compare all management choices with defensive and damage upgrades, check whether five minutes supplies meaningful pressure, and judge whether overloaded offense compensates for incoming risk. Retry from both modal types, victory, and defeat. The recommended next milestone is balance/usability refinement and Windows validation. Critical debt remains a tuning band, unreachable with two default upgrades.

Review the Milestone 5 native character pass before treating it as an accepted art standard. Check the keyboard grip, attack anticipation/contact/recovery, running feet, dodge ring, enemy warning/recovery, and restrained audio. See [character provenance and integration](../assets/characters/README.md). Then play Incident 001 from beginning to end, including a wrong investigation choice, boss false positives, a death, and repeated R retries. Measure the ordinary run duration against the 5–10-minute target; do not pad an efficient run with waiting merely to reach it. Review whether the first combat arrives promptly, the evidence makes sense without domain knowledge, and the solid-diamond/OPEN cue is clear while moving.

The creator explicitly authorized Milestones 4, 5, 6, and 7 on 10 October 2026 while earlier human feel/art and Windows gates remained outstanding. This is an implementation checkpoint, not retroactive creative acceptance. Refine this episode and its new tradeoffs from feedback before further content expansion.

Current defensive rules remain unchanged. The existing 94 baseline assertions passed before and after integration. Incident tests additionally cover the state lifecycle, real investigation input, boss damage windows, copies, terminal reports, cleanup, and reload. See [architecture](architecture.md#incident-001-orchestration) for exact behavior and [README](../README.md#incident-visual-and-performance-review) for the measured boss scenario.

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
- Incident 001 now launches by default in the Office After Hours. The original single-opponent arena remains available for regression tests.
- Dodge and combos remain Combat Alpha experiments. Handcrafted reports and Friday incident reset fiction are implemented; the six circles and persistent progression remain deferred.
- The old proposed folder tree included progression/UI/data concepts that do not exist. [Architecture](architecture.md) now describes only the inspected implementation.
- The old movement lab has been replaced in the main scene by Office After Hours. Characters and simplified furniture remain provisional; the director has not yet accepted the final visual standard.

Office After Hours preserves Combat Alpha tuning, the free camera, and the existing movement baseline. Automated results do not replace the pending human playtest.
