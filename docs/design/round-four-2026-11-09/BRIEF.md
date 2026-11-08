# Round four craft brief: Bin Day NZ interface directions

## What this is
Bin Day NZ is an iPhone app (SwiftUI, iOS 26) that tells New Zealand households which council kerbside bins go out and when. We are prototyping four interface directions as real SwiftUI screens on the iOS 26 simulator, three screens each: **Today**, **Schedule**, **Guide**. The owner will pick one direction from screenshots on a review canvas, so every screenshot must look finished and crafted. Nothing here ships; clarity and craft matter more than architecture.

The palette is fixed: **P5 Linen and clay** (`Sources/Shared/Palette.swift`). The app icon is two rows of seven matte spheres (a fortnight), one raised in recycling ochre and one in food-scraps sage. The matte sphere is the brand's physical unit (`LidSphere` in `Sources/Shared/LidSphere.swift`); use it for day markers, bin markers and beads so the interface and the icon share one material language.

Fixed moment for every screenshot (`Sources/Shared/Sample.swift`): Monday 9 November 2026, 5:30 pm, Mount Eden, Auckland. Next collection is **tomorrow, Tuesday 10 November: recycling, rubbish and food scraps**. Rubbish and food scraps are weekly, recycling fortnightly, all on Tuesdays. Copy: "Put them out by 7 am". Holiday notice: "Christmas week: collections run one day later from Friday 25 December."

## What the owner rejected last round, and why
Five rendered boards were rejected as "very old school and outdated, no craft". What they had in common:
- A 2019 interface skeleton: an opaque four-tab bar with outline glyphs, a navigation title, list rows with a leading icon disc and a trailing bell, a yellow note banner.
- Date pills and buttons as 3D "pills" in a grid.
- A friendly blog serif headline at mid size, with everything else also mid size: no scale contrast, no hierarchy drama.
- Cards on cream, cards in cards, drop shadows under tiles.
- Lid colours as flat UI fills.
Do not reproduce any of that.

## What the references do instead
From the owner's x6sense inspiration set and this year's Apple Design Award apps (Tide Guide, Moonlitt, grug, The Outsiders, Structured, (Not Boring) Camera):
- **One ownable object per screen carries it**: a giant numeral (Skrapp "14.07", 2050 "14.89"), a dial or ring (the "Your morning" clock, the climate ring with organic segments), a hanging frosted-glass tag with a huge numeral ("68%"), a photoreal moon, a tide curve, a line drawing. Everything else is quiet.
- **Type with real contrast**: one oversized numeral or word (Light or Regular weight for numerals), three or four smaller sizes, small tracked uppercase labels in a secondary colour, tabular numerals for times. Five sizes at most on a screen.
- **Chrome is iOS 26 Liquid Glass**: a floating glass tab pill, circular glass corner buttons, a location capsule as the title (Tide Guide: "Chatham, Stage Harbor"), no opaque bars, no hard hairline under a header, no back-chevron nav bar with a centred title.
- **Ground, not cards**: warm neutral grounds (greige, beige, linen), hero elements float on the ground, at most one level of container, 35 to 50 percent of the screen left empty. Moonlitt's calendar is a 7-column grid with hairline rules and rendered objects in the cells, no boxes.
- **Colour means something and lives in material**: lid colours appear as matte spheres, rendered lids, beads on a ring, tints behind deep text. Never as flat chips with white text, never full chroma.
- **Material and light**: matte clay with soft ambient occlusion, soft contact shadows, faint paper grain, glass that refracts a soft gradient behind it, long soft shadows. Commit to one rendering language per direction.
- **A verdict plus one human sentence** (The Outsiders): "Tonight" then "Recycling, rubbish and food scraps go out. Put them out by 7 am."

