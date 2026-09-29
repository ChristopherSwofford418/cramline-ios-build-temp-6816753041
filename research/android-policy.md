# Android companion and AccessibilityService beta — implementation memo

**Decision (current 27 September 2026):** Ship Android v1 as a **manual focus companion**. It can plan local study sessions and link a user to Android's own focus/Wellbeing controls, but must not claim to block or control other apps. The optional **Interruption Beta** is technically possible but is a policy-sensitive, fail-open feature: a non-accessibility-tool `AccessibilityService` may receive one narrowly filtered event from user-selected supported packages and show a Cramline-owned interruption card. It is neither an OS block nor a system shield. Google Play has no entitlement-style pre-approval; the relevant binary must pass the Accessibility declaration/review process before the track containing it is distributed.[5] [6]

## Implementation boundaries

| Area | Required build position | Consequence for Cramline |
|---|---|---|
| Installed-app visibility | Do **not** declare `QUERY_ALL_PACKAGES`. Android 11+ filters installed-package results by default; use finite `<queries>` entries only when code must verify a specific, named supported package is installed. | Render the fixed supported-app list from local constants. Never call `getInstalledApplications()` or construct an inventory. A finite package query is not a substitute for the `AccessibilityService` package filter.[1] [2] |
| Usage history | Do not declare `PACKAGE_USAGE_STATS` or request Usage Access. Its methods need the manifest permission plus a user grant in Settings and return package-level aggregate use and event history. | The v1 prohibition is sound. Do not use it as a foreground-app detector, analytics source, or fallback for the beta.[3] |
| Device policy | Do not use `DevicePolicyManager.setPackagesSuspended()` in the consumer app. It is an Android Enterprise DPC function for a device owner or profile owner. | A normally installed self-management app cannot obtain this authority. It must not market or attempt suspension, uninstall prevention, lock-task, or device-owner provisioning.[4] |
| Service identity | Cramline is **not** an accessibility tool: omit/set `isAccessibilityTool=false`; it is not a disability-support product whose primary purpose is accessibility. | It must complete the non-tool Accessibility declaration, use separate in-app disclosure and affirmative consent, and provide the required disclosure/consent/core-feature video. Do not seek the disclosure exemption.[5] [6] |
| Event scope | Register only `TYPE_WINDOW_STATE_CHANGED`, only for the current local selected supported package names, and only while the user-started session is active. Reset the event/package subscription outside a session. | Use `AccessibilityServiceInfo.packageNames` and `eventTypes` (both dynamically configurable) as a system-side filter. No `typeAllMask`, notification events, text, click, scroll, touch-exploration, key filtering, accessibility-button request, or broad package scope.[9] [10] |
| Content and automation | Put `android:canRetrieveWindowContent="false"` in the service XML. Set `android:canPerformGestures="false"` and implement no gesture, node action, global action, key interception, or UI automation API. | This is a permanent binary-level restriction, not a runtime preference. `canRetrieveWindowContent` is XML-configured; it cannot be made safe merely by changing runtime service info.[8] [9] |

### Important technical correction: `canRetrieveWindowContent=false` is necessary but not sufficient

The contract correctly rejects node-tree/content access, but it overstates what the flag alone proves. `TYPE_WINDOW_STATE_CHANGED` is a visually distinct UI-section event, not a reliable “app has opened” signal; true window changes use `TYPE_WINDOWS_CHANGED`. More importantly, a window-state event can expose a package name, class name, and **text including pane-title/subtree text**. Disabling window-content retrieval prevents APIs such as `getRootInActiveWindow()` and event-source tree access; it does **not** guarantee that the event object contains no textual fields.[10] [11]

Therefore the beta must do all of the following:

1. Read at most the event type and package name solely to match the local active allowlist. Do not call `getText()`, `getClassName()`, `getSource()`, `getRecord*()`, `getWindows()`, `getRootInActiveWindow()`, or `findFocus()`.
2. Never persist, log, send to analytics/crash reporting, or expose the package/event fact to AI. Do not retain event times or per-app counts.
3. Enforce the policy in code review and CI with static checks for the prohibited methods, manifest/resource assertions for the false capability flags, and network/telemetry tests using content-bearing test events.
4. Treat missed, duplicated, delayed, or OEM-specific events as normal. They must only result in **no interruption**, never a false “blocked” state.

