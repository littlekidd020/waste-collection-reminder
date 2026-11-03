# Bin Day NZ — competitor analysis and feature enhancement review

**Date:** 2 November 2026 (Pacific/Auckland). **Subject:** committed candidate 1.2 (3) at commit `4a8af1f`, compared with reminder apps in New Zealand, Australia, the UK, North America and Germany. **Evidence:** full read of the app, widget and service source; App Store listings and council pages read on the audit date; web search for each product. No competitor app was installed or run. Ratings and version numbers are as displayed on the listing on the audit date.

This document extends the [1 November engagement audit](../2026-11-01/engagement-audit.md). It does not repeat that audit's findings about setup, copy, iPad or store listing; those still stand. It answers two questions: *where does Bin Day NZ sit against the market*, and *which feature gaps are worth closing*.

---

## 1. Summary

Bin Day NZ competes in a category with two kinds of product: **council-fed apps** that look up the schedule from an address (Collection for Auckland, Antenno, LoopedIn, Recycle Coach, Christchurch Bins) and **personal schedule apps** where the household types its own recurrence (Bin Day Alert, Trash Collection Calendar, Abfall+). Bin Day NZ is now firmly the second kind, with Auckland-specific content on top.

Against the personal-schedule apps it is already competitive on the core loop (two reminders, widgets on home and lock screen, calendar sync, holiday shifts, share link, five languages, no account, no ads). Three capabilities that most of that group ship and Bin Day NZ does not: **a bring-bins-in reminder, Siri/Shortcuts, and sync across the user's own devices**. One capability the council-fed apps all have and Bin Day NZ cannot: automatic lookup. That gap is strategic and already has a plan (ask the council for data); nothing in this review changes it.

The direct competitor, Collection for Auckland, has moved toward entertainment (quiz, bin skins, coins) and ads. Its one 2025 review reports a blank screen after entering an address, which is the failure mode of a scraped data source. Bin Day NZ's position should be the opposite: the reminder that never breaks when the council website changes, with nothing to buy and nothing watching you. The listing should say that in those words.

**Recommended additions, in order:** plain-language schedule in the share text (so Android and non-app household members get value), notification actions (Done, Remind me later), an optional bring-bins-in reminder, direct links to report a missed collection and book inorganic, a pause-while-away control, then App Intents for Siri and Shortcuts, then iCloud key-value sync. Everything else is deferred or declined; see section 5.

---

## 2. Who the competitors are

### 2.1 Direct: Auckland households

| Product | Model | What it offers | Signals |
|---|---|---|---|
| **Collection for Auckland** (App House Ltd) | Free, ads, $4.99 ad removal; iOS (Android not confirmed) | Address lookup of rubbish and recycling dates; holiday-week reminders; "Binjamin" photo item identifier; recycling guide; rates and valuation lookup; "Trash Talk" quiz; bin skins earned with coins; saved home and recent addresses; report-a-missed-collection link | 4.6 from about 1.2K ratings. Version 3.8.0 shipped the week before this audit ("biggest update yet": UI, quiz, coins). Review complaints: ads overlaying controls (2022), blank screen after address entry on iOS 18.3 (2025), stuck badge (2020). Food scraps not named in the listing. |
| **Auckland Council** (first party) | Free | Address lookup on the website; PDF collection calendars; a text-reminder sign-up for collection-day changes on the public-holiday page; "Binny" sorting chatbot (app, Messenger); "find where an item goes" search | No API (data.govt.nz request 304). The holiday and collections pages returned HTTP 406 to both fetch tools and the in-app browser used for this audit, so the text-reminder status and the holiday table could not be confirmed on the live page. The 1 November audit stated holiday texts were discontinued; search results on this date still describe a sign-up. Treat as **unverified either way**. |
| **DIY** | Free | A Reddit shortcut that reads the council's address page with Apple Intelligence and posts a notification; Home Assistant's waste-collection integration; the Bindicator lamp (A$39) | Tech-savvy households want automatic lookup and holiday handling, and one commenter still gets confused about which week is recycling week. That last point is Bin Day NZ's exact job. |

### 2.2 Other New Zealand councils

