"""Asset integrity failures must be caught before a release is packaged."""
import copy
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('voices', ROOT / 'tools/voices.py')
voices = importlib.util.module_from_spec(spec)
spec.loader.exec_module(voices)


class VoiceManifestTests(unittest.TestCase):
    def setUp(self):
        self.data = json.loads(voices.MANIFEST.read_text())

    def test_current_assets_have_complete_provenance(self):
        voices.validate(self.data)

    def test_mismatched_subtitle_is_rejected(self):
        self.data['lines'][0]['subtitle'] = 'Wrong subtitle'
        with self.assertRaisesRegex(AssertionError, 'Subtitle mismatch'):
            voices.validate(self.data)

    def test_duplicate_event_is_rejected(self):
        self.data['lines'].append(copy.deepcopy(self.data['lines'][0]))
        with self.assertRaisesRegex(AssertionError, 'Duplicate ID'):
            voices.validate(self.data)

    def test_edited_script_cannot_reuse_stale_speech(self):
        self.data['lines'][0]['text'] = 'A changed performance.'
        self.data['lines'][0]['subtitle'] = 'A changed performance.'
        with self.assertRaisesRegex(AssertionError, 'Stale generated speech'):
            voices.validate(self.data)

    def test_existing_audio_cannot_be_declared_missing(self):
        self.data['lines'][0]['status'] = 'missing'
        with self.assertRaisesRegex(AssertionError, 'Untracked voice provenance'):
            voices.validate(self.data)


if __name__ == '__main__':
    unittest.main()
