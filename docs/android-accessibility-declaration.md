# Android Accessibility Declaration

## Current shipping state

The manual companion does **not** contain or request an AccessibilityService. This document is a gated template for a future exact-binary **Interruption Beta** and must not be submitted for the manual-only build.

## Core purpose statement

The optional service would support a user-started professional-exam study session by detecting a window-state event from one of a finite set of supported apps the user selected and showing a local Cramline interruption card. It would not block the app, inspect content, automate taps, change settings, monitor general use, or operate for another person.

## Prominent disclosure

> Optional Study Interruption Beta uses Android's AccessibilityService only during study sessions you start. It receives window-state events from the specific supported apps you select to detect that one has opened. Cramline uses that fact on your device to show its interruption card. It does not read or save on-screen text, messages, passwords, notifications, browser history, or app-usage history, and does not share accessibility-event data. You can turn this service off in Android Settings at any time.

This standalone disclosure must immediately precede an unchecked affirmative consent and the Android Settings enablement intent.

## Binary assertions

The service XML must set `canRetrieveWindowContent=false`, `canPerformGestures=false`, and `isAccessibilityTool=false`. Runtime `AccessibilityServiceInfo` must limit `packageNames` to the active finite local allowlist and `eventTypes` to the minimum approved type. Code must not call event text, class, source, records, windows/root, focus, gesture, key, global-action, or content APIs.

## Review package

Submit the exact AAB, declaration, disclosure/consent capture, accurate listing, privacy policy/Data Safety answers, and a video showing accept/decline, Settings enablement, interruption, pause/end, disable, and fail-open behavior. Public distribution requires Play review permission for that track plus physical TalkBack/OEM and no-leak evidence.
