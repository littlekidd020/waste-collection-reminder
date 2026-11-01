# Bin Day NZ — implementation and verification workflow

Updated 6 September 2026. The original bootstrap plan is obsolete. The current source and `project.yml` are the implementation baseline; the [current product design](2026-03-16-bin-day-nz-design.md) defines product boundaries.

1. Read the saved-schedule flow and every caller of the affected service before changing behavior. Keep date computation in the shared schedule engine; do not calculate a separate interpretation in a view, widget or calendar adapter.
2. Change `project.yml` for build settings and target membership, then generate the project with XcodeGen. Version and device-family settings live in the shared specification. Both executables need their privacy manifests and the widget needs the shared model/engine sources.
3. Keep household saves and optional notification/calendar effects recoverable. A failed optional service must not silently erase the previous schedule or claim successful setup. Delete only calendar objects the app can identify as its own.
4. Add a focused runnable regression for non-trivial behavior. Exercise the existing unit and UI targets on an isolated simulator. Never use a personal calendar for destructive tests.
5. Follow the [release checklist](../release-checklist.md), attach the candidate's test evidence, and report remaining device, source and language verification separately. Do not alter the historical audit to make an issue appear resolved.

Commands and support are in the [README](../../README.md). Publishing public copy, changing the external policy/listing, contacting users and uploading an App Store build are separate actions; a local commit or simulator build proves none of those outcomes.
