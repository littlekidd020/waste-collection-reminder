# Bin Day NZ — comprehensive product audit

**6 September 2026 · next public release · current working-tree candidate**

## Verdict

**Hold the next public release and wider promotion.** The native stack is appropriate and much of the basic product exists, but calendar data safety and the accuracy/lifetime of the schedule undermine its central promise. Correctness, correction and dependable reminders should lead the next work. A visual overhaul, new backend platform or national expansion would not resolve the present failure modes.

The most serious finding is a calendar data-loss path: sync identifies its calendar by title, can fall back to the user's default calendar, then deletes all events in that calendar in the next six months. This is confirmed in the current source, not reproduced against a person's calendar. Treat it as a release blocker even if every visual screen passes.

The strategy recommendation is to retain a focused, free Auckland utility while testing whether people prefer its verified setup, accessible presentation and correction experience over existing alternatives. This challenges the original expansion premise: a national free app is an ongoing data-and-support service, not merely additional council rows. No demand, retention or funding evidence was available to justify expansion or monetisation implementation.

## Evidence and limits

The existing uncommitted changes were preserved. Source hashes, starting Git status, build logs and executable audit checks are in [evidence](</Users/kexinli/My Drive/AI Projects/waste collection reminder/docs/audits/2026-09-06/evidence>). Audit-only tests were compiled in `/tmp/bindaynz-audit-workspace`; no production source was patched.

| Verification | Result | Meaning |
|---|---|---|
| Xcode 26.3 / iOS 26.2 SDK, Debug app and existing test compilation | Compiled | The code and test targets compile; this is not a test pass. |
| Additional audit-only unit/UI test compilation | **Passed** | Actual notification/calendar checks and screenshot/accessibility capture tests compile against the unchanged candidate. |
| Unsigned Release simulator build, arm64 | **Passed** | No signed device archive, App Store upload or review was performed. |
| Actual schedule engine, fixed-date executable checks | **2/9 desired invariants passed; 7 failed** | Both NZ DST checks passed. Fortnightly rollover, locale, property timezone and stored widget lifetime failed. This is a focused regression probe, not a whole-product pass percentage. |
| Public council endpoint matrix | **4/4 HTTP 401** | Two in-app example addresses, a unit variant and a nonexistent address returned an authorisation error from this host. No bypass attempted. This does not prove identical behavior on every iPhone. |
| Council sorting rules / current video metadata | Verified against primary sources | Food/inorganic guidance errors and the rubbish-video mismatch confirmed. |
| Localization coverage and format placeholders | Static checks passed | All 170 literal `L()` keys are catalogued; 198 translations per non-English language; no supplied empty translations or format mismatches. Human language quality is unverified. |
| Existing integrated unit/UI test execution | Runtime launch blocked | Xcode failed to launch the host with `NSPOSIXErrorDomain Code=3`, later `(ipc/mig) server died`. No completed test-case results were produced. See runtime record below. |

### Runtime record

Dedicated iPhone 17, iPhone SE (3rd generation) and iPad (A16) simulators were created. The app installed; Xcode's test-host launch and independent launches stalled. A built-in Settings launch on the dedicated compact simulator also stalled, supporting an environment-level problem rather than establishing an app-specific crash. The failed test attempt was stopped after approximately 643 seconds. Its interrupted result bundle could not be read; the retained text log is the evidence.

**Fresh app screenshots, current light/dark rendering, live VoiceOver, largest-text interactions, Reduce Motion, actual notification retention/delivery, calendar fault injection, widget rendering, permission recovery, and integrated cross-surface saves are not passed.** The screenshot/a11y and runtime probes are retained for a healthy simulator run. August screenshots are historical and are not substituted for current visual evidence. See [runtime and build evidence](</Users/kexinli/My Drive/AI Projects/waste collection reminder/docs/audits/2026-09-06/verification.md>).

