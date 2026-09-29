# TestFlight Release Status

**Release date:** 2026-09-28

## Current result

Version **1.0 (2)** of **Block Your Phone to Study** was archived with Xcode 26.6, uploaded to App Store Connect, processed by Apple, and marked **VALID** for TestFlight. It supersedes build 1 in the private internal testing group.

| Item | Verified value |
|---|---|
| App Store Connect Apple ID | `6816753041` |
| Bundle ID | `com.clearpasstechnologies.cramline` |
| Version/build | `1.0 (2)` |
| Source commit | `b3e65e84043df6d8f25f9dd082c4f4ec8f81c4e8` |
| EAS build | [`835e0ae8-5a28-4050-9fd2-79cb2aadf668`](https://expo.dev/accounts/cswofford/projects/block-your-phone-to-study/builds/835e0ae8-5a28-4050-9fd2-79cb2aadf668) — **FINISHED** |
| EAS submission | [`92da2928-6288-4c64-a09a-3cd8eb403720`](https://expo.dev/accounts/cswofford/projects/block-your-phone-to-study/submissions/92da2928-6288-4c64-a09a-3cd8eb403720) — **FINISHED** |
| Apple build resource | `87d5c0b0-f862-46b8-9480-ca34629e5778` — **VALID** |
| Minimum OS | iOS/iPadOS 16.0 |
| Export compliance | Uses non-exempt encryption: **No** |

## Picker correction in build 2

Build 1 initialized `FamilyActivitySelection` without category expansion. On the reported device, the Apple picker could therefore return a category token while the concrete application-token set remained empty, leaving the app count at zero and showing the unsupported-category warning.

Build 2:

1. initializes the system picker with `includeEntireCategory: true`;
2. lets Apple resolve a category choice into its current concrete app and website tokens;
3. rebuilds the result from only those concrete tokens when the picker closes;
4. never saves or applies a dynamic category token;
5. retains the 50-application ceiling and safety-review copy.

This corrects both onboarding and the post-onboarding target editor.

## Internal TestFlight distribution

The private **Internal Testers** group contains only build **2**. Build 1 was removed from the group to prevent confusion. The account-holder tester state is **INSTALLED**, and the group has no public link.

English “What to Test” notes for build 2:

> Fixes target selection. Verify selecting any individual app updates the count and enables Continue. If a category is selected, confirm it is converted to its current apps/websites and no dynamic category rule remains. Recheck 50-app limit, saving, scheduling, shields, emergency pause, and immediate end.

Open the build in [App Store Connect TestFlight](https://appstoreconnect.apple.com/apps/6816753041/testflight/ios).

## Remaining device evidence

Apple-framework compilation, signing, upload, and processing passed. The picker correction still needs confirmation on the reporting iPhone: install build 2, reopen Apple’s picker, select an app, close the picker, and confirm the selected count is nonzero and **Continue** is enabled. Complete the broader physical-device matrix before App Store review.
