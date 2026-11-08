# Settings, onboarding and sheets (Kerb build, 9 November 2026)

## What was built

Every form and list keeps its system structure (`Form`, `List`, `NavigationStack`, pickers, toggles,
confirmation dialogs) and now stands on the linen. Shared styling lives at the top of
`BinDayNZ/Views/Settings/SettingsView.swift`:

- `kerbFormGround()` hides the grouped background, puts `LinenGround()` behind, tints controls
  `Palette.accent` and sets text to `Palette.ink`.
- `kerbFormRows()` (on each `Section`) makes rows sit on the ground (no grouped fill) with
  `Palette.line` hairline separators. No rounded cards remain.
- `KerbSectionHeader` renders section headers as `.kerbLabel(12)`.
- `kerbFootnote()` is 13 pt `Palette.muted` explanatory text.
- `KerbPrimaryButtonLabel` is the label for the one prominent action per step
  (`.glassProminent`, capsule, accent tint). Its text is `Palette.onAccent`; the system white failed
  on the light moss accent in dark mode. Disabled, it falls back to `Palette.muted`.

Screens:

- **Settings** (sheet from the gear): inline "Settings" title, "Done" toolbar button. Sections: Your
  schedule, Notifications, Pause, reminder status, Calendar, Language, **Resources** (Council
  website, Check dates with council, and for Auckland: report a missed collection, book an
  inorganic collection, find where an item goes, then How Bin Day works and Privacy and Help),
  About (version, made in Aotearoa), Remove saved data. Duplicates removed: "Check official
  collection dates" (same URL as "Check dates with %@") and the Auckland links from Your schedule;
  "Council website", "How Bin Day works" and "Privacy and Help" moved from About into Resources.
  Action buttons are accent text, destructive text `Palette.attention`, integration errors
  `Palette.attention`. Both confirmation dialogs unchanged.
- **Welcome**: language menu as a glass capsule (`Menu` wrapping an inline `Picker`, same binding),
  the trio render (`BinCluster` at 230 pt) on a returning `GroundBand`, "Bin Day NZ" 34 pt
  semibold ink on one line, tagline 17 pt muted, three feature lines 15 pt ink with muted symbols
  and hairlines between, "Get Started" glass prominent capsule in the bottom inset over a linen fade.
- **Page indicator**: three 8 pt neutral `LidSphere`s, the current one raised and full opacity.
  Same type name and accessibility label.
- **Address step / Change schedule**: 28 pt heading, muted body, address field and council row as
  surface-linen wells (rounded 14, hairline border) with tracked labels, glass capsules for "Use
  current location" and "Clear", bins listed with `CollectionBinRow`. "Set up manually" is the
  prominent action until a schedule exists; then "Review bin schedule" becomes a secondary
  `.glass` capsule so Continue is the only prominent action. Errors in `Palette.attention`.
- **Back**: `OnboardingBackButton` now sits in the navigation bar's leading slot (system glass), which
  also gives the scrolling content a proper top edge instead of running under the status bar.
- **Notifications step**: Form on linen, 28 pt heading, Finish Setup (`finishSetup`) and the page
  indicator moved to the bottom safe-area inset, consistent with the other two steps.
- **Bin schedule editor**: each bin's toggle label is a `CollectionBinRow` (sphere + name, semibold);
  preview dates and the fortnight choice use `collectionDateLabel`. One-off changes on linen with
  attention-coloured remove buttons; dates there use `collectionDateLabel` too.
- **Council picker**: linen list, tracked region headers, accent checkmark.
- **You're set**: 34 pt heading, "Next collection" label, the date, the day's bins as a `BinCluster`
  at 150 pt on a `GroundBand`, `CollectionBinRow`s, then widget and share as plain text blocks
  between hairlines, Done as a glass prominent capsule in the bottom inset over linen (nav bar
  hidden; the duplicate toolbar Done was dropped). `WidgetNudgeCard` deleted (no references).
- **How Bin Day works / Privacy and Help**: linen lists, tracked headers, accent links.

## Motion

- Welcome: the bins settle up 12 pt and fade in with `spring(response: 0.6, dampingFraction: 0.85)`;
  the words follow 120 ms later (8 pt). The bottom button fades with the words.
- You're set: the day's bins settle up 12 pt; rows and text blocks follow 120 ms later.
- Reduce Motion: both become a 0.3 s fade with no movement (code path present; it cannot be set from
  the command line, so it is not verified on the simulator).
- Nothing idles.

## Strings

No new keys. "Resources" and every other label already existed in the catalog
(`strings/settings.json` is `{}`).

## Verified on the iPhone Air simulator

- Full onboarding with no seed: Get Started, choose council (Auckland), Set up manually, toggle
  "These dates look right", Save, Continue, Finish Setup, "Don't Allow", You're set, Done, Today,
  gear, Settings sheet (top and Resources). Note: Continue stays disabled until a council is
  chosen; that rule is unchanged from 1.2.1.
- Light, dark and extra-extra-extra-large text captures of every screen I own.

## Not verified / compromises

- Reduce Motion (cannot be toggled from `simctl`).
- iPad width (content is capped at 600 pt and centred, not captured).
- The address field is single-line; at accessibility sizes a long address truncates with an ellipsis.
- Glass toolbar buttons (Cancel, Save, Done) are system-drawn; their labels use the accent tint.
- The segmented "next collection" picker keeps the system segmented look (white thumb).
- UI tests were not run; they are owned elsewhere and still reference the old Info and Settings tabs.
