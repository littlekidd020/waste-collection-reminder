# Simulator recovery and iOS unit evidence

Started 6 September 2026; updated 7 September 2026. This records recovery, earlier failed attempts and the latest passing phone runtime results. A successful checkpoint is not proof that every simulator or every release scenario has completed verification.

Before recovery, [process samples](post-restart-launch-diagnosis.md) showed a system startup chain waiting below app code, including Spotlight's `xpcproxy_sim` performing dynamic-loader cache patching. Apple's Settings app also timed out. A user-authorised [CoreSimulator restart](simulator-restart.txt) alone did not immediately clear that condition.

The [cache update](simulator-cache-update.log) and [forced cache rebuild](simulator-cache-rebuild.log) both reported a usable iOS 26.2 / 23C54 dyld shared cache. The [first post-cache launch attempt](post-cache-launch.log) still timed out after 45 seconds, so that attempt must not be reported as successful. The later [app-hosted XCTest run](post-restart-tests.log) then reached all test cases and exited 0 in 103.4 seconds. This sequence establishes runtime recovery after the cache work, rather than proving that one particular command immediately resolved the original cause.

Apple's [Xcode 26.4 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-26_4-release-notes), checked on 6 September, describe a fix restoring automatic simulator runtime dyld-cache creation, degraded performance while scanning/building caches, and the `simctl runtime dyld_shared_cache update --all` command to wait for caching to finish (170836966). This is relevant official diagnostic context for the installed Xcode 26.3 environment. It supports the cache investigation; it does not prove this machine had precisely that Apple bug. No Xcode upgrade is claimed.

The [exported summary](ios-test-summary.json) from `/tmp/binday-post-restart-tests.xcresult` records an **earlier checkpoint of 30 cases: 29 passed, 1 skipped, 0 failed**, on dedicated simulator `E7B0A682-1912-4538-B8DC-EA62BEA8D745`, iPhone 17, arm64, iOS 26.2. The run finished at approximately 23:14:55 NZST and predates the final edge-case refinements below.

The passing isolated EventKit case performed actual saves and repeated sync, checked native recurrence/reminder events, preserved synthetic unrelated events in a same-title calendar and in the owned calendar, removed only managed events, and checked a second disable. Its cleanup protects every calendar that existed before the test. This is a passed mutation scenario, not merely a pure ownership-plan assertion. It does not cover all permission, missing-calendar, account-sync or failure conditions.

The notification integration case explicitly skipped because permission was not granted. Actual pending-request count, retention, trigger dates and cancellation remain unverified by this run.

## Source refinements after that checkpoint

- Calendar lookup now fails without replacing ownership when a missing calendar still requires cleanup. Once cleanup was confirmed, a missing calendar may safely be recreated; disabling an already-clean connection remains a no-op.
- The explicit local-only deletion path removes the calendar ownership record only after profile deletion saves. Its confirmation explains that remaining events may continue alerting, must be removed in Calendar and are no longer tracked by Bin Day NZ. Normal successful deletion preserves a clean reusable connection.
- Both final destructive Settings actions are disabled and guarded while refresh is active. The coordinator rejects detached/deleted SwiftData models before starting or repeating refresh. An iOS-only regression case was added for these model states.
- The [actual dark-mode image](screenshots/14-today-dark-before.png) exposed low-visibility dark-green links and selected-tab tint. AppTheme now uses a brighter accent in dark mode and a separate filled-button color. Current compact-dark journey screenshots are recorded; native contrast findings remain open as described below.

The final [Debug/test build](build-for-testing.log) and [unsigned Release build](release-build.log) pass. The [recorded host run](host-regressions.log) has 28 passes and two intentional integration skips; it excludes the iOS-only coordinator case and cannot verify the expanded EventKit runtime checks.