The public [App Store listing](https://apps.apple.com/nz/app/bin-day-nz/id6761326182) was reviewed separately. It records version 1.1, iPhone/iPad support, English/Māori and one review requesting schedule override. The candidate has manual editing and more translations; neither source changes nor that review establish what is in the public binary.

## Domain scorecard

Scores are evidence-based audit judgments: **0 broken/unsubstantiated, 1 major gaps, 2 partial, 3 good, 4 demonstrated strong**. They do not average away blockers or imply device testing was completed.

| Domain | Assessment | Evidence confidence |
|---|---|---|
| Strategy and differentiation | **1/4** — useful job, weak demonstrated advantage and no operating/demand evidence | Medium |
| Schedule correctness and trust | **1/4** — recurrence and source-confidence failures | High for reproduced/source defects |
| End-to-end reliability | **1/4** — finite delivery data and inconsistent updates | High source; runtime incomplete |
| Technical foundation | **3/4** — fitting native tools, modular services, no third-party dependency burden | High; runtime performance unmeasured |
| UX and recovery | **2/4** — native flows exist; correction and honest status need work | High source; usability untested |
| Aesthetic cohesion | **Provisional 2/4** — consistent native base with competing icon/card treatments | Source judgment only; fresh visual score withheld |
| Accessibility | **Partial, unscored** — useful adaptations exist; current conformance not demonstrated | Runtime gap |
| Content and language | **2/4** — broad coverage, but incorrect rules/media and unreviewed language quality | High for named errors |
| Release operations and disclosure | **1/4** — missing manifests/links and configuration drift | High source |

### Technical design-quality subscore

The audit skill's five checks are retained without fabricated measurements: accessibility **unscored**, performance **unscored** (no profiling), responsive layout **unscored** (fresh runtime blocked), theming **provisional 2/4**, visual anti-patterns **provisional 2/4**. **No /20 total is reported.** System fonts and native controls are appropriate here. Repeated rounded cards, glossy markers, emoji and outlined symbols deserve consolidation; they are not proof of AI authorship. Restraint and clear bin semantics matter more than decorative novelty.

## Prioritised findings

These are **17 grouped finding clusters: 1 P0, 12 P1, 4 P2**. Linked appendices contain individual source locations, reproduction/evidence, impact, recommendations and acceptance criteria. Multiple symptoms sharing a root cause are grouped here to prevent a misleadingly inflated issue count.

| ID | Priority / classification | Gap and consequence | Smallest durable action / acceptance |
|---|---|---|---|
| A01 | **P0 · source-confirmed** | Calendar name matching, destructive refresh and default-calendar fallback can remove unrelated appointments. | Manage only app-owned calendar/event identifiers; never fall back into another calendar. On creation failure, stop with an error. Synthetic unrelated events survive every sync, removal and retry. |
| A02 | **P1 · reproduced** | Week-number parity produces 7-/21-day gaps and different answers by locale; device timezone can change a property's collection day. | Anchor each recurrence to a confirmed collection date and the property's timezone. Fixed-date tests must preserve 14-day cadence across both tested year boundaries, locale settings and travel. |
| A03 | **P1 · source + live endpoint evidence** | First-property selection and silent suburb fallback present uncertain results as accurate; every matrix request returned 401 here. | Validate returned property identity and response status. Show failed/ambiguous matches honestly and offer explicit manual setup. No unavailable lookup silently yields a confirmed household date. |
| A04 | **P1 · source-confirmed** | Parsed next dates become permanent weekday/parity templates; holidays, different bin days and freshness are lost. CloudKit code is disconnected. | Preserve dated, source-backed results and explicit exceptions. Choose an actually maintained update path; remove unused CloudKit code/claims. Expired data is visible and cannot masquerade as current. |
| A05 | **P1 · source + deterministic reproduction** | Reminder scheduling is finite; widgets retain only 12 bin events and later say there are no collections. Normal foreground refresh is missing. | Use one authoritative schedule to reconcile app, notification and widget outputs. Widgets calculate from persisted recurrence/exception data; define long-inactivity behavior and test past the original horizon. Do not rely solely on opening the app or an assumed background refresh guarantee. |
| A06 | **P1 · source-confirmed** | Address save can commit profile/reminders, then fail calendar sync and skip widget refresh while reporting “Could Not Save.” | Persist the schedule once, refresh dependent outputs, and report recoverable integration failures accurately. Every surface reflects the saved schedule; calendar retry is explicit and idempotent. |
| A07 | **P1 · source-confirmed** | Manual setup applies one cadence to all bins and reopens with defaults. Ordinary weekly rubbish plus fortnightly recycling cannot be represented. | Edit existing per-bin schedules, preload values and preview the next two dates. Reopen/cancel/save preserves other bins and every downstream output agrees. |
| A08 | **P2 · source-confirmed** | GPS address formatting drops the street name when a number exists; location continuation/error handling also needs verification. | Build the complete address with existing platform formatting, retain text lookup recovery, and prevent overlapping location requests. Numbered/numberless addresses and denial complete predictably. |
| A09 | **P1 · official-content confirmed** | Food guidance accepts tea bags/rejects all compostable liners; inorganic guidance over-rejects timber and omits important service instructions. | Correct all languages using current council rules, show source/review date, and link inorganic booking with placement/limits/battery instructions. Verify exceptions survive translation. |
| A10 | **P1 · live metadata confirmed** | Rubbish still plays “Clean the Recycled Items.” A valid YouTube URL test misses the wrong subject. | Remove that video until a suitable source is verified. Review category, actual content, captions, availability and failure state for retained media. |
| A11 | **P1 · source/disclosure confirmed** | In-app privacy link and required-reason API manifests are missing; public policy does not explain address/video requests. | Add accurate accessible disclosures and correctly scoped manifests for app/widget. Inspect the archive and vendor data handling; do not assume the store's data label is false without retention evidence. |
| A12 | **P1 · source-confirmed** | Council missed-pickup contact is not an app-error reporting/correction route. | Provide one maintained developer-support route, reviewed diagnostics and a wrong-date correction path. A user can reach the maintainer without automatically disclosing an address. |
| A13 | **P1 · configuration confirmed** | Generator says iPhone-only while resolved project says iPhone/iPad; candidate and Settings report 1.0.0. | Establish one build specification, verify advertised devices, and read version from the bundle. Generated settings, archive and support UI agree. |
| A14 | **P2 · source-confirmed** | Language change resets navigation and leaves previously generated reminders/calendar/manual-address text in the old language. | Preserve navigation, store state rather than translated placeholders, and refresh app-owned generated content. Verify critical translations and localized purpose strings with fluent reviewers. |
| A15 | **P2 · design judgment / runtime open** | Today prioritises “No collection today,” repeats tomorrow/upcoming, and lacks source/reminder health. Tiny calendar marks and mixed visual treatments reduce clarity. | One next-collection answer, grouped bins, concise confidence/reminder status and coherent symbols. Verify fresh compact/iPad, dark, large-text and VoiceOver behavior before accepting visual changes. |
| A16 | **P2 · documentation confirmed** | Design/submission copy labels CloudKit, subscribed `.ics`, cross-device sync and accessibility as complete without evidence. | Rewrite around observed capability; separate the roadmap. A local `.ics` file is a snapshot, and SwiftUI alone is not proof of accessible use. |
| A17 | **P1 · assurance gap** | Existing tests cover a small manual round-trip, view existence, symbols and URL shape, but not core calendar/schedule/lifecycle hazards. Integrated execution was blocked. | Keep the smallest meaningful regression checks for each fixed root cause, then complete the named runtime matrix. Compilation, test execution and real-device delivery must have separate recorded outcomes. |

Details: [reliability](</Users/kexinli/My Drive/AI Projects/waste collection reminder/docs/audits/2026-09-06/reliability.md>), [experience, content and localization](</Users/kexinli/My Drive/AI Projects/waste collection reminder/docs/audits/2026-09-06/experience-source.md>), [strategy, privacy and distribution](</Users/kexinli/My Drive/AI Projects/waste collection reminder/docs/audits/2026-09-06/strategy.md>).

## What to keep and simplify

Keep SwiftUI, SwiftData, UserNotifications, WidgetKit, EventKit, MapKit and String Catalogs. The app is small enough for these native tools; no evidence justifies a cross-platform rewrite, state-management framework or service platform. Existing services separate concerns reasonably, but their callers coordinate updates inconsistently. A shared save/reconciliation operation is a smaller durable repair than independent view-specific patches.

Preserve the native tabs, forms, named bin categories, accessibility-size calendar list, single-column large-text guides and Reduce Motion branches already present. Validate rather than replace these foundations. The current Debug simulator app is about 24 MB; that is a local uncompressed artifact and must not be compared directly with the store's download figure or used as a performance score.

Remove the wrong video, unsupported “Coming Soon” commitments, duplicate next-day information and unused remote-update code if no working update service is selected. Do not replace missing data with more elaborate guesses. A reviewed manual schedule is useful when its limits are explicit; an inferred schedule presented as authoritative is a trust failure.

## Opportunities and strategic decision

The proposed primary audience is Auckland households responsible for ordinary council kerbside bins, especially people managing alternating recycling weeks or a recent move. This is a recruitment hypothesis. Private services, communal arrangements and island exceptions require explicit support boundaries.

| Opportunity | Value / possible distinction | Effort and ongoing burden | Evidence required |
|---|---|---|---|
| Verified setup and easy per-bin correction | Fewer wrong dates and a recoverable alternative to fragile automatic matching | Medium implementation; ongoing source/correction ownership | Official sample matrix, mixed-cadence tasks and household correction success |
| Dependable glanceable reminders/widgets | Useful without repeated app opening | Medium; ongoing OS/lifecycle checks | Real devices across six weeks, permission changes and extended inactivity |
| Accessible multilingual setup and guides | Could serve people poorly supported by existing tools | Medium; continued language/content review | Fluent reviewers, assistive-technology users and comparative task evidence |
| Council/community distribution partnership | Potential trusted acquisition and maintenance funding | Low-cost discovery first; high relationship/support burden if pursued | Named partner, unmet need, permitted source access and bounded maintenance agreement |
| Paid extras or household subscription | Possible funding, presently undemonstrated | Adds entitlement/support/product complexity | Demonstrated recurring value and actual willingness to pay before implementation |
| National coverage / data API | Larger potential reach | High recurring council-specific data, rights and support work | Repeatable maintained source access and a specific user/buyer need; defer now |

The competitive baseline already includes Council address tools, **Collection for Auckland**, **Antenno** in participating council areas and recurring calendar events. Free access and native styling alone are insufficient differentiation. Current sources and detailed tradeoffs are in the [strategy comparison](</Users/kexinli/My Drive/AI Projects/waste collection reminder/docs/audits/2026-09-06/strategy.md>).

After the safety/reliability work, run a suggested **six-week, 8–12-household qualitative pilot**. Compare correct setup and recovery with the council website plus a recurring calendar. Measure app-induced wrong dates/missed reminders, continued preference for reminders/widgets, support effort and correction turnaround. App opens and downloads are secondary indicators for a utility intended to work without attention. These study parameters are a proposed validation method, not market evidence or a promise of statistical significance.

No current user counts, retention measurements, cost ledger, conversion funnel or funding commitments were available. Do not claim missed-bin reduction, contamination reduction or commercial viability from the feature list.

## Sequenced roadmap and release gates

1. **Protect data and establish a correct schedule.** Resolve A01–A04 and A07; add focused regressions. Pass calendar ownership/failure checks, 14-day recurrence across locale/year boundaries, official-address matching, explicit unsupported states and manual mixed schedules.
2. **Make repeat use dependable.** Resolve A05–A06 and verify A08/A14. App, widgets, reminders and calendar agree after save, retry, relaunch, midnight, language change and permission revocation. Prove extended inactivity behavior on real devices; record OS constraints honestly.
3. **Repair content and public trust.** Resolve A09–A13 and A16. Verify sources/media, complete disclosures/manifests/support, reconcile build metadata, and validate the release archive. Do not treat an unsigned simulator build as distribution approval.
4. **Refine hierarchy and complete inclusion QA.** Resolve A15 with small native changes. Capture fresh screenshots, measure contrast, verify touch targets, dark mode, compact/iPad layouts, largest text, focus order and reduced motion. Polish follows reliable behavior.
5. **Validate before expanding.** Complete the bounded household study and review maintainer effort. Expand only when the next council has maintained source access, verified data/content, a responsible owner and a realistic operating commitment.

**Release gate:** zero unresolved P0/P1 clusters, recorded success for the relevant regression and integrated scenarios, verified official sample schedules, current privacy/content metadata, and a signed archive/device check. Any unavailable real-device or assistive-technology evidence remains an explicit open gate; a favorable build or design score cannot close it.

This audit implements investigation and recommendations only. It does not apply fixes, contact households or councils, change the listing, publish a build or infer that the existing public binary contains every candidate defect.
