import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'scripts'))
from check_recorded_sounds import validate


class RecordedSoundIntegrityTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for path in ['Sources/DuoSoundCore/Resources/RecordedSounds', 'third_party/audio']:
            shutil.copytree(ROOT/path, self.root/path)

    def test_catalog_and_preserved_sources_validate(self):
        self.assertEqual(validate(self.root), 26)

    def test_changed_shipped_audio_is_rejected(self):
        path = self.root/'Sources/DuoSoundCore/Resources/RecordedSounds/tinyFart.wav'
        data = bytearray(path.read_bytes()); data[-1] ^= 1; path.write_bytes(data)
        with self.assertRaises(AssertionError): validate(self.root)

    def test_changed_license_is_rejected(self):
        path = self.root/'third_party/audio/sources.json'
        data = json.loads(path.read_text()); data['sources'][0]['license_spdx'] = 'CC-BY-NC-4.0'
        path.write_text(json.dumps(data))
        with self.assertRaises(AssertionError): validate(self.root)

    def test_changed_preserved_source_is_rejected(self):
        path = self.root/'third_party/audio/originals/tinyFart.mp3'
        path.write_bytes(b'changed original')
        with self.assertRaises(AssertionError): validate(self.root)
