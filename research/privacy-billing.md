# Cramline — consent-first telemetry, privacy, and StoreKit memo

**Release position (current 2026-09-27).** The free local Screen Time shield, sessions, emergency pause, plan deletion, offline operation, and Restore Purchases must work with telemetry **never enabled**. Treat consent as a local, default-`disabled` state. Do not make it a condition of Family Controls authorization, the picker, active session, emergency route, purchase, AI request, or deletion. Apple requires consent even for anonymous usage data, a clear withdrawal path, and forbids making paid functionality depend on such consent. It also forbids monetizing Screen Time APIs; premium must remain the ongoing AI/planning value, never the shield, scheduling, exit, or deletion route. [11]

## Required implementation boundary

Create one main-app-only `TelemetryController` with a hard allowlist of the contract’s event names and enum-only properties. Its public API must accept typed enums—not strings or arbitrary dictionaries—and it must reject opaque app-selection tokens, app/package names, exact dates/times/time zone, durations, plans/reflections, shield copy, AI input/output, purchase/transaction IDs, Apple IDs, contacts, IP-derived location, and device/advertising IDs. Do not set Firebase user IDs/properties/default event parameters or Crashlytics custom keys, logs, breadcrumbs, user IDs, attachments, screenshots, or free-text non-fatals. Crash reports otherwise contain stack traces, application state, and device/OS information; Firebase identifies these as Crashlytics data and calls out Analytics breadcrumbs as user-action data. [5]

Persist only the consent decision locally. All telemetry calls should first test this state. The controller is the sole source file allowed to import analytics SDKs; CI should fail direct `Analytics.logEvent`, `Crashlytics`, or `Mixpanel` calls elsewhere. Keep the exact event schema and forbidden-field tests required by the build contract, including deliberately fictional selected-app tokens, session times, and reflection text.

## Firebase: static default-off controls, then local purge

Set these values in the **main-app target’s** `Info.plist` before Firebase initializes:

```text
FIREBASE_ANALYTICS_COLLECTION_ENABLED = NO
GOOGLE_ANALYTICS_IDFV_COLLECTION_ENABLED = NO
GOOGLE_ANALYTICS_DEFAULT_ALLOW_ANALYTICS_STORAGE = false
GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_STORAGE = false
GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_USER_DATA = false
GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_PERSONALIZATION_SIGNALS = false
FirebaseCrashlyticsCollectionEnabled = NO
```

`FIREBASE_ANALYTICS_COLLECTION_ENABLED=NO` is Firebase’s documented consent-before-collection switch. Runtime `Analytics.setAnalyticsCollectionEnabled` persists and overrides that plist value. Do **not** use `FIREBASE_ANALYTICS_COLLECTION_DEACTIVATED=YES` in a build that can ever opt in: it permanently deactivates Analytics for that app version. Omit `AdSupport` and use the Analytics Core dependency rather than the IDFA-capable dependency; also keep IDFV disabled. [1]

On consent, first set all four Google consent-mode values deliberately (this product should keep ad storage, ad-user-data, and ad-personalization denied), then enable Analytics only if the resolved event-policy issue below is approved. Google’s consent-mode settings persist, and consent storage denial makes `appInstanceID()` return `nil`. [2] [3]

On opt-out, local-data deletion, reset, sign-out, or future account deletion: stop the app’s telemetry gate, call `Analytics.setUserID(nil)`, clear default parameters, disable collection, and call `Analytics.resetAnalyticsData()`. Firebase documents that reset as clearing Analytics data from the device and resetting the App Instance ID. It is a **device-local** purge, not a deletion API for data that was already uploaded. [3]

For Crashlytics, `FirebaseCrashlyticsCollectionEnabled=NO` is essential on the very first run. Dynamic `setCrashlyticsCollectionEnabled` persists but takes effect on the **next** run, so it cannot be the initial or immediate opt-out guarantee. While automatic collection is disabled, call `deleteUnsentReports()` to remove cached unsent reports; the documented API does not delete reports that were previously uploaded. Do not call `sendUnsentReports()` in this product. [4]

## Mixpanel: no initialization before consent

Do not initialize Mixpanel at all before consent. After consent, initialize only in the main app with `trackAutomaticEvents: false`, `useIPAddressForGeoLocation: false`, no feature flags/experiments/replay dependency, no debug logging, no super-properties, and `useUniqueDistinctId: false`. The current Swift SDK defaults to tracking enabled, has a 60-second batch flush by default, enables IP geolocation by default, and uses a random UUID rather than IDFV when `useUniqueDistinctId` is false. Pin the SDK version and maintain an analytics-scoped random identifier only in the app sandbox; do not use Keychain persistence, IDFV, IDFA, `identify`, People, Groups, or a custom ID provider that reconnects data. [6]

