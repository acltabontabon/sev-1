# Prototype sounds

All eight short mono WAV effects are original, AI-assisted synthesis for SEV-1.
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
