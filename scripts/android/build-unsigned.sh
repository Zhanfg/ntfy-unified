#!/usr/bin/env bash
# Fresh local unsigned build only. No signing assets or debug keys generated here.
set -euo pipefail
pnpm exec tauri android init --ci --skip-targets-install
bash scripts/android/apply-insets.sh
python3 scripts/ci/g3-android-ui-insets.py --generated
pnpm exec tauri android build --apk --target aarch64
python3 scripts/ci/g3-android-ui-insets.py --exported
