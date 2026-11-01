# Bin Day NZ — engagement audit

**Audit date:** 1 November 2026 (Pacific/Auckland). **Subject:** uncommitted working-tree candidate 1.2 (3), plus the public App Store listing (still 1.1) and the main competitor's listing, both read on the audit date. **Scope:** business strategy, product direction, design, experience, tech, performance, with every finding framed around one question: *what would make more Auckland households keep a working reminder channel from this app?*

**Evidence gathered for this audit:** full read of all app, widget and test source; the September 2026 audit, remediation status and store-copy draft; a clean simulator build of the current tree (Xcode 26.3, exit 0); a string-catalog check; grep-based dead-code and copy-density counts; live reads of both App Store listings; Apple's TN3192 technote; web search for council data access and holiday rules. No tests were executed in this pass (the September record shows 31 iOS unit tests passing), no device runs, no analytics (none exist), no user research.

---

## 1. Verdict

The September remediation made Bin Day NZ **safe and honest, but it also made it a form.** The product's original promise ("we find your bin day") was removed because the council lookup was unreliable. What replaced it asks the user to leave the app, look up their own dates on the council website, come back, and type them into a per-bin editor behind a confirmation toggle. The home screen's most prominent button is now *Change schedule*, and 46 of the app's 250 user-facing strings are hedges about what the app does not do.

That is the engagement problem. It is not a visual-polish problem, and it is not a reliability problem any more. The engine, calendar safety, widget renewal and reminder planning are in good shape and well tested. The gap is between a trustworthy utility and one that people finish setting up, keep installed, and tell a flatmate about.

**Three things matter most, in order:**

1. **Make setup feel like a decision, not data entry.** Replace "pick a regular collection date" with "which weekday?" and "is recycling this week or next?". Keep the council page inside the app. End with a success screen that offers the widget.
2. **Own the one job a calendar event can't do: holiday shifts.** Christmas and New Year are eight weeks away. A bundled, dated, sourced holiday table with one-tap "apply" is the feature the established competitor leads on, and it is the strongest reason to open the app again.
3. **Fix what will silently cost you users.** Untranslated notification titles, an iPad configuration iPadOS 26 now ignores, a 16+ age rating, a listing that still promises a feature the app no longer has, and six months of uncommitted work.

### Scorecard

| Dimension | Score | One-line rationale |
|---|---|---|
| Business strategy | 2 / 5 | Clear boundaries, but no distribution loop, no seasonal plan, listing contradicts the product, no path back to automatic lookup. |
| Product direction | 2 / 5 | Correct scope-down, over-corrected into manual entry with no activation moment and thin notifications. |
| Design | 3 / 5 | Native, accessible foundations; hierarchy and copy are dominated by disclaimers; visual identity is system defaults. |
| Experience | 2.5 / 5 | Setup requires an external lookup and ~10 taps; good recovery flows; no post-setup success state. |
| Tech | 4 / 5 | Small, coherent, well-tested; one real localisation bug, dead code, no CI, 8k lines uncommitted. |
| Performance | 4 / 5 | Nothing user-visible today; a few cheap allocation fixes worth taking before adding features. |

---

## 2. Define engagement before optimising it

For a reminder utility, daily opens are the wrong target. A household that never opens the app but puts the right bin out every week because of a notification or a widget is a fully engaged user. The September strategy audit said this; the product should now act on it.

**North-star metric:** *households with a live reminder channel* — notification permission granted **and** reminders scheduled at least four weeks ahead, **or** a widget installed, **or** calendar sync enabled.

| Supporting metric | Why it matters | How to measure without an analytics SDK |
|---|---|---|
| Setup completion rate | The single biggest leak today | App Store Connect installs vs. a local counter surfaced only in an opt-in diagnostics share |
| Time to first confirmed schedule | Proxy for setup friction | Local timestamp delta, surfaced the same way |
| Reminder-channel retention at day 30 | Did the channel survive the first month? | Notification settings status + `WidgetCenter.getCurrentConfigurations` at launch |
| Renewal success | Do people respond to the renewal notice? | Pending-request horizon before/after a foreground refresh |
| Share-initiated installs | The only free growth loop available | Custom URL scheme + App Store campaign link on the share sheet |

