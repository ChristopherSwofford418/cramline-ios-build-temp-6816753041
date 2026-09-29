#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
XCODEGEN_BIN="${XCODEGEN_BIN:-xcodegen}"
PROJECT_FILE="$ROOT_DIR/ios/Cramline.xcodeproj/project.pbxproj"

"$XCODEGEN_BIN" generate --spec "$ROOT_DIR/project.yml" --project "$ROOT_DIR/ios"

python3 - "$PROJECT_FILE" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
text = text.replace("CODE_SIGN_ENTITLEMENTS = ios/", "CODE_SIGN_ENTITLEMENTS = ")
text = text.replace("INFOPLIST_FILE = ios/", "INFOPLIST_FILE = ")
path.write_text(text)

remaining = [
    line.strip()
    for line in text.splitlines()
    if "CODE_SIGN_ENTITLEMENTS = ios/" in line or "INFOPLIST_FILE = ios/" in line
]
if remaining:
    raise SystemExit("Uncorrected ios-relative build paths: " + "; ".join(remaining))
PY

printf 'Generated %s with ios-relative signing and plist paths.\n' "$PROJECT_FILE"
