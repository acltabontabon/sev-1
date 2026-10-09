# SEV-1 Game Design

The [vision](vision.md) establishes the identity and status vocabulary. This design distinguishes the existing combat prototype from future experiments. It defines a direction for playtesting, not authorization to build the full game.

## Gameplay loops

**Implemented prototype:** Incident 001 now combines the existing combat/office with two authored record encounters, a short operations investigation, The Variance, and a resolution/death report. R resets the entire episode. The single-opponent combat lab remains as a regression scene. Two temporary upgrade decisions now follow the record encounters; Technical Debt affects upcoming pursuit and office warnings. There are no saves or permanent unlocks.

**Intended episode loop:** investigate a visible problem → enter a short encounter → learn what the enemy or environment communicates → resolve the encounter → uncover a consequence or choose a tradeoff → face a culminating threat → receive a contextual incident review and restart or continue. The exact run structure, duration beyond the first incident, and persistence rules are unsettled.

## Combat philosophy

An attack must communicate anticipation, contact, and recovery through motion and sound. Player input should feel responsive without erasing commitment. Enemy wind-ups should be distinguishable from recovery; a missed attack should create an opportunity. Damage, reaction, and defeat must agree with the visible action.

Preserve the current ability to win through positioning. Develop dodge and other defense through isolated experiments, with explicit timing, travel, invulnerability, and cancel rules. Add combos only when the single strike and its recovery feel good. Evaluate buffering and targeting behavior before assuming either a large move set or a lock-on system is necessary.

Hades and Devil May Cry are references named by the creator for readable encounter decisions and expressive action. Use design principles as inspiration, not their assets, characters, or exact move sets. SEV-1's camera, scope, and control scheme must work on their own terms.

Milestone 5 replaces the baton with an oversized keyboard Escalation Blade and gives the native protagonist an exhausted office-worker design. Fragmented ledger-like enemies replace the generic incident silhouette; these remain provisional assets. Their tuning and camera-directed targeting are provisional. Current implementation details live in [architecture](architecture.md); the Combat Alpha now tests a three-hit combo and dodge; abilities and finished animation are not present yet.

## Narrative foundation

Friday, 4:59 PM. An exhausted senior engineer is shutting down. A critical incident interrupts: inconsistent states, missing transactions, cascading alerts, and no known cause. Management asks, “Quick question: Can we have an ETA?” Office lights flicker; meeting rooms open into server chambers, tickets become creatures, and elevators descend through organizational dysfunction.

Every death returns the protagonist to the workstation at 4:59 PM. A meeting-room incident review can bridge death and the return without replacing that time-loop anchor. Whether the protagonist remembers every run, what others remember, and why the loop exists remain open writing decisions.

The six circles reveal connected causes. Production fails because pressure, shortcuts, unreliable environments, conflicting goals, and missing ownership reinforce one another. The revelation is systemic: **the system is working exactly as the organization designed it to work.** Avoid reducing this to one incompetent employee or an evil manager.

## Six Circles of Corporate Hell

The names, order, and organizational themes are established narrative pillars. Enemy mechanics and signature bosses below are deferred concepts, not implemented levels or final encounter specifications.

### Circle I — The Reconciliation Abyss

*“The numbers don't match. Nobody knows why.”*

Three systems claim incompatible transaction states and each insists it is the source of truth. A financial operations floor merges with an impossible data center: transaction streams, floating ledger fragments, distorted racks, and red discrepancies cross otherwise believable architecture.

Proposed enemies include false positives, duplicates, and records arriving late enough to become telegraphed hazards. Precision and observation reveal a consistent truth beneath conflicting states. **The Variance** is a proposed shapeshifting boss: striking a false manifestation creates a bounded duplicate; readable, redundant tells identify the real one. Teach the distinction safely before penalizing mistakes. No reconciliation knowledge is required.

“Which system is the source of truth?” “Yes.” This circle introduces the missing transaction as evidence, not a database puzzle.

### Circle II — The Process Purgatory

*“Your emergency fix requires three approvals.”*

Approval prerequisites recursively block the emergency response. Endless corridors, impossible meeting-room layouts, giant stamps, forms, and mechanical gates turn process into architecture. Their delays allow the incident to spread.

Proposed encounters use interruptible approval rituals, shields, and brief authorization openings. Shortcuts could trade immediate access for a stated later cost; avoid literal waiting or paperwork chores. **The Change Advisory Board** is a proposed trio with rotating protection and coordinated moves the player can interrupt. Visual state changes must make vulnerability legible without reading a policy document.

