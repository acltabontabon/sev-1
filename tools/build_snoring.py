#!/usr/bin/env python3
"""Original GARY snoring: two raspy breaths, no recordings or outside samples."""
from pathlib import Path
import math
import random
import struct
import wave

RATE = 22050
DURATION = 8.0
TARGET = Path(__file__).resolve().parents[1] / "assets/audio/sfx/sleeper_snore.wav"


def build():
    rng = random.Random(110026)
    frames = bytearray()
    low = 0.0
    phase = 0.0
    for i in range(int(RATE * DURATION)):
        t = i / RATE
        breath = int(t / 4)
        u = t % 4
        low = .84 * low + .16 * rng.uniform(-1, 1)
        # Nasal inhalation swells, flutters, then falls into a softer breath out.
        inhale = math.sin(math.pi * min(1, u / 1.85)) ** 1.5
        exhale = math.sin(math.pi * max(0, min(1, (u - 2.15) / 1.25))) ** 2
        frequency = 72 + breath * 6 + 12 * math.sin(math.pi * min(1, u / 1.85))
        phase += 2 * math.pi * frequency / RATE
        flutter = .58 + .42 * math.sin(2 * math.pi * 23 * t) ** 2
        throat = sum(math.sin(phase * h) / h for h in range(1, 10)) / 2
        value = inhale * flutter * (.46 * throat + .9 * low)
        value += exhale * (.5 * low + .045 * math.sin(phase))
        frames.extend(struct.pack("<h", round(max(-1, min(1, value)) * 32767)))
    with wave.open(str(TARGET), "wb") as output:
        output.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        output.writeframes(frames)


if __name__ == "__main__":
    build()
