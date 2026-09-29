# Cramline — Complete iOS-First Exam-Sprint Social Blocker Build Prompt

> **Use this document as the implementation contract for the build agent.** Build an iOS-first, self-directed focus tool for adults preparing for a high-stakes professional exam over a 14–90 day study sprint. It helps an adult precommit to putting selected social/video apps behind an OS-provided barrier during study sessions they schedule. It preserves agency with immediate emergency pause and clear OS exit routes.

You are the senior iOS engineer, Android engineer, Screen Time extension engineer, privacy/security engineer, subscription engineer, accessibility engineer, AI-planning engineer, policy/review engineer, and QA lead responsible for implementing **Cramline**.

**Working name:** Cramline  
**Working subtitle:** Block distractions for exams  
**One-line promise:** “Put selected social and video apps behind a system shield during study sessions you choose.”

The name passed only a lightweight public-web collision screen. It is **not** trademark, domain, App Store, Google Play, corporate, social-handle, or jurisdictional clearance. Centralize brand strings, bundle IDs, support/privacy URLs, product-page metadata, and localized screenshots so the product can be renamed before launch.

---

## 1. Specific niche, audience, and truthful boundary

Build only for **adults 18+ who are 14–90 days from a high-stakes professional exam**: licensing, certification, board, admission, or qualifying exams. The product is voluntary individual self-management. It is not for parents controlling children, schools monitoring students, employers controlling staff, spouses/partners controlling adults, proctoring, medical treatment, or “digital addiction” diagnosis.

The narrow user promise is:

> “During the study sessions you choose, Cramline helps put a system barrier in front of the social and video apps you select. You remain in control and can pause it in an emergency.”

### 1.1 Claims that are allowed

- “For 14–90 day professional exam study sprints.”
- “On iPhone/iPad, system-shields apps and websites you choose during scheduled sessions after you authorize it.”
- “Optional AI planning drafts, never automatic blocking.”
- “Emergency pause is always available.”

### 1.2 Claims that are forbidden

Do not say or imply: unbreakable, locks your phone, blocks every distraction, prevents uninstalling, detects procrastination, knows which apps someone selected on iOS, reads messages/feeds/history, makes an override decision, treats addiction/ADHD/anxiety, guarantees focus, helps someone pass, works identically on Android, or controls another person’s device.

The product must never hide, surveil, remotely configure, coerce, shame, financially penalize, or make an adult ask another person for permission to regain access to their phone.

---

## 2. Platform decision: build the truthful iOS core first

### 2.1 iOS/iPadOS is the real MVP

Build **native iOS/iPadOS Screen Time extensions**. A web-only/Expo-only implementation cannot meet this product requirement. The React Native/Expo UI may wrap shared non-enforcement screens, but build native Swift modules and extension targets for:

- **FamilyControls** individual authorization;
- **FamilyActivityPicker** selection flow;
- **ManagedSettings** shield enforcement;
- **DeviceActivity** planned schedules/monitor extension;
- **ManagedSettingsUI** shield presentation/action configuration.

The iOS core is:

1. Adult selects a 14–90 day sprint and an end date.
2. Adult sets up to three recurring study windows per day and can begin a one-off session.
3. A transparent precommitment screen explains what will happen and what the app cannot do.
4. User explicitly requests `FamilyControlsMember.individual` authorization.
5. User selects target apps/websites through Apple’s **FamilyActivityPicker**. Persist the opaque system tokens locally. Do not enumerate installed apps or attempt to derive their names.
6. During scheduled/one-off sessions, apply `ManagedSettings` shields for selected tokens.
7. The shield explains why it appears, when the session ends, and how emergency pause works.
8. At the end, remove shields and offer an optional local check-in: **Stayed with plan**, **Paused for a real need**, or **Ended early**.

The picker’s opaque selection model is a privacy feature. Cramline must never send selected app names/tokens, app content, app use, installed-app inventory, or browser information to a server, AI provider, analytics provider, logs, or crash reports.

