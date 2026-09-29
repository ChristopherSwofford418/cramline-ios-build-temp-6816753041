# Accessibility

## Supported behavior

The SwiftUI host uses platform controls, semantic text styles, labels plus non-color status wording, dynamic layout, and no visual-only countdown. Required validation covers VoiceOver, Voice Control, Switch Control, Dynamic Type through accessibility sizes, increased contrast, reduced motion, keyboard on iPad, and landscape.

Critical actions use explicit accessible labels/hints:

- Screen Time authorization and picker;
- start/end session;
- Emergency pause — 15 minutes;
- local deletion;
- permission-revocation guidance;
- Restore Purchases.

No critical route depends on gesture-only interaction, small icon-only controls, color, animation, AI, network, or telemetry.

## Content rules

- Calm, literal, non-shaming language.
- State labels: Scheduled, Active, Paused, Cannot apply—authorization needed, Ended, State unknown.
- Dates/times use localized formatters and always expose the local time zone.
- Large text may scroll; controls remain reachable and do not overlap the tab bar or safe areas.
- Shield copy is concise because the system surface is constrained.

## Android

The manual companion uses standard Compose controls and content descriptions. If a future AccessibilityService beta is proposed, it must coexist with TalkBack and other services, request no touch exploration/gesture/key access, avoid stealing focus, and pass the separate physical-device matrix before release.

## Acceptance matrix

Test each critical flow with VoiceOver/TalkBack enabled, maximum text size, high contrast, reduced motion, portrait/landscape, external keyboard where applicable, offline state, and denied/revoked permission. Any inaccessible emergency or deletion route is a release blocker.
