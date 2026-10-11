# Milestone 11 — The Voices of Production

## Status and creative direction

Implemented candidate for Incident 001, built on Friday Deployment commit `f9b37f3`.
Six stock Kokoro profiles, 22 prerecorded candidate clips (53.37 seconds total,
418,014 bytes), and six local audition samples have been generated. The weekend
notification remains environmental text; its retained clip is available for future
replacement/audition but does not compete with the opening narrator. Thus 21 lines
have live speech triggers, with optional barks intentionally droppable under pressure.
No new combat, narrative chapter, or runtime service is introduced.

Milestone 12 update (10 October 2026): the rebuilt opening now speaks the `friday`
notification, rewrites `eta` ("Hi! Just checking if we have an ETA."), adds `leadership`,
and replaces the `start` profanity with the creator-requested "Tangina naman." The
Tagalog line uses a phonetic `pronunciation_text` override (`/tɑŋˈinɑ/ /nɑmˈɑn/`) with
the English protagonist voice; its pronunciation is a candidate pending the creator's
listening review, and the subtitle intentionally stays untranslated. Later Milestone 12 phases added lines for the pantry, the gate and corridor, every new archetype, Quick Sync, the status page, management replies, victory, the postmortem, awareness and protagonist barks: 53 clips ship, all subtitled and all candidates pending listening review.

These are **candidate performances, not human-approved performances**. Automated
checks and observed audio-player state cannot establish acting, intelligibility,
comedic timing, audible spatialization, or mixing quality. No listening-capable tool
was available in this session. The creator remains final casting director.

The office takes the absurdity seriously. No impersonation, reference recordings,
voice cloning, or identifiable-person prompts are used. English profanity is retained.
Kokoro controls voice and speed; delivery prose is an editorial/listening guide, not
an emotional prompt sent to the model. Short utterances need particular listening
attention, as noted in the upstream voice catalog.

Postmortem dialogue update (11 October 2026): nine revised clips and four new lines
(`pm_pitch`, `pm_objection`, `pm_consent`, `pm_agent`) stage the AI replacement pitch,
the engineer's objection, its misrecording as consent, and the replacement intern's
welcome. Existing stock executive, management, protagonist and postmortem profiles
are retained; fingerprints, checksums and rights are in `voices/provenance.json`.
These remain candidate performances awaiting human listening and comedic timing review.

Memorial update (11 October 2026): five new `doc_morgan`, `doc_nadia`, `doc_jun`,
`doc_jo` and `doc_val` clips use the existing `documentary` stock profile (`bm_george`,
0.88 speed). They narrate five distinct illustrated shared moments after the golden form fades,
then leave each casualty shot silent. The five takes total 53.28 seconds and are
measured by the cinematic rather than cut to a fixed budget;
fingerprints, checksums and rights are in `voices/provenance.json`. Timing waits for
actual playback completion. No real-person voice reference or impersonation was used.
Human listening, emotional pacing and comic timing acceptance remain pending.

Aftermath transition update (11 October 2026): `doc_battle_over`, `doc_fallen` and
`doc_remember` use the same stock documentary profile. They establish victory,
name the casualties and explain the engineer's move from checking on Morgan into
recollection. Shots wait for playback completion, and the casualty introduction
starts the existing mourning theme. Their fingerprints and checksums are recorded
in the voice provenance JSON; listening acceptance remains pending.

Pantry birthday update (11 October 2026): seven scene lines (`party_*`) and three
guest HR barks (`host_kevin_hr`, `host_brenda_hr`, `host_marco_hr`) come from
`talk.json` `party`, with new blended profiles `brenda`, `marco`, `kevin` and
`kevin_turning` (the same voice slowed and doubled), plus the existing `you` profile
for the engineer. `tools/voices.py talk` derives them; fingerprints and checksums are in
`talk/provenance.json`. They are candidate performances awaiting listening review.

## Casting

