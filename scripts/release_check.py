#!/usr/bin/env python3
"""Validate preparation files; --submission also requires explicit release evidence.

No network calls, account changes, uploads or approval flags are performed here.
"""
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import re
import struct
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
REQUIRED_EVIDENCE = {
    'public_sdk_compiles', 'physical_open_close_and_handoff',
    'audio_import_lifecycle_accessibility', 'privacy_manifest_and_policy_audited',
    'real_store_screenshots_reviewed', 'public_urls_and_contact_verified',
    'seller_age_rating_rights_and_availability', 'distribution_sdk_accepted_by_apple',
}
LIMITS = {'name': 30, 'subtitle': 30, 'keywords': 100, 'promotional_text': 170,
          'description': 4000, 'release_notes': 4000}
PHONE_SIZES = {(1398,2034),(2007,2853),(1320,2868),(1290,2796),(1260,2736)}
IPAD_SIZES = {(2064,2752),(2048,2732)}

def load(path):
    return json.loads(path.read_text(encoding='utf-8'))

def resolved_locales(listing):
    locales = listing['locales']
    result = {}
    def resolve(name, ancestors=()):
        if name in ancestors:
            raise ValueError('Locale inheritance cycle')
        value = locales[name]
        base = resolve(value['inherit'], ancestors+(name,)) if 'inherit' in value else {}
        return {**base, **{k:v for k,v in value.items() if k != 'inherit'}}
    for name in locales:
        if name not in {'en-US','en-GB'}:
            raise ValueError('Add deliberate validation before advertising another localization')
        result[name] = resolve(name)
    if 'en-US' not in result:
        raise ValueError('en-US is required')
    return result

def listing_errors(listing):
    errors = []
    for locale, values in resolved_locales(listing).items():
        for key, limit in LIMITS.items():
            value = values.get(key)
            if not isinstance(value, str) or not value.strip() or len(value) > limit:
                errors.append(f'{locale}: {key} must contain 1–{limit} characters')
        if errors:
            continue
        keywords = values['keywords'].split(',')
        if len(values['keywords'].encode('utf-8')) > 100:
            errors.append(f'{locale}: keywords exceed 100 UTF-8 bytes')
        if any(not k or k != k.strip() for k in keywords):
            errors.append(f'{locale}: empty keyword or spaces around commas')
        if len(set(k.casefold() for k in keywords)) != len(keywords):
            errors.append(f'{locale}: duplicate keywords')
        title_words = set(re.findall(r'[a-z]+', (values['name']+' '+values['subtitle']).lower()))
        if any(k.lower().rstrip('s') in {w.rstrip('s') for w in title_words} for k in keywords):
            errors.append(f'{locale}: keywords duplicate name/subtitle terms')
        forbidden = {'scrunch','apple','iphone','samsung','transformers','ringtone','notification','alarm','background'}
        if any(k.lower() in forbidden for k in keywords):
            errors.append(f'{locale}: trademark/competitor or unsupported keyword')
        if 'visible and active' not in values['description'] or 'locked' not in values['description']:
            errors.append(f'{locale}: foreground/lock-state disclosure missing')
    return errors

def source_fingerprint(root):
    paths = []
    for directory in ('App','Sources','DuoSound.xcodeproj'):
        paths.extend(p for p in (root/directory).rglob('*') if p.is_file()
                     and 'xcuserdata' not in p.parts and p.name != '.DS_Store')
    paths += [p for p in (root/'scripts').rglob('*') if p.is_file() and p.suffix in {'.py','.sh'}]
    paths += [root/'release/listing.json']
    digest = hashlib.sha256()
    for path in sorted(set(paths)):
        digest.update(str(path.relative_to(root)).encode()+b'\0')
        digest.update(path.read_bytes()+b'\0')
    # Bind public identity/URLs too, without the self-referential evidence hash.
    digest.update(json.dumps(load(root/'release/readiness.json')['owner'], sort_keys=True).encode())
    return digest.hexdigest()

def safe_path(root, value):
    if not isinstance(value, str) or not value:
        raise ValueError('Missing repository-relative path')
    path = (root/value).resolve()
    if Path(value).is_absolute() or not path.is_relative_to(root.resolve()):
        raise ValueError('Path escapes repository')
    return path

def png_info(path):
    data = path.read_bytes()
    if len(data)<33 or data[:8] != b'\x89PNG\r\n\x1a\n' or data[12:16] != b'IHDR':
        raise ValueError(f'Not a PNG: {path.name}')
    width,height,depth,color,_,_,_ = struct.unpack('>IIBBBBB', data[16:29])
    return width,height,depth,color

def https_url(value):
    if not isinstance(value,str): return False
    url = urlparse(value)
    return url.scheme == 'https' and bool(url.hostname) and not url.username and not url.password

