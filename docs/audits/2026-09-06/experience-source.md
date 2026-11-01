# Bin Day NZ: experience, language, content and privacy source audit

Reviewed 6 September 2026. This report examines the current working-tree candidate, not the public App Store binary. App code was not changed. Fresh simulator evidence belongs in the main audit; August screenshots are historical and are not treated as proof of current rendering.

## Assessment

The native navigation, system forms, optional manual setup, readable bin names and accessibility-specific calendar list are useful foundations. The most consequential experience gaps concern trusting and correcting the schedule, keeping settings consistent across app surfaces, and inaccurate educational content. A visual overhaul is not required to address these problems.

Priorities: **P1** should be resolved before claiming public-release readiness; **P2** materially improves task completion, inclusion or trust; **P3** is polish or an opportunity. Findings described as “source-confirmed” follow directly from inspected code. Runtime presentation, permission behaviour and assistive-technology results remain separate evidence.

## Findings and acceptance checks

### EXP-01 · P1 · Manual correction cannot represent common mixed-frequency schedules

**Source-confirmed.** [BinDayNZ/Views/Onboarding/ManualScheduleView.swift:6–11,33–43,89–100](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Views/Onboarding/ManualScheduleView.swift:6>) gives all selected bins one weekday, one frequency and one fortnightly pattern. [ChangeAddressView.swift:112–120](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Views/Today/ChangeAddressView.swift:112>) opens this form without existing values; it starts Monday/all three bins/weekly. A household needing weekly rubbish and food scraps with fortnightly recycling cannot express that configuration. Reopening to change one detail risks replacing previously correct choices with defaults.

**Smallest durable change:** reuse the existing per-bin `CollectionSchedule` model in a native form that loads the saved schedule and edits each active bin's day/frequency/next collection date. Do not invent another scheduling model or add a generic form framework.

**Acceptance:** create weekly rubbish/food and fortnightly recycling; reopen and preserve every value; change only recycling; cancel without mutation; relaunch and compare Today, calendar, reminders and widget. A user should verify the next two collection dates before saving.

### EXP-02 · P1 · Failed calendar update can misreport an already-saved address change

**Source-confirmed.** [BinDayNZ/Views/Today/ChangeAddressView.swift:392–412](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Views/Today/ChangeAddressView.swift:392>) saves profile changes and reschedules notifications before attempting calendar sync. Calendar failure shows “Could Not Save” and prevents widget refresh although the address already persisted. This creates different schedules across surfaces and an untrustworthy save result.

**Smallest durable change:** make the saved schedule authoritative; after persistence, update reminders/widget and report calendar success or a specific recoverable calendar failure separately. Keep the saved schedule visible and make retry explicit.

**Acceptance:** revoke calendar permission, save a changed schedule and confirm the UI accurately reports what saved. Today and widget agree, reminders target the saved schedule, calendar retry cannot duplicate events, and cancel after an error does not pretend to undo a committed change.

### EXP-03 · P1 · Food-scraps guidance contains two confirmed errors

**Source and official-content confirmed.** [BinDayNZ/Models/BinType.swift:121–127,158–164](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Models/BinType.swift:121>) accepts tea bags and rejects plastic bags “even compostable.” Auckland's Collections Control Appendix D excludes tea bags and allows certified home-compostable liners. The council food-scraps brochure also describes approved compostable liners and lists loose tea leaves. [Collections Control, Appendix D](https://www.aucklandcouncil.govt.nz/plans-projects-policies-reports-bylaws/bylaws/docssolidwastebylawoperationalcontrols/waste-management-minimisation-bylaw-collections-control.pdf), [food-scraps brochure](https://www.aucklandcouncil.govt.nz/rubbish-recycling/Documents/food-scraps-collection-service.pdf).

**Smallest durable change:** distinguish tea leaves from tea bags and approved liners from ordinary plastic bags/compostable packaging. Correct the same strings in all five languages. Attach the relevant council source and a review date to the guide; a reviewed static guide is sufficient for the current council coverage.

**Acceptance:** tea bags appear under exclusions; loose tea leaves/coffee grounds remain accepted; certified home-compostable liners are permitted; disposable compostable food packaging remains excluded. Bilingual review checks that the exception survives translation.

### EXP-04 · P1 · Inorganic guide omits essential collection instructions and over-rejects timber

