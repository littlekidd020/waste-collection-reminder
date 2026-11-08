# Guide (Kerb build, 9 November 2026)

## What was built
- `BinDayNZ/Views/Guide/GuideView.swift`: paged `TabView` (`.page(indexDisplayMode: .never)`), one `GuidePage` per bin in `BinType.guideBins(for: council)`, council from the saved `UserProfile` via `DataService`. Top leading: one 8 pt `LidSphere` per bin, the current one raised at full opacity, the others at 55 %, sprung. One VoiceOver element ("Rubbish, page 1 of 4") with an adjustable action that turns pages. Top trailing: `GlassCircleButton("safari")` in a `GlassEffectContainer`, "Open the council guide", which opens `bin.guideSourceURL(for: council)` for the current page in `SafariView`. A linen scrim (ground plus grain, easing out over 36 pt) sits behind the chrome so scrolled copy fades out under the spheres instead of colliding with them.
- `GuidePage.swift`: eyebrow from the saved schedule (`L("%@ · %@", Weekly|Fortnightly, weekday of the anchor date in NZ time)`), "Booked collection" for inorganic, "Not in your schedule" for a council bin the household has not set up; 40 pt name (capped at accessibility1, `minimumScaleFactor(0.6)`); 268 pt `BinProp` hero on a full-bleed `GroundBand(returns: true, peak: 0.62)`, 120 pt (180 pt at accessibility sizes); first guide note as a 17 pt blurb, the rest 15 pt muted; YES / NO columns split by a 0.5 pt vertical rule, stacked with a `Hairline` at accessibility sizes; Auckland's inorganic booking (`.glassProminent` capsule, moss) and terms; the source link; Auckland's food scraps rules; "Before collection" (the two tips from the old Info screen, so nothing is lost); "Guide reviewed" and the examples footnote at 13 pt; Auckland's council video.
- `CouncilVideoSection.swift`: restyled from the old Info screen. `.kerbLabel()` heading, muted body, `.glass` capsule "Load video", player clipped to a 24 pt rounded rect, Retry and Close as glass capsules, failure text in `Palette.attention`, "Open on YouTube" link. Nothing loads from YouTube until asked.
- Every link (source, booking, terms, food rules, YouTube) opens in the in-app `SafariView` sheet, as the safari button does.
- `Views/Info/InfoView.swift` deleted (its resources list belongs to Settings now); project regenerated.

## Motion
- Entrance per page: the hero settles up 10 pt and fades in with `spring(response: 0.6, dampingFraction: 0.85)`; the words fade in over 0.45 s starting 120 ms later. Reduce Motion: both fade over 0.35 s, no movement. The code path exists but Reduce Motion cannot be set from `simctl`, so it is not verified on the simulator.
- Page indicator: spring (0.4 / 0.7) on raise and opacity; an ease when Reduce Motion is on. Adjustable-action page turns use a spring, or no animation with Reduce Motion.
- Nothing idles.

## Decisions and compromises
- **One floor across pages.** Every page's stage is the same height so the ground band and the feet line sit at the same y on every page; while swiping, the floor reads as one continuous surface. A first pass shrank the stage for short objects and left visible steps in the band between pages.
- **The glass crate steps closer.** At the shared scale the crate is 38 % of a wheelie bin (about 100 pt) and reads as a lost object on its own page. The Guide scales any object shorter than 55 % of a bin up to 55 % (`closeUp`), so only the crate changes; the food caddy, garden bin and the rest keep the shared scale.
- The eyebrow uses the singular weekday ("WEEKLY · TUESDAY") rather than the prototype's "Tuesdays": a plural weekday is not localisable from a date formatter.
- VoiceOver: the heading is one header element read as name then eyebrow (label + value), then the blurb and notes, then YES and NO as containers with header labels. The hero is hidden; the bin name describes it.
- "Guide reviewed" now formats through `collectionDateLabel(_, template: "d MMMM y")` (NZ calendar, app language) instead of `Date.formatted`.

## Not verified / open
- Reduce Motion (see above).
- VoiceOver reading order was set in code, not walked with VoiceOver on.
- New keys are in `strings/guide.json`; the catalog still lacks them, so `check-localizations.py` fails until the localisation agent adds them (other areas' keys are missing too).
- Probably orphaned old keys now that `InfoView` is gone (unless Settings reuses them): "Kerbside guidance for %@. Written guides are available offline.", "Kerbside guidance. Written guides are available offline.", "Tap for details", "What goes in", "Book a collection", "Yes, put these in", "Not in this bin", "Info".
- In dark mode the bin renders show a faint light fringe along their contact shadow (a keying artefact in the props, not the page).