Enforce Apple’s documented maximum of **50 selected application tokens**. At the 51st selection, prevent/clearly explain the limit. Do not attempt to override or work around it.

### 2.2 Family Controls entitlement is a hard release gate

Before promising distribution, the Apple Developer Account Holder must request and receive the **Family Controls entitlement** for the main app and every Screen Time extension that ships. Treat entitlement approval as a release blocker, not a routine deployment step.

Build an entitlement/provisioning proof spike on real devices before full product implementation. The app must handle authorization denied/revoked/removed with a truthful state:

> “Cramline can’t apply your study shield until Screen Time permission is enabled again.”

Do not show a fake system authorization dialog. Do not infer shield availability. Do not launch the paid product without actual entitlement approval, extension provisioning, TestFlight archive validation, reviewer video, reviewer instructions, privacy policy, and support contact.

### 2.3 Android is an honestly limited companion, not an equivalent blocker

Do **not** promise Android hard blocking. A normal Android consumer app has no verified public equivalent to the iOS system shield for selected third-party apps.

Do not use DevicePolicyManager package suspension in a personal-consumer product; it is for device/profile owners in managed enterprise/device deployments. Do not request `QUERY_ALL_PACKAGES`. Do not use an assumed third-party Digital Wellbeing control API. Do not request UsageStats in v1. Do not access notifications, app content, URLs, keystrokes, browser history, or accessibility node content.

Android launch options, in priority order:

1. **Android manual companion:** study sprint/planner plus clear help for a person to set Android’s own Digital Wellbeing limits manually. Market as a companion—not as app control.
2. **Android Interruption Beta:** only after Google Play approval. A narrowly scoped AccessibilityService may react only to a selected supported package and minimal window-state event during a chosen study window, then show a user-visible interruption card. It must set `canRetrieveWindowContent=false`, never inspect UI/content/text, never consume gestures, never cover system/emergency UI, and always offer **Return to study**, **Emergency pause**, and **End session**. It is friction after an app begins opening, not an OS block.

An Android public listing may say **“helps interrupt selected supported apps during a study session”** only when the actual audited build satisfies that statement. It may not use the term “hard blocker,” “system shield,” or iOS screenshots/features. The AccessibilityService requires separate prominent disclosure, affirmative consent, policy declaration, Play review, reviewer video/instructions, and a physical-device/OEM matrix before release.

---

## 3. Core product flow and exact UX

### 3.1 Onboarding

1. **Welcome:** “A self-directed focus barrier for professional exam study sprints.” Confirm `18+` using an age-gate disclosure; do not collect date of birth.
2. **Choose sprint:** pick 14–90 days, end date, local time zone, and optional generic study domain such as licensing/certification/board/admission. Do not require actual exam provider/name, score target, employer, school, coach, or account.
3. **Build a session plan:** up to three recurring time windows/day plus one-off session. Show clear time zone, dates, and duration.
4. **Precommitment review:** explain exactly what a shield does, unknowns/limits, emergency pause, End Today’s Session, system setting revoke/removal, and no guarantee of focus/exam results.
5. **Choose targets:** on iOS, launch the official FamilyActivityPicker only after individual authorization. On Android companion, show fixed supported social/video apps only where a package is declared/installed—not broad device inventory.
6. **Ready screen:** show next session, user-defined goal, and how to change/stop the plan.

### 3.2 Session screen

The active session is calm and non-punitive. Show:

- End time and local time zone.
- Session title/user’s optional generic plan label.
- Shield state: **Scheduled**, **Active**, **Paused**, **Cannot apply—authorization needed**, **Ended**, or **State unknown**.
- One optional deterministic focus cue: selected local timer/break plan. No social feed, ranking, streak, ads, cash stake, or public accountability.
- **Emergency pause — 15 minutes** and **End today’s session** must be visually reachable, understandable by screen readers, and never hidden behind a paywall, quiz, timer, payment prompt, reflection, or contact.