The [earlier compact iOS run](compact-final-unit-tests-2.log), [exported summary](ios-final-test-summary.json), and result bundle `/tmp/binday-compact-final-unit-tests-2.xcresult` record **31 cases: 30 passed, 1 skipped, 0 failed**, exit 0 in 41.2 seconds. It ran on iPhone SE (3rd generation) / iOS 26.2 Simulator (`82F9EDCF-F739-4434-9EAD-0D1B36F87C0F`). The expanded EventKit scenario passed missing-calendar preservation, explicit forget/reconnect and recreation after confirmed cleanup, along with the original unrelated-event preservation checks. The detached/deleted-profile coordinator regression passed. Notification integration skipped for missing permission in this checkpoint.

## Final permission-granted unit run

The [first permission-granted attempt](ios-all-permissions-tests.log) failed two tests because the live app's startup coordinator was still writing the global notification queue while the tests inspected it or called the notification service directly. The detached/deleted-profile case observed its initial one-request snapshot grow to two, four and six requests; the notification integration then threw `incomplete`. Production caller inspection confirmed that the coordinator is the sole application caller of rescheduling. This was test-host startup interference, not evidence that detached models initiated work.

Only the tests changed for the rerun: both output-sensitive cases now wait asynchronously for `ScheduleCoordinator.shared.hasCheckedAuthorization && !isUpdating`, with a 15-second deadline that fails clearly rather than skipping. No production synchronization hook or app-source change was added. The production application source remains unchanged since the final Release build.

The [final execution log](ios-all-permissions-tests-2.log), [summary](ios-all-permissions-summary.json), and `/tmp/binday-ios-all-permissions-tests-2.xcresult` record **31 passed, 0 skipped, 0 failed**, completed **7 September 2026 at 00:02:13 NZST**, exit 0. This ran on the dedicated iPhone 17 / iOS 26.2 simulator (`E7B0A682-1912-4538-B8DC-EA62BEA8D745`). Both previously affected tests passed, alongside the full expanded EventKit case.

The notification test now verifies actual retention of 61 pending requests, exact identifiers, non-repeating Gregorian/NZ trigger dates, grouped bin bodies, the scheduled horizon and renewal trigger, stale-request replacement, cancellation and restoration of the prior queue. This is native queue evidence. It does not establish delivery, background refresh or long-term unattended behavior.

## Later runtime limits

[UI attempt 4](ui-recovered-4.log) completed all journey assertions through relaunch, then failed when Apple's native accessibility audit returned code -56 (“Audit failed to complete in time”). This remains a failed combined test, not a passed accessibility audit. The separated full journey subsequently passed on the [large light phone with notifications denied](ui-recovered-5.log), [compact dark phone with notifications denied](compact-dark-ui-2.log), and [large phone with notifications allowed](ui-allow-notifications.log). The permission-granted [curated screenshots](screenshots/ui-allow-notifications/manifest.json) include the reminder status and relaunch.

The [actual schedule-edit case](compact-edit-contrast.log) passed after changing Rubbish from weekly to fortnightly, moving an occurrence, saving, relaunching and reopening the editor; other bins remained intact. That two-case run had one pass and one contrast failure, so it is not an overall passing audit. The [Today/Schedule hit-region case](compact-dark-audits.log) passed. Native contrast checks flagged captured text strips occluded at the floating tab bar/top edge. Those findings remain unresolved, not suppressed or accepted as a clean audit. Largest-text and remaining accessibility results are still pending.

The [iPad unit attempt](ipad-unit-tests.log) was interrupted without a completed suite. The dedicated iPad was [reset](ipad-reset.log), booted and successfully installed, but its launch still timed out after 120 seconds. The [first final compact unit attempt](compact-final-unit-tests.log) also stalled; the second completed successfully as recorded above. Recovery on the compact phone does not establish reliable startup or correct app behavior across the full device matrix.

Physical-device delivery, minimum supported OS, fluent-language review, signed-archive/privacy checks and distribution gates remain open. The final unit-suite result is accepted within its recorded scope; no blanket product, visual or accessibility pass is assigned.