| Role | Stock voice | Language | Speed | Delivery / processing |
| --- | --- | --- | --- | --- |
| protagonist | `am_michael` | US English | 1.0 | Conversational, exhausted, competent. Dry sarcasm; never announce the punchline. Processing: clean. |
| management | `af_heart` | US English | 1.0 | Warm professionalism, artificial optimism, quiet pressure. Treat every request as reasonable. Processing: clean. |
| production | `af_kore` | US English | 1.0 | Measured authority. Flat certainty, clear consonants. Processing: intercom. |
| variance | `am_fenrir` | US English | 0.94 | Fragmented but intelligible. Pause between clauses; no monster growling. Processing: double. |
| narrator | `bm_george` | UK English | 1.0 | Restrained dramatic seriousness. No wink, parody, or trailer shouting. Processing: clean. |
| documentary | `bm_george` | UK English | 0.88 | The cold open's wry nature-documentary narrator (0.2.35): slow, warm, grave, sincere about the absurd. Never a parody or an impression of any real narrator. Processing: clean. Lines `doc_office`, `doc_shift`, `doc_chose`, `doc_engineer`, `doc_missing`, `doc_fascinating`. |
| postmortem | `bf_emma` | UK English | 1.0 | Precise, polite compliance. Emotionally indifferent. Processing: clean. |

**The night shift (0.2.9; NADIA, VAL and JUN added 0.2.38 with profiles `nadia`, `val`,
`jun`).** Conversations with coworkers and planted employees live in
`assets/audio/voices/talk.json` (crew, dialogue trees, voice profiles). Each profile
is a weighted blend of the six installed stock voices above plus a speed and a pitch
shift in semitones (FFmpeg `asetrate`/`atempo`, timing preserved), so no further voice
packs are downloaded. Employees' "turning" lines reuse their blend slower, lower and
with the Variance echo. `.tools/voice-env/bin/python tools/voices.py talk` generates
every line derived from the manifest (127 at 0.2.10, including the engineer's spoken
replies in the `you` profile, which matches the protagonist voice; parenthetical actions
are silent; replies are keyed by `reply_id()`, the same slug rule in GDScript and Python).
Monster barks (`barks`, `bark_<kind>_<moment>_<n>.ogg`) use `monster_<kind>` profiles
through the `monster` chain (light vibrato, a growl layer a fifth below at half level,
presence EQ, gentle compression, atan soft clip, short echo) at −16 LUFS; tuned in 0.2.21
for intelligibility after the creator found 0.2.20 too distorted. Move callouts (`callouts`, `call_<move>.ogg`) use the `shout` profile: the protagonist
voice at 1.18× and +1.5 semitones through the `hype` processing (EQ presence, exciter,
9:1 compression, chorus doubling, arena echo, tanh soft clip) mastered at −13 LUFS target
(measured −14), and played +4 dB in game. A callout may name its own profile: the engineer's roar
when he goes into Unpaid Overtime (`call_rage`) uses `rage`, the protagonist voice at 1.08× and −1.5 semitones
through the `rage` chain (an octave-down growl mixed in hard, exciter drive, presence and low boosts, 14:1
compression, hard then tanh clipping, a long vault echo) at −12 LUFS. Subtitles keep the written form; the manifest's `spoken` table rewrites acronyms and
numbers for speech only into `assets/audio/voices/talk/` with
`talk/provenance.json`; `talk-validate` (run by `tools/validate.py`) fails on a missing,
stale or untracked clip. Status: candidates; human listening acceptance pending.

Replay dialogue adds 52 authored, locally recorded alternate takes in those same stock
profiles: two greetings and two responses per coworker, plus two repeat-visit greetings
each for Pat and Morgan. Nodes store `text_variants`; generation uses
`talk_<character>_<node>_variant_<index>.ogg`, with the original retaining its existing ID.
Each take has its own fingerprint, checksum and license provenance in
`talk/provenance.json`. Caption and speech are chosen together from a shuffled bag when
the line is shown. Retries retain the bags for the application session, and an exhausted
bag refills without immediately repeating its last take. Acting and joke timing await
human listening acceptance.