On withdrawal, block new calls, purge application-side staging, and call `optOutTracking()`. Mixpanel documents that mobile opt-out deletes unsent events and People updates from its device queue and makes later tracking/identify calls no-ops. Previously ingested data remains until its retention period or a separate Mixpanel deletion/GDPR-deletion process; because Cramline must not identify people, do not promise a per-person server deletion mechanism that the design cannot perform. [7]

If the SDK has run, `reset()` clears its local storage and creates a new random ID in the currently documented SDK. The safe reset-plus-opt-out ordering is **version-sensitive**: test the pinned SDK under an intercepting proxy to prove that it leaves the opt-out flag intact, clears the queue, rotates the ID, and produces no egress. There is no documented atomic “forget all state and remain opted out” operation. [6] [7]

## Extension isolation

Screen Time extensions can run without the host app. They must contain **no** Firebase Analytics, Crashlytics, Mixpanel, Firebase configuration, telemetry controller, HTTP telemetry client, or consent-prompt code. Do not rely on the main app’s initialization guard to protect an extension process. Each extension may access only the minimum enforcement data it needs—opaque selections and fail-open session state—through a dedicated App Group container. Apple describes App Groups as a shared container/IPC capability between a host and its extension; they are therefore an explicit privilege boundary, not a telemetry conduit. [15]

Give the main app and every extension target its own reviewed privacy-manifest coverage, then archive-scan every embedded `.appex` for linked frameworks, strings/symbols, `.xcprivacy` files, and unexpected network domains. Separately, Apple requires the Family Controls distribution request for the app **and each** Device Activity/Shield extension, and reviewers should receive provisioning proof for all bundle IDs. [16]

## StoreKit 2 subscription and restore safety

Use StoreKit 2 as a local entitlement source, not an analytics source. At launch, start a single long-lived listener for `Transaction.updates` and compute premium access from verified `Transaction.currentEntitlements`. StoreKit makes current transactions available on first launch and after reinstall; verify every `VerificationResult`, grant premium only for `.verified`, handle pending/cancelled/failed purchases without unlocking, and call `finish()` only after local entitlement delivery. Never transmit transaction IDs, original transaction IDs, product IDs, entitlement status, price, renewal date, or StoreKit errors to analytics/crash reporting. [9]

Offer an always-visible **Restore Purchases** control. It may call `try await AppStore.sync()` only after that explicit tap because it can display an App Store authentication prompt. Normal entitlement refresh should use `currentEntitlements`; StoreKit says an app has current transactions at initial launch and ordinarily does not need `sync()`. [8]

On expiration, refund, revocation, billing issue, or failed restore, remove only the paid AI/planning entitlement. Never remove a live shield’s free emergency pause/end route, and never use a subscription state to leave a shield stuck. The paywall must prominently show subscription name, duration, provided premium value, full localized renewal price, trial-to-paid price (if any), renewal/cancellation information, Restore Purchases, Privacy Policy, Terms of Use, and a route to manage the subscription. Auto-renewable subscriptions need ongoing value, at least a seven-day period, and availability across supported devices. [10] [11]

## Privacy manifests, App Store disclosures, and review evidence

A privacy manifest is not the Privacy Nutrition Label. Add a valid `PrivacyInfo.xcprivacy` to each target that Cramline owns and keep vendor manifests from every dependency. Apple rejects invalid manifests; FirebaseCrashlytics, FirebaseCore, and several transitive Firebase/Google libraries are on Apple’s required-SDK list. Required signatures apply when a listed SDK is used as a binary dependency. [12] [13]

Complete App Store Connect privacy answers from the **shipping archive and observed traffic**, not SDK marketing claims. Apple defines “collect” as off-device transmission retained longer than real-time request processing and requires disclosure of the app’s and third-party partners’ practices. Local opaque tokens, schedules, reflections, and StoreKit-derived local state are not collected merely by staying on device. If an opt-in user can transmit telemetry, disclose that conditional collection unless it meets every narrow optional-disclosure condition. Likely candidates need archive-specific validation: Product Interaction for analytics, Crash Data/other diagnostics for Crashlytics, and Device ID if an SDK’s random instance ID is transmitted. Mark “tracking” only if data is joined with third-party data for ads/ad measurement or shared with a broker; the prescribed design must not do either and must not request ATT or use IDFA. [14]

Put this evidence in the review packet and retain it per release:

- A cold-install, pre-consent packet capture and SDK verbose-log capture showing no Mixpanel, Google Analytics, Crashlytics, or unexpected Firebase/Google endpoint traffic; repeat for each extension process. Test denied, enabled, disabled-after-enabled, local-delete, offline, relaunch, and network-recovery paths.
- Per-SDK queue/identifier evidence: after opt-out prove Analytics local reset, Crashlytics unsent-report deletion after a disabled launch, Mixpanel queue deletion, no new identifier reuse, and no event upload. Include negative tests that feed fake app tokens/schedules/reflections through every public telemetry/error API.
- Archive evidence: expanded target/dependency inventory, copied vendor `PrivacyInfo.xcprivacy` manifests, Xcode privacy report, required SDK signatures where applicable, extension bundle inspection, final App Store privacy answers, privacy policy, and consent/retention/deletion text.
- StoreKit Xcode, sandbox, and TestFlight evidence for first purchase, cancellation, pending/Ask-to-Buy-equivalent flow where applicable, restore on new device/reinstall, error, expiration, refund/revocation, renewal update, and no-paywall emergency exit. The purchase flow and reviewer instructions must be functional and visible; App Review requires complete IAPs and specific notes for non-obvious functionality. [11]
- Screen Time reviewer video/instructions showing default-off telemetry, consent location, 0/1/50/51 selection test, authorization revoke, scheduled shield, emergency pause/end, Restore Purchases, and entitlement/provisioning proof for every extension.

