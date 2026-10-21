#!/usr/bin/env python3
"""Reproduce bundled PCM from preserved, hash-pinned CC0 sources. No network."""
import array
import hashlib
import json
import math
from pathlib import Path
import subprocess
import sys
import wave

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'Sources/DuoSoundCore/Resources/RecordedSounds'
RATE = 44_100


def prepare(source):
    path = ROOT / source['source_path']
    assert hashlib.sha256(path.read_bytes()).hexdigest() == source['source_sha256'], path
    decoded = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(path),
        '-vn', '-ac', '1', '-ar', str(RATE), '-f', 'f32le', '-'])
    samples = array.array('f', decoded)
    if sys.byteorder != 'little': samples.byteswap()
    assert samples and all(math.isfinite(x) for x in samples)
    peak = max(abs(x) for x in samples)
    assert peak > 0.00001, source['id']
    # Trim quiet leaders/tails only. Preserve complete actions and all interior
    # pauses; GPT's proposed Cork/Zip/Jaw cuts were unverified planning budgets.
    window = 220
    energies = [math.sqrt(sum(x*x for x in samples[i:i+window]) / len(samples[i:i+window]))
                for i in range(0, len(samples), window)]
    threshold = max(energies) * 0.025
    active = [i for i, value in enumerate(energies) if value > threshold]
    first = max(0, active[0] * window - 661)
    last = min(len(samples), (active[-1]+1) * window + 1323)
    clip = list(samples[first:last])
    rms = math.sqrt(sum(x*x for x in clip) / len(clip))
    gain = min(0.10 / rms, 0.80 / max(abs(x) for x in clip))
    # Tiny impacts need a quarter-millisecond edge: a 3 ms ramp can erase a pop.
    fade = min(11 if len(clip) < RATE/5 else 132, len(clip)//2)
    pcm = array.array('h')
    for i, value in enumerate(clip):
        ramp = min(1, i / fade, (len(clip)-1-i) / fade)
        pcm.append(round(value * gain * ramp * 32767))
    if sys.byteorder != 'little': pcm.byteswap()
    assert 0 < len(pcm)/RATE <= 5
    target = OUTPUT / (source['id'] + '.wav')
    with wave.open(str(target), 'wb') as out:
        out.setnchannels(1); out.setsampwidth(2); out.setframerate(RATE)
        out.writeframes(pcm.tobytes())
    data = target.read_bytes()
    return {**source, 'file': target.name, 'sample_rate': RATE, 'channels': 1,
        'bits_per_sample': 16, 'frames': len(pcm), 'duration': len(pcm)/RATE,
        'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(),
        'processing': {'decoded_frames': len(samples), 'start_frame': first,
            'end_frame_exclusive': last, 'gain_db': 20*math.log10(gain),
            'boundary_fade_frames': fade, 'normalization': 'RMS target 0.10, peak cap 0.80',
            'auditioned': False}}


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    sources = json.loads((ROOT/'third_party/audio/sources.json').read_text())['sources']
    assert len(sources) == 26 and all(s['license_spdx'] == 'CC0-1.0' for s in sources)
    assets = [prepare(s) for s in sources]
    manifest = {'schema_version': 1, 'processed_on': '2026-10-19',
        'decoder': subprocess.check_output(['ffmpeg', '-version'], text=True).splitlines()[0],
        'notes': '26 CC0 recordings, independently selectable in either direction. '
            'Freesound inputs are official public HQ MP3 previews, not original WAV downloads. '
            'Complete actions retained; only quiet boundaries trimmed. Technical checks do not constitute listening review.',
        'assets': assets}
    (OUTPUT/'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
    credits = ['Hingy sound credits', '', '17 original procedural presets by the Hingy project.',
        '26 additional recordings under CC0 1.0 Universal. Attribution is not required; creators are credited here for provenance.',
        'https://creativecommons.org/publicdomain/zero/1.0/', '',
        'Recordings are converted to mono 44.1 kHz PCM16 WAV, with quiet boundaries trimmed, gain adjusted and short boundary fades.',
        'Freesound recordings use the official public HQ MP3 previews; they are not original WAV downloads.', '']
    for asset in assets:
        credits += [asset['title']+' — '+asset['creator'], asset['original_title'],
                    asset['source_url'], 'License: CC0 1.0 Universal', '']
    (OUTPUT/'CREDITS.txt').write_text('\n'.join(credits))
    print(f"Prepared {len(assets)} recordings, {sum(a['bytes'] for a in assets):,} PCM bytes")


if __name__ == '__main__': main()
