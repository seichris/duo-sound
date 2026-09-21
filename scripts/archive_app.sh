#!/bin/bash
# Local archive/export only. No upload, review submission, credentials or agreements.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${BUILD_NUMBER:?Supply a unique positive integer BUILD_NUMBER}"
[[ "$BUILD_NUMBER" =~ ^[1-9][0-9]*$ ]] || { echo 'Invalid BUILD_NUMBER' >&2; exit 1; }
python3 scripts/generate_assets.py
python3 scripts/generate_project.py
python3 scripts/release_check.py --submission
TEAM_ID="$(python3 -c "import json; print(json.load(open('release/readiness.json'))['owner']['team_id'])")"
mkdir -p build
xcodebuild -project DuoSound.xcodeproj -scheme DuoSound-AppStore -configuration AppStore \
  -destination 'generic/platform=iOS' -archivePath build/DuoSound.xcarchive \
  DEVELOPMENT_TEAM="$TEAM_ID" CURRENT_PROJECT_VERSION="$BUILD_NUMBER" archive
python3 - <<'PY'
import json,plistlib
owner=json.load(open('release/readiness.json'))['owner']
with open('build/ExportOptions.plist','wb') as f:
    plistlib.dump({'method':'app-store-connect','destination':'export','signingStyle':'automatic','teamID':owner['team_id']},f)
PY
xcodebuild -exportArchive -archivePath build/DuoSound.xcarchive \
  -exportPath build/export -exportOptionsPlist build/ExportOptions.plist
printf '\nArchive/export complete. Nothing has been uploaded or submitted to Apple.\n'
