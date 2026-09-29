# Cramline — Apple Screen Time implementation memo

**Decision:** The self-directed iPhone/iPad core is feasible, but only as a **conditional iOS/iPadOS 16.0+ release**: Apple must approve the Family Controls distribution capability for the host app and *each* shipped Screen Time extension, and the emergency-pause/resume design must pass a physical-device proof spike. The APIs support voluntary individual authorization; they do **not** create a hard lock or an “adult 18+” authorization class. This assessment reflects Apple documentation accessed **2026-09-27**.

## Required platform shape

Use `AuthorizationCenter.shared.requestAuthorization(for: .individual)` after Cramline’s own explanation and explicit user action. On first approval, iOS presents an alert followed by Face ID, Touch ID, or passcode authentication. `individual` means the device owner authenticates themself; it is not a Family Sharing requirement and Apple does not expose an age/18+ verification API. Individual authorization deliberately leaves the person able to delete Cramline and sign out of iCloud. That matches the product’s non-coercive promise. Check `authorizationStatus` at launch and foreground, observe its publisher while running, and treat every nonapproved state or request error as **cannot apply**. [1] [2]

Present the system `FamilyActivityPicker` only after authorization. On an individually authorized device it represents applications and sites on that device. Bind and locally persist the returned `FamilyActivitySelection` (it is `Codable`), but treat application, category, and web-domain values as opaque. Pass them only to Screen Time frameworks; never attempt to turn them into inventory, names, package IDs, analytics, logs, or AI input. Revocation voids the selection’s tokens, so revocation must invalidate and delete the local selection rather than attempting to reuse it. [3] [4]

Create these targets:

- **Cramline host app:** onboarding, authorization, picker, plan editor, immediate manual one-off shield, shared state, and Settings/revocation UI.
- **Device Activity Monitor extension:** one monitor for each of up to three recurring daily windows and distinct one-off activity names. In `intervalDidStart`, read the shared desired state and apply the shield; in `intervalDidEnd`, clear Cramline’s settings. Use a **single named `ManagedSettingsStore`** consistently.
- **Shield Configuration extension:** return the limited system shield surface—icon, title, subtitle, primary label/color, optional secondary label (and, where used, its submenu). Keep it fast; the system uses its default if the data source is absent or slow. [9]
- **Shield Action extension:** handle primary/secondary button events. Its documented responses are `close`, `defer`, `none`, and `openParentalControlsApp`; it is not a general deep-link/action surface. [10]

Add **Family Controls** and the same **App Groups** identifier (for example, `group.com.cramline.app`) to every target that needs either capability or shared state, then regenerate/provision every target. Use the app-group container or `UserDefaults(suiteName:)` for an atomically written `Codable` selection, active session identifier, intended end time, pause-until timestamp, and desired enforcement state. Do not use the group as an analytics bridge. App Groups are the documented mechanism for host-app/extension sharing. [12] [13]

## Shielding and picker limits

Apply only the shielding surface Cramline needs: `store.shield.applications`, and—only if later accepted by the product safety design—web-domain/category settings. Setting a managed setting to `nil` deletes Cramline’s configuration for that setting; `clearAllSettings()` is suitable for end, local delete, fail-open incident response, and best-effort revocation cleanup. The system determines effective device behavior, so the app must never claim that its requested state is an unbreakable or directly observable system state. [5] [6]

Apple’s documented ceiling is **50 `ApplicationToken`s in `ShieldSettings.applications` at once**. It is **not** documented as a 50-item `FamilyActivityPicker` selection limit, and the picker API provides bindings/header/footer—not a documented maximum-selection or per-row interception control. Therefore Cramline cannot truthfully “prevent the 51st tap” in Apple’s stock picker. Count `selection.applicationTokens` after confirmation; if more than 50, apply none, explain the enforceable 50-token limit, and ask the person to revise the picker selection. Test 0/1/5/50/51 as requested. [3] [5]

