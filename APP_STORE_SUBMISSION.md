# App Store Submission

## Registered Apple configuration

| Item | Value |
|---|---|
| Team ID | `W356BF2Y83` |
| App Store Apple ID | `6816753041` |
| SKU | `CRAMLINE-IOS-2026` |
| Main Bundle ID | `com.clearpasstechnologies.cramline` |
| Device Activity extension | `com.clearpasstechnologies.cramline.deviceactivity` |
| Shield Configuration extension | `com.clearpasstechnologies.cramline.shieldconfiguration` |
| Shield Action extension | `com.clearpasstechnologies.cramline.shieldaction` |
| Shared App Group | `group.com.clearpasstechnologies.cramline.shared` |
| Source-candidate display name | **Cramline Exam Sprint** |
| Source-candidate subtitle | **Study Focus & App Shield** |
| Categories | **Productivity** primary; **Education** secondary |

Every target has the App Group and Family Controls **development** capability configured in Apple Developer. Distribution entitlement approval remains a release blocker.

> **Apple record boundary:** the current App Store record still uses its prior title, **Block Your Phone to Study**. The title/subtitle above are source-only recommendations; no Apple record, availability, price, screenshot, build, or submission mutation was performed.

## Metadata boundary

Cramline Exam Sprint is an adult self-management Productivity app. The listing must explain that iOS applies a revocable Screen Time shield after individual authorization. Do not imply an unbreakable lock, surveillance, clinical treatment, exam guarantee, or Android parity.

## Reviewer notes template

> Cramline Exam Sprint uses Apple’s Screen Time APIs for voluntary individual self-control. No parent, school, employer, or third party controls the device. In onboarding, confirm 18+, choose a 14–90 day sprint, review the precommitment disclosure, grant individual Family Controls authorization, and select individual test apps in Apple’s FamilyActivityPicker. Start a one-off session from Today, open a selected app to view the shield, use Return to study or Emergency pause, and use End today’s session in the app. Revoke permission in Settings to verify the fail-open state. No account is required. Telemetry is off by default. Shielding, emergency access, deletion, and offline planning are free. Do not enable or mention AI/Premium until a secure production service and approved StoreKit product are configured and tested.

Provide a review contact, current support/privacy/terms URLs, non-expiring test guidance, product configuration, and physical-device video as helpful evidence without claiming Apple mandates the video.

## Submission evidence

| Area | Required proof |
|---|---|
| Capability | Approved Family Controls distribution capability for host and every extension |
| Signing | Entitlement-bearing archive, provisioning profiles, embedded `.appex` inspection |
| Core flow | Authorization, picker, 0/1/5/50/51 handling, schedule, shield, pause, end, revoke |
| Privacy | Default-off cold install, consent transitions, queue purge, extension silence, privacy report |
| Billing | StoreKit product approval, purchase, pending/cancel, restore, expiration/refund |
| Accessibility | VoiceOver, Dynamic Type, contrast, switch/voice/keyboard paths |
| Support | Published privacy, terms, support contact, deletion and revocation guidance |

## Hard blockers

Do not submit the shield build until Family Controls approval, physical iPhone/iPad proof, TestFlight archive validation, exact-archive network/privacy audit, functional IAP/restore, and support/privacy URLs are complete. Stop rollout for stuck shielding, inaccessible emergency access, false state, or unauthorized collection.
