# Incident Runbook

## Severity 0 triggers

Immediately stop rollout for a stuck or overlong shield, inaccessible emergency/end route, false protection state, pre-consent network transmission, selected-token/app/content leak, unintended Android permission/service, entitlement/provisioning failure, or misleading store behavior.

## First 30 minutes

1. Assign incident lead and timestamp the report without copying personal payloads.
2. Stop staged rollout/release promotion.
3. Activate only a reviewed fail-open mechanism: remove/disable Cramline enforcement. Never add targets or extend sessions.
4. Preserve the exact binary, commit, dependency locks, signing/provisioning metadata, device/OS facts, and redacted network evidence.
5. Publish a calm support notice if users need a Settings/revocation route; never imply Cramline can remotely unlock an OS state it does not control.

## Investigation

Classify the boundary: host, DeviceActivity, shield extension, App Group state, authorization, telemetry SDK, AI service, StoreKit, Android manifest, or store metadata. Reproduce with fictional data. Inspect only Cramline-owned logs; do not collect selected apps/content or ask users for sensitive device data.

For privacy events, disable affected telemetry/AI egress, rotate server credentials if exposed, preserve legal evidence, and follow the approved breach-response process. For a shield defect, prioritize immediate settings cleanup and revocation guidance over schedule recovery.

## Recovery gate

A fix requires peer review, targeted automated tests, physical-device regression, exact-archive/AAB inspection, updated privacy/store disclosures, and staged rollout. Document root cause, impact, corrective action, and any residual uncertainty. Never re-enable based only on simulator success.
