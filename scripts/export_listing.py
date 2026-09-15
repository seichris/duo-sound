#!/usr/bin/env python3
"""Write reviewable metadata files; never upload to App Store Connect."""
import argparse
from pathlib import Path
import shutil
import release_check as rc

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--draft',action='store_true',help='Export into an explicitly marked draft directory')
args=parser.parse_args()
errors=rc.check(rc.ROOT,submission=not args.draft)
if errors: raise SystemExit('\n'.join(errors))
output=rc.ROOT/'build'/('listing-draft' if args.draft else 'listing-release')
if output.exists(): shutil.rmtree(output)
output.mkdir(parents=True)
listing=rc.load(rc.ROOT/'release/listing.json')
owner=rc.load(rc.ROOT/'release/readiness.json')['owner']
for locale,values in rc.resolved_locales(listing).items():
    directory=output/locale;directory.mkdir()
    for name,text in values.items(): (directory/(name+'.txt')).write_text(text+'\n',encoding='utf-8')
    for key in ('support_url','privacy_url','marketing_url'):
        (directory/(key+'.txt')).write_text((owner[key] or '[OWNER TO CONFIRM]')+'\n')
(output/'copyright.txt').write_text((owner['copyright'] or '[OWNER TO CONFIRM]')+'\n')
if args.draft:
    (output/'DRAFT-DO-NOT-SUBMIT.txt').write_text('Unverified launch copy. The default app simulates folds. This is not an App Store submission package.\n')
print(output)
