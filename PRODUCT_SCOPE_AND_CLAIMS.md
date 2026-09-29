# Product Scope and Claims

## Audience and purpose

Block Your Phone to Study is a voluntary, self-directed focus tool for **adults 18+** who are **14–90 days** from a professional licensing, certification, board, admission, or qualifying exam. The age gate is a product disclosure; the app does not collect date of birth and Apple individual authorization is not an age-verification service.

## Approved iOS promise

> Put selected social and video apps behind an Apple Screen Time system shield during study sessions you choose.

Supporting statements:

- Uses individual Screen Time authorization on iOS/iPadOS 16+.
- Stores opaque system selections locally.
- Emergency pause and End today’s session are always free and reachable.
- Optional AI drafts a plan only after the user reviews fields and consents for that request.
- DeviceActivity scheduling and pause reapplication are best effort, not precision-timer guarantees.

## Approved Android promise

> Manual Focus Companion for professional-exam study sessions.

The Android v1 plans a local sprint and opens Android Settings so the adult can configure the device’s own controls. It does not block, shield, monitor, or interrupt other apps.

## Forbidden claims and designs

Never say or imply:

- unbreakable, strict mode, locks your phone, prevents uninstalling, or blocks every distraction;
- detects procrastination, reads activity/content/messages/feeds/history, or knows selected iOS app identities from picker tokens;
- diagnoses or treats addiction, ADHD, anxiety, or another condition;
- guarantees focus, exam performance, or passing;
- Android parity with iOS Screen Time shields;
- remote control, accountability-partner permission, financial penalty, paid exit, or coercive delay.

## Known contract corrections

- Apple documents a ceiling of **50 simultaneous application tokens in `ManagedSettings`**, not a picker-level maximum. The app validates after picker completion and applies none when over limit.
- Opaque category contents cannot be safety-classified. If the system picker returns a category choice, the app keeps only the category’s current concrete app/website tokens, discards the dynamic category token, applies the 50-app ceiling, and asks the user to review safety-critical apps. Category shielding itself remains disabled.
- The Shield Configuration extension may receive metadata for the item currently being shielded. The app does not retain, log, share, or analyze it.
- Emergency pause clears the app’s shield immediately and attempts to resume after 15 minutes. Exact callback timing cannot be guaranteed.
- An iOS reviewer video is strong evidence but is not described as an Apple-mandated artifact; Android Accessibility review video requirements are separate.

## Excluded markets/use cases

No parental control, school/employer monitoring, spouse/partner control, proctoring, clinical treatment, remote administration, device-owner provisioning, or public accountability leaderboard.