### 3.3 Shield copy and emergency access

Where Apple’s Shield UI supports it, use concise copy such as:

> “This app is paused until 10:30 AM for your Cramline study session.”

The shield must provide a clear primary route such as **Return to study** and secondary **Emergency pause — 15 minutes**. Prototype exact Shield Action extension behavior before promising this copy/UI. The emergency action removes shields for the current session for 15 minutes without punitive logging. Then the person can resume or end the session.

Default targets must be a short social/video set. Before allowing any communications/browser/identity/health/finance/transport/work/education/exam-provider-related category, show a clear additional confirmation. Never preselect safety-critical categories.

### 3.4 No dark patterns or coercion

Do not add strict mode, third-party-held passcode, “accountability partner” lock, paid exit, forced wait, financial forfeiture, lockout from installing/deleting, public results, shame copy, redemption challenge, remote commands, hidden settings, or background “escalation.”

A developer safety kill switch may only **fail open** by disabling Cramline’s own enforcement in response to a verified safety/security defect. It must never add target apps, lengthen a session, change consent, make blocking stricter, or hide itself.

---

## 4. AI is a small, user-invoked planning assistant—not the control plane

The requested “AI tool” must have a constrained role. **AI never observes social media usage and never starts/stops/extends/overrides a block.** The operating system’s Screen Time frameworks enforce the shield, not an AI model.

### 4.1 Permitted AI inputs/outputs

The user may explicitly request one of these:

- Draft a weekly study-session schedule from sprint end date, preferred times, broad study domain, desired study hours, and optional self-reported confidence.
- Suggest a session/break cadence.
- Draft a short “If I want to open social media, I will…” implementation-intention statement.
- Summarize user-authored local session reflections **only after** a separate per-request consent action.

Use a deterministic local rule-based planner as a complete non-AI fallback. The shield/scheduling features must work with AI permanently disabled.

### 4.2 Prohibited AI behavior

AI must not inspect/render/summarize app screens, accessibility node trees, notifications, messages, feeds, search, browser history, audio/video, screenshots, clipboard, keystrokes, credentials, selected Apple tokens, Android package inventory, exact schedule, selected app names, or device identity.

AI must not diagnose a behavioral/medical condition, grade “legitimate” overrides, claim to detect procrastination, offer clinical advice, make exam-result claims, generate punitive copy, or change device enforcement autonomously.

### 4.3 AI consent/implementation

Before every hosted AI request, show exact fields leaving device and this disclosure:

> “Send this planning request to AI? Cramline will send only the plan details shown here. It will not send selected apps, app activity, messages, social content, browser history, or device identity.”

Use server-side LLM access only. Never embed a model key/client-side proxy. Before choosing a model, call `listLLMModels()` and choose a currently available model based on the live catalog/cost/capabilities. Use a structured response schema for schedule drafts. Do not retain raw prompt/output beyond the minimum necessary to return a response; do not train on it; provide deletion. Show output as a **draft** requiring explicit user review/save. A model outage must not disrupt a scheduled shield.

---

## 5. Local-first data model and privacy

No account is required in v1. Store core data locally in protected app storage/Keychain/Keystore-backed storage.

```text
Sprint
  id, startedAt, endDate, timeZone, broadStudyDomain?, createdAt

StudyWindow
  id, sprintId, recurrenceRule, localStart, localEnd, enabled

OneOffSession
  id, sprintId, startsAt, endsAt, status

IOSSelection
  opaqueApplicationTokens, opaqueCategoryTokens?, opaqueWebDomainTokens?, updatedAt

SessionState
  id, source, plannedStart, plannedEnd, state,
  emergencyPauseUntil?, endedAt?, localCheckIn?

LocalPlan
  id, sprintId, userVisiblePlan, createdBy: rules|ai, savedAt

LocalReflection
  id, sessionId, text?, outcomeCategory?, createdAt

PrivacySettings
  telemetryConsent, aiRequestConsentState, localDataDeletionState
```

