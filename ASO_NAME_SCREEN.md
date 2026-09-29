# US App Store Name Screen — 2026-09-29

## Method

A fresh, read-only screen used Apple’s public [iTunes Search API](https://itunes.apple.com/search) with `country=us`, `entity=software`, and `limit=200`. Raw point-in-time output is retained outside the repository at `/home/ubuntu/jobs/6f59f28ee2a1_a0/itunes-us-name-screen.json`; it is **not** a name reservation, trademark search, or App Store Connect availability check.

| Query | Exact `trackName` match | Relevant result / risk |
|---|---:|---|
| `Block Your Phone to Study` | None | No exact API hit, but the generic verb phrase overstates the source behavior: the app explicitly does **not** lock the phone. |
| `Cramline Exam Sprint` | None | No `Cramline` or `Cramline Exam Sprint` title appeared in the returned US results. |
| `Exam Sprint Focus Shield` | None | The query returns dense focus-app competition and a `Focus Shield`-named result; do not adopt it. |
| `Focus Shield` | None | Returned `Focus Shield-App Blocker`, `App Blocker: Mind Focus Shield`, `Privacy Defender: Focus Shield`, and `Event Horizon: Focus Shield`. |
| `Study Sprint` | None | Returned `Study Sprint Timer` and `Amino Acid Quiz: Study Sprint`. |
| `Cramline` | None | Returned nearby generic `Cram`/exam-prep names, but no `Cramline` title. |

A canonical US listing, [Focus Shield-App Blocker](https://apps.apple.com/us/app/focus-shield-app-blocker/id6748439429), confirms that `Focus Shield` is an especially crowded and confusingly close descriptor. A separate `Study Sprint Timer` listing also exists in Apple search results. The prior suggested title **Exam Sprint Focus Shield** is therefore rejected despite having no exact match.

## Decision

**Use `Cramline Exam Sprint` as the source-candidate display name (20/30 characters) and `Study Focus & App Shield` as the subtitle (24/30 characters).**

This change is warranted because it:

1. replaces the misleadingly broad “Block Your Phone” language with a name consistent with the app’s explicit, revocable Screen Time shield behavior;
2. uses the established source namespace `Cramline` (target, bundle namespace, package, local storage) plus the implemented 14–90 day exam-sprint flow; and
3. avoids the crowded `Focus Shield` and `Study Sprint` phrase combinations.

The public name is synchronized in `app.json`, `project.yml`, the checked-in Xcode project, runtime fallback, localized copy, extension labels, ASO documentation, and submission guidance. Registered bundle IDs, app-group identifier, StoreKit product ID, EAS project ID, Expo slug, team, Apple ID, SKU, version, and build number are unchanged.

## Owner gates

The current Apple record has **not** been mutated and remains **Block Your Phone to Study**. Before changing that record, the owner must complete App Store Connect availability and trademark/legal clearance. This screen is only point-in-time discovery evidence.
