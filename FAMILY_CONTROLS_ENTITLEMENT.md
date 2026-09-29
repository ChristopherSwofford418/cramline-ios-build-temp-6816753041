# Family Controls Entitlement

## Distribution status

Apple’s managed Family Controls distribution capability was requested and assigned to the host app and every shipping Screen Time extension on 2026-09-28. Version **1.0 (2)** was signed with the resulting App Store profiles, uploaded, and marked **VALID** in TestFlight.

## Registered identifiers

| Target | Apple identifier |
|---|---|
| Main app | `com.clearpasstechnologies.cramline` |
| Device Activity monitor | `com.clearpasstechnologies.cramline.deviceactivity` |
| Shield Configuration | `com.clearpasstechnologies.cramline.shieldconfiguration` |
| Shield Action | `com.clearpasstechnologies.cramline.shieldaction` |
| App Group | `group.com.clearpasstechnologies.cramline.shared` |

The App Group plus Family Controls **development and distribution** capabilities are configured on all four App IDs. The separate **Family Controls App and Website Usage** capability is intentionally disabled because Block Your Phone to Study does not collect usage reports.

## Completed procedure

1. [x] Submit Apple’s Family Controls distribution request for the host and every extension.
2. [x] Confirm distribution capability assignment on all four identifiers.
3. [x] Generate App Store profiles containing the managed capability and App Group.
4. [x] Archive source commit `c2a9bc7f8671b7193aa0e724bae161ab27ce1d2c` with Xcode 26.6 distribution signing.
5. [x] Upload version **1.0 (2)** and confirm Apple processing state **VALID**.
6. [ ] Install through TestFlight and execute the reviewer flow on physical iPhone and iPad devices.

## Evidence to retain

- Apple capability approval correspondence/state;
- identifier and App Group screenshots/export;
- provisioning profile UUIDs and expiration dates;
- `codesign -d --entitlements :-` output for host/extensions;
- archive build number and commit SHA;
- physical-device and TestFlight results;
- reviewer instructions and support contact.

## Failure state

If approval, signing, authorization, or extension provisioning is missing, do not market or distribute the shield. Show:

> Block Your Phone to Study can’t apply your study shield until Screen Time permission is enabled again.

Never replace the system flow with a fake authorization screen.
