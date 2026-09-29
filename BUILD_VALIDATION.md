# Build Validation — Cramline Exam Sprint 1.0 (3)

**Validated:** 2026-09-29 (UTC)
**Scope:** source-first candidate for Apple app ID `6816753041`; no App Store Connect mutation, paid build, archive upload, screenshot upload, or submission was performed.

## Candidate identity

| Field | Source-candidate value | Status |
|---|---|---|
| Display name | `Cramline Exam Sprint` (20/30) | Synchronized in Expo config, Xcode spec/project, host/shared runtime fallbacks, localized text, and release documentation. |
| Subtitle | `Study Focus & App Shield` (24/30) | Synchronized in config/localized public copy. |
| Version / build | `1.0 (3)` | Synchronized in app config, Xcode spec/project, and all four Info.plist templates. |
| Host bundle ID | `com.clearpasstechnologies.cramline` | Preserved. |
| Extension IDs / app group / StoreKit product ID | Existing `com.clearpasstechnologies.cramline.*`, `group.com.clearpasstechnologies.cramline.shared`, and `com.clearpasstechnologies.cramline.premium.monthly` | Preserved. |
| Current Apple record | `Block Your Phone to Study`, version `1.0`, `PREPARE_FOR_SUBMISSION` | Unchanged. The title change is source-only and needs owner/legal availability clearance. |

## Source fixes in this candidate

- Replaced the misleading public title **Block Your Phone to Study** with **Cramline Exam Sprint** after a fresh US exact/close-title screen; avoided the crowded `Focus Shield` and `Study Sprint` combinations. See `ASO_NAME_SCREEN.md`.
- Removed every configured `example.com` support/privacy/terms destination. URLs are now optional, HTTPS-only runtime values; when absent, the Privacy screen honestly states that each document/contact is not yet published rather than opening a fake link.
- Corrected the paywall boundary: with the production AI endpoint blank, optional AI planning and the subscription purchase/restore surface are not presented. The app no longer advertises unavailable Premium functionality; free shielding, scheduling, emergency access, deletion, and offline planning remain available.
- Shortened extension display labels and synchronized the checked-in generated Xcode project from source values (including build 3) because XcodeGen is unavailable in this sandbox.
- Retained the existing distinctive production icon: 1024×1024 RGB PNG, SHA-256 `ff505af139794dad835e58b917648f79794f02daa8f230cc620069830078cf26`.

## Finite validation results

| Check | Result |
|---|---|
| Root clean install: `npm ci --ignore-scripts` | **Passed** — 1 package audited, 0 vulnerabilities. |
| Service clean install: `pnpm --ignore-workspace install --frozen-lockfile` | **Passed** — lockfile up to date. (Plain `pnpm install` is invalid because `server/pnpm-workspace.yaml` deliberately has no `packages` field.) |
| Service type check: `pnpm --ignore-workspace check` | **Passed**. |
| Service tests: `pnpm --ignore-workspace test` | **Passed** — 3/3 Vitest tests. |
| Finite service export: `pnpm --ignore-workspace build` | **Passed** — TypeScript export completed. No watcher was started. |
| Release config lint | **Passed** — name/subtitle limits, localized-copy parity, version/build parity, immutable IDs, no configured placeholder URL, and HTTPS-only optional endpoints. |
| Privacy lint | **Passed** — no prohibited telemetry field/API, Android enforcement permission, or Screen Time extension network/telemetry source. |
| Static iOS permission/entitlement/privacy audit | **Passed** — parsed four Info.plists, all four Family Controls/app-group entitlements, two privacy manifests, and confirmed no camera/location/microphone/contact/calendar/photo/health usage-description key. |
| Checked-in Xcode project static sync | **Passed** — contains candidate title/subtitle and build 3; contains no stale build 2, prior display title, or configured `example.com` URL. |
| App metadata manifest JSON parse | **Passed** — `app-store-record.json`. |
| Source title/placeholder, affirmative-claim, secret, and whitespace scans | **Passed** — matched claim terms occur only in explicit negative disclosures. |
| Fresh US exact/close name screen | **Completed** — no exact current or candidate title API match; see `ASO_NAME_SCREEN.md`. This is not name reservation or legal clearance. |
| Expo Doctor | **Not applicable / not passed** — `npx expo-doctor@latest` reports no installed `expo` package. This is a native Swift/Xcode project using `app.json`/EAS metadata, not an Expo SDK app. No Expo dependency was added merely to force a doctor result. |
| XcodeGen prebuild | **Blocked locally** — `xcodegen: command not found`; no project generator or paid/remote build was invoked. |
| Swift package tests / Swift parse / XCUITest / iOS archive | **Blocked locally** — `swift: command not found`; this Ubuntu sandbox has no Xcode, iOS runtime, simulator, or signing/archive toolchain. |
| Physical iPhone/iPad Screen Time matrix | **Not run** — requires a signed candidate and physical devices. |