| Product | Notes |
|---|---|
| **Christchurch Bins** (CCC) | Address lookup; multiple addresses; **put-out and bring-in reminders**; item lookup; holiday notices. 2.8 from 156 ratings; complaints about freezing, server errors, and a hidden item lookup. Last update 26 August. |
| **Antenno** (Datacom) | Free platform used by more than 50 councils; address-based route reminders with per-address category toggles. Waipā issued an alert in April 2026 after residents received incorrect recycling notifications. Not used by Auckland. |
| **Shared kerbside app** (Dunedin, Tauranga, Central Otago) | Council-funded, replaces older bespoke apps. |

### 2.3 Australia

| Product | Notes |
|---|---|
| **What Bin Day** (Socket Software) | Auto schedules for about 20 councils, manual entry elsewhere; A$1.99 unlock for reminders, extra locations and kerbside-cleanup events. 2.9 from 144; last update December 2021. Complaints: missing green bin, wrong fortnightly assumption, area not covered. |
| **LoopedIn Councils** | Council-funded; 50+ councils, 250K downloads; calendar, A–Z guide, delay notifications, report missed bin, reorder caddy bags; no ads. Complaint: cannot add a second council. |
| **Brisbane Bin and Recycling** | Council app; reminders fire only on collection day; reminders reset on address change. |
| **Bin Day Alert** (Hacknicity, $1.99 one-off) | Manual; up to two alerts per schedule; **snooze 15 min, 1 day or 1 week** for holidays; **disable-all for holidays away**; weekly through every 8 weeks; **Siri Shortcuts**; **Apple Watch**; home and lock screen widgets; calendar view; seasonal inactive schedules; iCloud Drive backup; **share via AirDrop, link or QR**. 5.0 from 8; last feature release January 2023. |

### 2.4 UK, North America, Germany

| Product | Notes |
|---|---|
| **Recycle Coach** (Municipal Media) | Business-to-government; 3,000+ municipalities; reminders; "What Goes Where" search of 10,000+ items; image-recognition scanning; report missed collection or broken bin; service-disruption alerts; polls and quizzes. Partnered with Bartec (UK) in March 2026; winning municipalities from ReCollect on price. |
| **UK council apps** (Milton Keynes, Rotherham, South Ayrshire MyBins) and **Binformation**, **BinPing** (email/SMS) | Council-fed calendars with reminders. Nothing here that the NZ council apps do not also do. |
| **Trash Collection Calendar** (Inspired Apps, free + $9.99 lifetime) | Manual; custom waste types with colour and icon; weekly, fortnightly, monthly, custom and **seasonal** schedules; reschedule one collection; evening and morning reminders; **optional bring-bins-in reminder**; extra alert per bin group; **mark put out, collected, brought in**; calendar view; widget; **Apple Watch**; **shareable schedule images**; **iCloud sharing so every household member gets notifications**; no account. Too new to show a rating. |
| **Binify** (BrewtayBits, subscription) | Two Pennsylvania townships; automatic holiday-shift alerts in advance; shows which recycling rotation week it is; SMS alerts for household members (paid); offline cache. |
| **Abfall+** (Germany, free) | Nationwide council data; reminders two days before, one day before or same day at a chosen time; filter by bin type; offline; Apple Watch; widget; Siri. |

---

## 3. Feature comparison

Legend: ● has it · ◐ partial · ○ missing · — not applicable. "Personal apps" = Bin Day Alert, Trash Collection Calendar, Abfall+ as a group.

