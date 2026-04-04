#!/usr/bin/env python3
"""Generate Better app icon — Variant 3: warm gradient + clay arrow."""

import numpy as np
from PIL import Image, ImageDraw

# Render at 4x for antialiasing, then downsample
RENDER = 4096
FINAL  = 1024
SCALE  = RENDER / 88  # viewBox was 88×88

# Colors
BG_A  = (0xFF, 0xF8, 0xF2)   # #FFF8F2 top-left
BG_B  = (0xF5, 0xE6, 0xD3)   # #F5E6D3 bottom-right
CLAY  = (0xC2, 0x67, 0x3A, 0xFF)  # #C2673A

# ── 1. Gradient background (135°: top-left → bottom-right) ────────────────
print("Building gradient…")
coords = np.arange(RENDER, dtype=np.float32)
xx, yy = np.meshgrid(coords, coords)
t = np.clip((xx + yy) / (2.0 * (RENDER - 1)), 0, 1)

r = (BG_A[0] + t * (BG_B[0] - BG_A[0])).astype(np.uint8)
g = (BG_A[1] + t * (BG_B[1] - BG_A[1])).astype(np.uint8)
b = (BG_A[2] + t * (BG_B[2] - BG_A[2])).astype(np.uint8)
a = np.full((RENDER, RENDER), 255, dtype=np.uint8)

img = Image.fromarray(np.stack([r, g, b, a], axis=2), 'RGBA')
draw = ImageDraw.Draw(img)

# ── 2. Arrow geometry (SVG viewBox 88×88, scaled up) ─────────────────────
stroke = 12 * SCALE
hs = stroke / 2  # half-stroke (for round caps)

def pt(x, y):
    return (x * SCALE, y * SCALE)

# Diagonal shaft: (20,68) → (64,24)
p1 = pt(20, 68)
p2 = pt(64, 24)

# Arrowhead L-path: M42,22  L66,22  L66,46
h1 = pt(42, 22)   # open end of horizontal arm
h2 = pt(66, 22)   # corner
h3 = pt(66, 46)   # open end of vertical arm

def draw_segment(a, b):
    """Thick line + round caps at both ends."""
    draw.line([a, b], fill=CLAY, width=int(stroke))
    for p in (a, b):
        draw.ellipse([p[0]-hs, p[1]-hs, p[0]+hs, p[1]+hs], fill=CLAY)

# Shaft
draw_segment(p1, p2)

# Arrowhead horizontal arm
draw.line([h1, h2], fill=CLAY, width=int(stroke))
# Arrowhead vertical arm
draw.line([h2, h3], fill=CLAY, width=int(stroke))
# Round cap on h1 (open end)
draw.ellipse([h1[0]-hs, h1[1]-hs, h1[0]+hs, h1[1]+hs], fill=CLAY)
# Round join at corner h2
draw.ellipse([h2[0]-hs, h2[1]-hs, h2[0]+hs, h2[1]+hs], fill=CLAY)
# Round cap on h3 (open end)
draw.ellipse([h3[0]-hs, h3[1]-hs, h3[0]+hs, h3[1]+hs], fill=CLAY)

# ── 3. Downsample & save ──────────────────────────────────────────────────
print("Downsampling to 1024×1024…")
out = img.resize((FINAL, FINAL), Image.LANCZOS).convert('RGB')
path = 'HabitStack/Assets.xcassets/AppIcon.appiconset/AppIcon.png'
out.save(path)
print(f"Saved → {path}")
