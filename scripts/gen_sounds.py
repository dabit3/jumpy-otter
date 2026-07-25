#!/usr/bin/env python3
"""Generate retro game sound effects as WAV files using only the stdlib."""
import math
import random
import struct
import wave
import os

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "JumpyOtter", "Resources", "Sounds")

def write_wav(name, samples):
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = b"".join(struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in samples)
        w.writeframes(frames)
    print("wrote", path)

def env(i, n, attack=0.01, release=0.5):
    t = i / n
    a = min(1.0, t / max(attack, 1e-6))
    r = min(1.0, (1.0 - t) / max(release, 1e-6))
    return min(a, r)

def hop():
    n = int(SR * 0.09)
    out = []
    for i in range(n):
        t = i / SR
        f = 650 + 900 * (i / n)
        s = 1.0 if math.sin(2 * math.pi * f * t) > 0 else -1.0
        out.append(0.28 * s * env(i, n, 0.02, 0.55))
    return out

def bump():
    n = int(SR * 0.06)
    out = []
    for i in range(n):
        t = i / SR
        s = 1.0 if math.sin(2 * math.pi * 160 * t) > 0 else -1.0
        out.append(0.3 * s * env(i, n, 0.02, 0.6))
    return out

def coin():
    out = []
    for freq, dur in ((987.77, 0.07), (1318.5, 0.16)):
        n = int(SR * dur)
        for i in range(n):
            t = i / SR
            s = math.sin(2 * math.pi * freq * t)
            s += 0.35 * math.sin(2 * math.pi * freq * 2 * t)
            out.append(0.3 * s * env(i, n, 0.02, 0.7))
    return out

def splash():
    random.seed(7)
    n = int(SR * 0.4)
    out = []
    prev = 0.0
    for i in range(n):
        white = random.uniform(-1, 1)
        prev = prev * 0.82 + white * 0.18  # lowpass
        s = prev * 2.2
        out.append(0.55 * s * env(i, n, 0.02, 0.85))
    return out

def hit():
    random.seed(3)
    n = int(SR * 0.22)
    out = []
    prev = 0.0
    for i in range(n):
        t = i / SR
        white = random.uniform(-1, 1)
        prev = prev * 0.7 + white * 0.3
        thump = math.sin(2 * math.pi * (110 - 60 * i / n) * t)
        out.append((0.5 * prev + 0.5 * thump) * 0.7 * env(i, n, 0.005, 0.9))
    return out

def train():
    n = int(SR * 0.5)
    out = []
    for i in range(n):
        t = i / SR
        s = 0.0
        for f in (311.1, 415.3):
            # sawtooth-ish via harmonics
            for h in range(1, 5):
                s += math.sin(2 * math.pi * f * h * t) / h
        out.append(0.12 * s * env(i, n, 0.05, 0.35))
    return out

def eagle():
    random.seed(11)
    n = int(SR * 0.55)
    out = []
    prev = 0.0
    for i in range(n):
        white = random.uniform(-1, 1)
        k = 0.6 + 0.35 * math.sin(math.pi * i / n)  # sweep filter
        prev = prev * k + white * (1 - k)
        amp = math.sin(math.pi * i / n) ** 1.5
        out.append(0.8 * prev * amp)
    return out

def bell():
    out = []
    for rep in range(3):
        n = int(SR * 0.14)
        for i in range(n):
            t = i / SR
            s = math.sin(2 * math.pi * 1244 * t) + 0.4 * math.sin(2 * math.pi * 1864 * t)
            out.append(0.22 * s * env(i, n, 0.01, 0.8))
        out.extend([0.0] * int(SR * 0.1))
    return out

write_wav("hop", hop())
write_wav("bump", bump())
write_wav("coin", coin())
write_wav("splash", splash())
write_wav("hit", hit())
write_wav("train", train())
write_wav("eagle", eagle())
write_wav("bell", bell())