The app has no telemetry by design. That is a defensible privacy position, but it means every claim about engagement is a guess. The minimum viable approach is to compute these locally and show them to the user on a diagnostics screen they can choose to share when reporting an issue. If you later want aggregate numbers, use an opt-in, privacy-preserving provider and disclose it in Privacy and Help. Do not add a general analytics SDK.

---

## 3. Business strategy

### B1 — The public listing promises what the candidate removed · P1

The NZ listing still shows 1.1 with "Rubbish collection days are now fetched in real-time from the council" and describes interactive address-based zone lookup. The candidate does neither. Every install from that listing arrives expecting automatic lookup and meets a form. The one public review asks for the ability to override collection day, which 1.2 delivers, so the 1.2 release should reply to that review.

The September store-copy draft fixes the honesty problem but reads like a terms sheet. Its second paragraph is "An address is optional; address search helps label your schedule and does not verify collection dates." That sentence belongs in Privacy and Help, not in the description.

**Recommendation:** lead the listing with the outcome ("Never miss recycling week"), name the three channels (notifications, widget, calendar), and state the Auckland boundary once. Put all qualifications under a single "Good to know" paragraph. Reply to the June review when 1.2 ships.

### B2 — No distribution loop · P1

A free, local utility with no marketing budget grows through households telling households. Everyone on the same street has the same schedule, which makes the schedule itself the viral object. The app has native share only for a 90-day `.ics` file.

**Recommendation:** add a *Share this schedule* action that produces a `bindaynz://` link (later a universal link) encoding each bin's anchor date and frequency. Opening it on a device with the app shows a prefilled, editable schedule; without the app it goes to the App Store. No backend, no account. Surface it on the success screen after setup and in Settings. The widget's "edit" affordance and the calendar event notes can carry the same link.

### B3 — The seasonal moment is in eight weeks and there is no plan for it · P1

Searches for "rubbish collection Christmas" spike every December. Auckland Council's rule is that collections run one day later for the rest of the week after certain public holidays, with city-centre, island and private-service exceptions, and the council discontinued its holiday text reminders. The established competitor, Collection for Auckland (about 1.2K ratings, 4.6 average, ads with a $4.99 removal purchase, version 3.8.0 shipped this week), leads with holiday-week reminders.

Bin Day NZ can already represent moved and skipped collections per bin. What it lacks is the data and the prompt.

**Recommendation:** ship a small bundled holiday table for the current season (holiday date, shift rule, source URL, review date), validated against the council's holiday page before release. On launch during the affected window, show one card: "Christmas Day falls on your rubbish day. Council says collections move one day later that week. Apply to your schedule?" One tap writes the one-off changes. Repeat for New Year, and review the table each release. Do **not** encode a universal "every public holiday" rule; the council applies it to specific holidays and areas.

### B4 — Automatic lookup has no path back · P2

There is no official API. A 2017 data.govt.nz request records the council saying it had no API capability but was open to discussion; community scrapers have since broken as the site changed; the council's own endpoint returned HTTP 401 to the September audit. Scraping is the wrong bet.

**Recommendation:** write one email to Auckland Council Waste Solutions asking for read access to collection-day data for a free resident app, with a privacy posture they can approve of (no address storage server-side). Treat this as the single strategic unlock; everything else in this report works whether or not it lands. Until then, keep manual entry but make it fast (see P1 below).

### B5 — Monetisation: correctly deferred · P3

The competitor demonstrates willingness to pay $4.99 to remove ads, so some value capture exists in this category. Bin Day NZ's differentiators are "no ads, no account, no tracking". Keep it free. If costs need covering, an optional supporter tip (one non-consumable, clearly optional, no features gated) is compatible with that position. Not before the engagement work.

### B6 — Operating risk: one maintainer, six months of uncommitted work, no CI · P1

The working tree carries 51 changed files and roughly 8,400 added lines since the April commit, including the entire September remediation. One disk failure loses it. There is no `.gitignore`, no CI, and scratch files are tracked. This is strategy, not hygiene, because the whole product value sits in that uncommitted diff.

---

## 4. Product direction

### P1 — Setup asks for a date when the user knows a weekday · P1

Today's flow: Welcome → Get Started → optional address → *Set up manually* (sheet) → per bin: toggle, frequency picker, a `DatePicker` labelled "A regular collection date" defaulting to **tomorrow**, one-off changes link → "I have checked these dates for my property" toggle → Save → Continue → reminders form → Finish → system permission prompt. That is ten or more taps and one trip to Safari before the first useful screen.