“Your approval request is awaiting approval to request approval.”

### Circle III — The Priority Paradox

*“Everything is P0. Everything.”*

Competing departments demand mutually exclusive outcomes. Countdown clocks, oversized priority boards, and invading task lists transform a war room into a combat arena. Chasing every request prevents anyone from addressing the incident's underlying cause.

Proposed mechanics include optional competing objectives, enemies that escalate demands, and clear risk/reward target prioritization. Objective changes need advance warning and a visible consequence. **The Stakeholder Hydra** is a proposed boss whose defeated heads generate new requirements. The solution becomes attacking its coordination mechanism, taught through observable cues, rather than fighting endless heads.

“Which one should I do first?” “Yes.”

### Circle IV — The Shared Environment

*“Who deployed to staging?!”*

Invisible teams overwrite one another's environment. Overlapping office layouts, fragmented testing facilities, version seams, and broken deployment holograms express unreliable evidence: a passing test no longer describes what reached production.

Proposed encounters shift between clearly signaled arena or enemy versions. Preview the change, allow time to react, and retain an escape route. **The Race Condition** is a proposed boss alternating distinct states with temporary duplicates and exploitable transition windows. The fantasy is instability; the actual rules must remain learnable and fair.

“It passed five minutes ago.” “Try testing again.”

### Circle V — The Assumption Engine

*“I thought that was already covered.”*

Conflicting instructions and missing ownership conceal dependencies. Incomplete blueprints, impossible rooms, and objects switching between assumed and actual forms expose gaps in the organization's shared understanding.

Proposed enemies reveal weaknesses through their own actions. Environmental clues can contradict claims, but at least one reliable, repeatable clue must resolve the contradiction. **The Unspoken Requirement** is a proposed apparently invulnerable boss whose attacks expose an undocumented weakness. Never require obscure guessing, developer trivia, or an invisible prerequisite for progress.

“We assumed your team owned that.” The discovery is a missing connection, not proof that one team is stupid.

### Circle VI — Production: The Final Incident

*“It worked in staging.”*

A production data center merges with an executive tower. Burning racks, cascading alerts, distorted pipelines, and fragments of prior floors make the accumulated consequences visible.

**The Root Cause** is a proposed evolving final boss combining already-taught mechanics from the earlier circles. Escalation should test mastery, not introduce several unexplained rules at once. Each phase reveals how mismatches, approval delays, competing priorities, unreliable testing, and assumptions contributed to the failure. No single villain explains the incident.

The campaign scale and number of phases depend on the smaller slices proving feasible and enjoyable.

## Ability candidates

These are proposed experiments, not a committed loadout or implementation queue. Introduce at most one when it answers a concrete combat question.

| Concept | Mechanical opportunity | Question to prove |
| --- | --- | --- |
| Force Push | Shockwave and knockback | Does space creation add tactical choice without trivializing enemies? |
| Rollback | Return to a recent safe position or restore limited state | Which state is restored, and can the destination remain safe and understandable? |
| Hotfix | Burst damage with future Technical Debt | Is the immediate gain worth an explicit later cost? |
| Garbage Collector | Area attack against weaker enemies | Is target clearing distinct from a universal damage button? |
| Circuit Breaker | Temporary protection | Does its timing reward intent rather than passive immunity? |
| Works on My Machine | A decoy | Can players read enemy attention and the decoy's limits? |
| Emergency Deployment | High-risk ultimate | Are side effects visible and avoidable rather than arbitrary? |

## Roguelite system candidates

**Burnout:** pressure from damage, failed objectives, escalations, or risky abilities might increase offense while reducing safety. First prove it offers a choice; avoid a damage spiral that punishes struggling players twice.

