# Android Companion Boundaries

## Shipping v1

`android-companion/` is a **manual focus companion**. It stores a sprint choice locally, explains Android’s own Digital Wellbeing controls, and opens Settings. Its manifest requests no package inventory, usage, notification, accessibility, overlay, or device-admin permission.

Approved title: **Cramline Manual Focus Companion**  
Approved promise: **Plan a study session and set Android focus limits yourself.**

## Explicitly absent

- no `QUERY_ALL_PACKAGES`;
- no `PACKAGE_USAGE_STATS` or UsageStats;
- no `DevicePolicyManager` package suspension;
- no AccessibilityService in the shipping manual companion;
- no notification, URL, content, keystroke, node-tree, or browser-history access;
- no iOS shield screenshots or “app blocker/system shield” copy.

## Optional Interruption Beta

Do not add this service to the public binary until the exact AAB passes policy review and physical-device QA. If pursued:

- finite local supported-package allowlist;
- `AccessibilityServiceInfo.packageNames` filtering;
- only `TYPE_WINDOW_STATE_CHANGED` as a best-effort trigger;
- `canRetrieveWindowContent=false`, `canPerformGestures=false` in XML;
- never call event text/class/source/record or window/node APIs;
- a small branded, non-system-imitating card only after an eligible event;
- Return to study, Emergency pause, and End session;
- every error, disabled service, process death, or OEM limitation fails open.

The beta is not an accessibility tool and must use the non-tool declaration plus prominent disclosure, affirmative consent, accurate listing, privacy/Data Safety declarations, review video, exact-binary Play review, and TalkBack/OEM testing.

## Release checks

Run `scripts/privacy-lint.sh`, inspect the merged manifest/AAB, and verify prohibited permissions are not introduced transitively. Maintain distinct Android store text and screenshots.