Households know "bins go out Tuesday night" and "recycling is every other week". They rarely know a date.

**Recommendation:** a guided editor that produces the same `CollectionSchedule` values:

1. "Which day are your bins collected?" — seven-segment weekday picker, shared by default, with a "different days per bin" disclosure.
2. For fortnightly bins: "Is recycling collected this week or next week?" — two buttons. The app derives the anchor date.
3. Preview the next two dates per bin (already implemented) and a single confirm button.

Open the council lookup page in an in-app `SFSafariViewController` so returning is one swipe, not an app switch. Keep the per-bin date editor as the advanced path for exceptions.

### P2 — There is no activation moment · P1

After Finish Setup the app drops the user onto Today with a status card. Nothing says "you're done", nothing offers the widget, and the Welcome page's third promise ("Home screen widget") is never followed up. Widget adoption is the strongest retention lever this app has because it survives notification fatigue and renewal windows.

**Recommendation:** a success screen: "You're set. Next collection: Tuesday 4 November — Rubbish, Food Scraps." Below it, two cards: *Add the widget* (with a short how-to, since iOS has no programmatic install) and *Share with your household*. On later launches, if `WidgetCenter.shared.getCurrentConfigurations` returns empty after two weeks, show the widget card once more in Today.

### P3 — Notifications are plain text with no way back into the app · P2

Content is a title ("Bins out tonight") and a body of bin names. No category, no actions, no deep link, no colour, no interruption level. The renewal notice asks the user to open the app but tapping it lands on whatever tab was last open.

**Recommendation:** add a notification category with a *Done* action (dismiss) and open-on-tap routing to Today; prefix the body with the bin glyphs; mark collection reminders `timeSensitive` (needs the Time Sensitive Notifications capability, no special approval); make the renewal notice open Settings' reminder section.

### P4 — The lock-screen widget family people actually use is missing · P2

Families offered: `systemSmall`, `systemMedium`, `accessoryInline`, `accessoryCircular`. `accessoryRectangular` is absent, and it is the lock-screen family with room for "Tomorrow · Rubbish, Recycling". StandBy and the Apple Watch Smart Stack also consume rectangular widgets.

### P5 — Reminder coverage depends on the user opening the app · P2

The 60-request batch covers 30 collection dates (about 30 weeks for a one-day-a-week household, 15 weeks if bins fall on two days), then a renewal notice fires seven days before the last reminder. Reconciliation runs on foreground and significant time change. That is sound, but it still ends in a dead reminder channel if the renewal notice is ignored.

**Recommendation:** register a `BGAppRefreshTask` that reruns the coordinator's refresh. iOS gives no guarantee, so keep the renewal notice, but most devices will top up silently. Separately, promote calendar sync as the "set and forget" option in the success screen; its recurring events never expire.

### P6 — Keep Auckland-only, keep no AI sorting · agree with September

Nothing found changes the September decision to hold expansion. The competitor's photo-based item identifier is a distraction for a one-person team; the council's "find where an item goes" page is already linked.

---

## 5. Design

### D1 — Today reads as a compliance screen · P1

Order on Today: hero card (good) → address → "User-confirmed schedule" → "Confirmed 6 September 2026" → **Change schedule** (borderedProminent, large: the most prominent control on the home screen) → "Check dates with Auckland Council" link → reminder status card with two lines of copy → integration message → Upcoming. The hero answers the user's question in the first 120 points; the next 300 points tell them what to doubt.

**Recommendation:** move *Change schedule* to a toolbar menu alongside *Share* and *Check with Council*. Collapse source and reminder state into one tappable status row ("Reminders on · schedule confirmed 6 Sep ›") that expands to the detail. Show integration messages only when non-nil. Let Upcoming start above the fold.

### D2 — Copy is repetitive and defensive · P1

Counts from the current source: 250 user-facing strings; 46 contain "Council", "check", "confirm", "optional", "does not" or "depend"; 15 links to the council website. "Reminder times stay in New Zealand time, including when you travel" appears in both onboarding and Settings. "App reminders have a limited window. Open Bin Day NZ regularly to renew them…" appears twice, in full. The confirmation toggle text "I have checked these dates for my property" is a legal posture, not a user action.

**Recommendation:** one *How Bin Day works* screen under Privacy and Help holds every boundary statement once. Each surface keeps at most one inline hint. Rename the toggle to "These dates look right" or replace it with the two-date preview plus a single Confirm button. Keep the "User-confirmed" label on Settings only.

