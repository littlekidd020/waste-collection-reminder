# Host regressions and bounded launch diagnosis

Observed 6 September 2026, NZST. This is evidence for the remediation source state, not proof of release readiness.

## Host test result

`host-regressions.log`: **30 XCTest cases, 28 passed, 2 skipped, 0 failures**, exit status 0, rerun at 23:03 NZST after the integration-test safety changes. The skipped cases are the opt-in simulator EventKit and notification integration tests. The six suites are ManualScheduleTests (8), SchedulePersistenceAndReminderTests (9 including the skips), CalendarSafetyTests (6), WidgetSnapshotTests (3), VideoSourceTests (3), and IconographyTests (1).

Reproduce from the repository root:

```sh
bash docs/remediation/2026-09-06/evidence/run-host-regressions.sh > docs/remediation/2026-09-06/evidence/host-regressions.log 2>&1
```

The script records the Swift version, input SHA-256 hashes, expanded compilation commands, and full XCTest output. SwiftData macros require an environment that permits the compiler's macro subprocess. It creates a temporary macOS test executable with a unique bundle identifier and preferences domain, removing that domain after the test run. No app/project source or simulator configuration is changed.

The actual model, engine, calendar service, DataService and LanguageManager files are compiled. NotificationService.plan and YouTubePlayerView.request are extracted **verbatim** into temporary host wrappers because notification ephemeral authorization and UIViewRepresentable are unavailable on macOS. Tests use the original checked-in XCTest files. This verifies reminder planning and request construction, not notification delivery, video playback, SwiftUI navigation, WidgetKit rendering, live calendar writes, or iOS app startup. SwiftData persistence is exercised with an actual in-memory store and separate save/fetch contexts.

## Launch observations

The existing app and build-for-testing logs end in success. The built app has a resolved executable and bundle identifier, arm64 iPhoneSimulator binary, minimum OS 17.0, and ad hoc simulator signing. Installation succeeded in `/tmp/binday-launch-details.log`. No bundle/signature rejection or app exception was found in the inspected interval.

One metadata gap is present: `BinDayNZ/Info.plist:30–31` names the launch-screen color `LaunchBackground`, but a complete file inventory (`rg --files -uu BinDayNZ`) contains no matching color asset. Removing the stale reference or supplying the intended asset would resolve that configuration gap. It may explain a default launch background; it is not an established cause of the process-start stall.

`launch-process-diagnosis.log` contains the read-only simulator log interval:

- At 22:33:12 CoreSimulatorBridge resolves the app bundle and sends a FrontBoard open request.
- At 22:34:48 SpringBoard responds to an icon tap and starts bootstrapping a foreground process.
- At 22:34:50 its request to splashboardd times out. A later bootstrap request says a pending process already exists.
- A host process-list snapshot at approximately 22:36 showed no BinDayNZ application process. The only BinDayNZ process was an older widget extension on a different simulator.
- The unit-test session connected to testmanagerd, then stopped progressing after launch-session setup. Its captured standard output was empty at inspection time.

Capture command (read only):

```sh
xcrun simctl spawn E7B0A682-1912-4538-B8DC-EA62BEA8D745 log show \
  --start '2026-09-06 22:33:00' --end '2026-09-06 22:35:30' --style compact \
  --predicate 'process == "BinDayNZ" OR ((process == "SpringBoard" OR process == "runningboardd" OR process == "CoreSimulatorBridge") AND (eventMessage CONTAINS[c] "bindaynz" OR eventMessage CONTAINS[c] "denied"))'
```

**Inference:** the observed stall is before app process startup, in the simulator's process/launch-screen orchestration. The blank screen is not evidence that SwiftData initialization or app view code was reached. The exact underlying cause remains unproven; the inspected logs do not justify claiming a specific app defect or a successfully tested app flow. An equivalent control-app launch and a process stack sample during the stall would distinguish a shared simulator service problem from an app-specific bundle launch path. No processes were terminated, no simulator settings were changed, and no Xcode test/build was started by this diagnosis.