The privacy model has two further product consequences. Cramline cannot prepopulate a “default social/video” app set, classify opaque selections as communications/finance/health/browser/education, or conditionally show confirmation based on a chosen category. The picker has no documented filter that restricts those choice types. For v1, either ignore category tokens (recommended) and use a generic pre-picker safety warning, or redesign the policy; do not promise category-specific post-selection safeguards. Similarly, do not make a claim that Cramline *never sees an app name* in every extension: the configuration data source is given display names, bundle IDs, and domains for items it is currently shielding, although it is sandboxed from network requests. Keep that metadata in-process, use generic shield copy, and never transmit it. [3] [4] [9]

## Scheduling, one-off sessions, and end dates

`DeviceActivitySchedule` is calendar-based (`DateComponents`, interval start/end, repeats, optional warning). It has no separate “repeat until sprint end” property. Represent the three daily windows with three stable repeating activity names, retain the 14–90 day end date in shared local state, and have the monitor **skip/clear** whenever the current date is outside the sprint. Do not schedule 14–90 × 3 separate activities; `DeviceActivityCenter` can reject excessive activities as well as invalid/too-short/too-long intervals. One-off sessions should use a nonrepeating schedule plus an immediate host-app shield to avoid waiting for a callback. [7] [8] [14]

The monitor callbacks are not a precision background-timer contract: Apple states that activity starts/ends and callbacks occur when the device is in use. On launch, foreground, calendar/time-zone change, DST transition, and monitor callback, recompute the intended local plan, compare the center’s `schedule(for:)`/`activities`, repair stale monitoring, and show **State unknown** rather than asserting active enforcement after an error. Test real time-zone/DST, reboot, force termination, and an inactive device before release. [7] [8]

## Emergency pause and revocation

A free emergency route is feasible, but the contract must not describe it as a native exact 15-minute pause API—Apple supplies no such API. Configure the secondary shield label as **Emergency pause — 15 minutes**. On that action, either write a minimal app-group request and return `openParentalControlsApp`, or prove in the action extension that it can clear Cramline’s named shield safely; then set `pauseUntil`, clear Cramline’s shield, and register/repair a nonrepeating monitor interval to reapply the remaining session. The host app must provide the same pause and **End today’s session** directly, without payment, AI, confirmation games, or network.

Because reapplication depends on Device Activity scheduling/callback behavior, the exact 15-minute end cannot be guaranteed as a real-time deadline. The physical-device spike must test: action extension → host open/clear → backgrounded host → re-shield at expiry → end session/revocation; fail open and surface an honest state if any step fails. Map **Return to study** to a tested system response—normally `close` means close the shielded app; it does not provide arbitrary navigation. [7] [10]

On authorization change to nonapproved: stop monitoring Cramline activities; clear its named store best-effort; delete the selection, pause/session state, and any cached tokens; then show the contract’s truthful reauthorization state. Require a new user-authorized picker selection after reauthorization. In current SDKs, `ManagedSettingsStore.TokenExpiryMessage` is available only on iOS/iPadOS 26.5+, so gate it with availability and preserve the iOS 16–26.4 fallback: fail open, request reselection/refresh during a user-present flow, and never silently expand the shield. [1] [4] [6] [15]

## Deployment, simulator, and distribution gates

Set **iOS 16.0 / iPadOS 16.0 minimum deployment targets**. The frameworks and picker begin at iOS/iPadOS 15, but `FamilyControlsMember.individual` and `requestAuthorization(for:)` begin at 16.0. The new 26.5 token-expiry notification is optional, not a reason to raise the baseline. [1] [2] [15]

Do not state that Screen Time APIs are categorically unavailable in Simulator: Apple’s public reference pages inspected do not make that claim, and Apple Developer Forum material indicates authorization can be exercised there. Simulator is nevertheless insufficient evidence for this product. Require physical iPhone and iPad tests for managed-capability provisioning, actual picker catalog, shield rendering/action extensions, schedule lifecycle, Settings revocation, reboot, and a TestFlight archive.

