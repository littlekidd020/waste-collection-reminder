# Round four: crafted interface directions, 9 November 2026

Four interface directions for Bin Day NZ, built as real SwiftUI screens on iOS 26.2 and captured on the iPhone 17 Pro simulator, after the round-three image boards were rejected as old school. Palette P5 Linen and clay (approved 9 November). Review canvas: https://claude.ai/artifact/NtCiPULTBksHVGKeso8vim (section "Round four").

| Direction | Idea | Prototype |
|---|---|---|
| A Numeral | The day as a 180 pt light numeral; bins as matte spheres | `prototypes/a-numeral` |
| B Dial | The fortnight as a matte clay ring with the bins as beads; scrubbable | `prototypes/b-dial` |
| C Tag | One Liquid Glass hang tag on a cord with a New York numeral | `prototypes/c-tag` |
| D Kerb (recommended) | The rendered bins stand on the linen ground; swipe them to the kerb | `prototypes/d-kerb` |

## What is here
- `BRIEF.md`: the craft brief every direction followed (hard rules, content checklist, capture commands).
- `benchmark-analysis.md`: study of six Apple Design Award 2026 apps that informed the rules.
- `shots/`: the sixteen captures, 603 px wide (`r4-<direction>-<screen>.jpg`).
- `props/`: Codex-rendered matte clay bins keyed to transparency (3x assets) and the brief that produced them.
- `critique/`: independent fresh-eyes critiques of each direction's stills by Codex, and the brief used.
- `prototypes/scaffold/`: the shared XcodeGen project (palette, sample data, lid sphere, grain, launch-argument routing). Each direction folder holds its `Direction/` sources and `NOTES.md` (motion design, compromises).

## Rebuild a direction
```
cp -R prototypes/scaffold /tmp/r4 && rm -rf /tmp/r4/Sources/Direction && cp -R prototypes/d-kerb/Direction /tmp/r4/Sources/Direction
cp -R prototypes/d-kerb/Assets.xcassets /tmp/r4/Assets.xcassets   # Kerb only
cd /tmp/r4 && xcodegen generate && xcodebuild -project RoundFour.xcodeproj -scheme RoundFour -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath dd build
xcrun simctl launch booted nz.binday.proto.scaffold -screen today   # today | schedule | guide | extra
```
Sample data is fixed at Monday 9 November 2026, 5:30 pm, Mount Eden, Auckland. Nothing here is wired to the app's schedule engine, languages or dark mode.