**Technical Debt — implemented Milestone 6 experiment:** choose one of three upgrades after each record encounter. Ship It Friday adds 35% base damage and 30 debt; Add More Tests reduces incoming damage by 20% of base with no debt; Temporary Workaround reduces dodge recovery by 25% of base and adds 15 debt. Choices last only this run and stack additively. Debt bands at 25/50/75 increase upcoming enemy pursuit by 5/10/15%, including shielded boss pursuit, with unchanged tells and damage windows. Office warnings escalate alongside the HUD. The normal two-choice episode reaches at most 60 debt. Critical is implemented and tested for tuning, not naturally reachable. No healing, unavoidable punishment, or permanent progression is introduced. Balance and the meaningfulness of these tradeoffs require creator playtesting. See [architecture](architecture.md#technical-debt-run-progression) for integration and limits.

**Corporate Reputation:** choices might affect dialogue, assistance, events, or upgrades. Technical correctness and organizational approval need not align. Prefer competing relationships or situational reactions over a good/evil meter; the representation remains undecided.

Do not prototype all three together. The [roadmap](roadmap.md) puts progression after enjoyable combat and the first narrative incident.

### Corporate decisions

A future manager request—“Leadership already promised the client; can you deploy this untested change?”—could offer immediate power with debt, a stability benefit with lost approval or time pressure, or preservation of resources with a different escalation. These outcomes are examples, not balance commitments. Present costs before selection, reflect the actual choice afterward, and allow outcomes that are funny, uncomfortable, or unexpectedly helpful. The speaker should have understandable pressures of their own.

## Death and post-incident review

The established narrative goal is to turn death/restart into an absurd Post-Incident Review. Incident 001 now implements deterministic victory/death reports and a Friday reset with R; a cinematic workstation sequence remains deferred.

Use handcrafted templates with deterministic contextual variation based on recorded run events. For example, “SEV-404 — Developer Unexpectedly Ceased Functioning” might assign “Improve anticipation” to “You,” due “Yesterday,” after a missed telegraph. Separate truthful gameplay feedback from the fictional organization's unfair assessment so players can still learn.

Future rewards may unlock abilities, playstyles, customization, knowledge, or narrative revelations. Avoid making replay depend on endless stat increases. Persistence, report categories, and unlock rules remain experiments. No paid inference or generative dialogue service is needed.

## Visual and writing principles

Build a believable modern workplace first: coherent scale, materials, infrastructure, workstations, and lighting. Let the impossible intrude through a small number of controlled transformations—a conference room extending into a boss arena, a ledger leaking into architecture, cables moving like organisms. The contrast supplies the joke.

Cold fluorescents, red incident alarms, industrial shadows, restrained atmosphere, readable silhouettes, and purposeful effects form the visual language. Keep threats identifiable by motion, shape, sound, and timing rather than color alone. Test floor hazards and enemy outlines with the player actually moving. Forward+ remains the renderer; measure frame times and tune effects instead of maximizing settings. The current teal/amber blockout and primitive characters are tools, not the approved final style.

Keep writing dry, absurd, occasionally dark, and capable of unexpected empathy. Do not make every line a programming joke or explain the punchline. “Let's take this offline” can precede lights going out; the blackout must still communicate combat threats. “Blameless postmortem” can assign every corrective action to the protagonist. Satirize incentives and consequences without portraying entire professions as malicious or incompetent.

## Incident 001: The Missing Transaction

**Established slice target:** a compact, replayable 5–10-minute episode combining satisfying combat, a representative corporate environment, reconciliation horror, and an incident review. A first implementation now exists; the duration, feel, and creative acceptance remain unverified playtest targets. The following beat structure remains the creative direction; [architecture](architecture.md#incident-001-orchestration) records the narrower implemented rules, including two harmless false copies and no wrong-strike multiplication penalty.

1. **Friday interruption.** In one small office, a missing transaction alert interrupts departure. A brief management message supplies pressure. Use in-world text and simple staging before considering a cinematic pipeline.
2. **A visible discrepancy.** Conflicting records intrude into the office. Teach one perceptual cue for a genuine threat; no accounting task or coding knowledge gates progress.
3. **Corrupted records.** A short authored encounter reuses accepted combat foundations and tests that cue. Add only the enemy variation required to teach it.
4. **Miniature Variance.** A compact encounter combines the familiar attack language with one true/false manifestation mechanic. A wrong strike may create a limited, manageable duplicate; its exact penalty and reliable tell require playtesting. Avoid unlimited multiplication.
5. **Review and return.** Resolution or death produces a short contextual review using actual episode events. Acknowledge partial incident knowledge, then provide a fast retry; no permanent progression is required for this slice.

Reuse one office footprint, existing interaction conventions, and a small coherent asset set. Establish combat, visuals, and teaching in separate playable increments before combining them. Acceptance requires readable truth/falsehood cues, understandable stakes for a non-developer, a rewarding replay without upgrades, clean death/retry, and measured performance in the complete scene. The duration is a playtest target, not a delivery estimate.

## Proposed ending

After The Root Cause falls, production stabilizes and the office returns to normal. A company-wide message thanks leadership for the resolution. The protagonist earns “Exceeds Expectations,” with a 0% salary increase, and finally leaves. A final notification announces “Monday, 9:00 AM — Sprint Planning.” Credits.

This is a proposed payoff, subject to refinement. Preserve the systemic revelation and the protagonist's humanity rather than using the ending solely as a punchline.