### D3 — Visual identity is system defaults · P2

Bin colours are SwiftUI `.red`, `.yellow`, `.green`; `.yellow` on a light grouped background is low-contrast for the recycling glyph (the adjacent name keeps it accessible, but it looks washed out). The Welcome page shows three identical `trash` symbols with drop shadows. `BinType` still carries `gradient`, `darkColor`, `rgbComponents` and `gradientForeground`, none of which are used.

**Recommendation:** define three lid-colour tokens matching Auckland's actual lid colours with light/dark variants that pass 3:1 against both grouped backgrounds, and use them as a small lid chip beside every bin name (Today, Schedule, widget, notification body). Delete the dead colour code. Replace the Welcome trio with the three lid chips and the real next-collection preview once a schedule exists.

### D4 — iPad is configured for a world iPadOS 26 no longer runs · P1

`UIRequiresFullScreen` is set and only portrait is supported, with iPad in the device family. Apple's TN3192 (revised 9 October 2026) states the key is ignored starting in iPadOS 26, that apps which don't update "may experience broken layouts", and that from the iOS 27 SDK the system resizes the scene regardless. The September iPad runtime run never completed. The listing also advertises Mac (Apple silicon) and visionOS, neither of which has been exercised.

**Recommendation:** remove the key and the `INFOPLIST_KEY_UIRequiresFullScreen` build setting, support all orientations (the `maxWidth: 680` columns already help), and run the UI journey once on an iPad simulator in split view. Decide explicitly whether to keep Mac and visionOS availability in App Store Connect; untested surfaces generate one-star reviews.

### D5 — Open accessibility items · P2

Foundations are strong: 44-point targets, accessibility labels and values on calendar cells, Reduce Motion respected, one-column layouts at accessibility sizes, list alternative to the grid. Still open from September: native contrast audits failed on compact dark with text occluded at the floating tab bar; VoiceOver traversal order has not been recorded; no iPad pass.

### D6 — App icon asset is 874 KB · P3

The 1024-point marketing icon is an 874 KB PNG. Re-export at 8-bit with compression; it is the largest file in the bundle.

---

## 6. Experience

### E1 — The first notification a non-English household receives is in English · P1 (bug)

`NotificationService.swift:77` builds the title as `L(reminder.isEvening ? "Bins out tonight" : "Collection today")`. Because the key is a ternary expression, the localisation check script's regex never sees the literals, and neither string exists in `Localizable.xcstrings`. The script reports PASS. Users who chose Māori, Chinese, Hindi or Korean get English titles on every reminder. Fix: hoist the two literals into separate `L("…")` calls, add catalog entries in all five languages, and extend the script to flag any `L(` whose first argument is not a string literal.

### E2 — Welcome sets expectations the app does not meet · P2

"Smart reminders", "Calendar integration", "Home screen widget" are feature labels, two of which are optional and one of which is never prompted. Replace with the user outcome in three lines: *Know which bins go out tonight. Get a nudge the evening before. See it on your lock screen.*

### E3 — Language switching is good; one gap · P3

Runtime switching preserves navigation, refreshes widget and regenerates reminders. Info.plist purpose strings are localised in all five languages. Fluent-speaker review of critical strings remains unrecorded; the Māori sample read well ("Tēnei Rā", "Āpōpō", "Toenga Kai") but this auditor is not qualified to sign it off.

### E4 — Recovery flows are a strength · keep

Denied notifications show a direct *Open notification settings* action. Storage failures roll back and explain. Remove saved data handles calendar cleanup failure with an honest second confirmation. The invalid-profile path clears every output. These are better than most utilities and should be protected by the existing tests.

### E5 — No feedback after saving · P3

Saving a schedule, toggling calendar sync and refreshing reminders complete silently. Add `.sensoryFeedback(.success, trigger:)` on save and a brief inline "Updated" state on the refresh button.

---

## 7. Tech

### T1 — Build and tests · verified / recorded

The current tree builds cleanly for iOS Simulator with Xcode 26.3 (this audit, exit 0). The September record shows 31 iOS unit tests and three full UI journeys passing. Tests cover recurrence, calendar safety, notification planning, widget snapshots, persistence and content invariants. This is a strong base for a one-person project.

### T2 — Source control and CI · P1

