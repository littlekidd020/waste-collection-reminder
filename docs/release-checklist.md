# Bin Day NZ — release checklist

Candidate defaults: **1.2.1 (5)**, iPhone and iPad, iOS 17+. This is a working checklist, not a release certificate; the record below covers the 1.2.1 (5) candidate (1.2 (4) was approved and released on 2 November 2026, submission `a0c4dbe0…`). Keep the audit of 6 September unchanged and attach new evidence for each repaired finding.

Release record:

| Field | Value to record |
|---|---|
| Date and responsible reviewer | 3 November 2026 (NZDT), Kexin Li; prepared with Claude Code |
| Commit / working-tree state | `821ed00` on `main` plus the 1.2.1 version bump, `metadata/version/1.2.1` and this record |
| Generated project / tool versions | XcodeGen from `project.yml`; Xcode 26.3 (iOS 26.2 SDK) on macOS 26; asc CLI 6.3.0 |
| Archive version and build | 1.2.1 (5), archived from a Release build with automatic development signing (`DEVELOPMENT_TEAM` passed on the command line), exported with manual Apple Distribution signing and the "Bin Day NZ App Store 2026-11-02" / "Bin Day NZ Widget App Store 2026-11-02" profiles (App Groups and Time Sensitive Notifications verified in the export summary, `get-task-allow` false) |
| Devices and OS versions | Unit tests on the iPhone 17 Pro simulator (iOS 26.2); notification snooze action and refresh behaviour exercised by hand on the same simulator; no physical-device run and no UI-test run recorded for this build |
| Automated results and screenshots | 42 unit tests pass (2 skipped by design); the new strings were reviewed per language against the catalog; store screenshots are the 1.2 set |
| Remaining limitations and decision | Build 5 uploaded, processed VALID with export compliance exempt, attached to App Store version 1.2.1 (`3a9904f8…`), readiness validation clean with two advisories (SDK version not reported by the API; App Privacy publish state not verifiable via API). Tap-to-open from a notification was not exercised on the simulator. Review submission pending the owner's go-ahead. |

## Build, signing and metadata

- [ ] Generate from `project.yml`; confirm generation does not introduce unexplained configuration drift. Both app and widget use version 1.2.1/build 5, family 1,2 and the expected App Group.
- [ ] Build and run unit/UI tests on an isolated simulator. Verify shared scheme target membership and bundled resources, including permission translations and app/widget privacy manifests.
- [ ] Produce a signed release archive. Inspect the actual archive's version, device family, entitlements, required-reason declarations and privacy report; simulator signing bypasses do not establish this.
- [ ] Check latest App Store processing/validation requirements before upload. Record the result only after a real validation. No upload or submission is implied by checking this document.
- [ ] Check current public listing, support URL, age-rating answers, languages, device availability and screenshots against the final candidate. Replace unsupported precision, indefinite reminder, national-coverage and private-sync claims.

## Schedule correctness and data safety

- [ ] Compare user-entered exact-property schedules with current official information for public sample addresses: ordinary street, unit, ambiguous address, service boundary and unsupported/private arrangement. Record source URLs and time checked; do not store participants' addresses in the report.
- [ ] Failed address search and ambiguous map matches do not produce an inferred schedule. The app does not claim automatic Council lookup; user-confirmed schedules are clearly identified and editable.
- [ ] Check every bin independently: weekly/fortnightly, distinct weekdays, next-date anchor, change to another frequency, and one-off skipped/moved collection. Confirm dates agree across Today, Schedule, pending reminders, widget and calendar.
- [ ] Check 14-day spacing across December–January, a 53-week year, different device locales, NZ daylight saving and travel to a different timezone. Collection dates retain the service timezone's meaning.
- [ ] Check source changes and holiday/disruption exceptions. Confirm they alter only intended occurrences and do not redefine the permanent weekday. Use a current official source; do not infer a national rule from a holiday name.
- [ ] Using synthetic events only, test a calendar with the same title, rename, missing calendar, creation/save failure, denied/revoked access, repeated enable/disable and partial operation. Unrelated events and calendars remain intact; retries do not duplicate or erase data.
- [ ] Check exported `.ics` in Apple and Google Calendar with non-English labels and punctuation. It imports the intended dates, states its snapshot limit and does not claim future synchronisation. Record what happens on repeated import.
- [ ] Interrupt a save, relaunch and change address after calendar/notification failure. The saved profile and optional-service state remain truthful and recoverable.

## Reminder, widget and experience checks

- [ ] Inspect pending reminder count, earliest/latest date and renewal warning; verify denial, revocation, regrant, different times, multiple bins on one day and rescheduling. Scheduling success is not recorded as delivery success.
- [ ] On a physical device, observe foreground, background and terminated-app delivery with permission granted. Record Focus/notification settings and limitations. Check behavior near and beyond the stated reminder horizon without relying on daily app opening.
- [ ] Add every supported widget family on a device. Check beyond the old finite cache horizon, midnight, schedule/language edits, malformed/absent data and stale source information. Record actual rendering separately from timeline unit tests.
- [ ] Inspect compact/large iPhones and iPad in light/dark mode. Check accessibility text sizes, VoiceOver order/labels/actions, colour-independent bin identification, Reduce Motion, keyboard/tap behavior and permission recovery.
- [ ] Have fluent reviewers check critical copy, sorting guidance, errors and permission prompts in each advertised language. Record names or reviewer identifiers with consent; machine-generated resource presence is not language approval.
- [ ] Verify every bin guide against current Council guidance and each video's actual content. Text remains usable without loading video; wrong/missing/blocked media offers a clear recovery.

## Privacy, support and operation

- [ ] Trace Apple address search, optional location, external Council links, user-confirmed setup, guide opening, video loading and calendar/export flows. Confirm no in-app Council API upload remains. Confirm text-only guidance makes no video requests, and reports do not automatically include private addresses.
- [ ] Reconcile the [candidate policy](privacy-policy.md), in-app explanation and App Store answers with observed behavior and vendor retention evidence. API manifests do not establish a “Data Not Collected” claim. Publish external policy changes only as an explicitly authorised release action.
- [ ] Open the in-app privacy and support destinations. Verify GitHub public-post guidance, app version reporting, incorrect-date reporting and the separate Council missed-pickup route.
- [ ] Assign an operating owner and capacity using the [maintenance record](pilot-and-maintenance.md). Run public sample checks before each holiday, each release, and after a reported Council-source change. Record investigation and correction turnaround.
- [ ] Record the go/no-go decision: no unresolved P0/P1 defects, relevant checks passed, and any unavailable real-device/source/language evidence remains an open gate. A successful build cannot waive these gaps.

Apple references checked on 6 September 2026: [required-reason API declarations](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api), [approved API reasons](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype), [privacy disclosure guidance](https://developer.apple.com/app-store/app-privacy-details/), [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/). Refresh requirements before release.
