#!/usr/bin/env python3
"""Original, deterministic music beds for SEV-1. Pure synthesis, no samples or deps.
Loops are seamless: sustained voices use whole cycles per loop and periodic envelopes.
Writes assets/audio/music/{menu_pad,tension_bed,boss_pulse,mourning}.wav (mono, 22.05 kHz).
Pass track names to build only those."""
from pathlib import Path
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1] / 'assets/audio/music'
RATE = 22050
TAU = math.tau


def note(name):
    names = {'C': -9, 'C#': -8, 'Db': -8, 'D': -7, 'Eb': -6, 'E': -5, 'F': -4, 'F#': -3, 'G': -2, 'G#': -1, 'Ab': -1, 'A': 0, 'Bb': 1, 'B': 2}
    return 440.0 * 2 ** ((names[name[:-1]] + (int(name[-1]) - 4) * 12) / 12)


def snap(freq, length):
    # Whole cycles per loop: no phase jump where the file wraps.
    return max(1, round(freq * length)) / length


def lowpass(samples, amount):
    # Periodic one-pole filter: prime the state with the loop's own tail.
    y = 0.0
    for x in samples[-RATE:]:
        y += (x - y) * amount
    out = []
    for x in samples:
        y += (x - y) * amount
        out.append(y)
    return out


def write(name, samples, peak=.89):
    top = max(abs(s) for s in samples) or 1.0
    ROOT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(ROOT / f'{name}.wav'), 'wb') as out:
        out.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        out.writeframes(b''.join(struct.pack('<h', int(s / top * peak * 32767)) for s in samples))
    print(f'{name}: {len(samples) / RATE:.1f}s')


def menu_pad():
    """Late office: four slow ninth chords, a soft shimmer, the wall clock."""
    length = 32.0
    count = int(length * RATE)
    chords = [['D3', 'F3', 'A3', 'C4', 'E4'], ['Bb2', 'D3', 'F3', 'A3'], ['G2', 'Bb2', 'D3', 'F3', 'A3'], ['A2', 'D3', 'E3', 'G3']]
    span = length / len(chords)
    voices = []
    for index, chord in enumerate(chords):
        for pitch in chord:
            base = note(pitch)
            voices.append((index * span, snap(base, length), snap(base * 1.004, length)))
    samples = []
    for i in range(count):
        t = i / RATE
        value = 0.0
        for start, f1, f2 in voices:
            local = (t - start) % length
            if local > span + 2.5:
                continue
            env = min(1.0, local / 2.2) * (1.0 if local < span else max(0.0, 1 - (local - span) / 2.5))
            value += env * (math.sin(TAU * f1 * t) + .6 * math.sin(TAU * f2 * t) + .12 * math.sin(TAU * 2 * f1 * t))
        shimmer = math.sin(TAU * snap(note('E5'), length) * t) * max(0.0, math.sin(TAU * t / 16)) ** 6 * .5
        # The wall clock, offset from the loop point so the wrap stays silent.
        tick_time = (t - .5) % 1.0
        tick = math.sin(TAU * 2600 * tick_time) * math.exp(-tick_time * 220) * .25
        samples.append(value * .08 + shimmer * .2 + tick)
    return lowpass(samples, .18)


def tension_bed():
    """The incident: a low drone, a muted D pulse, ticking hats, a riser each half."""
    length, bpm = 16.0, 120
    beat = 60.0 / bpm
    count = int(length * RATE)
    rng = random.Random(1659)
    noise = [rng.uniform(-1, 1) for _ in range(count)]
    drone = [snap(note('D1'), length), snap(note('A1'), length), snap(note('D2') * 1.003, length)]
    pattern = ['D2', 'D2', 'F2', 'D2', 'D2', 'Eb2', 'D2', 'C2']
    samples, hiss = [], 0.0
    for i in range(count):
        t = i / RATE
        swell = .7 + .3 * math.sin(TAU * t / length)
        value = swell * (math.sin(TAU * drone[0] * t) * .5 + math.sin(TAU * drone[1] * t) * .25 + math.sin(TAU * drone[2] * t) * .2)
        eighth = int(t / (beat / 2))
        local = t % (beat / 2)
        bass = note(pattern[eighth % len(pattern)])
        value += math.sin(TAU * bass * local + .8 * math.sin(TAU * bass * 2 * local)) * math.exp(-local * 9) * .55
        hiss = hiss * .3 + noise[i] * .7
        sixteenth = t % (beat / 4)
        value += hiss * math.exp(-sixteenth * 70) * (.10 if int(t / (beat / 4)) % 2 else .05)
        half = t % (length / 2)
        if half > length / 2 - 2 * beat:
            rise = (half - (length / 2 - 2 * beat)) / (2 * beat)
            cut = min(1.0, (length / 2 - half) / .03)
            value += noise[i] * rise ** 2 * .22 * cut
        bar = t % (beat * 16)
        if beat * 12 <= bar < beat * 12.6:
            stab = bar - beat * 12
            value += (math.sin(TAU * note('D4') * t) + math.sin(TAU * note('Eb4') * t)) * math.exp(-stab * 6) * .18
        samples.append(value)
    return lowpass(samples, .35)


