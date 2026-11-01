# Bin Day NZ

A native iPhone and iPad bin-day reminder for households using Auckland Council kerbside services. The app stores a schedule on the device, shows upcoming collections, and offers notifications, widgets and optional calendar integration.

The local candidate is **1.2 (3)**. This repository does not establish what is currently installed from the App Store. Build success is not release approval; see the [release checklist](docs/release-checklist.md).

## Product boundaries

- Confirm the schedule for the exact property using the council source. A map result is an address suggestion, not confirmation of collection service. User-entered schedules are labelled separately.
- Saved schedules can be viewed offline. Apple address search, the Council website and optional external content need a connection. The app does not fetch authoritative Council dates automatically; you check the official source and confirm your schedule.
- Notification permission, device settings and iOS delivery behavior affect reminders. Check the reminder coverage/renewal status in the app; no delivery guarantee is made.
- Calendar integration manages app-owned collection entries. An exported `.ics` file is a copy of the schedule at export time, not a live council subscription. Calendar clients do not automatically learn later changes from an exported file.
- There is no account, private CloudKit sync, nationwide coverage commitment or automatic response to every council disruption. Check official notices and correct the saved schedule when needed.

## Build and check

`project.yml` is the project specification. Use XcodeGen and Xcode with an installed iOS simulator runtime. Do not hand-edit generated project settings.

```sh
xcodegen generate
xcodebuild -project BinDayNZ.xcodeproj -scheme BinDayNZ -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcrun simctl list devices available
```

Run the suite on an isolated simulator; replace `REPLACE_WITH_UUID` with its identifier. Calendar and permission tests must not use a personal device or calendar store.

```sh
xcodebuild -project BinDayNZ.xcodeproj -scheme BinDayNZ -destination 'platform=iOS Simulator,id=REPLACE_WITH_UUID' CODE_SIGNING_ALLOWED=NO test
```

The app and widget share the recurrence model and schedule engine. SwiftData stores the household profile; App Group defaults share only the schedule and language needed by the widget. Apple frameworks provide UI, maps, notifications and calendars. Both bundles carry required-reason API declarations.

## Support and operation

- [Report an app issue](https://github.com/littlekidd020/waste-collection-reminder/issues): GitHub reports are public and submitting one requires a GitHub account. Do not post a home address, location, calendar contents or screenshots containing personal details. Provide the app version, expected date, displayed date and steps with a public sample or redacted details.
- [Report an actual missed collection to Auckland Council](https://www.aucklandcouncil.govt.nz/rubbish-recycling): app issues and collection-service failures have different owners.
- [Candidate privacy policy](docs/privacy-policy.md), [current design](docs/plans/2026-03-16-bin-day-nz-design.md), [six-week pilot and maintenance record](docs/pilot-and-maintenance.md).
- The [6 September audit](docs/audits/2026-09-06/audit.md) records the pre-remediation baseline. Preserve it as historical evidence; close findings with new verification records rather than rewriting that history.
