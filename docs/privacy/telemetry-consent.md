# Telemetry Consent

## Exact copy

> Help improve Block Your Phone to Study with anonymous usage and crash information. We never send selected apps, app activity, social content, messages, browser history, your exact schedule, exam details, reflections, or identity. Saying no does not change your study shield.

Offer this in Privacy Settings and, at most once, after core setup. Never place it inside authorization, picker, precommitment, active session, emergency, AI, purchase, restore, or deletion flows.

## State machine

| Local state | Firebase Analytics | Crashlytics | Mixpanel | Core product |
|---|---|---|---|---|
| Not asked/declined | Static default-off | Static default-off | Not initialized | Fully available |
| Enabled | Disabled in strict compliance mode unless archive exception approved | Opt-in setting; documented to take effect next launch | Initialized with automatic events/IP geo/flags/replay off | Fully available |
| Disabled after enabled | Gate immediately; disable/reset local data | Disable for next launch; delete unsent reports | Opt out, clear queue, reset, discard ID | Fully available |

Do not transmit a `state=disabled` event after withdrawal; store that evidence locally. An enabled event may be sent only after consent.

## Firebase exception

Firebase Analytics documents automatic events when enabled and no public switch was verified to restrict it to only the app’s manual allowlist. Therefore `CRAMLINE_FIREBASE_ANALYTICS_ALLOW_AUTOMATIC_EVENTS` defaults to `NO`. Turning it on requires a recorded policy decision, updated consent/privacy language, and exact-release packet/event inventory.

Crashlytics’ runtime collection setting applies on the next run, so do not promise unconditional immediate current-process opt-out. The implementation still gates app calls immediately and deletes unsent reports.
