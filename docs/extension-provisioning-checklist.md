# Extension Provisioning Checklist

| Check | Host | Device monitor | Shield config | Shield action |
|---|:---:|:---:|:---:|:---:|
| Explicit final bundle ID registered | [ ] | [ ] | [ ] | [ ] |
| Family Controls capability assigned for distribution | [ ] | [ ] | [ ] | [ ] |
| Shared App Group attached | [ ] | [ ] | [ ] | [ ] |
| Development profile regenerated | [ ] | [ ] | [ ] | [ ] |
| App Store profile regenerated | [ ] | [ ] | [ ] | [ ] |
| Release archive contains target | [ ] | [ ] | [ ] | [ ] |
| Signed entitlement inspection passes | [ ] | [ ] | [ ] | [ ] |
| Privacy manifest present | [ ] | [ ] | [ ] | [ ] |
| Telemetry/network SDK absent from extension | N/A | [ ] | [ ] | [ ] |
| TestFlight execution observed | [ ] | [ ] | [ ] | [ ] |

## Archive commands

```bash
codesign -d --entitlements :- Payload/Cramline.app
find Payload/Cramline.app/PlugIns -name '*.appex' -maxdepth 2 -print -exec codesign -d --entitlements :- {} \;
find Payload/Cramline.app -name PrivacyInfo.xcprivacy -print
```

Record the commit SHA, build number, Xcode version, profile UUIDs, team ID, device OS versions, and tester. Any missing or mismatched Family Controls/App Group entitlement blocks distribution.
