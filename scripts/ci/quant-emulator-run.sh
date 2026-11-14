#!/usr/bin/env bash
set -euo pipefail
mkdir -p quant-out
mapfile -t apks < <(find src-tauri/gen/android/app/build/outputs/apk -type f -name '*debug.apk' | sort)
test "${#apks[@]}" -eq 1
adb install -r "${apks[0]}"
bash scripts/ci/quant-measure.sh quant-out
