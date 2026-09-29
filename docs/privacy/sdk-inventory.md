# SDK and Framework Inventory

| Component | Version/source | Target | Data/network role | Owner/review |
|---|---|---|---|---|
| SwiftUI/Foundation | iOS SDK | Host/extensions/core | UI and local data | Apple platform |
| FamilyControls | iOS SDK | Host/shared extensions | Individual auth and opaque selection | iOS/privacy |
| ManagedSettings | iOS SDK | Host/extensions | Named shield configuration | iOS/safety |
| DeviceActivity | iOS SDK | Host/monitor/action | Best-effort schedules | iOS/QA |
| ManagedSettingsUI | iOS SDK | Shield configuration | Generic shield UI | iOS/accessibility |
| StoreKit 2 | iOS SDK | Host | Purchase/restore/entitlement | Billing |
| FirebaseAnalyticsCore | 12.19.2 | Host only | Compiled; strict mode disabled | Privacy/release |
| FirebaseCrashlytics | 12.19.2 | Host only | Opt-in crash diagnostics | Privacy/release |
| Mixpanel | 6.7.0 | Host only | Opt-in allowlisted events | Privacy/release |
| Express | lockfile | Planning server | HTTPS request routing | Backend/security |
| Zod | lockfile | Planning server | Strict request validation | Backend/privacy |
| AndroidX Compose | BOM 2025.08.01 | Android companion | Local UI only | Android |

No advertising, attribution, session replay, remote experiment, behavioral messaging, social, account, database, location, notification, accessibility, usage-stats, or broad package-inventory SDK is included.

At every dependency update, regenerate this inventory from lockfiles and the final archive/AAB, inspect privacy manifests/signatures, run traffic capture, and repeat the source/binary policy checks.
