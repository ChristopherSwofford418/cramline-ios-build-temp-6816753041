# Mixpanel and Firebase Configuration

## Pinned source dependencies

- Firebase iOS SDK: `12.19.2`
- Mixpanel Swift: `6.7.0`

`project.yml` links both only to the main app. Extensions have no telemetry dependency.

## Firebase static defaults

The app `Info.plist` sets Analytics and Crashlytics collection off, disables IDFV and ad-personalization/storage/user-data defaults, and disables automatic screen reporting. The target uses `FirebaseAnalyticsCore`, not the IDFA-capable product. Firebase config occurs only when a release-supplied `GoogleService-Info.plist` exists.

Firebase Analytics remains disabled in strict compliance mode. If legal/privacy accepts vendor automatic events after exact-archive validation, set `CRAMLINE_FIREBASE_ANALYTICS_ALLOW_AUTOMATIC_EVENTS=YES` and update consent, data map, privacy labels, and tests.

## Mixpanel after consent

Use `MixpanelOptions` with automatic events off, unique/IDFV ID off, no super-properties, feature flags off, replay absent, logging off, and a random analytics-only ID provider. Immediately set `useIPAddressForGeoLocation=false`. Never call identify, People, Group, default properties, or opt-in APIs that emit `$opt_in`.

## Withdrawal

Gate calls first. Disable/reset Firebase local analytics, delete unsent Crashlytics reports, call Mixpanel opt-out, reset its local state, release the instance, and remove the analytics ID. Re-test this exact order whenever the pinned SDK changes.

## Release audit

Capture cold-install/pre-consent, opt-in, opt-out, delete, offline/reconnect, relaunch, and extension-process traffic. Scan the archive for linked SDKs/privacy manifests and compare observed events to `telemetry-data-map.md`. Do not ship a zero-collection claim without packet evidence.
