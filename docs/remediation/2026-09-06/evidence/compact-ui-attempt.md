# Compact UI verification attempt

6 September 2026, 10:43–10:46 UTC. Dedicated BinDay Audit Compact 0609 simulator only: `82F9EDCF-F739-4434-9EAD-0D1B36F87C0F`, iOS 26.2. Synthetic Bin Day app data was uninstalled before testing.

Ran `xcodebuild test-without-building` for `BinDayNZUITests` only, no parallel testing, using `/tmp/bindaynz-remediation-dd`. This predates the separate final resource/launch-screen packaging fixes.

**Blocked before test execution; not passed.** No test suite/case output appeared. The test process was interrupted at the instructed three-minute cutoff; Xcode recorded 187.175 seconds including finalization and `TEST EXECUTE INTERRUPTED`. Its cancellation diagnostic lists unfinished simulator install and launch workers and waiting for runner workers to materialize. This does not establish an app-specific crash or the underlying cause.

The launch-state screenshot shows SpringBoard with the installed UI test runner icon; it is not a rendered app screen. No interaction, accessibility or app screenshot verification was completed.

Evidence: [text log](binday-remediation-ui.log), [launch state](binday-remediation-ui-launch-state.png). The interrupted `/tmp/binday-remediation-ui.xcresult` was unreadable by `xcresulttool get test-results summary` because its Info.plist was absent; no testcase result is inferred from that directory.

## Corrected-build direct launch check

After the root reported a successful final build for testing and bundle-resource inspection, one bounded install was attempted from `/tmp/bindaynz-final-dd/Build/Products/Debug-iphonesimulator/BinDayNZ.app` to the same dedicated compact simulator. Installation returned no output and exceeded 30.011 seconds; successful installation of that corrected binary is therefore unconfirmed. One direct `simctl launch` for `com.bindaynz.app` then returned no app PID or launch result and exceeded 30.067 seconds. Only those individual simctl subprocesses were stopped. No other simulator was changed.

**Final runtime verification remains blocked.** No new UI-test run or app-state pass is claimed. The launch-screen/resource repair is not established as a cause or solution by this result. See [bounded install/launch log](binday-remediation-final-launch.log).