The transformation buildup adds `call_powerup`, a wordless vocal effort using the
stock protagonist blend with a light doubled echo, at its natural pitch and −15 LUFS.
Creator feedback removed the distorted octave growl from this charge track.
Its separate `powerup` profile
stretches the performance 4.5× with pitch-preserving FFmpeg tempo stages, so it holds
through the 3.8-second charge; game volume rises from −6 to 0 dB before the spoken
rage line. Skip and restart stop both tracks. The model/voice rights, fingerprint,
master/output checksums and duration are recorded in `talk/provenance.json`; no
Dragon Ball recording or actor voice is used. Listening acceptance remains pending.

The wordless charge uses explicit Misaki vowel phonemes (`ɑː`) for three "ah"
efforts, rather than stretched uppercase spellings which the front end can interpret
as letter names. The waveform is sustained in processing instead of spelling more
letters; the third vowel gets the longest notation.

“Clean” preserves the voice, intercom uses a light 180–6500 Hz band limit, and
Variance adds a quiet 38 ms echo. All clips target −20 LUFS / −2 dB true peak before
Vorbis encoding; decoded peaks are checked. Runtime voice gain is −3 dB plus the
saved Voice and Master settings. No compression/ducking is applied to Effects,
so attack warnings retain their original gain. No music exists in this slice.

## Initial script and event map

The [manifest](../assets/audio/voices/dialogue.json) is the runtime and generation
source of truth. This table is its review copy. Priorities: 3 critical/terminal,
2 important information, 1 character, 0 optional corporate atmosphere.

| ID | Speaker | Text | Trigger | Priority |
| --- | --- | --- | --- | --- |
| `friday` | PEOPLE OPERATIONS | Happy Friday, team! Enjoy your well-deserved weekend! | Opening monitor close-up, Friday chat message | 0 |
| `relief` | ENGINEER | One minute. No deployments. No surprises. | Opening face shot at 8.6 seconds | 1 |
| `alert` | MONITORING / SEV-1 | CRITICAL PRODUCTION INCIDENT Inconsistent transaction states detected. | Opening SEV-1 takeover at 13.6 seconds | 3 |
| `eta` | MANAGEMENT | Hi! Just checking if we have an ETA. | Opening chat insert at 18.9 seconds | 1 |
| `leadership` | LEADERSHIP | Leadership is already asking for updates. | Opening face push-in at 21.5 seconds | 1 |
| `start` | ENGINEER | Tangina naman. | Opening at 24.7 seconds after a held silence; short retry at 0 seconds | 3 |
| `enemy` | ENGINEER | This was not in the ticket. | First record spawn | 1 |
| `investigate` | INCIDENT CHANNEL | Can we confirm whether this is a known issue? | Investigation begins | 2 |
| `debt` | ENGINEER | That's a Monday problem. | First paid upgrade | 1 |
| `contain` | MANAGEMENT | Please keep the incident channel updated. | Containment begins, after evidence confirmation | 1 |
| `visibility` | LEADERSHIP | Leadership needs visibility. | Containment after 18 seconds | 0 |
| `burnout` | ENGINEER | I am so done with this. Still fixing it. | First critical Burnout crossing | 1 |
| `boss` | ENGINEER | Finally. A reproducible issue. | Boss manifests | 1 |
| `copies` | ENGINEER | Great. Duplicate records. | First false-positive event, after Variance reaction | 1 |
| `rca` | MANAGEMENT | Do we have an RCA? | Boss stage after 22 seconds | 0 |
| `opening` | NARRATOR | Friday. Four fifty-nine PM. He was almost free. | Opening wide shot at 0.5 seconds | 3 |
| `evidence_open` | PRODUCTION SYSTEM | Delivery records available. Please identify the missing transaction. | Console first inspected | 2 |
| `evidence_confirmed` | PRODUCTION SYSTEM | Missing delivery confirmed. Containment authorized. | Containment begins after management choice | 2 |
| `variance_intro` | THE VARIANCE | Records do not match. Reconciliation failed. | Boss arrival begins | 2 |
| `variance_half` | THE VARIANCE | One record. Two truths. Neither belongs to you. | First surviving half-health crossing | 2 |
| `victory` | ENGINEER | Can I go home now? | Retained legacy clip; resolved report is silent | 3 |
| `defeat` | ENGINEER | Still my incident. Of course. | Failed report opens | 3 |
| `postmortem` | POSTMORTEM AI | Corrective action assigned. Due date: yesterday. | After victory or defeat response | 3 |

