# Milestone 11 — The Voices of Production

## Status and creative direction

Implemented candidate for Incident 001, built on Friday Deployment commit `f9b37f3`.
Six stock Kokoro profiles, 22 prerecorded candidate clips (53.37 seconds total,
418,014 bytes), and six local audition samples have been generated. The weekend
notification remains environmental text; its retained clip is available for future
replacement/audition but does not compete with the opening narrator. Thus 21 lines
have live speech triggers, with optional barks intentionally droppable under pressure.
No new combat, narrative chapter, or runtime service is introduced.

These are **candidate performances, not human-approved performances**. Automated
checks and observed audio-player state cannot establish acting, intelligibility,
comedic timing, audible spatialization, or mixing quality. No listening-capable tool
was available in this session. The creator remains final casting director.

The office takes the absurdity seriously. No impersonation, reference recordings,
voice cloning, or identifiable-person prompts are used. English profanity is retained.
Kokoro controls voice and speed; delivery prose is an editorial/listening guide, not
an emotional prompt sent to the model. Short utterances need particular listening
attention, as noted in the upstream voice catalog.

## Casting

| Role | Stock voice | Language | Speed | Delivery / processing |
| --- | --- | --- | --- | --- |
| protagonist | `am_michael` | US English | 1.0 | Conversational, exhausted, competent. Dry sarcasm; never announce the punchline. Processing: clean. |
| management | `af_heart` | US English | 1.0 | Warm professionalism, artificial optimism, quiet pressure. Treat every request as reasonable. Processing: clean. |
| production | `af_kore` | US English | 1.0 | Measured authority. Flat certainty, clear consonants. Processing: intercom. |
| variance | `am_fenrir` | US English | 0.94 | Fragmented but intelligible. Pause between clauses; no monster growling. Processing: double. |
| narrator | `bm_george` | UK English | 1.0 | Restrained dramatic seriousness. No wink, parody, or trailer shouting. Processing: clean. |
| postmortem | `bf_emma` | UK English | 1.0 | Precise, polite compliance. Emotionally indifferent. Processing: clean. |

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
| `friday` | PEOPLE OPERATIONS | Happy Friday, team! Enjoy your well-deserved weekend! | Environmental Friday notification only; available for audition/import, not spoken during opening | 0 |
| `relief` | ENGINEER | One minute. No deployments. No surprises. | Opening at 5 seconds | 1 |
| `alert` | MONITORING / SEV-1 | CRITICAL PRODUCTION INCIDENT Inconsistent transaction states detected. | Opening at 10 seconds | 3 |
| `eta` | MANAGEMENT | Quick question. Can we have an ETA? | Opening at 15 seconds | 1 |
| `start` | ENGINEER | You've got to be fucking kidding me. | Opening at 20 seconds; short retry at 0 seconds | 3 |
| `enemy` | ENGINEER | This was not in the ticket. | First record spawn | 1 |
| `investigate` | INCIDENT CHANNEL | Can we confirm whether this is a known issue? | Investigation begins | 2 |
| `debt` | ENGINEER | That's a Monday problem. | First paid upgrade | 1 |
| `contain` | MANAGEMENT | Please keep the incident channel updated. | Containment begins, after evidence confirmation | 1 |
| `visibility` | LEADERSHIP | Leadership needs visibility. | Containment after 18 seconds | 0 |
| `burnout` | ENGINEER | I am so done with this. Still fixing it. | First critical Burnout crossing | 1 |
| `boss` | ENGINEER | Finally. A reproducible issue. | Boss manifests | 1 |
| `copies` | ENGINEER | Great. Duplicate records. | First false-positive event, after Variance reaction | 1 |
| `rca` | MANAGEMENT | Do we have an RCA? | Boss stage after 22 seconds | 0 |
| `opening` | NARRATOR | Friday. Four fifty-nine PM. He was almost free. | Opening at 0 seconds | 3 |
| `evidence_open` | PRODUCTION SYSTEM | Delivery records available. Please identify the missing transaction. | Console first inspected | 2 |
| `evidence_confirmed` | PRODUCTION SYSTEM | Missing delivery confirmed. Containment authorized. | Containment begins after management choice | 2 |
| `variance_intro` | THE VARIANCE | Records do not match. Reconciliation failed. | Boss arrival begins | 2 |
| `variance_half` | THE VARIANCE | One record. Two truths. Neither belongs to you. | First surviving half-health crossing | 2 |
| `victory` | ENGINEER | Can I go home now? | Resolved report opens | 3 |
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
