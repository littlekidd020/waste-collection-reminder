# Today, built from direction D "Kerb"

Files: `BinDayNZ/Views/Today/TodayView.swift`, `TodayCopy.swift`, `HolidayShiftCard.swift`,
`BinDayNZ/App/ContentView.swift` (three-tab shell, Settings sheet, notification tab routing),
`BinDayNZ/App/DebugSeed.swift` (debug-only sample schedule for simulators).

## What the screen does
- **Chrome**: a Liquid Glass location capsule (the suburb from the saved address, else the council,
  else "Your schedule") that opens a menu with Change schedule, Check dates with the council and
  How Bin Day works; a glass gear that presents Settings as a sheet.
- **Words**: eyebrow "TOMORROW · TUESDAY 10 NOVEMBER" (relative day, then the full date with the
  English comma removed), a 44 pt verdict and one 17 pt sentence. `TodayCopy` derives them from the
  clock and the next collection: "Out tonight" the day before, "Collection today" on the day (morning
  and afternoon sentences differ), "Nothing tonight" otherwise, "Done for tonight" once the bins are
  at the kerb. Bin lists follow New Zealand English (no serial comma) and te reo joins with "me".
- **Hero**: `BinCluster` of the next day's bins at up to 300 pt (420 pt on iPad). Auckland's
  recycling week uses the prototype's true trio render; every other set is composed from the single
  renders on one baseline. Captions and the sentence list the bins in the order they stand.
- **Fortnight awareness**: "Then Tuesday 17 November: Rubbish and food scraps."
- **Attention panel** (one glass panel, only when needed): the holiday change (Auckland's one-tap
  rule, or the council notice link) or, two weeks after setup with no widget, the widget nudge.
- **Footer**: a quiet status line when all is well ("Reminders on · 7 pm and 7 am", tap for
  Settings) or one `.glassProminent` call to action when something needs doing (Turn on reminders,
  Allow notifications, Refresh reminders); "Undo" while the bins are at the kerb.

## The kerb gesture
Swiping the bins right rolls them 54 pt towards the edge (they follow the finger at half speed and
lean up to 4° on their wheels; the roll commits on the predicted end past 120 pt) and records
`UserProfile.binsOutForCollectionOn`. The reminder plan skips that collection's evening and morning
reminders (the bring-in reminder stays) and the coordinator reschedules at once. Undo, a left swipe,
the menu, or a VoiceOver custom action brings them back. The state is saved, survives relaunch and
clears itself once the collection day has passed. The gesture is only offered the day before and on
the day.

## Motion
- Entrance: the bins roll in from the right leaning at −5°, spring(0.7, 0.8); the lean rights
  itself 380 ms later with a bouncier spring; the words settle up 12 pt; captions fade in once the
  bins land. Reduce Motion: everything fades in standing.
- Kerb: spring(0.7, 0.8) with a 4° lean that settles; Reduce Motion: a 0.3 s cross-fade.
- Success haptic when the state changes.

## Layout
One frame, no scrolling, on phones: the chrome, words, captions, following line, panel and footer
are measured and the bins take what is left (never under 150 pt). When they would, or at
accessibility text sizes, or on screens under 640 pt, Today becomes a scrolling layout with 190 pt
bins. On iPad the block is capped at 900 pt and centred. The ground band starts 59 pt above the bins'
feet and the deeper linen runs to the bottom of the screen.

## Compromises and open points
- The trio render and the composed clusters differ slightly in camera distance; the composite
  arrangement follows the trio's placement so the two read as one family.
- The props are flat renders: the wheels do not turn during the roll.
- The holiday panel is the only element that can push the hero smaller; with both a holiday and
  the widget nudge due, the holiday wins and the nudge waits.
- "Collection today" cannot know whether the truck has been; the afternoon sentence says to bring
  the bins in once they are emptied.