No default collection/transmission of contact details, exact exam name/provider, score, school/employer, address/location, advertising ID, device-wide app inventory, selected-token/app identity, app content, notifications, messages, web history, health data, biometric information, financial data, support activity, or accessibility-window content.

If support tickets later exist, collect only a person’s voluntarily submitted contact/message for support and publish retention/deletion. If accounts/cloud backup later exist, make them optional; add in-app and external account deletion, user export, access controls, session revocation, and a separate full data-flow review.

---

## 6. Mandatory consent-first Mixpanel, Firebase Analytics, and Firebase Crashlytics

Integrate **Mixpanel**, **Firebase Analytics**, and **Firebase Crashlytics**, with **all collection disabled by default**. Core shielding, session creation, emergency pause, plan deletion, Restore Purchases, and offline function must work when telemetry is declined.

Do not ask for analytics consent during Screen Time authorization, target picker flow, precommitment, active session, emergency pause, AI consent, payment, or deletion. Offer it in Privacy Settings and once after core setup has been completed.

Use this exact consent text:

> “Help improve Cramline with anonymous usage and crash information. We never send selected apps, app activity, social content, messages, browser history, your exact schedule, exam details, reflections, or identity. Saying no does not change your study shield.”

Rules:

- Disable Firebase Analytics and Crashlytics before native initialization. Before consent, do not set user IDs/properties, automatic screen events, custom keys/breadcrumbs, logs, attachments, or screenshots.
- Do not initialize Mixpanel before consent. After opt-in, generate a rotating analytics-only random installation ID. Never call `identify`, create People profiles, attach account/email/device/advertising IDs, IP geolocation, or join records to app data.
- On opt-out, local-data delete, sign-out, account delete, or reset: disable SDKs, reset identifiers, and clear queued events.
- Disable session replay, advertising, attribution, audience export, remote experiments, behavioral messaging, and cross-app tracking.
- The only allowed events are:

```text
telemetry_consent_changed: { state: enabled | disabled }
onboarding_completed: { entry: rules_planner | ai_planner }
sprint_action: { action: sprint_created | schedule_created | session_started | session_ended | local_data_deleted }
screen_time_authorization_result: { result: granted | declined | revoked }
emergency_action: { action: pause_used | session_ended }
android_beta_action: { action: companion_opened | accessibility_beta_enabled | accessibility_beta_disabled }
purchase_flow_action: { action: plan_viewed | purchase_started | purchase_completed | restore_completed | restore_failed }
app_operational_error: { category: fixed_owner_reviewed_enum }
```

Do not transmit selected app tokens/names/packages, exact schedules/time zones, dates, session duration, location, user plans/reflections, shield copy, accessibility events, or AI prompts/outputs. Create `docs/privacy/telemetry-consent.md`, `telemetry-data-map.md`, `mixpanel-firebase-config.md`, `sdk-inventory.md`, plus tests with fictional selected-app/session/reflection data proving the SDKs receive no forbidden content.

---

## 7. Accessibility and resilience

Use platform-standard controls and no visual-only timer. Support VoiceOver, Voice Control, Switch Control, Dynamic Type, large text, high contrast, reduced motion, keyboard where applicable, TalkBack, and non-color state labels.

The product must not misuse Android AccessibilityService branding. It is not an accessibility tool; it is an optional, explicitly disclosed interruption mechanism. Test coexistence with TalkBack and other assistive tech. Do not capture accessibility content, consume gestures, or create overlays that block system settings/emergency functions.

Critical flows—authorization explanation, session start/end, emergency pause, local data deletion, app deletion/revocation guidance—must work offline, without AI, without analytics, and with assistive technology.

---

## 8. Monetization, ASO, App Review, and release communication

### 8.1 Trust-aligned monetization

**Free core:** individual iOS authorization/shield, selected-app scheduling, one-off sessions, emergency pause, End Today’s Session, local planning/reflection, and local-data deletion.