| Capability | Bin Day NZ 1.2 | Collection for Auckland | Council apps (CHC, Antenno, LoopedIn, Recycle Coach) | Personal apps |
|---|---|---|---|---|
| Automatic schedule from address | ○ (by design, no data access) | ● | ● | ○ / ◐ (Abfall+ ●) |
| Separate weekly / fortnightly per bin | ● | ● | ● | ● |
| Food scraps as its own bin | ● | ○ not listed | varies | ● (custom types) |
| Evening-before and morning-of reminders at chosen times | ● | ◐ | ◐ (often one reminder) | ● |
| Bring-bins-in reminder | ○ | ○ | ◐ (Christchurch ●) | ● (TCC) |
| Notification actions (done, snooze) | ○ (category defined, no actions) | ○ | ○ | ◐ (Bin Day Alert snooze) |
| Pause while away | ○ (per-bin one-off skip only) | ○ | ○ | ● (Bin Day Alert) |
| Holiday shifts with one-tap apply | ● (bundled 2026–27 table, 21-day lead) | ● (holiday-week reminders) | ● (push notices) | ◐ (snooze 1 day; Binify ●) |
| Home screen widget | ● small, medium | ○ not listed | ○ mostly | ● |
| Lock screen widgets | ● inline, circular, rectangular | ○ | ○ | ◐ (Bin Day Alert ●) |
| Apple Watch | ○ | ○ | ○ | ● (3 of 3) |
| Siri / Shortcuts / Spotlight | ○ | ○ | ○ | ● (Bin Day Alert, Abfall+) |
| Calendar sync | ● app-owned events | ○ | ○ | ◐ |
| .ics export | ● 90 days | ○ | ○ | ○ |
| Sync across the user's own devices | ○ (local only) | ● (account-less lookup, so trivially) | ● | ● (iCloud) |
| Share schedule with household | ● `bindaynz://` link + store link | ○ | ○ | ● (link/QR/AirDrop; TCC iCloud sharing with notifications) |
| Household members on Android get value | ○ (link is iOS-only, text has no dates) | ● (they install the app) | ● | ◐ (TCC image) |
| Multiple addresses | ○ | ● (saved + recents) | ● | ● |
| Sorting guide | ◐ (about 5 items per bin, no search) | ● photo identifier | ● searchable A–Z (10K items at Recycle Coach) | ○ |
| Report missed collection | ○ (generic council link only) | ● | ● | ○ |
| Service alerts (weather, strikes) | ○ | ○ | ● | ○ |
| Offline | ● | ○ | ◐ | ● |
| Languages | ● 5 | ○ | ○ | ○ (1–2) |
| No ads, no account, no tracking | ● | ○ (ads, $4.99 removal) | ◐ (council-funded; some analytics) | ● mostly |
| Accessibility work recorded | ● | ○ ("not yet stated") | ○ | ○ |
| Android | ○ | ? not confirmed | ● | ◐ |
| Gamification | ○ | ● quiz, coins, skins | ◐ polls | ○ |

**Where Bin Day NZ leads:** reminder depth (two reminders at chosen times, time-sensitive, routed), lock-screen widget coverage, calendar integration, languages, privacy, accessibility, and holiday handling that writes real one-off changes rather than just a notice.

**Where it trails the whole field:** bring-in reminder, Siri, Watch, cross-device sync, searchable sorting guide, and (strategically) automatic lookup.

**Where it trails only the direct competitor:** address lookup, missed-collection reporting, multiple addresses, and sheer rating volume (1.2K vs one review).

---

## 4. What the market says people want

Drawn from reviews and council launch pages, not from Bin Day NZ users (there is no research yet; the pilot protocol in `docs/pilot-and-maintenance.md` remains the way to get it).

1. **"Which week is it?"** The recurring confusion is fortnightly recycling, not the weekday. Every well-rated app answers this on the first screen. Bin Day NZ's hero card does; the widget should always name the bins, never just a date.
2. **Holiday weeks.** The most-mentioned reason people miss a bin. Council SMS, Collection for Auckland, Binify and Christchurch all make it a headline feature. Bin Day NZ's card is good; it needs its table verified on the live page before release (blocked by the 406 in this pass).
3. **The whole household, not one phone.** Bindicator's entire pitch, Trash Collection Calendar's iCloud sharing, Binify's SMS. A reminder on one person's phone is a single point of failure.
4. **Reliability over features.** What Bin Day (2.9), Christchurch Bins (2.8) and Antenno's Waipā incident show that wrong or missing notifications cost more than any feature earns. Collection for Auckland's 2025 blank-screen review is the same risk. Bin Day NZ's manual model cannot break this way, and the listing should claim that.
5. **People resent paying for reminders.** A What Bin Day reviewer: phones already do this free. Keep the core free; any supporter purchase stays optional.
6. **Bring the bins back in.** Christchurch and Trash Collection Calendar both list it; it is a cheap, visible differentiator among Auckland options.

---

## 5. Feature enhancement recommendations

Effort is a rough solo-developer estimate. "Horizon" refers to the 60-request reminder batch; iOS caps pending requests at 64.

### Tier 1 — small, ship in 1.2.x