## Hard rules for every screen
1. One hero per screen, with no container around it. Hero numeral or word 120 to 180 pt (use `minimumScaleFactor` so it survives Dynamic Type); hero objects at least 45 percent of the screen width.
2. At most five type sizes. Labels: 12 or 13 pt, semibold, `.textCase(.uppercase)`, `.tracking(1.2)`, colour `Palette.muted`. Body 17 pt regular `Palette.ink`. Times and dates `.monospacedDigit()`.
3. Fonts: San Francisco through `.system(size:weight:design:)`. New York (`design: .serif`) only where the direction spec says so, and then for one element only.
4. Chrome: `TabView` with the iOS 26 `Tab(_:systemImage:value:)` API and exactly three tabs: Today (`sun.horizon` or `house`), Schedule (`calendar`), Guide (`book`). Add `.tabBarMinimizeBehavior(.onScrollDown)`. Settings is a circular glass toolbar button (`gearshape`) in the top trailing corner, never a fourth tab. Use `.buttonStyle(.glass)` and `.buttonStyle(.glassProminent)` for buttons, `.glassEffect(_:in:)` inside a `GlassEffectContainer` for custom glass. Never draw your own tab bar. No `navigationTitle` large titles unless the spec says so; prefer a location capsule or an eyebrow label.
5. Ground: `Palette.ground` edge to edge with `Grain(opacity: 0.05)` over it. Grouped areas may use `Palette.surface`. No white cards on linen. At most one level of container on a screen, and only if the spec needs one.
6. Lid colours appear only in `LidSphere`, in rendered props, or as `Bin.tint` backgrounds carrying `Bin.deep` text. Never as flat fills with white text, never as outline rings, never as text on linen. Always pair a colour with the bin's name or glyph.
7. Margins 24 pt. Vertical rhythm on an 8 pt grid. Keep 24 pt clear above the tab bar; let content scroll under it (that is what the glass is for).
8. Corners concentric: inner radius = outer radius minus padding. Use `.rect(cornerRadius:)` and `ContainerRelativeShape` where it fits.
9. Motion with purpose, honouring `@Environment(\.accessibilityReduceMotion)`: one entrance (spring, response about 0.6, damping about 0.85, staggered by 40 ms per element), one quiet idle if the direction has an object that can breathe or tick, and `.contentTransition(.numericText())` on any number that changes. The still frame after the entrance must look finished.
10. Real copy only, from `Sample`. New Zealand English. No lorem, no "Lorem", no placeholder names.
11. Accessibility: VoiceOver labels on glyph-only buttons; no meaning carried by colour alone; hero text uses `minimumScaleFactor(0.5)`; touch targets 44 pt.
12. No chevrons, no bells, no badge counts, no FAB, no horizontal chip rows of dates, no segmented pill selectors unless the spec says so.

## What a crafted Today screen contains (the content checklist, not a layout)
- Where and when: suburb or address, the collection weekday and date, how soon (tonight / tomorrow / in N days).
- Which bins, by name, as objects in the brand material.
- The instruction: put them out by 7 am.
- One primary action: a reminder control (glass).
- Quiet awareness of the fortnight rhythm (what is different next week) and of a holiday shift when one is near.
- Settings reachable, not prominent.

## Deliverables (per direction, in your own copy of the project)
- Replace `Sources/Direction/DirectionRoot.swift` with your shell and screens. `DirectionRoot(screen:)` must show the Today, Schedule or Guide tab for `.today`, `.schedule`, `.guide`, and for `.extra` a fourth state that shows your signature interaction mid-moment (a sheet open, a tag mid-swing, a dial being scrubbed), or Today again if you have none. Add as many files as you like under `Sources/Direction/`. Do not modify `Sources/Shared/` except to add new helpers in new files.
- Build and capture:
  ```
  cd <your project dir>
  xcodegen generate
  xcodebuild -project RoundFour.xcodeproj -scheme RoundFour -destination 'platform=iOS Simulator,id=<UDID>' -derivedDataPath dd -quiet build
  xcrun simctl status_bar <UDID> override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
  xcrun simctl install <UDID> dd/Build/Products/Debug-iphonesimulator/RoundFour.app
  xcrun simctl launch --terminate-running-process <UDID> <bundle id> -screen today ; sleep 3 ; xcrun simctl io <UDID> screenshot shots/today.png
  ```
  Repeat for `schedule`, `guide`, `extra`. The screenshots are 1206 x 2622 px (402 x 874 pt).
- Look at every screenshot with the Read tool. Iterate at least twice: first against the hard rules, then against craft (alignment, optical centring, rhythm, type contrast, whether a stranger would call it 2026). Fix, rebuild, re-shoot.
- Write `NOTES.md` in your project dir: the idea in one sentence, what each element is and why, the motion design (entrance, idle, transitions, gestures), what you compromised, what you would do with another day.
- Final report: one paragraph on the idea, the list of screenshot paths, and the honest weaknesses.

## Do not
- Touch anything outside your project directory. Do not run or edit the real Bin Day NZ app. Do not commit.
- Use another simulator than the one assigned to you.
- Leave placeholder views in any screenshot.
