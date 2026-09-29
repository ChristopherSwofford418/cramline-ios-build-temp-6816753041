# Cramline Exam Sprint

Cramline Exam Sprint is an iOS-first, self-directed focus tool for adults preparing for a professional exam over a 14–90 day sprint. On iPhone/iPad, it asks Apple’s Screen Time frameworks to shield user-selected apps and websites during chosen study sessions. Android is a separate manual companion, not an equivalent blocker.

`Cramline` remains the internal Xcode target, Swift package, storage namespace, and registered bundle-ID namespace so the public rename does not break signing, persistence, or App Store continuity.

## Included

- SwiftUI iOS/iPadOS 16+ host app;
- FamilyControls authorization and FamilyActivityPicker;
- ManagedSettings shielding with DeviceActivity, Shield Configuration, and Shield Action extensions;
- immediate free emergency pause and session end;
- protected local data, deletion, deterministic offline planner, and optional per-request AI client;
- consent-first Mixpanel/Firebase integration with SDKs excluded from extensions;
- StoreKit 2 premium planning boundary and Restore Purchases;
- permission-free Android manual companion;
- tests, CI, privacy/claims checks, and release documentation.

## Quick start

### iOS

1. Install Xcode 26+ for App Store uploads and XcodeGen 2.46+.
2. Review the registered Apple identifiers and team in `Config/Brand.example.xcconfig`, then replace placeholder support/privacy/terms URLs, Mixpanel token, and optional AI endpoint. Create the documented StoreKit product before billing QA.
3. Add a valid `GoogleService-Info.plist` only after configuring default-off Firebase collection.
4. Run `scripts/generate-xcode-project.sh` and open `ios/Cramline.xcodeproj`.
5. Let automatic signing generate development profiles, or assign regenerated profiles to the host and all extensions.
6. Test on physical iPhone/iPad. Simulator builds are not release evidence.

### Shared core

```bash
swift test --package-path Packages/CramlineCore
```

### Planning service

```bash
cd server
pnpm install --frozen-lockfile
pnpm test
pnpm dev
```

The service reads model credentials only from server environment variables and dynamically lists available models. Do not expose them to clients.

### Android manual companion

```bash
cd android-companion
./gradlew testDebugUnitTest lintDebug
```

An Android SDK is required. The companion intentionally requests no app-control or accessibility permission.

## Privacy/claims validation

```bash
scripts/privacy-lint.sh
```

Firebase Analytics is compiled but remains disabled in strict compliance mode because enabled Firebase emits vendor automatic events outside the contract’s literal allowlist. Enabling `CRAMLINE_FIREBASE_ANALYTICS_ALLOW_AUTOMATIC_EVENTS` is a release-policy decision that requires exact-archive event/egress evidence and revised disclosures.

## External release blockers

The source candidate is **1.0 (3)**. The existing App Store record and baseline TestFlight build **1.0 (2)** have not been modified. Remaining external gates include owner approval of the source-only title change, physical iPhone/iPad evidence, StoreKit product and remaining store metadata, production support/privacy/terms URLs, exact-archive network/privacy evidence, and production AI abuse protection. See `BUILD_VALIDATION.md` and `docs/release-checklist.md`.

## Status

The current source configuration uses **Cramline Exam Sprint** with immutable registered bundle and product identifiers. App Store Connect Apple ID `6816753041` still carries its prior public title until the account owner completes availability and legal clearance; no Apple mutation, paid build, upload, or submission is performed from this repository. Physical-device and store-review gates remain intentionally open until completed by the account owner/release team.
