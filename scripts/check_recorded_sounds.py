#!/usr/bin/env python3
"""Check the shipped audio and preserved provenance without a decoder/network."""
import hashlib
import json
from pathlib import Path
import wave

ROOT = Path(__file__).resolve().parents[1]


def validate(root=ROOT):
    folder = root/'Sources/DuoSoundCore/Resources/RecordedSounds'
    manifest = json.loads((folder/'manifest.json').read_text())
    sources = json.loads((root/'third_party/audio/sources.json').read_text())['sources']
    by_id = {s['id']: s for s in sources}
    assets = manifest['assets']
    assert len(assets) == len(by_id) == 26, 'Expected 26 unique CC0 recordings'
    assert len({a['id'] for a in assets}) == 26, 'Duplicate recording ID'
    assert {p.name for p in folder.glob('*.wav')} == {a['file'] for a in assets}, 'Stale/missing WAV'
    for asset in assets:
        source = by_id[asset['id']]
        assert asset['license_spdx'] == source['license_spdx'] == 'CC0-1.0'
        assert asset['license_url'] == 'https://creativecommons.org/publicdomain/zero/1.0/'
        assert asset['file'] == asset['id']+'.wav'
        original = (root/source['source_path']).resolve()
        assert original.is_relative_to((root/'third_party/audio/originals').resolve())
        assert hashlib.sha256(original.read_bytes()).hexdigest() == source['source_sha256'], asset['id']
        assert source['source_sha256'] == asset['source_sha256']
        path = folder/asset['file']; data = path.read_bytes()
        assert len(data) == asset['bytes'] < 8*1024*1024
        assert hashlib.sha256(data).hexdigest() == asset['sha256'], asset['id']
        with wave.open(str(path), 'rb') as audio:
            assert (audio.getnchannels(),audio.getsampwidth(),audio.getframerate()) == (1,2,44100)
            assert audio.getnframes() == asset['frames']
            assert 0 < audio.getnframes()/44100 <= 5
            assert abs(audio.getnframes()/44100-asset['duration']) < 1e-9
        assert asset['title'] in (folder/'CREDITS.txt').read_text()
    return len(assets)


if __name__ == '__main__': print(f'Validated {validate()} bundled CC0 recordings and source hashes.')