No `.gitignore`. Tracked: `UserInterfaceState.xcuserstate`, seven `test_*.swift` scratch files at the repo root. Untracked in the folder: a 70 MB `BinDayNZ_SourceCode.zip`, `.DS_Store`, 19 MB of remediation evidence logs and screenshots. No CI.

**Recommendation:** add a standard Xcode `.gitignore`; untrack the xcuserstate and scratch files; move the zip out of the repo; commit the working tree in two or three logical commits (remediation, localisation, docs); add a GitHub Actions workflow that runs `xcodegen generate` and `xcodebuild test` on an iPhone simulator for every push. Consider whether 19 MB of evidence belongs in git or in a release attachment.

### T3 — Dead code · P2

Unused outside their defining files: `BinType.gradient`, `.darkColor`, `.rgbComponents`, `.gradientForeground`; `UpcomingCollection.isTomorrow`, `.daysUntil`; `ScheduleEngine.collectionsOnDate`, `.todaysCollections`, `.tomorrowsCollections`; `CollectionSchedule.dayOfWeek`; `Council` and `DataService.council(withId:)` are vestigial (one call site, constant answer); `UserProfile.councilId` and `.zoneId` are written but never read for a decision; `CollectionZone.suburbs` is always empty. Removing them shrinks the surface the widget target compiles and makes the model honest about being single-council.

### T4 — Age rating and listing configuration · P2

The listing is rated 16+ with "Unrestricted Web Access". The app's only web content is a `WKWebView` locked to a single `youtube-nocookie.com` embed behind an explicit *Load video* button. That is not unrestricted web access. Re-answer the questionnaire; a 4+ rating widens Family Sharing and Screen Time eligibility and removes a reason for parents to skip it.

### T5 — Privacy and security · good

Both bundles carry required-reason manifests for UserDefaults with correct reason codes. Network egress is limited to Apple services and the optional YouTube embed with a non-persistent data store. No third-party SDKs. The address is stored locally only. Keep this; it is a selling point, and the listing should say so in plain words.

### T6 — Architecture notes · P3

`ScheduleCoordinator` as the single writer for every output is the right shape and the detached/deleted-model guards are careful. Singletons (`.shared`) on `CalendarService`, `NotificationService`, `LanguageManager`, `DataService` make unit isolation harder; `CalendarService` already has an injectable initialiser, which is the pattern to extend when tests need it. Swift 5.9 language mode; moving to Swift 6 strict concurrency would surface a few `nonisolated` delegate paths but nothing alarming was seen.

### T7 — Launch screen requirement for iOS 27 · informational

TN3192 notes a launch screen is required for App Store submission from the iOS 27 SDK. The Info.plist declares an empty `UILaunchScreen` dictionary, which satisfies the requirement. No action.

---

## 8. Performance

Nothing here is user-visible at today's data size. These are cheap, correct changes worth making before new features multiply the call sites.

### F1 — `ScheduleEngine.collectionCalendar` is rebuilt on every access · P2

It is a computed static that constructs a `Calendar` and resolves `TimeZone(identifier: "Pacific/Auckland")` each call. There are 44 call sites, and the hottest are inside loops: `binsCollectedOn` → `isRegularCollection` → `collectionCalendar`, evaluated per schedule per day when the month grid renders (31 days × 3 schedules × several accesses). Change to `static let`. `Calendar` is a value type and safe to share.

### F2 — The saved schedule is JSON-decoded on every view evaluation · P2

`DataService.zone(for:)` decodes `manualSchedulesJSON` each time `currentZone` is read in Today, Schedule and Settings. Today sits inside `TimelineView(.everyMinute)`, so while visible it decodes and recomputes 30 upcoming collections every minute and on every SwiftData change. Cache the decoded zone keyed on the JSON string (a one-entry cache on `DataService` is enough).

### F3 — A `DateFormatter` is allocated per date label · P3

`collectionDateLabel` creates a formatter every call. The month grid calls it for every day cell's accessibility label (31–35 per render) plus the hero and list. Cache one formatter per (template, locale) pair; invalidate on language change.

### F4 — Widget and notifications · fine

The widget timeline supplies eight entries and recomputes from rules; notification scheduling awaits 61 adds sequentially, which is fine for a batch that runs on foreground. No change needed.

---

## 9. Prioritised roadmap

Effort is a rough solo-developer estimate.

### Now — before 1.2 ships (about one to two weeks)