## Product-first premium pass

The source UI now applies one restrained evergreen, warm-paper, amber, and local-success system across every real SwiftUI route rather than styling only a marketing surface:

- six-step onboarding includes meaningful progress, responsive cards, truthful precommitment, permission/selection states, saving feedback, and the real `FamilyActivityPicker` handoff;
- Today includes calendar-only sprint progress (explicitly not a performance score), responsive inactive cards, active/paused/unknown states, loading feedback, and direct confirmations for emergency pause and free session end;
- Plan includes an adaptive day grid, schedule and selected-target success states, offline draft visualization, saved-plan empty state, and explicit AI-unavailable copy when the default endpoint is absent;
- Privacy includes telemetry saving/success feedback, local-data boundaries, unavailable-document states, and fail-open deletion confirmation;
- Premium includes unavailable, StoreKit loading, empty-product, product, restore, and error states without exposing purchase actions when the offer is not configured; and
- shared controls include pressed states, meaningful haptics, restrained reduced-motion-aware transitions, semantic text styles, bounded iPhone/iPad widths, and scrollable large-text layouts.

The Xcode project still targets iOS 16 and both device families, and all changed files were already included by the existing XcodeGen source globs; no generated project membership change was required. The checked-in project and `project.yml` continue to preserve host bundle ID `com.clearpasstechnologies.cramline` and all extension/app-group identifiers.

The alternate 1920×1920 generated icon was technically RGB/no-alpha, but its near-black square corners, dense neon detail, and security-gate reading were less truthful and less consistent than the existing phone/book/path mark. It was not integrated. The checked-in universal 1024×1024 iOS master remains byte-identical to the retained approved asset.

Additional finite checks for this pass:

- all 19 Swift files parsed without syntax errors using Tree-sitter Swift (syntax evidence only, not an iOS compile);
- expanded `scripts/static-release-audit.py` verifies immutable identity, both device families, 1024×1024 8-bit RGB/no-alpha icon structure and manifest, required truth boundaries, responsive source patterns, and named XCUITest coverage;
- service `pnpm --ignore-workspace check`, 3/3 Vitest tests, and finite TypeScript build passed; and
- root `npm test` is not defined, while XcodeGen/Xcode/Swift/XCUITest execution remains blocked by the Ubuntu toolchain.

## Screenshot and asset boundary

**0 screenshots were created.** The prior audit documented no existing complete App Store screenshot family, so nothing was deleted, replaced, or uploaded. This sandbox has no runnable signed iOS app, simulator, or physical device; creating mockups, screenshots from static source, or design-reference images would violate the requirement that screenshots come from the actual running UI. Required capture is therefore blocked until a signed physical candidate is available. Use the real UI sequence in `ASO.md` and include the real Apple `FamilyActivityPicker` only.

## Release blockers

1. **Published legal/support URLs:** owner must supply, publish, configure, and test HTTPS Support, Privacy Policy, and Terms URLs; `app-store-record.json` truthfully records them as `null`.
2. **Name/legal clearance:** owner must clear `Cramline Exam Sprint` for trademark and final App Store Connect availability, then intentionally update the existing Apple record. No reservation has been made.
3. **Store metadata:** App Store version needs the final description, keywords, What’s New, support URL, age rating, content-rights declaration, price/availability, and screenshot families.
4. **StoreKit and AI:** product configuration/approval, price/localization, purchase/restore/expiration/refund testing, secure production endpoint, abuse controls, vendor/privacy proof, and disclosure review are absent. AI remains off in source by default.
5. **Native and device evidence:** macOS Xcode/XcodeGen compile, unit/UI tests, signed archive entitlement inspection, packet/queue privacy audit, accessibility validation, and the complete physical Screen Time matrix are mandatory.
6. **Actual screenshots:** capture 6–8 professional screens from the signed, running iPhone/iPad candidate; never recreate Apple system UI or use source/design mockups.

## Release decision

**Not release-ready.** The source candidate is safe to hand to the owner for native/device validation, but must not be archived, uploaded, or submitted until every blocker above is closed.
