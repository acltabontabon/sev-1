#!/usr/bin/env python3
"""Original deterministic mono effects, synthesized without third-party samples."""
from pathlib import Path
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1] / 'assets/audio'
RATE = 22050
for name, duration, gain in [('step', .10, .32), ('dodge', .22, .28), ('defeat', .48, .32), ('alert', .65, .22)]:
    rng = random.Random(501)
    samples = []
    low = 0.0
    for i in range(int(duration*RATE)):
        t = i / RATE
        u = t / duration
        low = low * .82 + rng.uniform(-1, 1) * .18
        attack = min(1, t / .008)
        if name == 'step':
            value = (math.sin(2*math.pi*92*t)*.55 + low) * math.exp(-u*7)
        elif name == 'dodge':
            value = (low*2 + math.sin(2*math.pi*(190*t-160*t*t))*.15) * math.sin(math.pi*u)**2
        elif name == 'defeat':
            value = (math.sin(2*math.pi*(170*t-130*t*t))*.5 + low) * (1-u)**2
        else:
            gate = max(0, math.sin(math.pi*min(1,(u % .5)*3)))
            value = (math.sin(2*math.pi*660*t)*.6 + math.sin(2*math.pi*880*t)*.25)*gate*(1-u)
        samples.append(struct.pack('<h', int(max(-1,min(1,value*gain*attack))*32767)))
    with wave.open(str(ROOT/(name+'.wav')), 'wb') as out:
        out.setparams((1,2,RATE,0,'NONE','not compressed'))
        out.writeframes(b''.join(samples))