| # | Item | Why first | Effort |
|---|---|---|---|
| 1 | Add `.gitignore`, untrack junk, commit the tree, add CI (T2, B6) | Protects six months of work | 0.5 day |
| 2 | Fix untranslated notification titles and harden the check script (E1) | Every non-English reminder is wrong today | 0.5 day |
| 3 | Remove `UIRequiresFullScreen`, support all orientations, one iPad split-view pass; decide Mac/visionOS (D4) | iPadOS 26 already ignores the key | 1 day |
| 4 | Today hierarchy: toolbar for Change schedule, one status row, copy consolidation into *How Bin Day works* (D1, D2) | The home screen currently argues against itself | 2 days |
| 5 | Rewrite store copy around outcome; fix age rating to 4+; reply to the June review on release (B1, T4) | The listing is the first screen most people see | 0.5 day |
| 6 | Performance quick wins: static calendar, cached zone, cached formatters (F1–F3) | Cheap now, expensive after features land | 0.5 day |
| 7 | Delete dead code (T3) | Keeps the widget target lean | 0.5 day |

### Next — 1.3, before the Christmas holiday window (by early December)

| # | Item | Why | Effort |
|---|---|---|---|
| 8 | Guided setup: weekday picker + this-week/next-week, in-app council page (P1) | Largest single leak in the funnel | 3 days |
| 9 | Success screen with *Add widget* and *Share* cards; `accessoryRectangular` widget (P2, P4) | Activation and the strongest retention channel | 2 days |
| 10 | Holiday-shift pack for Christmas 2026 / New Year 2027 with one-tap apply (B3) | Seasonal spike; competitor's lead feature | 2 days plus source review |
| 11 | Notification category, actions, deep link, time-sensitive (P3) | Turns a text into a tap | 1 day |
| 12 | Share-a-schedule deep link (B2) | Only free growth loop | 1.5 days |
| 13 | Lid-colour tokens and chips across surfaces (D3) | Recognition at a glance; identity | 1 day |

### Later — once the above is measured

| # | Item | Gate |
|---|---|---|
| 14 | Email Auckland Council Waste Solutions about data access (B4) | Send now; build only on a written yes |
| 15 | `BGAppRefreshTask` top-up (P5) | After observing renewal behaviour for one cycle |
| 16 | Opt-in diagnostics share with the local metrics in section 2 | After the success screen exists to host it |
| 17 | Fluent-speaker review of critical strings (E3) | Before promoting any non-English language in the listing |
| 18 | Optional supporter tip (B5) | Only if costs need covering and retention is proven |

---

## 10. What this audit did not establish

- No runtime tests were executed in this pass; the build was verified, test results are quoted from the September record.
- No device delivery of notifications, no widget-family rendering, no VoiceOver traversal, no iPad or Mac run.
- No user research, no funnel data; every engagement claim is reasoned from the flow, not measured.
- Council holiday rules were read from search excerpts; the council's holiday page itself returned HTTP 406 to the fetch tool. Verify the dated table on the live page before bundling it.
- Translation quality was not assessed by a fluent speaker.

## Sources consulted

- [Bin Day NZ — NZ App Store listing](https://apps.apple.com/nz/app/bin-day-nz/id6761326182)
- [Collection for Auckland — NZ App Store listing](https://apps.apple.com/nz/app/collection-for-auckland/id866911194)
- [TN3192: Migrating your app from the deprecated UIRequiresFullScreen key](https://developer.apple.com/documentation/technotes/tn3192-migrating-your-app-from-the-deprecated-uirequiresfullscreen-key)
- [Auckland Council — Public holiday collections](https://www.aucklandcouncil.govt.nz/en/rubbish-recycling/rubbish-recycling-collections/public-holiday-collections.html)
- [data.govt.nz dataset request 304 — Rubbish and Recycling Collection Dates](https://data.govt.nz/datasetrequest/show/304)
- [rusq/aklapi — unofficial Auckland collection API](https://github.com/rusq/aklapi), [reubznz/rubbish-day — scraper, now broken](https://github.com/reubznz/rubbish-day)
- Repository: `docs/audits/2026-09-06/`, `docs/remediation/2026-09-06/status.md`, `docs/remediation/2026-09-06/store-copy.md`, all Swift sources under `BinDayNZ/`, `BinDayNZWidget/`, `BinDayNZTests/`.
