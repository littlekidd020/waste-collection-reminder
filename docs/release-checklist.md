# Bin Day NZ — release checklist

Candidate defaults: **1.2 (3)**, iPhone and iPad, iOS 17+. This is an uncompleted checklist, not a release certificate. Keep the audit of 6 September unchanged and attach new evidence for each repaired finding.

Release record:

| Field | Value to record |
|---|---|
| Date and responsible reviewer | Not recorded |
| Commit / working-tree state | Not recorded |
| Generated project / tool versions | Not recorded |
| Archive version and build | Not recorded |
| Devices and OS versions | Not recorded |
| Automated results and screenshots | Not recorded |
| Remaining limitations and decision | Not recorded |

## Build, signing and metadata

- [ ] Generate from `project.yml`; confirm generation does not introduce unexplained configuration drift. Both app and widget use version 1.2/build 3, family 1,2 and the expected App Group.
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
