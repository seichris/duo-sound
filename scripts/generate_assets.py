#!/usr/bin/env python3
"""Validate the supplied app icon and generate the original short test WAV."""
from pathlib import Path
import math
import struct
import wave

ROOT = Path(__file__).resolve().parents[1]
ICON = ROOT/'App/Assets.xcassets/AppIcon.appiconset/AppIcon.png'

def validate_icon():
    data = ICON.read_bytes()
    if len(data) < 29 or data[:8] != b'\x89PNG\r\n\x1a\n' or data[12:16] != b'IHDR':
        raise ValueError('AppIcon.png must be a PNG')
    width, height, depth, color, compression, filtering, interlace = struct.unpack('>IIBBBBB', data[16:29])
    if (width, height, depth, color, compression, filtering, interlace) != (1024, 1024, 8, 2, 0, 0, 0):
        raise ValueError('AppIcon.png must be a 1024x1024 opaque RGB PNG')

def main():
    validate_icon()
    fixture = ROOT/'build/fixtures/original-chime.wav'
    fixture.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(fixture), 'wb') as audio:
        audio.setparams((1,2,44100,0,'NONE','not compressed'))
        samples = [int(9000*math.sin(2*math.pi*660*i/44100)*math.sin(math.pi*i/13229)**2)
                   for i in range(13230)]
        audio.writeframes(struct.pack('<'+'h'*len(samples), *samples))
    print(f'Validated {ICON.relative_to(ROOT)} (1024x1024 opaque RGB) and generated the original test fixture.')

if __name__ == '__main__':
    main()
