#!/usr/bin/env python3
"""Original whoosh effects for the move calls, synthesized from filtered noise.

Run with the voice environment (numpy + soundfile):
    .tools/voice-env/bin/python tools/build_whoosh.py
Writes assets/audio/sfx/whoosh_{slice,dash,spin,rise}.ogg. Deterministic (fixed seeds).
"""
from pathlib import Path

import numpy as np
import soundfile as sf

ROOT = Path(__file__).resolve().parents[1]
RATE = 44100


def bandpass(noise, centers, q):
    """A state-variable band-pass whose centre frequency follows `centers` per sample."""
    out = np.zeros_like(noise)
    low = band = 0.0
    for index, sample in enumerate(noise):
        f = 2.0 * np.sin(np.pi * min(centers[index], RATE / 6) / RATE)
        high = sample - low - band / q
        band += f * high
        low += f * band
        out[index] = band
    return out


def envelope(length, attack, curve=2.0):
    t = np.linspace(0.0, 1.0, length)
    rise = np.clip(t / attack, 0, 1) ** curve
    fall = np.clip((1 - t) / (1 - attack), 0, 1) ** (curve * 1.4)
    return np.minimum(rise, fall)


def whoosh(seconds, sweep, attack, q, seed, wobble=0.0, layers=2):
    length = int(seconds * RATE)
    rng = np.random.default_rng(seed)
    t = np.linspace(0.0, 1.0, length)
    mix = np.zeros(length)
    for layer in range(layers):
        noise = rng.standard_normal(length)
        # Sweep up to the peak, then fall away: the air passing.
        centers = np.interp(t, [0, attack, 1], sweep) * (1 + .18 * layer)
        if wobble:
            centers *= 1 + .35 * np.sin(2 * np.pi * wobble * t * seconds)
        mix += bandpass(noise, centers, q) * (.7 ** layer)
    mix *= envelope(length, attack)
    if wobble:
        mix *= .75 + .25 * np.abs(np.sin(2 * np.pi * wobble * t * seconds))
    mix /= np.max(np.abs(mix)) + 1e-9
    return mix * .89


def rise(seconds, seed):
    """A swell into the ultimate's slam: rising air plus a tone climbing an octave."""
    length = int(seconds * RATE)
    t = np.linspace(0.0, 1.0, length)
    air = whoosh(seconds, [250, 3200, 3600], .95, 2.5, seed, layers=3)
    frequency = 110 * 2 ** (t * 1.0)
    phase = 2 * np.pi * np.cumsum(frequency) / RATE
    tone = (np.sin(phase) + .4 * np.sin(2 * phase)) * t ** 2.5
    mix = air * .8 + tone * .35
    mix *= np.clip((1 - t) / .04, 0, 1)
    return mix / (np.max(np.abs(mix)) + 1e-9) * .89


SOUNDS = {
    'whoosh_slice': lambda: whoosh(.42, [500, 4200, 900], .3, 3.0, 11),
    'whoosh_dash': lambda: whoosh(.55, [300, 2600, 400], .4, 2.2, 23),
    'whoosh_spin': lambda: whoosh(1.2, [400, 1800, 700], .25, 2.0, 37, wobble=6.0),
    'whoosh_rise': lambda: rise(.9, 41),
}


def main():
    for name, make in SOUNDS.items():
        path = ROOT / 'assets/audio/sfx' / f'{name}.ogg'
        sf.write(path, make().astype(np.float32), RATE, format='OGG', subtype='VORBIS')
        print('Wrote', path.relative_to(ROOT))


if __name__ == '__main__':
    main()
