# Release Checklist

## Product and legal

- [ ] Final brand, bundle/package IDs, product IDs, domains, support, privacy, and terms cleared.
- [ ] iOS and Android claim sheets approved; Android does not reuse shield/blocker claims.
- [ ] Adult-only, voluntary self-management, no-clinical/no-guarantee boundaries visible.

## iOS capability and build

- [x] Team ID, four explicit App IDs, shared App Group, and Family Controls development capability configured.
- [x] App Store Connect Apple ID `6816753041` bound to `com.clearpasstechnologies.cramline`; English ASO name, subtitle, and categories configured.
- [x] Public iOS name **Block Your Phone to Study**, subtitle, version `1.0 (2)`, and 1024×1024 AppIcon configured.
- [x] Manual macOS TestFlight archive/upload workflow and export options validated without embedded credentials.
- [x] Family Controls distribution approved for host and all three extensions.
- [x] App Group and App Store provisioning match every signed target in TestFlight build `1.0 (2)`.
- [x] Xcode 26.6 picker-fix archive uploaded; Apple build `87d5c0b0-f862-46b8-9480-ca34629e5778` processed as **VALID** and is the only build assigned to the private Internal Testers group.
- [ ] Exact archive passes `docs/extension-provisioning-checklist.md`.
- [ ] Physical iPhone/iPad and TestFlight matrix passes.
- [ ] 0/1/5/50/51 app handling, app-row selection, category-to-current-token conversion, websites, revocation, DST/travel/reboot/overlap pass.
- [ ] Emergency pause, best-effort resume, end, deletion, and unknown/fail-open state pass.

## Privacy and security

- [ ] Mixpanel/Firebase SDK versions and transitive dependencies pinned/inventoried.
- [ ] Cold-install pre-consent packet capture shows approved behavior.
- [ ] Consent enable/disable/delete/relaunch/offline-reconnect queue and ID tests pass.
- [ ] Firebase automatic-event exception remains off or has a signed policy decision and updated disclosures.
- [ ] Extensions link no telemetry/network SDK and emit no traffic.
- [ ] Privacy manifests, App Privacy labels, privacy policy, retention/deletion text match exact archive.
- [ ] AI endpoint has TLS, dynamic model catalog, schema validation, no body/output logs, rate limiting/App Attest, vendor/legal review, and no-retention evidence—or remains disabled.

## Billing

- [ ] StoreKit products approved and localized terms complete.
- [ ] Verified purchase, pending/cancel, update, restore, expiration/refund/revocation tests pass.
- [ ] Shielding, schedule, emergency, deletion, offline use, and restore are not paywalled.

## Accessibility

- [ ] VoiceOver, Voice Control, Switch Control, Dynamic Type, contrast, reduce motion, keyboard, and non-color status pass.
- [ ] Emergency, end, deletion, authorization/revocation, and restore remain reachable.

## Android manual companion

- [ ] Exact AAB contains no `QUERY_ALL_PACKAGES`, UsageStats, Device Admin, AccessibilityService, overlay, or content permission.
- [ ] OEM/manual Settings guidance, offline, accessibility, and fail-open tests pass.
- [ ] Manual-companion listing/screenshots and Data Safety answers match the binary.

## Submission and operations

- [ ] Reviewer notes, optional iOS evidence video, Android materials, support contact, and escalation owner ready.
- [ ] Staged rollout and kill/rollback plan approved.
- [ ] No Severity 0 issue remains open.
- [ ] Release owner signs date, commit SHA, archive/AAB hashes, and evidence location.
