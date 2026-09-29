#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

node <<'NODE'
const fs = require("node:fs");

const fail = (message) => {
  console.error(`release-config-lint: ${message}`);
  process.exit(1);
};
const app = JSON.parse(fs.readFileSync("app.json", "utf8")).expo;
const project = fs.readFileSync("project.yml", "utf8");
const globalSettings = project.match(/^settings:\n  base:\n([\s\S]*?)(?=^targets:)/m)?.[1];
if (!globalSettings) fail("missing global settings.base block in project.yml");
const projectValue = (key) => {
  const match = globalSettings.match(new RegExp(`^    ${key}:\\s*(.*?)\\s*$`, "m"));
  if (!match) fail(`missing ${key} in project.yml`);
  return match[1].replace(/^['"]|['"]$/g, "");
};
const assertEqual = (label, actual, expected) => {
  if (actual !== expected) fail(`${label} is ${JSON.stringify(actual)}, expected ${JSON.stringify(expected)}`);
};

const nativeName = projectValue("CRAMLINE_APP_NAME");
const nativeSubtitle = projectValue("CRAMLINE_APP_SUBTITLE");
const nativeBundleID = projectValue("CRAMLINE_APP_BUNDLE_ID");
const nativeVersion = projectValue("MARKETING_VERSION");
const nativeBuild = projectValue("CURRENT_PROJECT_VERSION");
const nativeSupportURL = projectValue("CRAMLINE_SUPPORT_URL");
const nativePrivacyURL = projectValue("CRAMLINE_PRIVACY_URL");
const nativeTermsURL = projectValue("CRAMLINE_TERMS_URL");
const nativeAIBaseURL = projectValue("CRAMLINE_AI_BASE_URL");

assertEqual("app name", app.name, nativeName);
assertEqual("iOS bundle identifier", app.ios?.bundleIdentifier, nativeBundleID);
assertEqual("marketing version", app.version, nativeVersion);
assertEqual("iOS build number", app.ios?.buildNumber, nativeBuild);
if (nativeName.length > 30) fail(`app name exceeds App Store's 30-character limit (${nativeName.length})`);
if (nativeSubtitle.length > 30) fail(`subtitle exceeds App Store's 30-character limit (${nativeSubtitle.length})`);

const localizable = fs.readFileSync("ios/Cramline/Resources/en.lproj/Localizable.strings", "utf8");
const localizedValue = (key) => {
  const match = localizable.match(new RegExp(`"${key}"\\s*=\\s*"([^"]+)"\\s*;`));
  if (!match) fail(`missing ${key} in en.lproj/Localizable.strings`);
  return match[1];
};
assertEqual("localized app name", localizedValue("app.name"), nativeName);
assertEqual("localized subtitle", localizedValue("app.subtitle"), nativeSubtitle);

const expectedImmutableValues = {
  CRAMLINE_APP_BUNDLE_ID: "com.clearpasstechnologies.cramline",
  CRAMLINE_MONITOR_BUNDLE_ID: "com.clearpasstechnologies.cramline.deviceactivity",
  CRAMLINE_SHIELD_CONFIGURATION_BUNDLE_ID: "com.clearpasstechnologies.cramline.shieldconfiguration",
  CRAMLINE_SHIELD_ACTION_BUNDLE_ID: "com.clearpasstechnologies.cramline.shieldaction",
  CRAMLINE_APP_GROUP: "group.com.clearpasstechnologies.cramline.shared",
  CRAMLINE_PREMIUM_MONTHLY_PRODUCT_ID: "com.clearpasstechnologies.cramline.premium.monthly",
};
for (const [key, expected] of Object.entries(expectedImmutableValues)) {
  assertEqual(key, projectValue(key), expected);
}

for (const [key, value] of Object.entries({
  CRAMLINE_SUPPORT_URL: nativeSupportURL,
  CRAMLINE_PRIVACY_URL: nativePrivacyURL,
  CRAMLINE_TERMS_URL: nativeTermsURL,
  CRAMLINE_AI_BASE_URL: nativeAIBaseURL,
})) {
  if (/example\.com/i.test(value)) fail(`${key} must not use example.com`);
  if (value && !/^https:\/\//i.test(value)) fail(`${key} must be empty or use HTTPS`);
}

for (const runtimeFile of [
  "ios/Cramline/AppEnvironment.swift",
  "ios/Shared/SharedIdentifiers.swift",
]) {
  if (/Block Your Phone to Study/.test(fs.readFileSync(runtimeFile, "utf8"))) {
    fail(`${runtimeFile} retains the prior display name`);
  }
}

const infoPlists = [
  "ios/Cramline/Info.plist",
  "ios/Extensions/DeviceActivityMonitor/Info.plist",
  "ios/Extensions/ShieldConfiguration/Info.plist",
  "ios/Extensions/ShieldAction/Info.plist",
];
for (const file of infoPlists) {
  const source = fs.readFileSync(file, "utf8");
  const match = source.match(/<key>CFBundleVersion<\/key>\s*<string>([^<]+)<\/string>/);
  if (!match) fail(`missing CFBundleVersion in ${file}`);
  assertEqual(`${file} CFBundleVersion`, match[1], nativeBuild);
}

console.log(`release-config-lint: passed (${nativeName} ${nativeVersion} (${nativeBuild}); legal URLs ${nativeSupportURL && nativePrivacyURL && nativeTermsURL ? "configured" : "not published"})`);
NODE