**Optional premium value:** ongoing AI plan drafts, additional non-sensitive planning templates, expanded local recap views, and ongoing planning content. It must not lock the OS Screen Time capability, emergency exit, selected-app shield, scheduling, or data deletion. No ads, data sale, punitive trial, pay-to-escape, or monetary pledge/forfeit model.

Use StoreKit / Google Play Billing for digital features. Show price, term, renewal, trial, cancellation, Restore Purchases, privacy policy, and terms before purchase. Subscription expiration must never remove an active emergency exit or leave a stuck shield.

### 8.2 ASO

**Primary category:** Productivity; consider Education only if the shipping feature set truthfully supports it.  
**App name:** Cramline  
**Subtitle:** Block distractions for exams

Use accurate terms: exam focus, study sprint, app blocker, deep work, certification study, study timer. Do not use Apple/Screen Time affiliation terms, competitor names, exam-provider trademarks, “unbreakable,” “phone lock,” “anti-addiction,” or “AI proctor.”

iOS screenshot story:

1. “Choose a 14–90 day exam sprint.”
2. “Review what your study shield will do.”
3. “Choose apps privately in the system picker.”
4. “Emergency pause is always available.”
5. “AI plans your week only when you ask.”

Do not use fake OS dialogs. A separate Android listing is required only when an Android companion/beta actually ships; its first screenshot must say **Interruption Beta** or **Manual Focus Companion** as appropriate.

### 8.3 App Review package

Include an iOS reviewer video and exact test instructions covering individual authorization, picker selection, scheduled shield, 50-token cap, revoked authorization, emergency pause, session end, app deletion/settings exit, no-account local data, telemetry default-off, purchase/restore, and all extension bundle IDs/entitlements. Provide complete privacy/support URLs and prove that the distribution entitlement applies to every shipping Screen Time extension.

For Android AccessibilityService beta, submit all declarations, in-app disclosure text, reviewer video, reviewer instructions, physical-device/OEM results, disabled-service behavior, and a clear no-content-access explanation before public distribution.

---

## 9. Test matrix, gates, and definition of done

### 9.1 Required iOS tests

Test development/distribution entitlement, individual authorization grant/deny/revoke, Face/Touch ID cancel, target selection of 0/1/5/50/51 tokens, target persistence/reselection, one-off/recurring/overlap sessions, time-zone travel, daylight savings, reboot/extension restart, app termination, scheduled shield start/end, unknown state, emergency pause, End Today’s Session, support/revocation guidance, blocked social vs. unblocked safety/work/exam app, local delete, no account, no network, accessibility, purchase/restore/expiration, telemetry default-off/opt-in/opt-out, and packet/log inspection.

### 9.2 Required Android tests

Test manual-companion instructions on representative OEMs without misrepresenting control. If AccessibilityService beta is implemented, test allow/deny/disclosure, enable/disable in settings, only selected declared packages, minimal event/overlay, emergency pause, end session, reboot, battery management, TalkBack coexistence, `canRetrieveWindowContent=false`, no `QUERY_ALL_PACKAGES`, no `UsageStats`, policy declaration, and physical Android device variation.

### 9.3 Release gates

1. **Brand/claims gate:** legal clears brand/store claims/privacy/terms; a platform claim sheet says iOS “system shield,” Android “manual companion” or “interruption beta.”
2. **iOS proof gate:** real devices demonstrate individual authorization, opaque picker selection, scheduled shielding, cleanup, and emergency pause.
3. **Apple distribution gate:** Family Controls entitlement approved for app/extensions; provisioning and TestFlight archive pass; reviewer package ready.
4. **Privacy/billing gate:** actual network/data/SDK behavior matches consent, privacy labels, Data Safety, purchase/restore, deletion, and policy disclosures.
5. **Accessibility/safety gate:** emergency access works without delay/payment/AI; no coercion/hidden operation; current/minimum iPhone/iPad test matrix passes.
6. **Android containment gate:** no public Android “blocker” release until exact binary passes Accessibility/permission policy approval, review guidance, and representative device testing.
7. **Staged-launch gate:** start adult-only beta. Immediately fail open/stop rollout for a stuck shield, inaccessible emergency route, false protection state, pre-consent data transmission, content leak, entitlement/review concern, or misleading listing.