## Package visibility and target selection

A finite, local supported-package list is the right model. The service can itself subscribe to named packages via `packageNames`; it does not need broad visibility to do that. If the UI needs an “Installed” badge, declare only those same finite names in `<queries>` and test each with `PackageManager`; otherwise do not query installation at all. On Android 11+, all-app enumeration and many package APIs are filtered by default precisely to reduce sensitive installed-app access.[2] [9]

`QUERY_ALL_PACKAGES` remains out of scope. Play treats installed-app inventory as personal and sensitive information, permits broad visibility only when the app's core function requires searching **all** apps and a less intrusive approach cannot work, and requires a Play Console declaration. The Cramline use case has a finite supported set, so it does not have that justification.[1] Do not use a library/SDK that adds the permission transitively.

## Interruption UX, overlays, and TalkBack

An accessibility service can draw an accessibility overlay, including an overlay attached to a display or window.[11] That API capability does not authorize a coercive or deceptive UI. Play prohibits use of Accessibility APIs to change settings without permission, prevent disable/uninstall, bypass platform controls, or leverage UI deceptively; it also requires listing metadata and behavior to be accurate.[6] [13]

**Recommended beta card:** after one eligible event during an active session, display a clearly branded, non-full-screen Cramline card once for that opening, then auto-dismiss quickly. The card may offer **Return to study** (open Cramline/timer after the user's tap), **Emergency pause — 15 minutes**, and **End session**. The latter two immediately remove the event subscription and card; all failures dismiss/fail open. The card must not auto-click Back, launch an activity on its own, capture keys/gestures, imitate an Android warning, hide Settings, or keep the target app unusable.

Do not design the card as a background-launched full-screen activity. Android has restricted background activity launches since Android 10 because they can hijack UI and enable tapjacking. A user-tapped notification/overlay action is a different, testable route, but automatic activity starts can be blocked and should not be Cramline's enforcement mechanism.[12] Do not claim that an overlay can reliably avoid every system/emergency surface on every OEM. Instead keep it small and temporary, never target system packages, remove it immediately on pause/end, provide OS Settings/revoke guidance, and test the asserted behavior on the release matrix.

TalkBack and other services can be enabled at the same time. Android explicitly directs services to handle only the events they need and not consume events other services may handle.[9] Keep the service package/event filter narrow; request no touch exploration, gesture dispatch, accessibility focus, speech feedback, or key filtering. Build the card with labelled, screen-reader-operable controls; do not steal TalkBack focus. Test both Cramline-on and Cramline-off paths with TalkBack, Switch Access/Voice Access where available, large text, navigation gestures, locked screen, incoming call/emergency flows, Settings disable, and OEM battery/restart behavior. The OEM matrix is prudent release evidence, not a substitute for Play's formal declaration/video requirements.

## Required disclosure, declaration, and release evidence

Before the Android Settings enable intent, show a **standalone** Accessibility disclosure in normal setup—not in a policy, menu, or combined privacy consent—and require an unchecked affirmative choice. It must accurately name the data and purpose. Suggested audited wording:

> **Optional Study Interruption Beta uses Android's AccessibilityService only during study sessions you start. It receives window-state events from the specific supported apps you select to detect that one has opened. Cramline uses that fact on your device to show its interruption card. It does not read or save on-screen text, messages, passwords, notifications, browser history, or app-usage history, and does not share accessibility-event data. You can turn this service off in Android Settings at any time.**

Use this wording only if the shipped code exactly complies. The disclosure must immediately precede consent/Settings enablement; backing out is not consent.[5] [7] The Play listing must document Accessibility use. Submit the non-accessibility-tool declaration and a video showing: app open; path to the full disclosure; accept and decline paths; Android service enablement; and the core beta interruption. If any accessibility-derived personal/sensitive data is actually stored or transmitted, declare it accurately in the Accessibility form, privacy policy, and Data Safety section; do not predeclare “no data collected” until the final code and SDK traffic prove it.[5] [7]

## Claims and listing language

**Safe Android companion wording**

- “Manual Focus Companion for professional-exam study sessions.”
- “Plan a study session and set Android focus limits yourself.”
- “Optional Interruption Beta can show a Cramline reminder after a selected **supported** app opens during a session you start.”
- “Emergency pause and End session are always available.”

**Do not use in Android title, subtitle, screenshots, onboarding, or paid copy**

- “Block distractions,” “app blocker,” “hard blocker,” “system shield,” “locks apps/your phone,” “unbreakable,” “prevents uninstalling,” “works like iPhone/iOS,” or “blocks every selected app.”
- Any screenshot that resembles Android system UI or an OS warning, or any claim that the beta detects procrastination, reads app content, tracks use, or guarantees focus/exam performance.

Play requires every listing field and image to accurately reflect functionality and prohibits impossible or misleading claims, hidden functionality, OS-warning mimicry, and nonreversible device-setting changes.[13] Maintain a distinct Android listing/creative set. The contract's generic subtitle **“Block distractions for exams”** and ASO keyword **“app blocker”** are acceptable only for a truthful iOS listing; they should not ship as Android metadata for either the manual companion or interruption beta.

## Contract corrections and release gates

1. Replace “Interruption Beta only after Google Play approval” with: **“Submit the exact beta binary with the required non-tool Accessibility declaration, disclosure/consent video, accurate listing, privacy policy, and Data Safety information; distribute only after Play review permits that track.”** There is no public pre-approval entitlement to rely on.[5]
2. Change “minimal window-state event” from a privacy assurance to a **best-effort trigger**. The event can contain text, and it does not prove an app launch. Retain only the package-match fact in memory for the current callback; do not inspect content.[10]
3. Specify that `canRetrieveWindowContent=false` belongs in the XML resource, and verify it in the built APK/AAB. It is not an adequate standalone no-content guarantee.[8] [9]
4. Change “only selected declared packages” to **“only a finite local allowlist enforced by `AccessibilityServiceInfo.packageNames`; use manifest `<queries>` only for a finite installed-check need.”** “Declared” package visibility alone does not filter accessibility events.[2] [9]
5. Add a hard fail-open gate: disabled service, unrenderable card, event ambiguity, reboot, app process death, overlay error, or battery/OEM failure must leave the target usable and show no protected/blocked state.
6. Treat the manual companion as the launchable Android product. The beta needs a separate policy review, source/manifest audit, Play video, accessibility coexistence matrix, and packet/log proof before any public claim is enabled.

## References

[1]: https://support.google.com/googleplay/android-developer/answer/10158779?hl=en "Use of the broad package (App) visibility (QUERY_ALL_PACKAGES) permission"
[2]: https://developer.android.com/training/package-visibility "Package visibility filtering on Android"
[3]: https://developer.android.com/reference/android/app/usage/UsageStatsManager "UsageStatsManager API reference"
[4]: https://developer.android.com/work/dpc/security "Android Enterprise security: disable access to apps"
[5]: https://support.google.com/googleplay/android-developer/answer/10964491?hl=en "Use of the AccessibilityService API"
[6]: https://support.google.com/googleplay/android-developer/answer/16558241?hl=en "Permissions and APIs that Access Sensitive Information"
[7]: https://support.google.com/googleplay/android-developer/answer/10144311?hl=en "Google Play User Data policy"
[8]: https://developer.android.com/guide/topics/ui/accessibility/service "Create an accessibility service"
[9]: https://developer.android.com/guide/topics/ui/accessibility/views/service "Create your own accessibility service (Views)"
[10]: https://developer.android.com/reference/android/view/accessibility/AccessibilityEvent "AccessibilityEvent API reference"
[11]: https://developer.android.com/reference/android/accessibilityservice/AccessibilityService "AccessibilityService API reference"
[12]: https://developer.android.com/guide/components/activities/secure-bal "Activity security and background activity launch restrictions"
[13]: https://play.google.com/about/privacy-security-deception/deceptive-behavior/dishonest-behavior/ "Google Play Deceptive Behavior policy"
