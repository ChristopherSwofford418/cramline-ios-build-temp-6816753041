# Block Your Phone to Study Validation Report

**Validation date:** 2026-09-28
**Environment:** Ubuntu 24.04 sandbox, Swift 6.1 Linux toolchain, Node.js 22, pnpm 11.25, JDK 17, Android SDK 36, Gradle 8.14.5, XcodeGen 2.46.0, and EAS macOS with Xcode 26.6.

## Passed locally

| Check | Result |
|---|---|
| Swift domain package compile/test | **10 tests passed, 0 failures** |
| Swift syntax parse | Every source under `ios/` and `Packages/CramlineCore` parsed successfully |
| XcodeGen project generation | **Passed**; generated host app, three Screen Time extensions, and UI-test target |
| Generated Info.plist assertions | **Passed**; default-off Firebase keys, app-group values, and all extension point identifiers present |
| Generated entitlement assertions | **Passed**; Family Controls and shared App Group present in host and every extension |
| Planning service type check | **Passed** |
| Planning service tests | **3 tests passed, 0 failures** |
| Android manual companion unit tests | **2 tests passed, 0 failures** |
| Android lint | **Passed**; one dependency-update warning remains because the newest Compose BOM requires Android 37/AGP 9.1, while this project deliberately uses the current Android 36/AGP 8.11-compatible line |
| Privacy source lint | **Passed**; prohibited telemetry APIs/fields and Android permissions absent |
| Plist/entitlement/privacy-manifest parsing | **Passed** |
| Secret pattern scan | **Passed** |
| Git whitespace check | **Passed** |
| Public rename and AppIcon | **Passed**; generated project contains **Block Your Phone to Study**, version `1.0 (2)`, and a 1024×1024 RGB `AppIcon` |
| TestFlight workflow configuration | **Passed**; YAML and export plist parse, credentials are referenced only as encrypted secrets |
| Apple development identifiers | **Configured**; production team, four explicit App IDs, shared App Group, and Family Controls development capability verified |
| App Store Connect record | **Configured**; Apple ID `6816753041` is bound to `com.clearpasstechnologies.cramline` as **Block Your Phone to Study**, with subtitle **Exam Focus Timer & App Blocker** and the approved categories |
| Family Controls distribution | **Passed**; managed distribution capability assigned to the host and all three Screen Time extensions |
| Signed iOS archive | **Passed**; Xcode 26.6 EAS build `835e0ae8-5a28-4050-9fd2-79cb2aadf668` produced version `1.0 (2)` from commit `b3e65e84043df6d8f25f9dd082c4f4ec8f81c4e8` |
| App Store upload and processing | **Passed**; EAS submission `92da2928-6288-4c64-a09a-3cd8eb403720` finished and Apple build `87d5c0b0-f862-46b8-9480-ca34629e5778` reached **VALID** |
| Internal TestFlight setup | **Passed**; only build 2 is assigned to the private Internal Testers group, fix-specific testing notes are present, and the account-holder tester state is **INSTALLED** |

## Coverage represented by tests

The Swift tests cover 14/90-day bounds, invalid 13/91-day sprints, maximum recurring windows per day, DST wall-clock preservation, immediate emergency pause capped at the session end, terminal ended state, deterministic offline planning, exact telemetry event/property allowlisting, fictional sensitive-data rejection, and the constrained AI request shape.

The service tests cover strict rejection of selected-app/device/activity/reflection fields, live-catalog model choice, structured request/output behavior, and no-retention response metadata. Android tests cover explicit non-enforcement claims and prohibited hard-block language; Android lint and `scripts/privacy-lint.sh` check the shipping manifest/source boundary.

## Not yet proven

The Xcode 26.6 release archive compiled and signed the complete host-plus-three-extension product and Apple accepted the binary. Automated UI tests and the physical Screen Time behavior matrix still require real iPhone/iPad execution. GitHub-hosted Actions did not allocate runners during earlier attempts; EAS supplied the successful macOS release environment instead.

The following are explicit release blockers rather than source-code tasks:

- physical iPhone/iPad plus TestFlight validation of authorization, picker, shields, callbacks, pause/resume, overlap, reboot, DST, travel, revocation, and deletion;
- exact-release network/queue audit for Firebase, Crashlytics, and Mixpanel plus final App Privacy answers;
- production support/privacy/terms URLs, Firebase/Mixpanel projects, StoreKit products, and AI endpoint abuse protection;
- App Store/Google Play review outcomes and Android OEM/accessibility matrices.

## Contract corrections implemented

Apple’s 50-token rule is enforced after picker completion as a simultaneous app-shield limit; the stock picker cannot prevent the 51st tap. The picker expands category choices into current concrete app/website tokens, and the app discards dynamic category tokens before persistence or enforcement. Emergency resume is described and implemented as best effort. Shield metadata is not retained/exported. Firebase Analytics remains disabled in strict compliance mode because enabled Firebase automatic events conflict with a literal custom-event allowlist. Android ships as a permission-free manual companion; the AccessibilityService beta is documentation-only and absent from the manifest.