| # | Enhancement | Why | Where | Effort |
|---|---|---|---|---|
| 1 | **Plain-language schedule in the share text.** "Rubbish: every Tuesday. Recycling: every second Tuesday, next 11 Nov. Food scraps: every Tuesday." followed by the link and store URL. | Today the text is only a `bindaynz://` link plus a store link. Anyone on Android, or without the app, gets nothing usable. The whole street has the same schedule; make the message useful on its own. | `ScheduleLink.shareText` | 0.5 day |
| 2 | **Notification actions: *Done* and *Remind me in 1 hour*.** Optionally *Skip this one* for the evening reminder, writing a one-off cancellation. | The `binday.collection` category exists with `actions: []`. Bin Day Alert's snooze is its most-praised feature. Actions turn a banner into a tap without opening the app. | `NotificationRouter.install`, `didReceive` | 0.5–1 day |
| 3 | **Optional bring-bins-in reminder** (default off; afternoon of collection day at a chosen time). | Only Christchurch Bins offers it in NZ; Trash Collection Calendar shows it is expected in personal apps. Trade-off: a third request per date cuts the horizon from 30 to 20 collection dates when all three are on. Acceptable; the renewal notice still covers it, and the planned `BGAppRefreshTask` top-up makes it moot. | `ReminderPreferences`, `NotificationService.plan`, `ReminderPreferenceFields` | 1 day |
| 4 | **Direct links: *Report a missed collection*, *Book an inorganic collection*, *Council text alerts* (if live).** | Collection for Auckland, LoopedIn and Recycle Coach all route service problems to the council from inside the app. Bin Day NZ sends people to a generic council page. | Settings "Your schedule" section and Info | 0.25 day |
| 5 | **Pause while away.** One control: "Pause reminders while away" with a resume date. Built as a reminder filter, not as schedule changes: the collections still happen for the street, so widgets and calendar keep showing the real dates and only the alerts are silenced. The pause clears itself once the date passes. | Bin Day Alert's disable-all is the standard; today the user must skip each bin's date separately in the advanced editor. | `ReminderPreferences.pausedUntil`, `NotificationService.plan`, a Settings section | 1 day |

### Tier 2 — 1.3, after the engagement roadmap items

| # | Enhancement | Why | Effort |
|---|---|---|---|
| 6 | **App Intents for Siri, Shortcuts and Spotlight:** "What bins go out tonight?", "When is recycling next?", plus an *Open Today* intent. | Zero-UI access from Siri, the Action Button, CarPlay and Apple Watch Siri without a Watch app. Bin Day Alert and Abfall+ both have it; no Auckland option does. Reuses `ScheduleEngine`. | 1.5 days |
| 7 | **Sync across the user's own devices with `NSUbiquitousKeyValueStore`** (schedule JSON, reminder preferences, language). No account, no CloudKit schema, no server. | README says "no private CloudKit sync" as a scoping statement; key-value sync is a different, much smaller thing and every personal app in the comparison keeps iPhone and iPad in step. Changing the schedule on an iPad today leaves the iPhone's reminders stale. | 1–2 days plus conflict rule (last writer wins, with `scheduleConfirmedAt`) |
| 8 | **Searchable A–Z sorting guide** built from the council's published item list, dated and sourced like the bin guide, indexed into Spotlight. | Every council-fed app has it; the current guide lists about five items per bin. This is content work more than code, and it must carry a review date like `guideReviewDate`. Not AI, not photos. | 3 days plus content review |
| 9 | **Apple Watch app** with a Smart Stack widget and complication, using the existing rectangular widget view. | All three personal apps have one. Needs a new target; the schedule snapshot is already in the App Group. | 3 days |

### Tier 3 — gated

