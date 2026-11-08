# Bin Day NZ — current product design

Updated 6 September 2026 for the local 1.2 candidate. This replaces the original speculative feature plan. Completed audit evidence remains in `docs/audits/2026-09-06/`; this document is not proof that a candidate passed release checks.

## Purpose and coverage

Help New Zealand households put out the correct bins on the correct day. Focus on ordinary council kerbside services: rubbish, recycling, and where the council offers them, glass, food scraps, garden waste or combined organics. Auckland's inorganic collection is a separately booked service with guidance, not a predictable weekly bin.

Since November 2026 the app carries a directory of all 67 territorial authorities. The household chooses its council (suggested from the address when the placemark is unambiguous); the council decides which links, bins, guidance source, anniversary day and holiday policy the app shows. The council never supplies dates.

An Apple Maps address suggestion does not prove service coverage. The exact property's council information is the source to check externally, and a user-confirmed schedule is stored locally. The app does not fetch authoritative Council dates automatically. A manually entered schedule must remain identifiable. Private collections, shared-building arrangements and area-specific exceptions require confirmation with the responsible provider; no national-coverage promise is made.

The critical job is a dependable date and an understandable correction path. Free access and a native appearance do not by themselves demonstrate that the app is more useful than the Council website and a recurring calendar event.

## Core experience

1. Find or enter the household address. Explain the network request and offer a path without device-location permission.
2. Enter each selected bin's day, frequency and next date after checking the exact property's official source. Address search supplies suggestions only; it must not assign a schedule from a suburb or map match.
3. Save the confirmed schedule. Show whether it is user-entered and let the person edit it later, including one-off date changes.
4. Show the next collection in Today, the same dates in Schedule, and the same rules in widgets. Bin names accompany colour so colour is not the only cue.
5. Offer reminders after the schedule is clear. Show permission and renewal state, and make recovery from denial or expiration actionable.
6. Offer calendar integration as optional. Users can continue without granting full calendar access. Manage only the app's own entries; export a schedule copy when that is preferable.
7. Provide concise source-linked sorting guidance, optional videos, privacy information and app support. A missed pickup routes to Council; an incorrect app date routes to the developer.

## Implementation boundaries

| Concern | Candidate approach and limit |
|---|---|
| Interface | SwiftUI on iPhone/iPad, iOS 17+. Dynamic Type, VoiceOver and Reduce Motion need task verification, not framework-based assumptions. |
| Persistence | SwiftData household profile and app preferences on the device. No account or application-level private iCloud sync. Device backup is separate. |
| Recurrence | Shared anchored weekly/fortnightly rules and explicit one-off changes, evaluated in the service timezone. One engine feeds screens, calendar and widget. |
| Address source | Apple address/location services provide suggestions. Council information is opened on the external official website, not fetched by an in-app Council API. The person enters and confirms dates. Do not describe this as automatic authoritative lookup. |
| Notifications | Native scheduled local notifications. Finite coverage is disclosed with renewal status; OS permissions, Focus and scheduling can affect delivery. Opening the app permits reconciliation; it is not continuous background execution. |
| Widget | App Group shares the saved schedule and language; WidgetKit computes future entries from the rules. iOS controls when a widget is rendered or refreshed. |
| Calendar | Optional EventKit management of app-owned recurring collection events and alerts. A local `.ics` export is a snapshot; it is not a subscription feed and does not acquire future Council changes. |
| Sorting content | National standard-materials lists, with Auckland's reviewed wording and videos kept for Auckland. Each guide links the saved council's page as its source. Loading a video is optional and makes third-party requests; text guidance remains available without video. |
| Holiday shifts | Auckland's published one-day-later rule is bundled and applied with one tap. Other councils get the national and regional holiday dates with a link to the council's own notice; nothing is written to the schedule without a verified rule. |
| Languages | English, Māori, Simplified Chinese, Hindi and Korean resources. Fluent review of critical instructions and permission prompts is a release gate. |

The repository must not retain unused CloudKit update code or claim remote updates, private sync, location-triggered reminders, guaranteed notification delivery or fully offline online-media playback. Holiday and disruption notices need authoritative verification; a generic annual holiday rule is insufficient for every service and locality.

## Validation and growth

Use the release checklist for data safety, cross-surface agreement, timezone/year-boundary cases, permission recovery, accessibility, privacy and signed-device checks. Record the exact candidate and separate automated, simulator and real-device evidence.

After release blockers are resolved, use the six-week household pilot to measure correct setup, actual useful reminders, correction success and maintenance work. Start with one Auckland service boundary. A second council requires maintained source access, validated examples, applicable guidance and an owner with capacity. No AI sorting, accounts, paid tiers or national data platform are committed.

See [release checklist](../release-checklist.md), [pilot and maintenance record](../pilot-and-maintenance.md), and [privacy policy draft](../privacy-policy.md).
