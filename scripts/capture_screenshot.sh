#!/bin/bash
# Capture real simulator pixels in the current app state; never resize or relabel.
set -euo pipefail
if [[ $# -ne 2 ]]; then echo "Usage: bash $0 <simulator-UDID> <output.png>" >&2; exit 2; fi
[[ "$1" =~ ^[A-Fa-f0-9-]{36}$ ]] || { echo 'Use an explicit simulator UDID' >&2; exit 2; }
[[ "$2" == *.png ]] || { echo 'Output must be PNG' >&2; exit 2; }
[[ ! -e "$2" ]] || { echo 'Refusing to overwrite an existing capture' >&2; exit 1; }
xcrun simctl io "$1" screenshot --type=png "$2"
sips -g pixelWidth -g pixelHeight "$2"
shasum -a 256 "$2"
printf 'Record device/OS/build and simulation status. This capture is not automatically approved for App Store use.\n'
