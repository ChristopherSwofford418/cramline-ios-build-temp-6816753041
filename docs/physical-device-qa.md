# Physical Device QA

Source/CI checks are not release evidence for Screen Time or Android OEM behavior. Record model, OS/build, install source, account state, time zone, test date, tester, expected result, actual result, logs/network capture location, and pass/fail for every row.

## iPhone/iPad matrix

| Area | Scenarios | Required devices |
|---|---|---|
| Entitlement | development, Ad Hoc, TestFlight distribution | Current minimum iPhone/iPad and current OS device |
| Authorization | grant, deny, biometric/passcode cancel, revoke, reauthorize | iPhone + iPad |
| Picker | 0, 1, 5, 50, 51 apps; app-row selection; category-to-current-token conversion with no saved category rule; website selection; persistence/reselection | iPhone + iPad |
| Schedule | recurring, one-off, overlap, cross-midnight, DST, travel/time-zone change | Minimum/current OS mix |
| Lifecycle | lock/unlock, inactive device, background, force quit, reboot, extension restart | iPhone + iPad |
| Shield | selected test app/site, unselected safety/work/exam app, generic copy, large text | iPhone + iPad |
| Emergency | shield secondary action, host pause, resume attempt, end, failure/unknown state | iPhone + iPad |
| Privacy | cold install, denied, opt-in, opt-out, delete, offline/reconnect, packet capture | Exact archive |
| StoreKit | buy, pending, cancel, restore, reinstall/new device, expiration/refund | Sandbox + TestFlight |
| Accessibility | VoiceOver, Voice Control, Switch Control, Dynamic Type, contrast, reduce motion, keyboard | iPhone + iPad |

A stuck shield, inaccessible exit, false Active state, pre-consent egress, or token/content leak is an immediate fail-open/stop-rollout defect.

## Android manual companion matrix

Test representative Google, Samsung, and one additional OEM across minimum/current Android versions. Verify adult disclosure, 14/90-day bounds, local plan, Settings handoff, offline behavior, TalkBack, Voice Access/Switch Access where available, large text, rotation, process death, and that the merged manifest contains none of the prohibited permissions.

## Future Accessibility beta

Add exact-AAB tests for disclosure accept/decline, enable/disable, finite package filter, content-bearing synthetic events, no text/node access, small card behavior, pause/end, reboot, battery management, TalkBack coexistence, incoming call/emergency/system Settings, overlay failure, and every fail-open path. Do not infer results from the manual build.