ETA and RCA use explicit letter pronunciation in the generation text only. Displayed
subtitles retain their authored spelling. Evidence confirmation plays on containment
entry after the management modal; it cannot speak over the choice cards. Boss
half-health speech comes from the existing one-shot false-positive event, not a new
combat mechanic. Optional reactions use an eight-active-second cooldown.

## Reproduce, replace, and validate

Use Python 3.10 on macOS and FFmpeg. All Python dependencies, including the English
pronunciation model, are pinned in [voice_requirements.txt](../tools/voice_requirements.txt).
The model and six stock voice files are pinned to revision
`f3ff3571791e39611d31c381e3a41a3af07b4987` and checked against
[voice_model_lock.json](../tools/voice_model_lock.json). Setup needs downloads once;
generation then uses local files only. There are no API keys or paid calls.

```sh
python3.10 tools/voices.py setup
.tools/voice-env/bin/python tools/voices.py audition
.tools/voice-env/bin/python tools/voices.py generate
python3 tools/voices.py validate
python3 tools/validate.py
```

Setup creates `.tools/voice-env` and `.tools/voices`. Auditions live in
`.tools/voices/auditions`, original WAV takes in `.tools/voices/takes`, and shipped
mono 24 kHz Vorbis clips in `assets/audio/voices`. Models and original takes are not
exported or committed. The small 418 KB candidate set does not constitute a large
binary library; establish LFS before substantial expansion.

Generation caches by pronunciation text, profile, model revision, processing version,
and dependency lock. An unchanged rerun preserves clips and generation timestamps.
Use `generate --id start` to target one line. Imported replacements are preserved
unless `--replace-imported` is explicitly supplied. Unknown IDs fail. When changing
processing code, increment its processing version so existing caches invalidate.
Long opening clips print `TIMING REVIEW`; re-edit pronunciation, pacing, or performance
before acceptance. Do not increase the gameplay timeline to fit a take.

Import a clean dry recording with an exact transcript and explicit provenance:

```sh
.tools/voice-env/bin/python tools/voices.py import --id start --file /absolute/take.wav \
  --provider 'Recording source' --model 'Human recording or model version' \
  --voice 'Consented performer or stock voice ID' --date 'YYYY-MM-DD' \
  --rights 'Documented permission and usage terms' --license 'Source URL or rights document'
```

Import preserves a hashed source copy, applies the profile processing, encodes the
clip, and updates provenance. Supply a dry take to avoid doubling effects. Import
cannot verify that the recording says the supplied text: listen before approving it.
All clips ship with `loop=false` import sidecars. Manifest validation rejects missing
declared assets, changed checksums, stale generated text/settings, duplicate IDs,
and subtitle mismatches. To intentionally use a subtitle fallback, remove the audio
and its sidecar and set that entry's status to `missing`; do not label missing audio
as generated. The runtime safely handles unexpectedly absent clips as well.

If setup fails, fix the reported download/dependency error and rerun setup; no cloud
fallback is attempted. Install FFmpeg if unavailable. A damaged model file fails its
checksum: remove only that named cached file and rerun setup. Existing committed
clips continue to work without the development environment.

## Playback contract

`Incident/Voice` owns two players (flat and positional), one active line, a priority
queue capped at three, run-scoped once guards, and a four-stream cache. Requests are
non-blocking. Higher priority interrupts lower priority; equal priority stays ordered.
Stage changes discard stale lines. Tab clears introductions; R clears requests,
players, cooldowns and subtitles. Scene unload frees players and cached streams.

Speech and subtitle timing pause with choices, Escape, focus loss and settings.
The report screen explicitly permits victory/defeat followed by the same authored
Postmortem AI response despite the paused gameplay tree. Opening settings from a
report suspends its speech. Report text/statistics remain deterministic and readable.
Standalone incident runs retain the existing terminal HUD; the report subtitle slot
belongs to the release application.

