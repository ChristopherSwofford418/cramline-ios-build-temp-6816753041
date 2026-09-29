# Telemetry Data Map

All application-originated events use one enum property. Arbitrary dictionaries fail validation.

| Event | Allowed property/value | Purpose | Destinations after consent |
|---|---|---|---|
| `telemetry_consent_changed` | `state=enabled` only in transmitted practice | Consent audit | Mixpanel; Firebase only if exception approved |
| `onboarding_completed` | `entry=rules_planner|ai_planner` | Funnel count | Same |
| `sprint_action` | `action=sprint_created|schedule_created|session_started|session_ended|local_data_deleted` | Aggregate feature use | Same |
| `screen_time_authorization_result` | `result=granted|declined|revoked` | Authorization reliability | Same |
| `emergency_action` | `action=pause_used|session_ended` | Safety-route reliability | Same |
| `android_beta_action` | Fixed companion/beta enum | Future Android beta audit | Not used by manual companion |
| `purchase_flow_action` | Fixed view/start/complete/restore enum | Billing flow reliability | Same |
| `app_operational_error` | Fixed owner-reviewed category | Aggregate reliability | Same |

## Forbidden payloads

Selected tokens/apps/packages/categories/websites, installed inventory, app activity/content, exact dates/times/time zone/duration, location, study plan, reflection, shield copy, accessibility event, AI prompt/output, product/transaction/price/renewal data, contact/account/device/advertising identifiers, free-text errors, logs, attachments, screenshots, user properties, and profiles.

## Vendor-originated data

Mixpanel uses an analytics-only random identifier and is configured without IP geolocation, automatic events, feature flags, replay, People, Groups, or identify calls. Crashlytics may process stack, app, OS, and device diagnostics after opt-in. Firebase/Google transport behavior must be verified from the exact archive; privacy labels cover actual conditional collection even when optional.