**Source and official-content confirmed.** [BinDayNZ/Models/BinType.swift:129–136,165–170](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Models/BinType.swift:129>) rejects timber generically. Auckland accepts timber shorter than two metres without exposed nails. The detail screen contains media and Yes/No lists, but no booking action, property-boundary instruction, volume/weight limits or battery-removal warning ([BinDayNZ/Views/Info/InfoView.swift:502–575](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Views/Info/InfoView.swift:502>)). Council requires a booked collection, placement within the property boundary, at most one cubic metre and individual items no heavier than 55 kg; its current guide explicitly requires removing batteries. [Accepted and rejected inorganic items](https://new.aucklandcouncil.govt.nz/en/rubbish-recycling/inorganic-collections/what-put-out-inorganic-collection.html), [collection terms](https://new.aucklandcouncil.govt.nz/content/dam/ac/docs/rubbish-recycling/inorganiccollectiontermsandconditions.pdf).

**Smallest durable change:** give this category a short service explanation and official booking link above its reviewed item examples. Correct the timber qualification and put battery handling beside electronics. Keep it visibly distinct from recurring kerbside bins.

**Acceptance:** a user can distinguish “eligible item” from “collection booked,” reach council booking, understand where to place items and the limits, and see battery-removal instructions. No automatic annual date is implied without a confirmed booking.

### EXP-05 · P1 · The rubbish guide still plays recycling-cleaning content

**Source plus live metadata confirmed.** [BinDayNZ/Models/BinType.swift:175–180](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Models/BinType.swift:175>) maps Rubbish to `AIkjD2vszQo`. On 6 September, YouTube's public oEmbed endpoint returned its title as **“Clean the Recycled Items - English | Auckland Council.”** This confirms the category mismatch reported in August still exists in the candidate. The current video unit test checks URL construction only ([BinDayNZTests/VideoSourceTests.swift:5–20](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZTests/VideoSourceTests.swift:5>)). [Current rubbish video](https://www.youtube.com/watch?v=AIkjD2vszQo).

**Smallest durable change:** remove the mismatched video from Rubbish until a verified category-appropriate council source is selected. Video is optional; accurate written guidance already provides value.

**Acceptance:** review the actual content, title, language and captions for every retained video; verify playback and unavailable/offline behaviour on device. A successful URL test cannot satisfy this gate.

### EXP-06 · P1 · Privacy and sync claims do not describe the current data flow

**Source-confirmed; production practices not inferred.** [docs/technovation_submission_guide.md:33,54–58](</Users/kexinli/My Drive/AI Projects/waste collection reminder/docs/technovation_submission_guide.md:33>) says addresses/preferences stay locally or in private iCloud, describes cross-device sync and AVKit. The candidate stores address and coordinates in SwiftData ([UserProfile.swift:28–33](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Models/UserProfile.swift:28>)), sends search input to Apple MapKit and an Auckland Council endpoint ([AddressSearchService.swift:31–49,184–206](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Services/AddressSearchService.swift:31>)), and loads a regular YouTube web embed as soon as a guide detail opens ([YouTubePlayerView.swift:12–24,35–45](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Views/Info/YouTubePlayerView.swift:12>)). App entitlements currently declare only the widget app group. [CloudKitService.swift:4–15](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Services/CloudKitService.swift:4>) is a public council-data service, not evidence of private-profile sync. No analytics SDK was found in the inspected app source; that does not establish what third-party services collect.

**Smallest durable change:** publish and link a plain explanation of local data, optional location access, address lookups and third-party video requests. Verify actual shipped entitlements before advertising iCloud sync. Use an explicit video action so reading a guide does not automatically initiate a third-party embed. Update submission/marketing copy to match the candidate.

**Acceptance:** trace requests during manual-only setup, typed lookup, location lookup and guide opening; disclosure matches those traces. The guide remains usable without video. Privacy and support destinations are reachable in-app. Confirm actual release metadata separately from source.

### EXP-07 · P2 · Language changes reset navigation and leave generated content in the old language

**Source-confirmed.** [BinDayNZ/App/ContentView.swift:29–42](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/App/ContentView.swift:29>) replaces the entire view identity on language change; `MainTabView` initializes to Today at line 49. It refreshes widget data but does not recreate already-scheduled notification content or calendar titles/notes. Those strings are generated when scheduled ([NotificationService.swift:38–45](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Services/NotificationService.swift:38>); [CalendarService.swift:50–55](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Services/CalendarService.swift:50>)). Manual setup stores localized “Manual schedule” in `profile.address` ([ChangeAddressView.swift:116](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Views/Today/ChangeAddressView.swift:116>)), leaving old-language display text after switching.

**Smallest durable change:** preserve navigation while updating locale; keep manual status as state, not translated address data; refresh app-owned generated content where the integration is enabled. Keep independently imported `.ics` files explicitly described as snapshots.

**Acceptance:** switch each supported language while on Settings and stay there; Today, schedule, widget and the next pending reminder use the selected language; manual status changes language; enabled calendar content is refreshed or clearly reports a recoverable failure. No duplicate events are created.

### EXP-08 · P2 · Localization coverage passes, but critical prompts and translation quality are unproven

**Executed static check:** 203 catalog keys; 198 translations each for `mi`, `zh-Hans`, `hi`, `ko`; every one of 170 literal `L()` keys found in Swift is catalogued; no empty supplied translations or format-specifier mismatches. The five untranslated catalog entries are format/brand/example-address strings, not proof of five missing product translations. All provided units are marked translated, but 193 catalog entries have `extractionState: stale`, consistent with a custom lookup workflow requiring care during catalogue cleanup.

[BinDayNZ/Info.plist:41–46](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Info.plist:41>) has English-only calendar/location purpose strings and no `InfoPlist.strings` files were found. [TodayView.swift:312](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Views/Today/TodayView.swift:312>) constructs the day suffix with an English `d`. Runtime date/weekday conventions, translated notification grammar and Māori language quality require human checking. Broad source coverage must not be described as validated cultural inclusion.

**Smallest durable change:** localize purpose strings and remaining displayed fragments; retain one small catalogue coverage/placeholder check and have native speakers review critical setup, schedule and sorting terms.

**Acceptance:** permission prompts, plural/date formats and errors are understandable in each supported language; no truncated critical action or lost exception at larger text sizes; bilingual reviewers sign off the content rather than relying on the “translated” flag.

### EXP-09 · P2 · Schedule confidence and reminder health are hard to assess

**Source-confirmed structure; usability impact needs fresh testing.** Today shows an address/zone and gives substantial space to “No collection today,” followed by Tomorrow and a repeated upcoming list ([TodayView.swift:42–75,148–159,187–207,261–315](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Views/Today/TodayView.swift:42>)). There is no displayed source/review date or distinction between a verified address schedule and an estimated match. Settings exposes requested reminder toggles rather than a persistent permission/delivery status ([SettingsView.swift:77–114,180–210](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Views/Settings/SettingsView.swift:77>)). Notification denial instructions do not include a direct system-Settings action.

**Smallest durable change:** lead Today with the next bins and exact date, show whether the schedule is manual/verified/unverified, and add a concise reminder status with recovery action. Group bins sharing a collection date. Retain native navigation and the current visual vocabulary while fixing hierarchy.

**Acceptance:** users answer “what goes out next and when?” and “will I be reminded?” without visiting multiple tabs. Denied/revoked permission is shown honestly. Today and tomorrow are not repeated as separate competing answers.

### EXP-10 · P2 · Accessibility foundations need focused verification and a few source fixes

**Source-confirmed risks:** calendar symbols are 8 pt inside 52 pt cells ([ScheduleView.swift:270–280](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Views/Schedule/ScheduleView.swift:270>)); Today always places up to three bin cards in a horizontal row ([TodayView.swift:214–218,252–255](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Views/Today/TodayView.swift:214>)); the day detail uses a medium-height sheet with non-scrolling content ([ScheduleView.swift:159–162,409–454](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Views/Schedule/ScheduleView.swift:159>)). Address-input accessory buttons use symbols without explicit action names ([AddressSearchView.swift:189–224](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Views/Onboarding/AddressSearchView.swift:189>)). White text on system-green onboarding buttons warrants measured contrast checks, not an assumed pass ([WelcomeView.swift:64–74](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Views/Onboarding/WelcomeView.swift:64>)).

**Retain:** accessible calendar list, date/value labels, native forms, scalable type styles, Info's one-column accessibility layout and Reduce Motion hooks. Animation under Reduce Motion is not itself a failure: assess the actual movement and readability rather than demanding no opacity transitions.

**Smallest durable change:** label input actions, allow cards/detail content to reflow, strengthen tiny schedule marks where needed, and fix measured failures while preserving native patterns.

**Acceptance:** fresh small-iPhone and iPad checks at default and largest accessibility text; VoiceOver order/action names; keyboard focus; dark mode; Reduce Motion; contrast; minimum usable targets. The full next collection and each essential control remain available without clipping.

### EXP-11 · P2 · Generic guide content omits qualifications and an effective support path

Recycling examples broadly match current council categories, but omit lids-off, loose/clean preparation and container limits ([BinType.swift:113–119,150–156](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Models/BinType.swift:113>)). “Food-contaminated containers” as an exclusion needs an actionable rinse/empty instruction so users do not discard recoverable containers. Council guidance also distinguishes Aotea arrangements. [Recycling guidance](https://new.aucklandcouncil.govt.nz/en/rubbish-recycling/bin-requests/what-put-your-recycling.html).

Rubbish exclusion of food scraps is unconditional in the app; the council's guidance allows an exception outside food-scraps service areas. [Rubbish guidance](https://new.aucklandcouncil.govt.nz/en/rubbish-recycling/bin-requests/what-put-your-rubbish.html). Global “night before/by 7am” tips ([InfoView.swift:259–265](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Views/Info/InfoView.swift:259>)) need to defer to the property's actual collection instructions, including apartment/private-collection arrangements.

All resource destinations are Auckland-specific ([InfoView.swift:331–360](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Views/Info/InfoView.swift:331>)), which is coherent with Auckland-only data but should be stated in coverage copy. Settings About provides version, council website and a credit, with no app support/feedback/privacy action ([SettingsView.swift:150–163](</Users/kexinli/My Drive/AI Projects/waste collection reminder/BinDayNZ/Views/Settings/SettingsView.swift:150>)). The displayed version is hardcoded to `1.0.0`.

**Smallest durable change:** use concise, source-linked preparation and exception guidance; expose an app-support route for incorrect dates/content; read version from the bundle; describe supported coverage honestly. Do not build a national content-management system ahead of verified council coverage.

**Acceptance:** a user can recover from an incorrect schedule, identify the responsible service and reach support; source links resolve; unsupported service arrangements are never presented as covered. Reported version matches the installed build.

## Content verification record

Official sources were retrieved on 6 September 2026. Several council pages redirect to `new.aucklandcouncil.govt.nz`; retrieval time is not a claim that their content was newly published. Search-only archived articles with older recycling rules were not used to override the current service guidance.

| Category | Result of comparing current examples |
|---|---|
| Rubbish | Nappies/sanitary products, polystyrene/plastic-wrap examples and hazardous/recyclable exclusions broadly align. Food-scraps exclusion needs the service-area qualification. Exact current Auckland instructions for vacuum dust, cold ashes, broken crockery and bubble wrap were not individually established by the available pages; retain as unverified until item-specific confirmation, not as confirmed errors. |
| Recycling | Accepted paper/cardboard, grade 1/2/5 containers, glass bottles/jars and cans align. Listed soft plastics, ceramics/drinking glasses, polystyrene and nappies exclusions align. Add preparation/size qualifications and explain washable food residue. Steel/aluminium cans and tin cans duplicate one category. |
| Food scraps | Food, dairy, meat/bones, bread/rice/pasta and coffee grounds align. Tea bags conflict with official guidance; liner wording wrongly excludes a permitted option. Garden/pet waste exclusions align. The app's exact liquids/cooking-oil wording was not individually confirmed; no contrary permission is inferred. |
| Inorganic | Furniture/appliances and carpet broadly align, with size, lifting and booking conditions missing. Generic timber rejection conflicts. Vehicle parts/tyres, hazardous liquids/gas and garden waste exclusions align. Exact blanket acceptance of scrap metal and underlay was not individually confirmed. Add battery removal and restrictions on asbestos-containing floor coverings. |

The app currently uses the same English video IDs in all languages. Titles were read from YouTube oEmbed; playback, captions, translation and the full instruction content were not watched or certified:

| App category | ID | Public title returned | Metadata result |
|---|---|---|---|
| Rubbish | `AIkjD2vszQo` | Clean the Recycled Items - English · Auckland Council | Wrong category |
| Recycling | `42dWHzAqO7E` | Recycling Standards – How to recycle right - English · Auckland Council | Category matches; current instruction content unverified |
| Food scraps | `fCk0RGm-xK8` | Food Scraps Service – how to use your food scraps bin and caddy · Auckland Council | Category matches; current instruction content unverified |
| Inorganic | `vq5rAaNrevA` | Your new inorganic service · Auckland Council | Category matches; current instruction content unverified |

## Evidence limits and release gate

- This source pass does not establish current simulator/device rendering, VoiceOver usability, actual contrast ratios, successful notifications, App Store privacy declarations, production entitlements or the public binary's behaviour.
- No user interviews, retention data, verified reduction in missed collections or contamination outcomes were found in the inspected product/submission documents. These remain validation needs, not demonstrated impact.
- No broad redesign is proposed. Resolve P1 correctness/content issues, verify essential journeys and inclusion on the candidate, then evaluate the smaller P2 hierarchy/support improvements with users.
