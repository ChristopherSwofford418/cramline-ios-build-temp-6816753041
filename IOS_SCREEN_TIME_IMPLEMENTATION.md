# iOS Screen Time Implementation

## Targets

| Target | Responsibility | Network/telemetry |
|---|---|---|
| `Cramline` | SwiftUI flow, authorization, picker, scheduling, local state, StoreKit, optional AI/telemetry | Main app only, consent-gated |
| `CramlineDeviceActivityMonitor` | Apply/clear named shields at interval callbacks | None |
| `CramlineShieldConfiguration` | Generic shield title, end time, buttons | None |
| `CramlineShieldAction` | Close shielded app or clear shield for emergency pause | None |

All four use the Family Controls capability. Targets that share state use the same App Group.

## Authorization and selection

1. Explain capability, limits, revocation, and emergency access.
2. Call `AuthorizationCenter.shared.requestAuthorization(for: .individual)` only after a user tap.
3. Treat every status except `.approved` as unavailable.
4. Present `FamilyActivityPicker` after approval.
5. Initialize the picker selection with `includeEntireCategory: true` so an accidental or intentional category choice produces its current concrete app and website tokens.
6. On picker dismissal, rebuild the selection from only `applicationTokens` and `webDomainTokens`; never persist or enforce a dynamic category token.
7. Persist the normalized `Codable` opaque selection in App Group `UserDefaults` and reject more than 50 resulting application tokens before enforcement.
8. On revocation, clear shields/monitors/selection and require a new picker flow.

## Scheduling

- A stable `DeviceActivityName` is created for each enabled window/day pair.
- Repeating schedules use local weekday/hour/minute components.
- Sprint bounds are stored separately because `DeviceActivitySchedule` has no repeat-until date.
- The monitor fails open outside the sprint and clears its named store.
- One-off sessions apply the shield immediately in the host, then register a nonrepeating monitor.
- Overlap bookkeeping records active Cramline monitor names; the final ending monitor clears settings.
- App foregrounding rechecks authorization. Release hardening must also reconcile center activities and time-zone/calendar changes on physical devices.

## Shield application

The selection is passed directly to:

- `ManagedSettingsStore.shield.applications` for at most 50 application tokens;
- `ManagedSettingsStore.shield.webDomains` for user-selected web-domain tokens;
- category shielding is deliberately `nil` in v1.

No token is converted to a name, logged, uploaded, placed in telemetry, or sent to AI.

## Emergency pause

The host and Shield Action extension both:

1. call `clearAllSettings()` on Cramline’s named store first;
2. write `pauseUntil = min(now + 15 minutes, plannedEnd)`;
3. best-effort register a nonrepeating resume interval;
4. remain fail-open if re-registration fails.

`Return to study` maps to the system `.close` response. It closes the shielded surface; it is not an arbitrary deep link.

## State language

UI values are `Scheduled`, `Active`, `Paused`, `Cannot apply—authorization needed`, `Ended`, and `State unknown`. “Active” describes Cramline’s requested state, not independently observed proof that every system surface is shielded.

## Mandatory real-device spike

Prove on supported iPhone and iPad models:

- development and distribution authorization;
- 0/1/5/50/51 token behavior;
- recurring, one-off, overlap, reboot, termination, DST, and travel;
- shield presentation and both actions;
- immediate pause, best-effort resume, end, revoke, uninstall/settings exit;
- TestFlight archive entitlements for every extension.