The Account Holder must request **Family Controls distribution** through Apple’s request/capability flow. Submit the request for the host and every Device Activity Monitor, Shield Action, Shield Configuration (and any report) extension. Apple uses managed capabilities; verify the Family Controls capability is **Assigned** and that Provisioning Support includes the required distribution methods. Apple explicitly requires this distribution entitlement for **TestFlight and App Store** and says it supports development, Ad Hoc, and App Store profiles. A development-capability build is not release proof. [11] [12]

Before TestFlight, archive with all target provisioning profiles and entitlement signatures validated on a physical device. Provide beta test information and a support email. External testing may send the first build to App Review; the build must be intended for public distribution and satisfy App Review Guidelines. For App Store review, provide detailed notes/instructions for the non-obvious authorization, picker, shield, revocation, and emergency flows. A reviewer video is a strong internal release artifact, but it is **not stated by Apple as a mandatory gate**; do not present it as an Apple requirement. [16] [17]

## Contract corrections to make before implementation

1. Replace “Apple’s documented maximum of 50 selected application tokens” and “prevent at the 51st selection” with the post-picker **50 simultaneous app-shield tokens** validation above.
2. Replace selectable “default social/video targets” and post-selection safety-category confirmation with user-only selection plus a generic pre-picker warning, or deliberately omit category enforcement in v1. The opaque picker model prevents that classification/preselection.
3. Change “emergency pause removes shields for 15 minutes” to **“requests an immediate pause; Cramline attempts to reapply at 15 minutes and reports state honestly.”** Ship only after the action/rescheduling proof spike succeeds.
4. Change any absolute “Cramline cannot know selected app names” statement: picker tokens are opaque, but the Shield Configuration extension receives metadata for an actively shielded item. Prohibit retention, logging, and export instead.
5. State **iOS/iPadOS 16+**, not 15+, for the individual-authorization MVP; make the adult-only restriction a product/terms control, not an Apple authorization assertion.
6. Do not call Simulator unsupported; call it **non-release evidence** and require physical devices/TestFlight.

## References

[1]: https://developer.apple.com/documentation/familycontrols/authorizationcenter "Authorization Center"
[2]: https://developer.apple.com/documentation/familycontrols/authorizationcenter/requestauthorization%28for%3A%29 "Requesting authorization for a child or individual"
[3]: https://developer.apple.com/documentation/familycontrols/familyactivitypicker "Family Activity Picker"
[4]: https://developer.apple.com/documentation/familycontrols/familyactivityselection "Family Activity Selection"
[5]: https://developer.apple.com/documentation/managedsettings/shieldsettings/applications-swift.property "Shielded application tokens"
[6]: https://developer.apple.com/documentation/managedsettings/managedsettingsstore "Managed Settings Store"
[7]: https://developer.apple.com/documentation/deviceactivity/deviceactivitycenter "Device Activity Center"
[8]: https://developer.apple.com/documentation/deviceactivity/deviceactivityschedule "Device Activity Schedule"
[9]: https://developer.apple.com/documentation/managedsettingsui/shieldconfigurationdatasource "Shield Configuration Data Source"
[10]: https://developer.apple.com/documentation/managedsettings/shieldactionresponse "Shield Action Response"
[11]: https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement "Requesting the Family Controls entitlement"
[12]: https://developer.apple.com/documentation/xcode/configuring-family-controls "Configuring Family Controls"
[13]: https://developer.apple.com/documentation/xcode/configuring-app-groups "Configuring app groups"
[14]: https://developer.apple.com/documentation/deviceactivity/deviceactivitycenter/monitoringerror "Device Activity Center monitoring errors"
[15]: https://developer.apple.com/documentation/managedsettings/managedsettingsstore/tokenexpirymessage "Managed Settings token-expiry message"
[16]: https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/ "TestFlight Overview"
[17]: https://developer.apple.com/app-store/review/guidelines/ "App Review Guidelines"
