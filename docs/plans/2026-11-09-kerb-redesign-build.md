# Kerb redesign: build plan (9 November 2026)

Direction D "Kerb" was chosen on 9 November 2026 from the round-four prototypes
(`docs/design/round-four-2026-11-09`). This plan turns the prototype into the shipping app.

## Decisions

- **Platform: iOS 26.0 minimum.** The chosen direction is built on Liquid Glass
  (`glassEffect`, `GlassEffectContainer`, `.glass`/`.glassProminent` button styles,
  `Tab(_:systemImage:value:)` with `tabBarMinimizeBehavior`). Shipping a fallback chrome for
  iOS 17 and 18 would mean designing and verifying a second, lesser interface. Existing users on
  older systems keep 1.2.1. This is a one-line revert in `project.yml` if the owner prefers.
- **Palette: P5 Linen and clay**, with a dark counterpart (warm charcoal ground, lighter moss
  accent, the lid colours unchanged because they are physical). Every colour lives in
  `BinDayNZ/Design/Palette.swift`; `AppTheme` is kept only as an alias for older call sites.
- **Three tabs, Today, Schedule, Guide**, with Settings behind a glass gear on Today, as in the
  prototype. Notification routing maps the old tab indexes (0 Today, 3 Settings) onto this.
- **Props.** The bins are matte clay renders from Codex (gpt-image-2) keyed to transparency. The
  prototype's four singles and trio are kept; garden waste, food-and-garden organics and the
  inorganic group are rendered to the same brief, and the singles are re-rendered as pairs at
  higher resolution. Every single is normalised so a full-size bin spans 20 % to 80 % of its canvas
  height, which lets `BinProp` stand any set of bins on one baseline. A vector bin draws in place of
  any missing render so the app never shows a blank.
- **The kerb gesture means something.** Swiping the bins to the kerb records
  `UserProfile.binsOutForCollectionOn` and the reminder batch skips that collection's evening and
  morning reminders; undo restores them. The state expires after the collection day.
- **Dynamic Type.** Display type scales with `@ScaledMetric` and is capped at the first
  accessibility size; at accessibility sizes Today becomes a scrolling layout with smaller props.
- **Reduce Motion.** Entrances fade, the roll to the kerb becomes a cross-fade, no tilt.

## Work breakdown and ownership

| Piece | Files | Owner |
|---|---|---|
| Design system: palette, type, ground, grain, lid sphere, props, glass buttons | `BinDayNZ/Design/*`, `App/AppTheme.swift`, `Models/BinType.swift`, `Views/Shared/BinLidChip.swift` | Fable |
| Props: render, key, normalise, imagesets | `scripts/key-props.py`, `Assets.xcassets/Props` | Codex (render), Fable (keying) |
| Today: hero, verdict, kerb gesture, reminder status, holiday panel, location capsule, settings sheet | `Views/Today/*`, `App/ContentView.swift` | Fable |
| Schedule: fortnight street, month grid, next collections, day detail | `Views/Schedule/*` | Claude subagent |
| Guide: one page per bin, yes/no columns, source, Auckland videos | `Views/Info/*` | Claude subagent |
| Settings and onboarding on linen, sheets restyled | `Views/Settings/*`, `Views/Onboarding/*`, sheets | Claude subagent |
| Localisation of new copy into mi, zh-Hans, hi, ko (catalog order preserved) | `Resources/Localizable.xcstrings` | Claude subagent |
| UI tests updated to the new structure | `BinDayNZUITests/*` | OpenCode |
| Fresh-eyes critique of the built screens | `docs/design/kerb-build-2026-11-09/critique` | Codex |

## Verification

1. `python3 scripts/check-localizations.py`, `xcodegen generate`, unsigned simulator build.
2. Unit tests on an isolated simulator (`BinDayNZTests`).
3. Screens captured on iPhone 17 Pro, iPhone 17 Pro Max, iPhone 16e, iPhone Air and iPad Pro 11-inch
   in light and dark, English and Chinese, default and accessibility text sizes, Reduce Motion on.
4. Onboarding UI test run on a clean simulator.
5. Independent critique, then the top three issues fixed and re-captured.

Limits are recorded with the results in `docs/design/kerb-build-2026-11-09/README.md`.
