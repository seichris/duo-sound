import copy
import hashlib
import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'scripts'))
import release_check as rc

class ReleaseCheckTests(unittest.TestCase):
    def setUp(self):
        self.listing = rc.load(ROOT/'release/listing.json')
        self.readiness = rc.load(ROOT/'release/readiness.json')

    def test_current_metadata_has_valid_limits(self):
        self.assertEqual(rc.listing_errors(self.listing),[])

    def test_british_override_inherits_description(self):
        locales=rc.resolved_locales(self.listing)
        self.assertEqual(locales['en-US']['description'],locales['en-GB']['description'])
        self.assertIn('personalise',locales['en-GB']['keywords'])

    def test_overlong_title_fails(self):
        self.listing['locales']['en-US']['name']='x'*31
        self.assertTrue(rc.listing_errors(self.listing))

    def test_keyword_byte_limit(self):
        self.listing['locales']['en-US']['keywords']='折'*40
        self.assertTrue(any('bytes' in x for x in rc.listing_errors(self.listing)))

    def test_keyword_duplicates_fail(self):
        self.listing['locales']['en-US']['keywords']='hinge,hinge'
        self.assertTrue(any('duplicate' in x for x in rc.listing_errors(self.listing)))

    def test_competitor_keywords_fail(self):
        self.listing['locales']['en-US']['keywords']='scrunch'
        self.assertTrue(rc.listing_errors(self.listing))

    def test_missing_disclosure_fails(self):
        self.listing['locales']['en-US']['description']='Always everywhere!'
        self.assertTrue(rc.listing_errors(self.listing))

    def test_locale_cycle_fails(self):
        self.listing['locales']['en-US']['inherit']='en-GB'
        with self.assertRaises(ValueError): rc.resolved_locales(self.listing)

    def test_empty_locale_set_fails(self):
        with self.assertRaises(ValueError): rc.resolved_locales({'locales':{}})

    def test_current_submission_is_explicitly_blocked(self):
        errors=rc.check(ROOT,submission=True)
        self.assertIn('Release status is blocked',errors)
        self.assertIn('Launch listing is still a draft',errors)
        self.assertTrue(any('physical_open_close' in e for e in errors))

    def test_deleting_evidence_cannot_bypass_gate(self):
        self.readiness['evidence']={}
        self.assertTrue(any('removed' in e for e in rc.submission_errors(ROOT,self.readiness)))

    def test_stale_fingerprint_fails(self):
        self.readiness['validated_source_sha256']='0'*64
        self.assertTrue(any('fingerprint' in e for e in rc.submission_errors(ROOT,self.readiness)))

    def test_setting_ready_alone_does_not_approve_release(self):
        self.readiness['status']='ready'
        errors=rc.submission_errors(ROOT,self.readiness)
        self.assertGreater(len(errors),8)

    def test_no_fake_contact_from_example_values(self):
        self.readiness['owner']['legal_name']='EXAMPLE Publisher'
        self.assertTrue(any('legal_name' in e for e in rc.submission_errors(ROOT,self.readiness)))

    def test_paths_cannot_escape(self):
        for path in ('../secret','/etc/passwd',''):
            with self.assertRaises(ValueError): rc.safe_path(ROOT,path)

    def test_url_requires_https_without_credentials(self):
        for value in (None,'http://example.com','https://user:password@example.com','not a url'):
            self.assertFalse(rc.https_url(value))
        self.assertTrue(rc.https_url('https://github.com/seichris/duo-sound'))

    def test_original_icon_is_rgb_not_transparent(self):
        self.assertEqual(rc.png_info(ROOT/'App/Assets.xcassets/AppIcon.appiconset/AppIcon.png'),(1024,1024,8,2))

    def test_bad_png_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/'bad.png';path.write_bytes(b'not a png')
            with self.assertRaises(ValueError): rc.png_info(path)

if __name__ == '__main__': unittest.main()
