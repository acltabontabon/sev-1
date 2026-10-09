"""Original deterministic oscillator-only placeholder cues; no samples or dependencies."""
import math
import struct
import wave
from pathlib import Path

DEST = Path(__file__).resolve().parents[1] / 'assets/audio'
RATE = 22050
for name, duration, notes, gain in [
    ('notification', .3, [660, 880], .16),
    ('boss_arrival', 1.8, [65, 98, 131], .18),
    ('resolved', 1.4, [262, 330, 392], .18),
    ('office_air', 4, [60, 120, 180, 241], .06),
]:
    data = []
    for i in range(int(RATE * duration)):
        t = i / RATE
        envelope = 1 if name == 'office_air' else min(1, t / .025) * (1 - t / duration) ** 2
        value = sum(math.sin(2 * math.pi * f * t) for f in notes) / len(notes)
        data.append(struct.pack('<h', int(32767 * gain * envelope * value)))
    with wave.open(str(DEST / (name + '.wav')), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(b''.join(data))