def submission_errors(root, readiness):
    errors = []
    if readiness.get('status') != 'ready': errors.append('Release status is blocked')
    if readiness.get('validated_source_sha256') != source_fingerprint(root):
        errors.append('Source fingerprint is missing/stale: device evidence must match this candidate')
    evidence = readiness.get('evidence',{})
    if set(evidence) != REQUIRED_EVIDENCE:
        errors.append('Required evidence entries were removed or changed')
    for key in sorted(REQUIRED_EVIDENCE):
        item = evidence.get(key,{})
        reference = item.get('reference')
        if item.get('passed') is not True or not isinstance(reference,str) or not reference.strip():
            errors.append(f'Unverified: {key}')
        elif not https_url(reference):
            try:
                if not safe_path(root,reference).is_file(): errors.append(f'Missing evidence file: {key}')
            except ValueError as error: errors.append(str(error))
    owner = readiness.get('owner',{})
    for key in ('legal_name','support_email','copyright','team_id','bundle_id','app_store_id'):
        value = owner.get(key)
        if not isinstance(value,str) or not value.strip() or re.search(r'(?i)TODO|TO.CONFIRM|EXAMPLE',value):
            errors.append(f'Owner must supply {key}')
    if not re.fullmatch(r'[^\s@]+@[^\s@]+\.[^\s@]+',owner.get('support_email') or ''):
        errors.append('A real public support email is required')
    if not re.fullmatch(r'[A-Z0-9]{10}',owner.get('team_id') or ''):
        errors.append('Apple development team ID must be verified')
    if not re.fullmatch(r'[0-9]+',owner.get('app_store_id') or ''):
        errors.append('App Store record ID must be verified')
    for key in ('support_url','privacy_url','marketing_url'):
        if not https_url(owner.get(key)): errors.append(f'Public HTTPS {key} is required')
    groups = set()
    for capture in load(root/'release/screenshots.json').get('captures',[]):
        try:
            path = safe_path(root,capture['path'])
            if not str(path.relative_to(root)).startswith('release/screenshots/'):
                raise ValueError('Store captures must be in release/screenshots/')
            actual = png_info(path)
            if list(actual[:2]) != [capture['width'],capture['height']]:
                raise ValueError('Screenshot dimensions do not match manifest')
            if hashlib.sha256(path.read_bytes()).hexdigest() != capture['sha256']:
                raise ValueError('Screenshot checksum mismatch')
            family = capture['device_family']
            sizes = PHONE_SIZES if family == 'iphone' else IPAD_SIZES if family == 'ipad' else set()
            if actual[:2] not in sizes and actual[:2][::-1] not in sizes:
                raise ValueError('Unverified screenshot slot/dimensions')
            if capture['locale'] not in resolved_locales(load(root/'release/listing.json')):
                raise ValueError('Unknown screenshot locale')
            if capture['source'] not in {'physical-device','simulator'}:
                raise ValueError('Screenshot provenance must be an actual device or simulator')
            groups.add(family)
        except (KeyError,ValueError,OSError) as error:
            errors.append(f'Screenshot: {error}')
    if groups != {'iphone','ipad'}:
        errors.append('Actual reviewed iPhone and iPad screenshots are required for the current universal target')
    return errors

def check(root, submission=False):
    listing = load(root/'release/listing.json')
    readiness = load(root/'release/readiness.json')
    errors = listing_errors(listing)
    if listing.get('schema_version') != 1 or readiness.get('schema_version') != 1:
        errors.append('Unknown release schema')
    if set(readiness.get('evidence',{})) != REQUIRED_EVIDENCE:
        errors.append('Readiness evidence schema is incomplete')
    icon = root/'App/Assets.xcassets/AppIcon.appiconset/AppIcon.png'
    if png_info(icon) != (1024,1024,8,2): errors.append('App icon must be 1024x1024 opaque RGB PNG')
    info = plistlib.loads((root/'App/Info.plist').read_bytes())
    if info.get('UIBackgroundModes'): errors.append('Unexpected background mode: re-audit the product claims')
    privacy = plistlib.loads((root/'App/PrivacyInfo.xcprivacy').read_bytes())
    if privacy.get('NSPrivacyTracking') is not False or privacy.get('NSPrivacyCollectedDataTypes'):
        errors.append('Privacy manifest disagrees with local-only listing; audit required')
    if submission:
        if listing.get('status') != 'approved_launch_copy': errors.append('Launch listing is still a draft')
        errors += submission_errors(root,readiness)
    return errors

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--submission',action='store_true')
    parser.add_argument('--fingerprint',action='store_true')
    args = parser.parse_args()
    try:
        if args.fingerprint:
            print(source_fingerprint(ROOT)); return 0
        errors = check(ROOT,args.submission)
        if errors:
            for error in errors: print('BLOCKED:',error)
            return 1
        print('Preparation checks passed.' if not args.submission else 'Evidence and package checks passed; no upload performed.')
        if not args.submission: print('This is not submission approval. Run --submission to see unresolved release gates.')
        return 0
    except (OSError,ValueError,KeyError,TypeError,AttributeError,struct.error,plistlib.InvalidFileException) as error:
        print('BLOCKED: invalid or missing preparation file:',error)
        return 1

if __name__ == '__main__':
    raise SystemExit(main())
