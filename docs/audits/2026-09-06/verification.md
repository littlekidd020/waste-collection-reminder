# Verification record — 6 September 2026

This file separates executed checks, source findings and uncompleted runtime checks. Product source, existing tests, project files and the user's starting changes were preserved. `source-integrity.json` verifies 55 original files remained byte-identical; the tracked binary diff was also compared with its pre-audit snapshot and matched.

## Executed checks

| Check | Evidence | Result |
|---|---|---|
| Starting working tree and source fingerprints | [baseline-status.txt](</Users/kexinli/My Drive/AI Projects/waste collection reminder/docs/audits/2026-09-06/evidence/baseline-status.txt>), [source-sha256.json](</Users/kexinli/My Drive/AI Projects/waste collection reminder/docs/audits/2026-09-06/evidence/source-sha256.json>), [source-integrity.json](</Users/kexinli/My Drive/AI Projects/waste collection reminder/docs/audits/2026-09-06/evidence/source-integrity.json>) | Preserved |
| Resolved app build settings | [build-settings.txt](</Users/kexinli/My Drive/AI Projects/waste collection reminder/docs/audits/2026-09-06/evidence/build-settings.txt>) | Swift setting 5.9, deployment target 17.0, version 1.0.0, device family 1,2. Generator spec has family 1. |
| Existing Debug app and test compilation, integrated attempt | [existing-tests.log](</Users/kexinli/My Drive/AI Projects/waste collection reminder/docs/audits/2026-09-06/evidence/existing-tests.log>) | Compiled, then simulator test-host launch failed; no completed test-case results. |
| Extended audit-only test build | [extended-build.log](</Users/kexinli/My Drive/AI Projects/waste collection reminder/docs/audits/2026-09-06/evidence/extended-build.log>) | `TEST BUILD SUCCEEDED`; app source is unchanged in the temporary copy. |
| Release simulator arm64 build | [release-build.log](</Users/kexinli/My Drive/AI Projects/waste collection reminder/docs/audits/2026-09-06/evidence/release-build.log>) | `BUILD SUCCEEDED`; signing disabled, no archive/upload. |
| Actual-engine deterministic checks | [reliability-checks.txt](</Users/kexinli/My Drive/AI Projects/waste collection reminder/docs/audits/2026-09-06/evidence/reliability-checks.txt>) | 2/9 desired invariants pass, 7 fail; details below. |
| Live council property endpoint | [council-endpoints.json](</Users/kexinli/My Drive/AI Projects/waste collection reminder/docs/audits/2026-09-06/evidence/council-endpoints.json>) | Four requests returned HTTP 401 at 09:43 UTC. |
| Sorting guidance / video titles / localization | [experience-source.md](</Users/kexinli/My Drive/AI Projects/waste collection reminder/docs/audits/2026-09-06/experience-source.md>) | Official-source errors and video mismatch confirmed; string coverage/placeholder check passed. |
| Public listing, competitors and Apple requirements | [strategy.md](</Users/kexinli/My Drive/AI Projects/waste collection reminder/docs/audits/2026-09-06/strategy.md>) | Primary sources linked and dated; no App Store Connect analytics or published-binary inspection. |

The AppIntents metadata extraction warning occurred because the app does not depend on AppIntents. It is not counted as a launch or release defect. No app startup, memory, energy or interaction-speed benchmark was obtained. Do not interpret simulator boot time as app performance.

## Reproduced date and lifetime results

The harness compiles the repository's actual `ScheduleEngine`, collection models and bin type with audit-only localization substitutes. It does not invoke notification delivery, EventKit or a running widget. It can be rerun from the repository root:

```sh
sh docs/audits/2026-09-06/evidence/run_reliability_checks.sh
```

Exit 1 deliberately means the desired product invariants failed. The harness is retained as an audit reproduction, not an implementation fix.

| Scenario | Observed result |
|---|---|
| ISO odd-week fortnight at 2026→2027 | Dates include 28 December then 4 January: **7-day gap**. |
| ISO even-week fortnight at 2026→2027 | Dates include 21 December then 11 January: **21-day gap**. |
| NZ Gregorian odd/even fortnight at 2028→2029 | The same **7-/21-day gap** defect is reproduced under NZ week rules. |
| Locale comparison, 4 January 2027 | GB week rules collect recycling; NZ/US week rules do not. |
| NZ DST ends, 30 March→6 April 2026 | **Pass:** 7 calendar days, 169 elapsed hours, local midnight preserved. |
| NZ DST begins, 21→28 September 2026 | **Pass:** 7 calendar days, 167 elapsed hours, local midnight preserved. |
| Property versus travelling device timezone | Same instant is NZ Monday and Los Angeles Sunday; the default-device calendar gives different bin answers. |
| Weekly three-bin widget snapshot starting 6 September | Last of 12 stored bin events is 5 October; on 6 October the stored future list is empty although real recurring collections continue. |
| Notification generation observation | 60 bin events with both reminder options produce 120 one-shot requests. This does **not** measure how many the current OS retains. |