## Contract corrections and version-sensitive blockers

1. **“Disable Firebase before native initialization” needs precise wording.** Runtime Firebase APIs cannot be called before Firebase initializes. The achievable control is static plist default-off configuration that Firebase reads at initialization; Mixpanel alone can literally remain uninitialized before consent. [1] [4]
2. **The literal “only allowed events” list is incompatible with enabling Firebase Analytics as currently documented.** Firebase Analytics automatically logs some events. No documented switch found restricts an enabled SDK to only Cramline’s named manual events. Amend the contract to distinguish manual allowlisted events from vendor automatic events, or do not enable Firebase Analytics/use a collector that supports a literal allowlist. [17]
3. **Mixpanel opt-in conflicts with the literal event allowlist.** `optInTracking()` sends a built-in `$opt_in` event. If re-consent uses that API, allow `$opt_in` explicitly, or obtain and validate a pinned-version alternative that resumes tracking without it. Do not silently treat it as one of Cramline’s approved events. [7]
4. **A transmitted `telemetry_consent_changed {state: disabled}` contradicts immediate withdrawal and queue purge.** Keep a decline/disable record locally only. An `enabled` record may be emitted only after consent and only if the chosen SDK’s automatic-event behavior is accepted.
5. **Immediate Crashlytics withdrawal is not fully achievable with the documented dynamic API.** It takes effect next run. With strict consent requirements, use static default-off, accept that opt-in reporting begins on a later launch, and document/test the residual current-process risk; otherwise do not claim instant Crashlytics shutdown. [4]
6. **“No Firebase-originated collection of any kind before consent” is not proven merely by the Analytics/Crashlytics flags.** Firebase’s current Apple disclosure says GoogleDataTransport always collects SDK-performance metadata and calls Crashlytics stack/device/OS data “always collected.” Treat a zero-egress/zero-collection assertion as unresolved until the exact pinned release archive passes packet capture and Firebase confirms the behavior. Do not publish a “we collect nothing” label or privacy-policy claim without that proof. [5]
7. **Privacy labels are behavior- and release-specific.** Neither a privacy manifest nor an opt-in UX permits a blanket “no data collected” answer if the shipped app sometimes transmits SDK data. Update disclosures whenever the binary, SDK version, or configuration changes. [12] [14]

## References

[1]: https://firebase.google.com/docs/analytics/ios/configure-data-collection "Firebase: Configure Analytics data collection and usage for iOS"
[2]: https://developers.google.com/tag-platform/security/guides/app-consent "Google: Set up consent mode for apps"
[3]: https://firebase.google.com/docs/reference/swift/firebaseanalytics/api/reference/Classes/Analytics "Firebase Analytics Swift API reference"
[4]: https://firebase.google.com/docs/reference/swift/firebasecrashlytics/api/reference/Classes/Crashlytics "Firebase Crashlytics Swift API reference"
[5]: https://firebase.google.com/docs/ios/app-store-data-collection "Firebase: Apple App Store data-disclosure requirements"
[6]: https://docs.mixpanel.com/docs/tracking-methods/sdks/swift "Mixpanel Swift SDK documentation"
[7]: https://docs.mixpanel.com/docs/privacy/protecting-user-data "Mixpanel: Protecting user data"
[8]: https://developer.apple.com/documentation/storekit/appstore/sync%28%29 "Apple: AppStore sync"
[9]: https://developer.apple.com/documentation/storekit/transaction "Apple: StoreKit Transaction"
[10]: https://developer.apple.com/app-store/subscriptions/ "Apple: Auto-renewable subscriptions"
[11]: https://developer.apple.com/app-store/review/guidelines/ "Apple: App Review Guidelines"
[12]: https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk "Apple: Adding a privacy manifest to your app or third-party SDK"
[13]: https://developer.apple.com/support/third-party-SDK-requirements/ "Apple: Third-party SDK requirements"
[14]: https://developer.apple.com/app-store/app-privacy-details/ "Apple: App privacy details on the App Store"
[15]: https://developer.apple.com/documentation/xcode/configuring-app-groups "Apple: Configuring app groups"
[16]: https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement "Apple: Requesting the Family Controls entitlement"
[17]: https://firebase.google.com/docs/analytics/ios/events "Firebase: Log Analytics events on Apple platforms"
