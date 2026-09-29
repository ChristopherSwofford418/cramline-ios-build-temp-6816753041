#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

fail() { printf 'privacy-lint: %s\n' "$1" >&2; exit 1; }

telemetry_file="ios/Cramline/Services/TelemetryController.swift"
[[ -f "$telemetry_file" ]] || fail "telemetry adapter missing"

if grep -Eq '\.identify\(|setUserID\(|setUserProperty\(|record\(error:|Crashlytics\.log' "$telemetry_file"; then
  fail "forbidden identity, property, custom crash, or breadcrumb API found"
fi

if grep -RIEq 'QUERY_ALL_PACKAGES|PACKAGE_USAGE_STATS|android\.permission\.BIND_ACCESSIBILITY_SERVICE' \
  android-companion/app/src/main/AndroidManifest.xml android-companion/app/src/main/res 2>/dev/null; then
  fail "forbidden Android permission found in manual companion"
fi

if grep -RIEq 'import (Firebase|Mixpanel)|URLSession|https?://' \
  --include='*.swift' ios/Extensions ios/Shared 2>/dev/null; then
  fail "network or telemetry code found in a Screen Time extension source set"
fi

if grep -RIEq '"(selected_app|selectedApp|applicationToken|webDomainToken|reflection|exact_schedule|device_id)"[[:space:]]*:' \
  ios/Cramline/Services/TelemetryController.swift; then
  fail "forbidden telemetry field found"
fi

printf 'privacy-lint: passed\n'
