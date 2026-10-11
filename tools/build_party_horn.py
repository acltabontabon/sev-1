#!/usr/bin/env python3
"""Original party blowouts for the pantry birthday: no recordings or outside samples.
party_horn.wav is a cheerful double toot; party_horn_sad.wav deflates as the candles relight."""
from pathlib import Path
import math
import random
import struct
import wave

RATE = 22050
SFX = Path(__file__).resolve().parents[1] / "assets/audio/sfx"


def toot(rng, start, length, pitch, bend, buzz=.55):
    """A paper reed: a nasal pulse wave with a raspy flutter, bending as the tube unrolls."""
    samples = []
    phase = 0.0
    noise = 0.0
    for i in range(int(RATE * length)):
        u = i / (RATE * length)
        frequency = pitch * (1 + bend * u) * (1 + .012 * math.sin(2 * math.pi * 6.5 * i / RATE))
        phase = (phase + frequency / RATE) % 1.0
        pulse = 1.0 if phase < .32 else -.47
        noise = .7 * noise + .3 * rng.uniform(-1, 1)
        flutter = 1 - buzz * .5 * (1 + math.sin(2 * math.pi * 31 * i / RATE))
        attack = min(1.0, u / .06)
        release = min(1.0, (1 - u) / .18)
        samples.append((start + i, (.62 * pulse + .22 * noise) * flutter * attack * release))
    return samples


def render(name, parts, duration):
    out = [0.0] * int(RATE * duration)
    for part in parts:
        for index, value in part:
            if index < len(out):
                out[index] += value
    # Two cascaded one-pole low-passes take the edge off the pulse wave.
    smooth = [0.0, 0.0]
    frames = bytearray()
    for value in out:
        smooth[0] += .45 * (value - smooth[0])
        smooth[1] += .45 * (smooth[0] - smooth[1])
        frames.extend(struct.pack("<h", round(max(-1, min(1, smooth[1] * .7)) * 32767)))
    with wave.open(str(SFX / name), "wb") as output:
        output.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        output.writeframes(frames)


def build():
    rng = random.Random(4102026)
    render("party_horn.wav", [toot(rng, 0, .22, 420, .04), toot(rng, int(RATE * .3), .55, 440, .12)], 1.0)
    # The sad one: a long breath, the reed sagging a fifth and running out of air.
    render("party_horn_sad.wav", [toot(rng, 0, 1.35, 400, -.36, buzz=.8)], 1.5)


if __name__ == "__main__":
    build()
