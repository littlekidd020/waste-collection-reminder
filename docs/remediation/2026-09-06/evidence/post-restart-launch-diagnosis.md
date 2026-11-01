# Post-restart launch diagnosis

6 September 2026, samples at 23:00:59–23:02:50 NZ time. Read-only investigation of dedicated BinDay Audit 0609 simulator `E7B0A682-1912-4538-B8DC-EA62BEA8D745` after the authorised CoreSimulator restart. No service was killed/restarted and no app source, data or launch configuration was changed by this investigation.

## New evidence

Actual target PIDs were obtained through that simulator's `launchctl list`: SpringBoard 73234, runningboardd 73118, splashboardd 73378. Their sample headers identify the same `launchd_sim` parent, 73108. The inventory also identifies Spotlight's launched job PID 73277. See [inventory](binday-launchctl-e7.txt).

- [SplashBoard sample](binday-e7-splashboard.sample.txt): its launch-image server queue spends the full three-second sample waiting in `UIScreen.initialize` → `_UIApplicationConfigurationLoader._loadInitializationContext` → `dispatch_once`. The preload thread waits synchronously in `UISApplicationSupportClient.applicationInitializationContextWithParameters` for a system-service reply.
- [SpringBoard sample](binday-e7-springboard.sample.txt): the matching `com.apple.frontboard.systemappservices` connection from PID 73378 is in `UISApplicationSupportService` → FrontBoard process registration/bootstrap → `RBSConnection.executeLaunchRequest`, waiting for a synchronous XPC reply. Several other launch/registration queues show the same wait. Its main run loop still handles status-bar updates, so the whole SpringBoard process is not simply frozen.
- [RunningBoard sample](binday-e7-runningboard.sample.txt): the Spotlight process-manager queue waits in `RBLaunchdJobManager.createAndLaunchWithIdentity` → `OSLaunchdJob.submitAndStart` → XPC pipe reply for the entire sample.
- Process inspection at approximately 23:02:49 shows PID 73277 still executing `xpcproxy_sim UIKitApplication:com.apple.Spotlight[e30d][rb-legacy]` after 5 minutes 19 seconds. The [Spotlight-job sample](binday-e7-spotlight.sample.txt) contains only pre-main loader work: `dyld4::prepareSim` → `JustInTimeLoader::applyFixups` → `applyFixupsCheckCachePatching` → `applyCachePatchesToOverride` / `PatchTableV2::clientsExportsForImageAndClient`. Spotlight itself has not replaced that proxy executable.
- The [simulator launchd sample](binday-e7-launchd.sample.txt) shows idle signal/workqueue waits and does not identify an additional lower-level cause.
- The [filtered target logs](binday-e7-launch-filtered.log) record successful Bin Day installation at 22:57:44 and a SplashBoard request timeout for Apple's `com.apple.Preferences` at 22:59:01.702. That independent system-app failure is broader than Bin Day's app UI.

## Interpretation and limit

The captured wait chain localises this attempt to simulator system-process startup/registration, with the lowest observed active work in Apple's `xpcproxy_sim` dynamic-loader shared-cache patching before main. It provides a specific explanation for why the app/test runner never reaches normal execution and why a launch-screen change alone has not produced a successful launch.

The exact reason that loader work is not completing is **not established**: these samples do not prove corrupted caches, an OS/runtime incompatibility, an injected-library cause, or a particular deadlock. No additional cache deletion, runtime reinstall, service restart or host reboot was attempted. Bin Day functionality, screenshots and accessibility remain unverified by this run; this is not an app-specific crash report or a runtime pass.