def boss_pulse():
    """The Variance: thumping pulse, distorted ostinato, an alarm interval off the beat."""
    length, bpm = 8.0, 150
    beat = 60.0 / bpm
    count = int(length * RATE)
    rng = random.Random(4041)
    noise = [rng.uniform(-1, 1) for _ in range(count)]
    line = ['D2', 'D2', 'F2', 'Eb2', 'D2', 'D2', 'Ab2', 'G2']
    samples = []
    for i in range(count):
        t = i / RATE
        local_beat = t % beat
        kick_freq = 45 + 75 * math.exp(-local_beat * 30)
        value = math.sin(TAU * kick_freq * local_beat) * math.exp(-local_beat * 7) * .9
        eighth = int(t / (beat / 2))
        local = t % (beat / 2)
        bass = note(line[eighth % len(line)])
        value += math.tanh(2.5 * math.sin(TAU * bass * t)) * math.exp(-local * 4) * .35
        if int(t / beat) % 2 == 1:
            value += noise[i] * math.exp(-local_beat * 18) * .35
        if local > beat / 4 and local < beat / 2:
            value += (math.sin(TAU * note('A4') * t) + math.sin(TAU * note('Bb4') * t)) * .045
        samples.append(value)
    return lowpass(samples, .5)


def mourning():
    """Walking out at midnight: slow minor pads, a falling piano-like line, a long echo.
    Not a loop: 32 s, played once under the end of the incident."""
    length = 32.0
    count = int(length * RATE)
    chords = [['A2', 'E3', 'A3', 'C4'], ['F2', 'C3', 'A3', 'C4'], ['C3', 'G3', 'C4', 'E4'], ['E2', 'B2', 'E3', 'G#3']] * 2
    span = 4.0
    line = [(0, 'E5'), (1.5, 'D5'), (2, 'C5'), (4, 'C5'), (5.5, 'B4'), (6, 'A4'), (8, 'G4'), (9.5, 'A4'), (10, 'E4'),
            (12, 'G#4'), (13.5, 'B4'), (14, 'E5'), (16, 'E5'), (17.5, 'D5'), (18, 'C5'), (20, 'F5'), (21.5, 'E5'),
            (22, 'C5'), (24, 'D5'), (25.5, 'C5'), (26, 'B4'), (28, 'A4')]
    dry = []
    for i in range(count):
        t = i / RATE
        value = 0.0
        index = int(t / span)
        if index < len(chords):
            local = t - index * span
            for pitch in chords[index]:
                base = note(pitch)
                env = min(1.0, local / 1.6) * min(1.0, (span + 1.2 - local) / 1.2)
                value += env * (math.sin(TAU * base * t) + .5 * math.sin(TAU * base * 1.003 * t)) * .05
        for start, pitch in line:
            local = t - start
            if local < 0 or local > 6:
                continue
            base = note(pitch)
            attack = min(1.0, local / .006)
            value += attack * (math.sin(TAU * base * local) * math.exp(-local * .9) + .35 * math.sin(TAU * 2 * base * local) * math.exp(-local * 1.6)
                               + .12 * math.sin(TAU * 3 * base * local) * math.exp(-local * 2.6)) * .16
        # Fade the very end to silence.
        value *= min(1.0, (length - t) / 3.0)
        dry.append(value)
    # A hall: two echoes, a little dulled.
    wet = list(dry)
    for delay, gain in ((.38, .32), (.76, .18), (1.21, .09)):
        offset = int(delay * RATE)
        for i in range(offset, count):
            wet[i] += dry[i - offset] * gain
    return lowpass(wet, .22)


if __name__ == '__main__':
    import sys
    tracks = {'menu_pad': menu_pad, 'tension_bed': tension_bed, 'boss_pulse': boss_pulse, 'mourning': mourning}
    for name in sys.argv[1:] or list(tracks):
        write(name, tracks[name]())
