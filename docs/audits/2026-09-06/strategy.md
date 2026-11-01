# Bin Day NZ — strategy, distribution and public trust audit

Audit date: **6 September 2026, Pacific/Auckland**. Scope: current working tree, product documents and publicly available primary sources. The published App Store binary was not installed or inspected. Public metadata is evidence about the published offer, not proof of candidate behavior. No adoption analytics, customer interviews, cost ledger or funding agreements were available.

## Decision

**Keep a small, free Auckland product while proving dependable reminders and a correction path. Hold national expansion and monetisation implementation.** The product has a plausible household job, but the repository establishes features rather than sustained service reliability or demand. A release must earn its accuracy promise before additional promotion.

The strongest proposed positioning is: *Know which bins to put out, with a clearly sourced schedule you can check and correct.* This is a strategic hypothesis, not a demonstrated advantage today. The defensible work would be reliable address matching, exceptions and freshness, accessible glanceable delivery, and fast recovery when information is wrong. Native presentation and a zero price alone do not distinguish this product from current alternatives.

| Domain | Audit assessment | Confidence |
|---|---|---|
| Household problem | Credible practical need; scale and frequency unmeasured | Medium |
| Differentiation | Weak in current documented offer; reliability and accessibility could make it stronger | Medium |
| Auckland-first boundary | Sensible, but advertised breadth exceeds the verified scope | High on source/metadata mismatch |
| Free community sustainability | Undemonstrated; no ongoing maintenance budget or owner process in reviewed docs | High on documentation gap, unknown actual costs |
| Public trust and distribution | Release work required for in-app privacy/support, coverage promises, and version/device configuration | High |
| Commercial readiness | Insufficient evidence to justify a paid platform, subscription or national rollout | High on missing evidence; not a finding of no demand |

## Current offer and alternatives

