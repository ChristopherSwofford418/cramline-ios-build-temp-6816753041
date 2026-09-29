# Local Data and Privacy

## Local-first model

No account is required. The main app writes sprint, windows, sessions, local plans, reflections, and consent state to an app-support JSON file using complete file protection unless open. The App Group stores only opaque Screen Time selection data and minimum extension state.

| Data | Location | Leaves device by default | Delete behavior |
|---|---|---:|---|
| Sprint/domain/time zone | Protected app storage | No | Removed |
| Study windows/sessions | Protected app storage | No | Removed |
| Apple selection tokens | App Group preferences | No | Removed/void after revocation |
| Plans/reflections | Protected app storage | No | Removed |
| Telemetry consent/ID | Main app preferences | Only allowlisted events after opt-in | Disabled, queue-purged, ID removed |
| StoreKit entitlement | Apple APIs/local derived state | StoreKit-controlled | Not treated as app analytics |
| AI request | Ephemeral HTTPS request after consent | Allowed fields only | Server reference stores nothing |

## Never collected by Block Your Phone to Study

Contact details, exact exam/provider/score, employer/school, address/location, advertising ID, installed-app inventory, selected token identity, app usage/content, notifications, messages, browser history, health/biometric/financial data, credentials, clipboard, and accessibility content.

The Shield Configuration extension may receive OS metadata for a currently shielded item. It uses generic copy and does not retain, log, share, or analyze that metadata.

## Deletion order

1. clear the app’s shields;
2. stop the app’s DeviceActivity monitors;
3. erase App Group selection/session/sprint policy;
4. disable telemetry and purge local vendor queues/IDs as supported;
5. delete the protected local state file;
6. return to onboarding.

Deletion and emergency controls work offline.

## Release caveat

App Store privacy answers must describe conditional opt-in analytics/crash data based on the exact archive and observed network traffic. A privacy manifest is not a substitute for App Privacy labels.