| # | Enhancement | Gate |
|---|---|---|
| 10 | Automatic lookup from council data | Written yes from Auckland Council Waste Solutions (already in the 1 November roadmap). Do not scrape. |
| 11 | Multiple addresses | Evidence from the pilot that landlords, split households or baches are a real segment. |
| 12 | Live Activity on bin night (Lock Screen and Dynamic Island from the evening reminder until the morning one) | Nobody in the field has it; worth a prototype only after Tier 1 and 2 are measured. |
| 13 | A second council (Christchurch's 2.8-star app is an opening; Wellington has no app of its own in the results) | A maintainable content owner for the second council's bin guide and holiday rules; the recurrence engine needs no change. |

### Declined, with reasons

- **Ads or an ad-removal purchase.** The competitor's reviews show the cost; the no-ads position is Bin Day NZ's clearest differentiator.
- **Quiz, coins, bin skins.** Collection for Auckland has gone this way; it is not what reviews ask for and it would dilute a utility that is meant to need no attention.
- **Photo or AI item identification.** Council-grade content risk for a one-person team; the council's own Binny and search already exist and are linked.
- **Rates and valuation lookup.** Unrelated to the job.
- **Service-disruption alerts.** Needs a data feed the council does not provide.
- **Scraping the council site.** Collection for Auckland's blank-screen review and the broken community scrapers show the failure mode.

---

## 6. Positioning

The listing should claim the three things no Auckland alternative can:

1. **It never breaks.** Your schedule lives on your phone; a council website change cannot take your reminders away.
2. **Nothing to buy, nothing watching you.** No ads, no account, no tracking, no analytics.
3. **Made for your lock screen.** Three lock-screen widgets, two home-screen widgets, calendar sync and a time-sensitive reminder.

And one honest limit, once: you confirm the dates with the council; the app keeps them.

---

## 7. What this review did not establish

- Auckland Council's public-holiday and collections pages returned HTTP 406 to every tool used. The bundled 2026–27 holiday table and the status of council text reminders remain unverified on the live page.
- Collection for Auckland was not installed; features are from its listing and release notes. Its Android availability was not confirmed.
- All ratings and version numbers were read on 2 November 2026 from App Store listings and may have changed.
- No Bin Day NZ user research exists; section 4 is inferred from other products' reviews.

## Sources

- [Collection for Auckland — NZ App Store](https://apps.apple.com/nz/app/collection-for-auckland/id866911194)
- [Binny — NZ App Store](https://apps.apple.com/nz/app/binny/id1403678779) (listing returned 404 on the audit date; details from search excerpts)
- [Christchurch Bins — App Store](https://apps.apple.com/nz/app/id898683154)
- [Enviro NZ — Bins & Collections](https://apps.apple.com/nz/app/environz/id1403213045) (on-demand bookings, not a reminder competitor)
- [Antenno — Invercargill City Council](https://www.icc.govt.nz/news-events/03-antenno), [Waipā alert on incorrect Antenno notifications, April 2026](https://insidegovernment.co.nz/waipa-issues-alert-for-recycling-app/)
- [Dunedin — new kerbside collection app](https://www.dunedin.govt.nz/services/rubbish-and-recycling/kerbside-faq/faqs-july-1/new-dcc-kerbside-collection-app)
- [What Bin Day — AU App Store](https://apps.apple.com/au/app/what-bin-day/id586144371)
- [LoopedIn Councils — Hobsons Bay](https://www.hobsonsbay.vic.gov.au/News-Media/2026/January/Keep-looped-in-with-new-bin-app), [Livingstone](https://www.livingstone.qld.gov.au/Your-Council/Publications-and-Media/Media-Releases/New-and-Improved-Waste-App-Launching-Soon-for-Livingstone-Residents), [Kempsey](https://www.kempsey.nsw.gov.au/Residents/Waste-recycling/Household-waste/LoopedIn-Councils-App)
- [Brisbane Bin and Recycling app](https://www.brisbane.qld.gov.au/about-council/your-brisbane/environment-and-sustainability/recycling/brisbane-bin-and-recycling-app)
- [Bin Day Alert — App Store](https://apps.apple.com/us/app/-/id762807953)
- [Trash Collection Calendar — App Store](https://apps.apple.com/us/app/-/id6752492788)
- [Binify — App Store](https://apps.apple.com/us/app/binify/id6761966154)
- [Abfall+ — DE App Store](https://apps.apple.com/de/app/abfall-app-abfall/id493516557)
- [Recycle Coach — Westchester County](https://www.westchestercountyny.gov/all-press-releases/westchester-county-launches-recycle-coach-mobile-app), [Dutchess County](https://www.dutchessny.gov/Departments/County-Executive/County-Offers-Recycle-Coach-App-to-Make-Recycling-Easier-for-Dutchess-Residents.htm), [North Battleford switch from ReCollect](https://www.recyclingtoday.com/news/north-battleford-canada-adopts-recycle-coach-app)
- [Bindicator vendor comparison of Australian apps](https://bindicator-website.pages.dev/blog/the-best-bin-day-reminder-apps-in-australia-2026) (vendor blog; used for feature lists only)
- [Reddit: Auckland bin-day shortcut thread, May 2026 snapshot](https://reddit.sentinel-team.org/posts/1t0gquf/snapshots/2026-05-01T23%3A31%3A42.293805Z)
- [data.govt.nz dataset request 304](https://data.govt.nz/datasetrequest/show/304)
- [Auckland Council — public holiday collections](https://www.aucklandcouncil.govt.nz/en/rubbish-recycling/rubbish-recycling-collections/public-holiday-collections.html) (HTTP 406 on the audit date)
