#!/usr/bin/env python3
"""Generate a 1024x1024 pixel-art app icon of Devin the otter using only the stdlib."""
import struct
import zlib
import os

SIZE = 1024
GRID = 16
CELL = SIZE // GRID

# palette
BG1 = (72, 164, 188)    # bay blue
BG2 = (62, 148, 174)    # deeper water stripe
A = (255, 167, 68)      # orange coat
D = (229, 138, 40)      # dark orange shade
C = (250, 247, 237)     # cream muzzle
W = (255, 255, 255)     # eye highlight
K = (34, 34, 40)        # eyes and nose

# 16x16 Devin sprite ('.'=bg, letters=palette)
SPRITE = [
    "................",
    ".....AAAAAA.....",
    "....AAAAAAAA....",
    "...DDAAAAAADD...",
    "...AAAAAAAAAA...",
    "...AAKKAAKKAA...",
    "...AAWKAAKWAA...",
    "...AAAACCAAAA...",
    "...AACCKCCAAA...",
    "..DAAAAAAAA.....",
    ".DDAAAAAAAA.....",
    "DDAAAAAAAAA.....",
    ".DDAAAAAAAA.....",
    "..DDAAAAAA......",
    "....AA..AA......",
    "...AAA..AAA.....",
]
PAL = {"A": A, "D": D, "C": C, "W": W, "K": K}

rows = []
for y in range(SIZE):
    gy = y // CELL
    row = bytearray()
    row.append(0)  # filter: none
    for x in range(SIZE):
        gx = x // CELL
        ch = SPRITE[gy][gx]
        if ch in PAL:
            c = PAL[ch]
        else:
            c = BG1 if ((gy // 2) % 2 == 0) else BG2
        row.extend(c)
    rows.append(bytes(row))

raw = b"".join(rows)

def chunk(tag, data):
    return (struct.pack(">I", len(data)) + tag + data +
            struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF))

png = b"\x89PNG\r\n\x1a\n"
png += chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0))
png += chunk(b"IDAT", zlib.compress(raw, 9))
png += chunk(b"IEND", b"")

out = os.path.join(os.path.dirname(__file__), "..", "JumpyOtter", "Resources",
                   "Assets.xcassets", "AppIcon.appiconset", "icon-1024.png")
with open(out, "wb") as f:
    f.write(png)
print("wrote", out)
