#!/usr/bin/env python3
"""Original, deterministic RGB app icon and short test WAV. Standard library only."""
from pathlib import Path
import math
import struct
import wave
import zlib

ROOT = Path(__file__).resolve().parents[1]
SIZE = 1024
BACKGROUND = (24, 21, 49)
LEFT = (118, 104, 232)
RIGHT = (161, 149, 255)
WHITE = (249, 247, 255)
POLYGONS = [([(232, 246), (482, 354), (482, 794), (232, 686)], LEFT),
            ([(542, 354), (792, 246), (792, 686), (542, 794)], RIGHT)]
BARS = [(308, 426, 346, 546), (387, 408, 425, 638),
        (599, 408, 637, 638), (678, 426, 716, 546)]

def in_polygon(x, y, points):
    signs = []
    for a, b in zip(points, points[1:] + points[:1]):
        signs.append((b[0]-a[0])*(y-a[1]) - (b[1]-a[1])*(x-a[0]))
    return all(s >= 0 for s in signs) or all(s <= 0 for s in signs)

def in_capsule(x, y, rect):
    x0, y0, x1, y1 = rect
    r = (x1-x0)/2
    cx = (x0+x1)/2
    cy = min(y1-r, max(y0+r, y))
    return (x-cx)**2 + (y-cy)**2 <= r*r

def render_icon():
    pixels = bytearray(BACKGROUND * (SIZE*SIZE))
    shapes = [(points, color, None) for points, color in POLYGONS]
    shapes += [(None, WHITE, rect) for rect in BARS]
    for points, color, rect in shapes:
        bounds = (min(p[0] for p in points), min(p[1] for p in points),
                  max(p[0] for p in points), max(p[1] for p in points)) if points else rect
        for y in range(max(0, int(bounds[1])-1), min(SIZE, int(bounds[3])+1)):
            for x in range(max(0, int(bounds[0])-1), min(SIZE, int(bounds[2])+1)):
                hits = sum((in_polygon(x+dx, y+dy, points) if points else
                            in_capsule(x+dx, y+dy, rect))
                           for dx, dy in ((.25,.25),(.75,.25),(.25,.75),(.75,.75)))
                if hits:
                    i = (y*SIZE+x)*3
                    for c in range(3):
                        pixels[i+c] = (pixels[i+c]*(4-hits) + color[c]*hits + 2)//4
    rows = b''.join(b'\0' + pixels[y*SIZE*3:(y+1)*SIZE*3] for y in range(SIZE))
    def chunk(name, data):
        return struct.pack('>I', len(data))+name+data+struct.pack('>I', zlib.crc32(name+data)&0xffffffff)
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', SIZE,SIZE,8,2,0,0,0))
            + chunk(b'IDAT', zlib.compress(rows, 9)) + chunk(b'IEND', b''))

def main():
    destination = ROOT/'App/Assets.xcassets/AppIcon.appiconset/AppIcon.png'
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(render_icon())
    fixture = ROOT/'build/fixtures/original-chime.wav'
    fixture.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(fixture), 'wb') as audio:
        audio.setparams((1,2,44100,0,'NONE','not compressed'))
        samples = [int(9000*math.sin(2*math.pi*660*i/44100)*math.sin(math.pi*i/13229)**2)
                   for i in range(13230)]
        audio.writeframes(struct.pack('<'+'h'*len(samples), *samples))
    print(f'Generated {destination.relative_to(ROOT)} (1024x1024 opaque RGB) and original test fixture.')

if __name__ == '__main__':
    main()
