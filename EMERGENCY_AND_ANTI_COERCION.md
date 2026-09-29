# Emergency Access and Anti-Coercion

## Non-negotiable controls

During every active session the host app exposes:

- **Emergency pause — 15 minutes**;
- **End today’s session**;
- system-level permission revocation and normal app deletion remain available.

The shield shows Return to study plus Emergency pause where the OS surface supports it. These routes require no payment, quiz, countdown, reflection, contact, passcode held by another person, or justification.

## Technical sequence

Pause clears the app’s named `ManagedSettingsStore` before attempting any follow-up. It then stores a local pause deadline and best-effort registers a resume interval. Because DeviceActivity is not a precision timer, UI and store copy must not promise exact reapplication. A registration/callback uncertainty leaves the target usable and reports `State unknown`.

End and local deletion clear settings, stop the app’s monitoring names, and remove shared session/selection state. Subscription expiry or network failure never participates.

## Prohibited patterns

No strict mode, remote commands, third-party passcode, public accountability, cash stake/forfeit, paid escape, forced delay, shame copy, hidden settings, uninstall prevention, or escalation.

## Safety kill switch

A future signed kill switch may only disable this app’s enforcement for a verified safety/security issue. It must never add targets, lengthen sessions, alter consent, or hide itself. The present repository contains no remote kill-switch mechanism.

## Incident trigger

Stop rollout and fail open for a stuck shield, inaccessible emergency route, false Active state, unauthorized data transmission, token/content leak, or entitlement/review concern. Follow `docs/incident-runbook.md`.