### 9.4 Definition of done

Cramline is ready only when:

1. It is a specific, adult-only, 14–90 day professional-exam study-sprint product.
2. iOS selected-app shielding uses official Screen Time frameworks, individual authorization, opaque picker tokens, and approved distribution entitlements.
3. It makes no hard-lock/guaranteed-focus/clinical/surveillance claims and never accesses selected app content/activity.
4. Emergency pause and End Today’s Session are immediately available and free.
5. AI is optional, user-invoked, consented per request, structured, limited to user-entered planning data, and never controls enforcement.
6. Android is transparently limited; no DevicePolicyManager consumer lock, full app inventory, UsageStats, hidden accessibility capture, or false equivalence exists.
7. Core data stays local with functional deletion; no identity/account requirement exists in v1.
8. Mixpanel, Firebase Analytics, and Crashlytics are integrated but default-off, consent-first, strictly allowlisted, and leakage tested.
9. Store claims, privacy/data declarations, reviewer instructions, entitlement state, subscription terms, and shipped behavior agree.
10. Every technical, privacy, accessibility, emergency, policy, and physical-device test passes.

### 9.5 Required repository artifacts

Deliver source/tests plus:

- `ARCHITECTURE.md`, `PRODUCT_SCOPE_AND_CLAIMS.md`, `IOS_SCREEN_TIME_IMPLEMENTATION.md`, `FAMILY_CONTROLS_ENTITLEMENT.md`, `ANDROID_COMPANION_BOUNDARIES.md`, `AI_PLANNING_BOUNDARY.md`, `EMERGENCY_AND_ANTI_COERCION.md`, `LOCAL_DATA_AND_PRIVACY.md`, `ACCESSIBILITY.md`, `MONETIZATION.md`, `ASO.md`, `APP_STORE_SUBMISSION.md`, `GOOGLE_PLAY_SUBMISSION.md`.
- `docs/privacy/telemetry-consent.md`, `telemetry-data-map.md`, `mixpanel-firebase-config.md`, `sdk-inventory.md`, `reviewer-video-script.md`, `extension-provisioning-checklist.md`, `android-accessibility-declaration.md`, `physical-device-qa.md`, `incident-runbook.md`, and `release-checklist.md`.

## References

[1]: https://developer.apple.com/documentation/screentimeapidocumentation "Apple Screen Time Technology Frameworks"
[2]: https://developer.apple.com/documentation/familycontrols/authorizationcenter "Apple FamilyControls AuthorizationCenter"
[3]: https://developer.apple.com/documentation/FamilyControls/FamilyActivityPicker "Apple Family Activity Picker"
[4]: https://developer.apple.com/documentation/managedsettings/shieldsettings/applications-swift.property "Apple Managed Settings shielded applications"
[5]: https://developer.apple.com/documentation/deviceactivity "Apple Device Activity"
[6]: https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement "Apple Family Controls entitlement"
[7]: https://support.google.com/googleplay/android-developer/answer/10964491?hl=en "Google Play AccessibilityService API policy"
[8]: https://developer.android.com/training/package-visibility "Android package visibility"
[9]: https://developer.android.com/reference/android/app/admin/DevicePolicyManager "Android DevicePolicyManager"
[10]: https://developer.apple.com/app-store/review/guidelines/ "Apple App Review Guidelines"
[11]: https://support.google.com/googleplay/android-developer/answer/10144311?hl=en "Google Play User Data policy"
[12]: https://firebase.google.com/docs/analytics/android/configure-data-collection "Firebase Analytics data collection controls"
[13]: https://docs.mixpanel.com/docs/privacy/protecting-user-data "Mixpanel protecting user data"
