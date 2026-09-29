#!/usr/bin/env python3
"""Finite source-level iOS release audit; does not claim archive or device validation."""

from __future__ import annotations

import json
import plistlib
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ERRORS: list[str] = []


def fail(message: str) -> None:
    ERRORS.append(message)


def load(relative: str) -> dict:
    path = ROOT / relative
    try:
        with path.open("rb") as file:
            return plistlib.load(file)
    except Exception as error:  # pragma: no cover - release utility output
        fail(f"cannot parse {relative}: {error}")
        return {}


def require_text(relative: str, snippets: tuple[str, ...]) -> None:
    text = (ROOT / relative).read_text()
    for snippet in snippets:
        if snippet not in text:
            fail(f"{relative} lacks required source boundary: {snippet}")


host_info = load("ios/Cramline/Info.plist")
info_files = [
    "ios/Cramline/Info.plist",
    "ios/Extensions/DeviceActivityMonitor/Info.plist",
    "ios/Extensions/ShieldConfiguration/Info.plist",
    "ios/Extensions/ShieldAction/Info.plist",
]
for relative in info_files:
    info = load(relative)
    if info.get("CFBundleShortVersionString") != "1.0":
        fail(f"{relative} CFBundleShortVersionString must be 1.0")
    if info.get("CFBundleVersion") != "3":
        fail(f"{relative} CFBundleVersion must be 3")

sensitive_usage_keys = {
    "NSCameraUsageDescription",
    "NSLocationAlwaysAndWhenInUseUsageDescription",
    "NSLocationAlwaysUsageDescription",
    "NSLocationWhenInUseUsageDescription",
    "NSMicrophoneUsageDescription",
    "NSPhotoLibraryUsageDescription",
    "NSContactsUsageDescription",
    "NSCalendarsUsageDescription",
    "NSHealthShareUsageDescription",
}
found_usage_keys = sorted(sensitive_usage_keys.intersection(host_info))
if found_usage_keys:
    fail(f"unexpected sensitive usage-description keys: {', '.join(found_usage_keys)}")

expected_group = ["$(CRAMLINE_APP_GROUP)"]
entitlement_files = [
    "ios/Cramline/Cramline.entitlements",
    "ios/Extensions/DeviceActivityMonitor/DeviceActivityMonitor.entitlements",
    "ios/Extensions/ShieldConfiguration/ShieldConfiguration.entitlements",
    "ios/Extensions/ShieldAction/ShieldAction.entitlements",
]
for relative in entitlement_files:
    entitlements = load(relative)
    if entitlements.get("com.apple.developer.family-controls") is not True:
        fail(f"{relative} lacks Family Controls entitlement")
    if entitlements.get("com.apple.security.application-groups") != expected_group:
        fail(f"{relative} app-group entitlement differs from the immutable shared group")

host_privacy = load("ios/Cramline/Resources/PrivacyInfo.xcprivacy")
extension_privacy = load("ios/Extensions/PrivacyInfo.xcprivacy")
if host_privacy.get("NSPrivacyTracking") is not False:
    fail("host privacy manifest must declare tracking false")
if extension_privacy.get("NSPrivacyTracking") is not False:
    fail("extension privacy manifest must declare tracking false")
if extension_privacy.get("NSPrivacyCollectedDataTypes") != []:
    fail("extension privacy manifest must not declare collected data")
if host_privacy.get("NSPrivacyTrackingDomains") != []:
    fail("host privacy manifest must not declare tracking domains")

project_text = (ROOT / "ios/Cramline.xcodeproj/project.pbxproj").read_text()
for expected in (
    'CRAMLINE_APP_NAME = "Cramline Exam Sprint";',
    'CRAMLINE_APP_SUBTITLE = "Study Focus & App Shield";',
    "CURRENT_PROJECT_VERSION = 3;",
):
    if expected not in project_text:
        fail(f"checked-in Xcode project lacks synchronized setting: {expected}")
for stale in (
    "Block Your Phone to Study",
    "Exam Focus Timer & App Blocker",
    "https://example.com/cramline/",
    "CURRENT_PROJECT_VERSION = 2;",
):
    if stale in project_text:
        fail(f"checked-in Xcode project retains stale setting: {stale}")