Narration, Engineer, Management and Postmortem use flat speech. Production uses
baked intercom processing. Variance uses one spatial player at its arrival site,
then follows the live boss at head height. It uses a 12 m unit distance, 45 m cutoff,
reduced panning strength and no Doppler. Actual audibility remains a listening gate.

Voice defaults to 80%, Subtitles to on. Old preference files acquire defaults;
invalid types fall back safely. Muting Voice keeps subtitle timing. Hiding subtitles
never hides objectives, investigation evidence, health, warnings, or reports.
Real audio completion clears its subtitle; missing audio uses the manifest's
word-count reading duration. Headless tests simulate duration and skip audio output.

## Provenance and rights

The per-clip [provenance ledger](../assets/audio/voices/provenance.json) records
source, model, voice, UTC generation date, processing, checksums, duration, peak,
usage basis and review status. The game script is original authored SEV-1 text.
Kokoro's publisher marks the model Apache-2.0 and describes production use in its
[pinned model card](https://huggingface.co/hexgrad/Kokoro-82M/blob/f3ff3571791e39611d31c381e3a41a3af07b4987/README.md).
The [voice catalog](https://huggingface.co/hexgrad/Kokoro-82M/blob/f3ff3571791e39611d31c381e3a41a3af07b4987/VOICES.md)
identifies the stock voices. This records the source's stated license; it does not
assert exclusive copyright in generated performances or invent performer consent.

Kokoro code/model and pronunciation/audio dependencies run only in development.
Neither Python, PyTorch, eSpeak NG, model weights, nor voice tensors ship in the game.
The publisher's model card credits training sources; the selected voices are English.
Keep upstream source/license references with the asset inventory and bundled notices.

## Validation and human listening route

Automated evidence is recorded below after the final release gate. These commands
exercise graphics and real audio-player lifecycle without claiming listening quality:

```sh
sh tools/godot.sh --path . --script tests/voice_preview.gd
sh tools/godot.sh --path . --script tests/voice_preview.gd -- --1080
sh tools/release.sh --voice-candidate
```

The voice candidate exports under `builds/releases/0.1.0-voices`, preserving the
existing `0.1.0` tester package. Version remains 0.1.0 for this audio playtest.
The package contains the manifest, provenance and clips, not generation tooling.

Human checkpoint (headphones, then ordinary speakers):

1. Start Incident. Listen through all five opening beats. Check fatigue, restraint,
   word accuracy, acronym pronunciation, and whether alarms mask any syllables.
2. Tab and R: confirm no cut-off speech returns later and short retries stay quick.
3. Fight the first record, investigate, open both choice types and pause mid-line.
   Verify captions avoid combat UI and speech freezes/resumes with each overlay.
4. Reach The Variance. Move left/right and away from it, trigger half health, and
   judge localization, distance, the quiet doubling effect, and warning audibility.
5. Win, then retry and die. Hear the response and postmortem while reading reports;
   confirm buttons remain visible and retry/menu immediately stop old speech.
6. Set Voice to zero while keeping Effects audible; toggle Subtitles off/on and
   relaunch to check persistence. Essential information must remain available.
7. Rate all six voices for identity, intelligibility, naturalness, timing, and fit.
   Record line IDs needing retakes. No additional content is needed to accept this pass.

Existing first-use hitch, balance, ordinary run duration, Mac distribution and Windows
runtime gates remain open. This milestone does not establish a new performance claim.

## Recorded evidence — 10 October 2026

- `python3 tools/validate.py`, also rerun by the release gate: **519 Godot outcome
  assertions passed**, all imports/script parses passed, plus **5 Python asset
  integrity tests**. The voice suite contributes 32 of the Godot assertions.
- All 22 candidate assets have matching provenance and checksums. All five timed
  opening clips fit their budgets: narrator 3.66 s, relief 2.85 s, alert 4.37 s,
  ETA 2.12 s, protagonist response 1.83 s. An unchanged generator rerun reported
  all 22 clips cached. Real WAV import/encoding/provenance was also checked in an
  isolated temporary directory without replacing committed takes.
- Graphical probes passed **9 checks each** at 1280×720 and 1920×1080 on Apple M2 Pro,
  Godot 4.7.2 Forward+/Metal. Real stream start, pause, resume, natural completion,
  modal suppression and terminal playback were observed. Rendered opening, choice,
  settings and report layouts were inspected. This was not a performance benchmark
  and not a listening test.
- `sh tools/release.sh --voice-candidate` passed validation, macOS export, ad-hoc
  signature verification, packaged launch, complete real-melee headless smoke,
  all 22 packaged voice resource loads, ZIP creation and extracted signature checks.
  Package source checkpoint: `a7462ee`; existing 0.1.0 artifacts were not overwritten.
- Candidate ZIP SHA-256:
  `7290991172904c722f03716e0b94434d56800e3978371b5816e5290d3da76e30`.
  The package is ad-hoc signed, not notarized; Windows runtime testing remains open.
- No automated failures remain. Initial development failures were a missing upstream
  standalone LICENSE file, a missing FFmpeg Vorbis encoder (resolved by using
  libsndfile for encoding), and corrected test-fixture focus/staging assumptions.
- **Human listening is still pending.** No claim is made that performances, word
  accuracy, mixing or audible positional behavior were heard or accepted here.
  The local audition reel is `builds/voice_auditions.wav`, ordered Engineer,
  Management, Production, Variance, Narrator, Postmortem, with one-second gaps.
  Individual auditions can be recreated with the command above.

### Ordinary memories (11 October 2026 source refinement)

MORGAN, NADIA, JUN, JO and VAL each have five authored “good_days” takes about
coffee, lunch or gossip, plus three shared engineer reply clips (28 ordinary-conversation assets, including ten additional gossip takes). They
use the existing locked stock voice blends and local generator, with license, source
hash and generation metadata in `assets/audio/voices/talk/provenance.json`. No outside
reference recordings or runtime synthesis. The ending recalls the take heard this run,
or uses one of five dedicated `after_hours` takes for an unvisited coworker.
These add bleak policy satire with coffee/lunch invitations, recorded with the same
stock blends. The five memorial narrator clips were also rewritten and regenerated
to favor specific absurdity over repeated profanity. Memory clips use the Voice bus at −10 dB
and play one at a time; the existing original mourning theme loops on the Music bus.
Human acting and mix acceptance remain pending.

The 11 October closing refinement replaces `allhands_engineer` with
“So I’m the emotional support human for five fucking chatbots.”
The `good_days_variant_2` performances now vary their subjects: Migs, Gab and Bea,
with JO retaining Kevin the ancient fridge yogurt. The four revised gossip clips
and the final reply were regenerated locally with the existing profiles and
provenance; human listening acceptance remains pending. The resolved ending and
report no longer trigger the legacy victory or repeated postmortem sequence.

Ten more locally prerecorded gossip takes introduce Wei, Dexter, Bane, Juviline and
Pau. Each coworker now has coffee, lunch and three distinct gossip stories in the
existing session-local shuffled bag. Repeated visits and retries exhaust all five
takes before repeating; the ending recalls the exact last take heard this run.
Matching clips/captions and source/model/license hashes remain in talk provenance.


The 11 October containment handoff adds `handoff_find` (engineer identifies the active
delivery failure) and `handoff_eta` (Management requires a commitment before containment).
Both use the existing local Kokoro stock protagonist/management profiles and processing;
`provenance.json` records model revision, Apache-2.0 license source, hashes and durations.
The main manifest now has 88 lines. Human listening acceptance remains pending.

Corporate firefighting update (11 October 2026): ten cavalry recordings accompany
the hose/bucket response and new last words. All eight `variance` recordings now use
stock `bm_george` at 0.92 speed and −5 semitones, with the existing short doubling
process. Runtime playback remains at neutral pitch. The direction is cold executive
authority; profile, speed and baked pitch implement the change. Destructive Feedback
replaces the old pop call. Crew last words wait for the boss's move call to finish.
These remain listening candidates; the creator must accept authority, clarity and timing.
