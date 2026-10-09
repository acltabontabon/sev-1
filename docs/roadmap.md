# SEV-1 Development Roadmap

Advance through playable evidence, not calendar promises. Each milestone has an acceptance gate; completion of an automated check does not establish that combat is fun or the art is finished. The human director accepts creative outcomes. The six-circle vision is long-term scope that can be reduced if production cost exceeds what this indie project can sustain.

## Milestones

| Milestone | Scope and current status | Gate before expansion |
| --- | --- | --- |
| 1. First playable prototype | Technical core implemented: movement, camera, one melee attack, one enemy, HUD, health, pause, death/reset. Human acceptance pending. | Director can play and retry reliably, understand attacks, and identify specific feel problems. Existing regression checks remain green. |
| 2. Combat foundations and refinement | Next priority. Tune the current strike, reaction, warning, recovery, and camera from feedback. Then test one dodge/defensive option; consider buffering, combos, and animation transitions as separate increments. | Fighting one enemy is rewarding without jokes or rewards; threats and defensive outcomes are fair and repeatable. |
| 3. Visual vertical slice | Deferred. Finish one small office area with a coherent asset/animation pipeline, credible materials, deliberate light, and a readable encounter. | Director accepts the visual standard; moving combat remains readable; record frame times, resolution, and settings on the M2 Pro. Establish a Windows build check before major content expansion. |
| 4. First narrative incident | Deferred. Build [Incident 001: The Missing Transaction](game_design.md#incident-001-the-missing-transaction), reusing proven combat and office assets. | A replayable 5–10-minute experience teaches its true/false cue, supports resolution and death/review/retry, and works for a non-developer. It is enjoyable without progression. |
| 5. Roguelite progression prototype | Deferred until the prior gates pass. One small upgrade selection, one meaningful run modifier, and a bounded Technical Debt experiment; expand contextual postmortem variations. | The player understands the tradeoff, can recognize its later consequence, and wants to try another choice. Do not add Burnout and Reputation simultaneously. |
| 6. Expanded content | Conditional. Add only encounter, enemy, and ability variations supported by playtests and a sustainable asset pipeline. | Added content creates different decisions rather than repetition; production and regression costs stay manageable. |
| 7. Additional circles | Conditional long-term work. Prototype one new circle's distinct mechanic before producing its environment or boss. | Its mechanic is fair, its theme has a recognizable visual identity, and its contribution to the systemic incident is clear. Reassess campaign scope after each. |
| 8. Polish and release | Release scope determined by evidence. Controls, accessibility, performance, usability, audio, packaging, credits/licenses, and final platform testing. Save migration/testing only if persistence is adopted. | Supported builds behave correctly on target hardware; no critical blockers; director accepts the bounded release scope. |

The intended Windows release target is preserved. Native Windows runtime testing remains outstanding; exporting an executable alone will not satisfy that gate. No dates or final content counts are committed.

## Next development increment

First, play the existing combat lab and record what feels wrong about attack startup, reach, recovery, camera aim, and the enemy warning. Tune only the smallest changes supported by that feedback and deliver the same encounter again.

After that acceptance, a focused dodge experiment is the recommended next new mechanic: define the desired travel, recovery, input direction, invulnerability, and whether it can cancel an attack before coding it. Use the current enemy to prove that defense is understandable. Do not add upgrades or new enemy counts to test dodge.

This is a recommendation for the next authorized implementation task, not a request to start it during documentation work.

## Open creative decisions

| Decision | When it matters |
| --- | --- |
| Keep camera-directed melee, use movement direction, or add assistance? | Combat refinement; judge current aiming before changing it. |
| Dodge travel, invulnerability, and attack-cancel rules; eventual combo depth? | Separate combat experiments, one question at a time. |
| Protagonist identity, voice, silhouette, weapon fiction, and who remembers the loop? | Representative character/art work and the first incident's writing. |
| Realistic versus stylized-realistic materials, animation/asset sourcing, audio tone? | Visual slice; artistic seriousness and combat readability are already required. |
| The Variance's dependable true-form tell and bounded duplication penalty? | Narrative incident prototype; must work without domain knowledge or color-only cues. |
| What persists, what debt costs, whether Burnout/Reputation earn a place, and whether the ending changes? | Progression and later narrative playtests; do not prebuild storage or frameworks. |

## Planning corrections from vision alignment

- The old first-playable proposal combined a 3–5-minute wave encounter with an upgrade choice. It is superseded: the current one-opponent lab is milestone 1; the 5–10-minute narrative incident is milestone 4; upgrades start at milestone 5.
- “Incident Response” in the existing HUD is a prototype label. “Incident 001: The Missing Transaction” is the future narrative slice, not a claim that the current room implements that story.
- Dodge, combos, a post-incident report, workstation reset fiction, and the six circles are goals or proposals, not present features. The current R reset remains a development convenience.
- The old proposed folder tree included progression/UI/data concepts that do not exist. [Architecture](architecture.md) now describes only the inspected implementation.
- The lab's primitive character, generic opponent, and teal/amber room are temporary. They do not fulfill the representative visual-quality milestone.

The documentation pass changes no scene, script, tuning, asset, renderer, or working configuration. Previous test results support the technical baseline; they do not replace the pending human playtest.
