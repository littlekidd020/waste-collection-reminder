# Schedule (Kerb build, 9 November 2026)

## What was built
`BinDayNZ/Views/Schedule/`:
- `ScheduleView.swift`: the screen. One vertical `ScrollView` on `LinenGround()`, inside `TimelineView(.everyMinute)` so "today" moves at midnight. Order: header (displayed month as a `.kerbLabel()` eyebrow with `.numericText` transition; trailing `GlassCircleButton` "Check dates with <council>" opening `SafariView`), the street, the month grid, Next collections, holiday lines, footer (footnote, "Change schedule" → `ChangeAddressView`, "Check dates with %@" → `SafariView`). No-schedule state restyled (34 semibold title, 17 muted text, `.glassProminent` capsule). A linen fade sits under the status bar because the screen has no bar and content otherwise collides with the clock.
- `ScheduleStreet.swift`: fourteen 56 pt columns from today, `BinCluster(objectHeight: 48, preferComposite: true)` on one horizon line inside `GroundBand(returns: true)` 140 pt; one accessibility element per day (label = date [+ Today], value = `TodayCopy.list` or "No collection"). Also `SchedulePropMetrics` (prop canvas widths so text makes room for a row of bins).
- `ScheduleMonthGrid.swift`: Numeral's boxless grid, Monday first, weeks on `Hairline()`, 60 pt rows, today in the accent disc, past days muted at 75 % (their spheres at 45 %), 9 pt `LidSphere`s. Each day is a button opening the day sheet.
- `DayDetailView.swift`: sheet on linen; "Collection details" label and glass Done; weekday label over a 34 pt light numeral and the month; bins as `BinProp`s at up to 120 pt (scaled down to fit five-bin households) standing on a `GroundBand`; then `CollectionBinRow`s. Medium and large detents (large only at accessibility sizes).

Month change: horizontal swipe on the grid (the grid follows the finger at 30 %, then the new month pushes in from the swipe side with a spring), `accessibilityAdjustableAction` on the weekday-initials row (VoiceOver reads the month name, swipe up/down to change), and "Show current month" under the grid when another month is shown. At accessibility text sizes the month is a list of collection days (`CollectionBinRow`s between hairlines) with "Previous month" / "Next month" glass buttons, since swipes are not discoverable there.

## Motion
Sections settle up 10 pt with `.spring(response: 0.6, dampingFraction: 0.85)`: header 0 ms, street 40, grid 80, Next collections label 120, rows 140 + 40 ms each, holiday and footer 400/440. Day sheet: bins settle 40 ms apart, rows follow. Reduce Motion: every settle becomes a 0.3 s fade, the month push becomes a cross-fade and the grid does not follow the finger. Nothing idles.

## Decisions and compromises
- Weekday initials use `veryShortStandaloneWeekdaySymbols` rather than the first letter of `shortStandalone…`: identical in English, but Chinese short symbols all start with 周.
- Non-Auckland holiday line uses a new short key (spec wording); Auckland reuses the existing HolidayShiftCard key.
- Next collections includes today's collection if there is one, labelled "Today" (existing key).
- The header month follows the grid, so after swiping to December the eyebrow above the street reads "December 2026" while the street still shows the next fortnight. This is what was specified; worth a look in critique.
- A three-bin composite (e.g. Hamilton rubbish + glass + food) is 64 pt wide and overhangs its 56 pt kerb by 4 pt each side; kept at one scale so the street reads as one street.
- The street is capped at xxxLarge Dynamic Type (fixed-width kerbs); its columns carry full VoiceOver labels.

## Verified on iPhone 17 Pro Max simulator
Auckland seed in light, dark, xxxLarge and accessibility-extra-large (list mode); Hamilton seed (glass crate on the off week, in the street, grid, rows and day sheet); swipe to December and "Show current month"; day sheet open/Done.

## Not verified
Reduce Motion (cannot be set from the command line; code paths are in place). VoiceOver adjustable action and labels (not run with VoiceOver). Holiday lines (no holiday within the 21-day window on 9 Nov 2026 for the seeds). No-schedule state (ContentView sends a profile without a zone to onboarding, so it is unreachable in normal use). iPad width. UI tests still look for the old `navigationBars["Schedule"]` and the Calendar/List segmented control, which no longer exist (OpenCode owns `BinDayNZUITests`).