The classic 64-notification limit is found in deprecated `UILocalNotification` documentation. This audit does not promote it into a verified contemporary `UNUserNotificationCenter` result. A runtime pending-request test was compiled but could not execute.

## Simulator execution and screenshot boundary

All devices below were created for this audit, without personal accounts or calendar data:

- iPhone 17: `E7B0A682-1912-4538-B8DC-EA62BEA8D745`
- iPhone SE (3rd generation): `82F9EDCF-F739-4434-9EAD-0D1B36F87C0F`
- iPad (A16): `3D1C79B7-F52D-4D63-8286-28A57E4F847C`

The initial integrated command was:

```sh
xcodebuild -project BinDayNZ.xcodeproj -scheme BinDayNZ \
  -destination 'platform=iOS Simulator,id=E7B0A682-1912-4538-B8DC-EA62BEA8D745' \
  -derivedDataPath /tmp/bindaynz-audit-dd \
  -resultBundlePath /tmp/bindaynz-audit-existing-tests.xcresult \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test
```

At 21:43:58 NZST Xcode reported `Simulator device failed to launch com.bindaynz.app`, `NSPOSIXErrorDomain Code=3`, and “did not return a process handle nor launch error.” Independent launches on the dedicated devices stalled, as did a built-in Settings launch on the compact device. The failed test process was interrupted after approximately 643 seconds; its log also records `(ipc/mig) server died`. The result bundle is incomplete and the export tool cannot read its missing `Info.plist`; the failed export is retained in `existing-tests-summary.json` as error text, not test-result JSON.

A dedicated iPhone restart and independent launch were attempted. No current app screen was obtained. Do not classify this as an app-specific crash without a crash record or successful simulator control comparison. Other user simulators and tasks were not restarted or erased.

The following is a **fresh simulator-state capture**, showing the installed app and test runner on the home screen after the retry. It is diagnostic evidence only, **not a Bin Day NZ screen or visual acceptance result**:

![Audit simulator state after unsuccessful launch](</Users/kexinli/My Drive/AI Projects/waste collection reminder/docs/audits/2026-09-06/evidence/simulator-launch-state.png>)

## Retained runtime probes

[AuditRuntimeTests.swift](</Users/kexinli/My Drive/AI Projects/waste collection reminder/docs/audits/2026-09-06/evidence/AuditRuntimeTests.swift>) contains actual pending-notification inspection and an EventKit same-title-calendar collision test. The latter creates one synthetic unrelated appointment and asserts it survives app sync. **Run only on a new disposable audit simulator**, never a personal device or a simulator connected to a calendar account. The calendar-creation-failure fallback still needs a separately controlled failure test; the same-title probe does not force that branch.

[AuditScreenTests.swift](</Users/kexinli/My Drive/AI Projects/waste collection reminder/docs/audits/2026-09-06/evidence/AuditScreenTests.swift>) contains onboarding, permission-denial recovery, four-tab captures, change-address/manual editing, relaunch and accessibility inspection. Its issue handler logs findings and continues: a completed capture test would not mean accessibility passed.

These files were appended to existing test source files **only in `/tmp/bindaynz-audit-workspace`**, retaining the original project's target configuration. The generic simulator test build passed. They did not execute. A healthy-environment rerun must verify current identifiers/system permission labels against the resulting accessibility tree and export screenshots/audit issues from its completed `.xcresult`.

## Unresolved acceptance matrix

| Area | Still required before release |
|---|---|
| Calendar safety | Creation failure, title collision, external events, revoked access, repeated sync/removal and partial failure using synthetic data. |
| Address/live data | On-device Council requests; returned property identity for units/boundaries; current official dates and missing/malformed fields; offline behavior and visible freshness. The four 401 responses prevented date comparison here. |
| Notifications | Actual pending count/horizon and delivery; permission denial/regrant/revocation; rapid preference edits; midnight/timezone changes; long inactivity; real-device focus/notification settings. |
| Widgets | All four families, expired/corrupt payload, relaunch/language/address changes and extended inactivity. Simulator refresh requests alone cannot prove OS delivery. |
| Cross-surface state | Save/retry/cancel consistency across profile, Today/Schedule, notifications, calendar and widget; interrupted onboarding; storage errors. |
| Visual and assistive technology | Current compact/large iPhone and iPad screenshots; dark/light; largest Dynamic Type; contrast/touch targets; VoiceOver focus/actions; Reduce Motion; keyboard/search layout and error states. |
| Language/content | Fluent review of setup, schedules, sorting exceptions and permission prompts; actual video/caption playback and offline/unavailable media. |
| Distribution | Signed device archive, privacy report, device family/version agreement, minimum supported OS runtime and App Store validation. Only iOS 26.2 simulators were installed. |
| Product outcomes | Real household preference, missed reminders/bins, correction effectiveness, maintenance effort and cost; no recruitment/outreach was performed. |

This record keeps blocked work visible rather than converting an incomplete simulator run or historical screenshots into a pass.
