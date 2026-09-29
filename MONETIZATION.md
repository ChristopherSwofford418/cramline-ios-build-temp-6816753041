# Monetization

## Free forever

- individual iOS authorization and Apple system shield;
- selected-app/web-domain scheduling;
- recurring and one-off sessions;
- Emergency pause and End today’s session;
- deterministic local planner and reflections;
- local data deletion;
- Restore Purchases;
- offline operation.

## Optional premium

Premium may fund ongoing AI planning drafts, additional non-sensitive templates, expanded local recap views, and new planning content. It must never make an active shield stricter or remove an emergency route.

## StoreKit 2 implementation

`PurchaseController` loads configured products, verifies every transaction, derives access from `Transaction.currentEntitlements`, listens to `Transaction.updates`, finishes verified deliveries, and invokes `AppStore.sync()` only from Restore Purchases.

Pending, cancelled, failed, expired, refunded, or revoked purchases affect only premium planning. Product, transaction, price, renewal, and entitlement details never enter telemetry.

## Paywall requirements

Before purchase, show localized price, billing period, renewal behavior, trial conversion where applicable, cancellation/manage route, Restore Purchases, privacy policy, and terms. Do not ship the placeholder product ID or URLs.

## Testing

Use StoreKit configuration, sandbox, and TestFlight for purchase, cancel, pending, restore after reinstall/new device, renewal, billing retry, expiration, refund/revocation, offline launch, and emergency access while premium state changes.
