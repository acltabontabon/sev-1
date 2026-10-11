# Prototype sounds

All twelve mono WAV sounds are original, AI-assisted synthesis for SEV-1.
No recordings, third-party samples, commercial-game sounds, or outside licenses are
involved. They are provisional feedback sounds, not a finished sound design pass.

The existing `swing.wav`, `impact.wav`, `hurt.wav`, and `warning.wav` use sine waves
and seeded noise. Swing pitch already varies by combo step; accepted player hits
play impact, player damage plays hurt, and the enemy wind-up plays warning.

Milestone 5 adds `step.wav`, `dodge.wav`, `defeat.wav`, and `alert.wav`, reproducible
with `python3 tools/build_presentation_audio.py`. They are 22,050 Hz, 16-bit mono,
0.10–0.65 seconds each (about 64 KB total). Source gain is bounded; playback uses
−10 to −17 dB. Footsteps follow stride half-cycles, dodge plays only on accepted
start, defeat only on a live-to-dead transition, and the alert plays once on active
incident time after capture. R stops/reset-clears these cues; no looping soundtrack
or background audio framework was added. Defeat and player-hurt tails may finish
through terminal pause; reset still stops them. Headless validation skips playback.

Graphical runs exercise playback without engine errors. Listening and human volume,
material, and impact acceptance are still required. The existing accepted-hit impact
also serves as enemy-damage audio; no redundant second hit cue is layered onto it.


Milestone 9 adds four original oscillator-only cues, with no external samples or
licenses: `notification.wav` (0.3s), `boss_arrival.wav` (1.8s), `resolved.wav` (1.4s),
and `office_air.wav` (4s seamless integer-frequency hum). Reproduce with
`python3 tools/build_narrative_audio.py`; preserve the air sound's loop-enabled import
sidecar. They use 22,050 Hz / 16-bit mono, bounded source gain, −20 dB cue playback
and −28 dB ambience. The incident alert reuses `alert.wav`. Reset stops presentation
players; terminal transitions stop ambience and play one resolution/failure accent.
These AI-assisted synthesized placeholders need human listening and replacement by a
cohesive sound-design pass; there is no voice acting or adaptive score.


Milestone 10 routes every authored and dynamic player through the Effects bus, feeding
Master. The application saves separate master/effects gain (both default 80%); office
ambience shares Effects and no music control is advertised. Existing cue levels remain
unchanged. All twelve source WAVs were checked: no clipped 16-bit samples, peaks
−25.6 to −4.1 dBFS before per-player attenuation. This is a bounds check, not listening
acceptance. See [release asset inventory](../../docs/asset_licenses.md).

## Authored speech

Milestone 11 adds 22 candidate Kokoro speech clips under `voices/`, separate from the original synthesized effects. See the [voice guide](../../docs/voices.md), [manifest](voices/dialogue.json), and [provenance ledger](voices/provenance.json). Human listening acceptance is pending. Runtime needs no network or generator.


The 11 October Quick Sync stand-up adds five original scripted lines, synthesized locally
with the existing pinned Kokoro model and stock profiles. Their inputs, voices and output
checksums are recorded in `voices/dialogue.json` and `voices/provenance.json`; the game
plays prerecorded Ogg files only. Human casting/mix acceptance remains pending.

The 11 October corporate-firefighting revision regenerates ten cavalry lines and
all eight Variance lines locally. The boss uses stock `bm_george`, speed 0.92,
five semitones down, with the existing short doubling effect. `move_pop` now calls Destructive Feedback, matching the designer's
cutting-frame death. `voices/talk.json` and `voices/dialogue.json` own the text;
their corresponding provenance manifests record synthesis settings and output hashes.