The [NZ App Store listing](https://apps.apple.com/nz/app/bin-day-nz/id6761326182), retrieved on the audit date, advertises version 1.1 dated 16 April, free pricing, iPhone/iPad availability, iOS/iPadOS 17+, English and Māori, and a 16+ age classification associated with unrestricted web access. It shows one rating and a June review requesting collection-day override. Its description promises precise address lookup, dependable reminders and coverage beyond Auckland; release notes describe real-time council lookup. These are marketing claims requiring candidate verification. A single review is one useful problem signal, not a measure of adoption, retention or market size.

The local design document specifies a free community service, Auckland-first expansion, widgets, calendars, multilingual content and CloudKit updates. The current dataset has Auckland zones and five councils with no zones. Manual scheduling exists in the working tree. The published review therefore does not establish that the candidate still lacks overrides. See `docs/plans/2026-03-16-bin-day-nz-design.md`, `BinDayNZ/Resources/councils.json` and the functional audit.

| Alternative | Verified offer | Strategic implication — audit inference |
|---|---|---|
| Auckland Council website | Address/rates-assessment lookup, collection dates and missed-collection guidance. [Official lookup](https://www.aucklandcouncil.govt.nz/rubbish-recycling/rubbish-recycling-collections/Pages/rubbish-recycling-collection-days.aspx) | Authoritative reference with no additional app installation. Bin Day must reduce repeated checking without disguising stale information. |
| Council holiday guidance | Retrieved official page says holiday SMS reminders have ended and directs people to address search. It describes holiday delays with city-centre/private/island exceptions. Its rendered table covers 2025–early 2026. [Official holiday page](https://www.aucklandcouncil.govt.nz/rubbish-recycling/rubbish-recycling-collections/Pages/public-holiday-collections.aspx) | A possible gap for reliable exception reminders; verify the SMS status and next holiday details live before using them in acquisition copy. Never translate a generic holiday rule into universal Auckland coverage. |
| Collection for Auckland | Existing Auckland date lookup, reminders, sorting guidance and disposal assistance. NZ listing shows free access with in-app purchases, English, 1.2K ratings and a 4.6 aggregate at retrieval. [Developer’s App Store listing](https://apps.apple.com/nz/app/collection-for-auckland/id866911194) | A direct established substitute. Ratings show review volume, not current active households or revenue. Feature parity is insufficient; test whether users actually prefer Bin Day’s simpler, accessible experience. |
| Antenno | Datacom provides council-managed location alerts, scheduled bin reminders and two-way reporting. [Datacom product page](https://datacom.com/nz/en/products/datascape/antenno) | Relevant to council-by-council expansion and any B2B premise. Do not assume Auckland offers it; local availability requires verification. A small maintainer should not build a general council engagement platform without a specific buyer and unmet requirement. |
| Recurring calendar event | Apple supports configurable weekly intervals; Google supports repeated events and editing occurrences. [Apple Calendar](https://support.apple.com/en-ae/guide/calendar/icl1018/mac), [Google Calendar](https://support.google.com/calendar/answer/37115?hl=en) | A strong low-effort substitute for a known stable schedule. It requires manual exception handling. Bin Day needs to outperform this baseline on correct setup and ongoing changes, rather than merely reproduce recurrence. |

**Source freshness limitation:** the web reader returned an older cached Council holiday table; a direct read of the modern Council holiday URL returned HTTP 406. That response is an audit-tool observation, not proof the app’s address endpoint fails. The lookup/holiday sources establish the service and exception model, but they do not validate a September–December 2026 address schedule.

Council changes are operational, not just annual holiday arithmetic. A [10 April 2026 Council notice](https://ourauckland.aucklandcouncil.govt.nz/news/2026/04/rubbish-collections-during-cyclone-vaiano/) describes weather-related changes varying by collection type and locality. Conversely, the [current trial consultation result](https://akhaveyoursay.aucklandcouncil.govt.nz/proposed-fortnightly-rubbish-collection-trial) says the proposed six-month fortnightly rubbish trial did not proceed and weekly collections continue in the named areas. Older proposal dates must not become production schedule rules.

## Findings and release acceptance

### S01 — P1: Coverage and accuracy promises exceed demonstrated evidence

**Classification:** confirmed source/marketing gap; exact rate of wrong answers unmeasured. **Impact:** people can reasonably treat a plausible date as an authoritative household instruction.

**Evidence:** `AddressSearchService.swift:72–105` retains a suburb-derived zone if live resolution fails; `184–206` selects the first council search result without comparing its returned address; `209–260` converts parsed upcoming dates to a recurring bundled zone. The current bundle covers one council. There is no stored source-check timestamp or uncertainty state in the returned address structure. These facts do not prove every matched address is wrong; they show why broad precision and ongoing real-time accuracy cannot yet be promised.

**Smallest durable recommendation:** make address confirmation and source freshness part of the core offer. Restrict public coverage to tested service types and areas. A failed authoritative lookup should lead to a clearly labelled user-entered schedule rather than an inferred schedule presented as confirmed. Treat holidays and disruptions as exceptions with a source, not a new permanent weekday.

**Acceptance:** a coverage statement agrees across listing, onboarding and help; ambiguous/unavailable lookups cannot silently appear authoritative; confirmed and manual schedules are distinguishable; the verification matrix includes units, boundaries and explicitly unsupported/private services; current official dates agree with all app outputs for the supported sample set.

### S02 — P1: Privacy policy is not accessible inside the candidate app

**Classification:** confirmed source omission. **Impact:** users cannot inspect handling of their home address and optional services from the app; next-submission review risk.

**Evidence:** a search across all Swift views found no privacy-policy link. Settings About (`SettingsView.swift:150–164`) contains a fixed version, Council link and credit. Apple requires an accessible in-app policy link as well as metadata in [App Review Guidelines 5.1.1(i)](https://developer.apple.com/app-store/review/guidelines/#data-collection-and-storage).

**Smallest durable recommendation:** link the maintained policy from Settings and the address-entry flow. Keep it readable without an account.

**Acceptance:** a tester reaches the policy from Settings and before saving an address; the URL resolves in the release environment and text matches the shipped implementation.

### S03 — P1: Public privacy statement does not explain actual network flows

**Classification:** confirmed disclosure incompleteness; vendor retention and App Store label correctness remain unverified. **Impact:** users can interpret the short statement as meaning their address never leaves the phone.

**Evidence:** the [linked public policy](https://gist.github.com/littlekidd020/91c09b9a86a6b6f3a2dd161fddb4d351), directly retrieved on 6 September, describes preferences as local/personal-iCloud data and broadly denies personal-data storage or sharing. Candidate code performs Apple address search, sends an address query to Council (`AddressSearchService.swift:184–194`) and loads a YouTube embed (`YouTubePlayerView.swift:12–24,35–45`). The candidate has only App Group entitlements; the CloudKit service uses a public database for council data and has no caller. These are distinct from personal cross-device profile sync.

**Smallest durable recommendation:** describe local preferences, optional device-location lookup, Council address requests, calendar access, YouTube requests, deletion and support separately. Verify third-party behavior before finalising the App Store answers. Remove personal-iCloud sync claims unless that behavior is demonstrated in the released configuration; distinguish ordinary device backup from application sync.

**Acceptance:** record a data-flow inventory and observe requests for address entry and video opening; identify recipients/purpose and any retention from authoritative vendor evidence; revise policy and metadata consistently. Do not assert the current “Data Not Collected” label is automatically false: Apple excludes Apple’s own framework collection from developer responsibility and distinguishes transient request processing from retained collection; embedded-web collection still requires assessment. [Apple privacy disclosure guidance](https://developer.apple.com/app-store/app-privacy-details/)

### S04 — P1: No developer support or wrong-schedule correction route

**Classification:** confirmed app-source omission. **Impact:** an app error can send users to the council without alerting the maintainer; errors remain uncorrected and trust declines.

**Evidence:** Settings has no developer contact; Info’s “Report a missed collection” (`InfoView.swift:348–352`) calls Council. That is useful for collection-service failures but does not report an incorrect app schedule. Apple expects a contact route in the app and Support URL. [App Review Guidelines 1.5](https://developer.apple.com/app-store/review/guidelines/#developer-information)

**Smallest durable recommendation:** add one app-support contact route with separate choices for incorrect app information and an actual missed pickup. Keep the existing council route. Let users review any diagnostic text before sending; exclude their full address by default.

**Acceptance:** a user can report an incorrect app date and reach the maintainer; the report can include app version and selected dates without automatic personal disclosure; a documented owner triages errors and records correction/closure. Verify the configured App Store Support URL separately; it was not established from the rendered listing.

### S05 — P1: Release metadata and device configuration have drifted

**Classification:** confirmed configuration mismatch; submission outcome not tested here. **Impact:** the wrong configuration can ship, omit an advertised device family or report an unhelpful support version.

**Evidence:** candidate `project.yml` sets iPhone-only family `1`, version `1.0.0`, build `2`; the checked-in project’s app settings include family `1,2`; Settings hard-codes `1.0.0`. This does not match the published version record noted above. Regenerating the project can change the advertised device boundary.

**Smallest durable recommendation:** use one authoritative build specification, choose and verify the currently advertised iPhone/iPad support, and read the installed bundle’s version in Settings. Set release metadata explicitly during next-release preparation.

**Acceptance:** fresh generated and committed project configurations agree; candidate archive values are recorded; Settings matches the installed build; required iPhone/iPad screenshots and interactions are verified before submission. Do not remove a public device promise merely to avoid testing it.

### S06 — P2: Product documents describe unfinished capabilities as complete

**Classification:** confirmed documentation drift. **Impact:** future work, funding narratives and support responses can promise behavior the app cannot provide.

**Evidence:** the March design marks CloudKit, offline operation and subscription calendar capabilities complete; the Technovation guide describes cross-device sync, location-based notifications, AVKit, and automatic accessibility support. Candidate CloudKit update code is disconnected, `DataService.swift:22–42` reads bundled data only, the `.ics` path generates a local file (`CalendarService.swift:71–114`), and video is WKWebView. SwiftUI alone does not prove accessible flows.

**Smallest durable recommendation:** rewrite capability statements around observed behavior. Describe `.ics` as a dated export unless there is an actual refreshable subscription. Specify which functions work offline and what needs a connection. Keep unsupported roadmap items separate from shipped claims.

**Acceptance:** no user-facing or submission document promises automatic schedule updates, cross-device sync, online media offline, or tested accessibility without corresponding evidence. Delete unused CloudKit code if it is not part of the decided data-delivery approach.

### S07 — P2: Expansion has visible promises but no evidence gate

**Classification:** strategic judgment backed by current scope. **Impact:** disabled “Soon” councils add decisions to first use and imply an unfunded delivery commitment.

**Evidence:** `CouncilPickerView.swift:56–73` advertises five unsupported councils; the design’s expansion sequence has no data source, owner, permission, validation or running-cost criteria.

**Smallest durable recommendation:** present Auckland directly until a second region meets a written readiness gate. Offer a clearly bounded manual mode only if its geography and sorting guidance are coherent. Remove “Soon” claims without a resourced delivery decision.

**Acceptance:** users can identify supported coverage before onboarding; no inactive council is presented as imminent; a second council requires maintained source access, verified address/date samples, applicable content and a maintenance owner before entering production.

### S08 — P2: Success and operating limits are not defined

**Classification:** confirmed planning gap; demand and sustainability hypotheses remain open. **Impact:** more installs or screens could be mistaken for household value while maintenance silently grows.

**Evidence:** reviewed design/submission documents describe general convenience, education and future cities, but do not define reliability outcomes, operating effort, retention evidence or funding. This audit did not access App Store Connect analytics.

**Smallest durable recommendation:** use the bounded validation and maintenance model below before building growth features.

**Acceptance:** six weeks of observed household outcomes and maintenance effort are reviewed against a declared capacity ceiling; continuation, adjustment or pause is recorded. App-opening frequency is not the primary success metric for a reminder utility.

### S09 — P1: Required-reason API privacy manifests are missing

**Classification:** confirmed source omission and release-preparation gap; no App Store submission was attempted. **Impact:** the candidate lacks a required declaration for APIs it directly uses.

**Evidence:** no `PrivacyInfo.xcprivacy` file was found in the repository. `LanguageManager.swift:21,29` uses standard UserDefaults; `WidgetDataService.swift:20,29` and `BinDayNZWidget.swift:99` use App Group defaults. Apple's current documentation requires each executable's containing bundle to declare its required-reason API use in a manifest. [Required-reason API requirements](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)

**Smallest durable recommendation:** include a correctly targeted manifest in both the app and widget. Declare `NSPrivacyAccessedAPICategoryUserDefaults` with reasons matching actual storage: `1C8F.1` covers the shared App Group; `CA92.1` covers app-only preferences. Review the `AppleLanguages` read before choosing the final declarations, because reason codes have scope restrictions; do not paste a generic manifest to mask incompatible use. [Apple's approved API reasons](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype)

**Acceptance:** inspect the release archive for both manifests, confirm they appear in Xcode's privacy report, and validate each declared reason against the actual calls. Complete the normal App Store validation before release; this audit does not claim Apple rejected this build.

## Audience, validation and sustainable opportunities

**Proposed first segment:** Auckland iPhone households personally responsible for standard council kerbside bins, particularly people who lose track of alternating recycling weeks or have just moved. Treat this as a recruitment hypothesis. Private contractors, communal building arrangements, island exceptions and residents outside verified coverage need explicit boundaries. Māori-language value and accessibility preferences must be checked with fluent speakers and people who use assistive technologies; language files and native controls are not proof.

Run a **six-week, 8–12-household qualitative pilot** after critical reliability fixes. These are recommended study parameters, not a market benchmark. Include more than one collection weekday and recycling cycle, at least two people who benefit from large text/assistive technology, and address-change/permission-recovery tasks. Obtain permission before any recruitment contact. Real delivery observations complement deterministic holiday/year-boundary tests; if the pilot has no holiday, that behavior remains a separate required test.

Measure:

- **Setup:** completion without help, time to a confirmed first schedule, address mismatches, manual corrections and reasons for abandoning setup. Compare the council website plus a recurring-calendar setup on the same task.
- **Household outcome:** bin put out on the right day, any app-induced wrong date or missed reminder, and whether participants still choose reminders/widgets at weeks 2 and 6. Ask about missed bins directly; neither an OS scheduling success nor an app open proves a notification was seen or a bin collected.
- **Recovery:** whether people notice and fix an incorrect date, denied notification access, a changed address or stale source information without assistance.
- **Operations:** maintainer minutes on source checks, corrections, OS/build work and support; failed lookups by cause using volunteered/redacted diagnostics. Do not centralise household addresses merely to get metrics.

Use available aggregate App Store Connect conversion/crash/usage reports for direction, recognising opt-in coverage and small samples. Apple states usage reporting depends on users agreeing to share diagnostics; it does not represent every user or establish notification delivery. [Apple reporting overview](https://developer.apple.com/help/app-store-connect/measure-app-performance/overview-of-reporting-tools)

| Opportunity | User value and differentiation hypothesis | Effort / recurring burden | Evidence to justify it |
|---|---|---|---|
| Provenance, freshness and correction | Prevent confident wrong answers; directly supports the core promise | Medium / ongoing source review | Official sample-date agreement; users understand confirmed vs manual; corrections resolve |
| Dependable reminders and widgets | Less need to reopen or recheck; core repeat value | Medium / OS and lifecycle checks | Weeks without reopening, permission revocation/recovery and real-device delivery; no silent expiry |
| Fast accessible setup and glanceable bin guidance | Easier adoption by people poorly served by dense council pages | Low–medium / accessibility and language QA | Observed tasks with large text, VoiceOver and fluent language reviewers |
| Household schedule sharing | Helps flatmates coordinate without another account | Low for existing native share/export / low | Several pilot households struggle with coordination; shared result stays understandable and current |
| Verified holiday/disruption notices | Solves the part a fixed calendar cannot maintain itself | Medium–high / continuous authoritative inputs | Source terms/access and correction workflow; exceptional dates propagate consistently across outputs |
| Move-in/community distribution | Reach people at the moment they need a new schedule | Low / modest support if bounded | A community group or property manager agrees to a pilot; track verified setups and repeat outcomes, not leaflet distribution |
| Sponsorship or a funded local pilot | Pays for maintenance while keeping core access free | Low product work / medium relationship/reporting burden | Named sponsor, agreed deliverables, funded maintainer time and no influence over collection guidance |
| Optional supporter purchase | Allows appreciative users to contribute without blocking reminders | Low–medium / payment support and policy upkeep | Users volunteer willingness to support and realistic proceeds cover the added work; implement platform-compliant payments only after that evidence |
| Additional councils | Broader availability | High / each source and policy multiplies work | A specific region has unmet need, maintainable data access, validation and a funded owner |
| Paid council tooling | Potential revenue and authoritative distribution | Very high / procurement, support and service commitments | A named budget owner with a requirement not met by their existing tools, plus a paid pilot; currently unvalidated |

**Default economics:** a free app has no direct revenue by design. Track annual platform fees, source/content hosting, test devices, translation/accessibility review, and labour separately. Use actual invoices and logged time: `annual maintenance cost = cash expenses + maintainer hours × chosen internal hourly cost`. No download-to-revenue assumptions are justified. Supporter revenue is upside until demonstrated; an institution-funded arrangement is a hypothesis, not a partnership.

Start with a small declared monthly maintenance allowance and reserve for holiday/OS incidents. If it repeatedly exceeds the available allowance, reduce supported scope or stop promoting until funding/ownership is resolved. Do not rely on a permanent unpaid emergency obligation. A six-week pilot showing little advantage over a recurring calendar is a valid reason to keep this as a small local utility and stop expansion.

## Sequenced recommendations

1. **Protect users before the next release:** close schedule/calendar/reminder blockers from the technical audit; add truthful coverage, privacy and app-support routes; reconcile archive/device/version metadata. Remove unsupported guarantees and stale implementation claims.
2. **Prove dependable repeat use:** run the bounded household pilot and exception-date/device tests. Keep notifications/widgets useful between app launches; make correction and freshness visible. Record a maintainer owner, pre-holiday source checks, response expectations and a way to flag unverified data.
3. **Validate distribution before product expansion:** improve listing screenshots/copy around the tested household task; prepare one shareable setup/help page and measure verified setups from one opt-in community channel. No outreach was sent during this audit.
4. **Fund one proven need at a time:** explore sponsorship/supporter intent or a specifically funded pilot. Defer ads, AI sorting, nationwide infrastructure, social feeds, accounts and council dashboards until concrete evidence changes the decision.

Release approval still requires the functional/runtime audit’s gates. This strategy review cannot establish production readiness, demand, actual maintenance cost or translation quality by itself.
