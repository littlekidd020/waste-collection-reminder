# Technovation submission notes — Bin Day NZ

Updated 6 September 2026. Use this as a preparation guide, not evidence of competition eligibility, a submission already made, or demonstrated household/environmental impact. Check the current programme rules separately before submitting.

## Project description

Bin Day NZ is a native iPhone and iPad app for Auckland households that want to keep track of their bin days. It saves a reviewed household schedule and presents upcoming collections through the app, widgets and optional reminders or calendars. Source-linked sorting guidance helps people check what belongs in each bin.

The project is free to use. Its current focus is dependable dates, clear correction and accessible daily use within a defined Auckland service boundary. National coverage, institutional partnerships and a commercial model have not been established.

## Demonstrate the actual candidate

- Show an exact-property schedule check and the difference between source information and a user-entered schedule. Demonstrate editing different frequencies and a one-off date change.
- Show the same date in Today, Schedule and a real widget. Explain that the operating system controls widget refresh and notification delivery.
- Show reminders and their permission/renewal state. These are scheduled local notifications, not GPS-triggered reminders or a continuously running service.
- Show optional calendar handling using a synthetic calendar. Explain that exported files are copies; they are not live Council subscriptions.
- Show the text guide without loading a video, then deliberately open optional media and explain that it makes third-party network requests.
- Demonstrate large text, screen-reader navigation and language switching. Include actual test evidence; do not say SwiftUI automatically guarantees accessibility or that translations have fluent approval unless they do.

## Technology explanation

SwiftUI provides the interface. SwiftData stores the household profile locally. A shared schedule engine calculates anchored recurring dates and explicit exceptions. WidgetKit reads the schedule through an App Group. UserNotifications schedules local reminders; EventKit and `.ics` support optional calendars. Apple mapping/location services and the external Council website need a connection. The candidate does not fetch Council dates automatically; the person checks the source and confirms their own schedule. Optional online videos use web content.

There is no application account, private CloudKit profile sync or implemented national update network. Saved schedules work offline; online lookup, live Council information and videos do not. The app must disclose uncertainty and corrections instead of implying that a locally saved recurrence is permanently authoritative.

## Ethics and evidence

Describe actual address, device-location, calendar and video data flows using the [candidate privacy policy](privacy-policy.md). The app does not need a new central address database to test its usefulness. Public app-support reports must omit home addresses and personal calendar information.

Environmental benefits are a hypothesis: no measured reduction in contamination, landfill volume or missed collections is claimed. Use the [six-week pilot](pilot-and-maintenance.md) to collect consented household observations and maintenance costs. Recruit fluent language reviewers and people who use assistive technology; keep their findings and limitations visible.

## Submission assets and claims check

Prepare screenshots or clips from the exact candidate: reviewed schedule, edit/recovery, Today/widget agreement, reminders and guidance. Exclude private addresses and accounts. Record the app version, device/OS and test date. Compare every spoken or written feature claim with the [release checklist](release-checklist.md).

In a pitch, explain the household task, what the candidate currently does, what the pilot has actually shown, and the next bounded validation step. Leave results blank until observed. Do not invent downloads, partners, awards, grants, revenue, accessibility certification or environmental impact.
