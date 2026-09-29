# AI Planning Boundary

## Role

AI is an optional, user-invoked drafting assistant. It never observes app usage and never starts, stops, extends, resumes, or overrides a shield. The deterministic `RuleBasedPlanner` is the complete offline fallback.

## Allowed request fields

- sprint end date;
- broad study domain;
- desired weekly study hours;
- preferred days/start times and maximum session lengths;
- optional self-reported confidence;
- explicit consent acknowledgement.

The server uses a strict schema and rejects unknown keys. Selected tokens/apps, device identity, exact enforcement state, activity/content, messages, history, screenshots, clipboard, credentials, and reflections are not representable.

## Per-request consent

Before every hosted request, the app shows:

> Send this planning request to AI? Block Your Phone to Study will send only the plan details shown here. It will not send selected apps, app activity, messages, social content, browser history, or device identity.

Nothing is sent until the user taps the affirmative button. The response remains an unsaved draft until reviewed and saved.

## Server behavior

`server/`:

1. validates a maximum 16 KB JSON body;
2. calls `listLLMModels()` against the live model catalog;
3. prefers `gpt-5-mini` when available and otherwise selects the lowest-priced catalog entry;
4. requests strict JSON-schema output;
5. adds local UUIDs to draft sessions;
6. sends `Cache-Control: no-store` and logs no request body or model output;
7. returns a generic unavailable error with the on-device fallback.

Model credentials exist only in server environment variables. The client contains only a configurable service URL.

## Deployment choices

| Approach | Tradeoffs | Cost | Setup Complexity |
|---|---|---:|---:|
| Leave hosted AI disabled | Fully private/offline; premium AI unavailable while rules planner remains complete | None | Low |
| Deploy the supplied stateless service | Enables opt-in drafts; requires secret management, abuse protection/App Attest, privacy review, and operating budget | Usage-based | Medium |

Do not enable the production endpoint until transport security, rate limiting/App Attest, deletion language, vendor terms, and packet inspection pass release review.