project_spec = (ROOT / "project.yml").read_text()
for immutable in (
    "CRAMLINE_APP_BUNDLE_ID: com.clearpasstechnologies.cramline",
    "PRODUCT_BUNDLE_IDENTIFIER: com.clearpasstechnologies.cramline",
    "CRAMLINE_APP_GROUP: group.com.clearpasstechnologies.cramline.shared",
    'TARGETED_DEVICE_FAMILY: "1,2"',
):
    if immutable not in project_spec:
        fail(f"project.yml lacks immutable/responsive setting: {immutable}")

icon_path = ROOT / "ios/Cramline/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
try:
    with icon_path.open("rb") as icon_file:
        signature = icon_file.read(8)
        length = struct.unpack(">I", icon_file.read(4))[0]
        chunk = icon_file.read(4)
        ihdr = icon_file.read(length)
    if signature != b"\x89PNG\r\n\x1a\n" or chunk != b"IHDR":
        fail("AppIcon-1024.png is not a valid PNG")
    else:
        width, height, bit_depth, color_type = struct.unpack(">IIBB", ihdr[:10])
        if (width, height, bit_depth, color_type) != (1024, 1024, 8, 2):
            fail(
                "AppIcon-1024.png must be 1024x1024 8-bit RGB with no alpha; "
                f"found {width}x{height}, bit depth {bit_depth}, PNG color type {color_type}"
            )
except Exception as error:  # pragma: no cover - release utility output
    fail(f"cannot validate AppIcon-1024.png: {error}")

try:
    icon_manifest = json.loads(
        (ROOT / "ios/Cramline/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json").read_text()
    )
    images = icon_manifest.get("images", [])
    if not any(
        image.get("filename") == "AppIcon-1024.png"
        and image.get("platform") == "ios"
        and image.get("size") == "1024x1024"
        for image in images
    ):
        fail("AppIcon Contents.json does not reference the verified universal 1024 master")
except Exception as error:  # pragma: no cover - release utility output
    fail(f"cannot validate AppIcon Contents.json: {error}")

require_text(
    "ios/Cramline/Views/OnboardingView.swift",
    (
        "Onboarding step \\(step + 1) of 6",
        "It does not lock your phone",
        "Emergency pause for 15 minutes",
        "Apple system picker",
        "frame(maxWidth: CramlineTheme.contentWidth)",
    ),
)
require_text(
    "ios/Cramline/Views/HomeView.swift",
    (
        "Calendar progress, not a performance score",
        "Pause the shield for 15 minutes?",
        "free and has no penalty",
        "ViewThatFits(in: .horizontal)",
    ),
)
require_text(
    "ios/Cramline/Views/PlannerView.swift",
    (
        "AI planning unavailable in this build",
        "The on-device planner works offline and sends nothing anywhere.",
        "GridItem(.adaptive",
        "Schedule saved locally and submitted to iOS for best-effort registration.",
    ),
)
require_text(
    "ios/Cramline/Views/PrivacyView.swift",
    (
        "No planning request is sent to an AI service because no endpoint is configured.",
        "Delete all local \\(AppEnvironment.appName) data",
        "fail open by removing its shields and schedules first",
    ),
)
require_text(
    "ios/Cramline/Views/PremiumView.swift",
    (
        "No Premium offer in this build",
        "No subscription offer is available in this build.",
        "Core focus stays free.",
    ),
)

ui_test_text = (ROOT / "ios/Tests/CramlineUITests/CramlineUITests.swift").read_text()
for test_name in (
    "testOnboardingRevealsSprintStepAfterAgeConfirmation",
    "testEmergencyActionsRequireClearConfirmationAndRemainFree",
    "testPlannerShowsOfflineDraftAndUnavailableAIBoundary",
    "testPrivacyScreenOffersTelemetryControlAndConfirmedDeletion",
    "testPremiumScreenTruthfullyShowsUnavailableOfferAndFreeFoundation",
):
    if test_name not in ui_test_text:
        fail(f"UI test suite lacks deterministic premium-flow coverage: {test_name}")

if ERRORS:
    for error in ERRORS:
        print(f"static-release-audit: {error}", file=sys.stderr)
    sys.exit(1)

print(
    "static-release-audit: passed (identity, 4 target Info.plists, 4 Family Controls/app-group "
    "entitlements, 2 privacy manifests, 1024 RGB icon, premium UI boundaries and UI test coverage)"
)
