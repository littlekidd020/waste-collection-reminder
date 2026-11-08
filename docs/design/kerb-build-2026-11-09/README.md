# Kerb build, 9 November 2026

Direction D "Kerb" from round four, built into the shipping app. Plan and decisions:
`docs/plans/2026-11-09-kerb-redesign-build.md`. Review canvas: https://claude.ai/artifact/NtCiPULTBksHVGKeso8vim

## What is here
- `today/NOTES.md`, `schedule/NOTES.md`, `guide/NOTES.md`, `settings/NOTES.md`: what each area built, its
  motion, compromises and what could not be verified.
- `strings/`: the new interface strings with translator context, the translations merged into the
  catalog, and the merge script's notes.
- `shots/`: simulator captures of the built app (see the table below).
- `critique/`: the independent fresh-eyes critique of the built screens and the brief that produced it.
- `props/`: the renders behind the bins (source pairs from Codex, keyed cut-outs are in the asset catalog).

## Verification record (9 November 2026)

| Check | Result |
|---|---|
| `python3 scripts/check-localizations.py` | PASS: 378 source keys, 378 catalog keys in five languages; 34 keys added by the build, 38 unused keys pruned |
| Unsigned simulator build (`xcodebuild build`, iPhone 17 Pro) | Succeeded |
| Unit tests (`BinDayNZTests`, iPhone 17 Pro) | 61 tests, 0 failures, 2 skipped (calendar isolation tests skip without their flag) |
| UI tests | Rewritten for the three-tab structure; `OnboardingFlowUITests.testConfirmedScheduleRecoveryEditingGuidesAndRelaunch` passes on the iPhone Air simulator (denied-notifications path, 110 s). The store-screenshot test compiles but was not run |
| Today | iPhone 17 Pro light and dark; at the kerb and back; XXXL and accessibility text; iPhone 16e (Tauranga, four composed bins; Simplified Chinese); iPad Pro 11-inch; relaunch keeps the kerb state |
| Schedule | iPhone 17 Pro Max light, dark, XXXL, accessibility list; Auckland and Hamilton seeds; month swipe; day sheet |
| Guide | iPhone 17 light, dark, XXXL, accessibility; Auckland (four pages) and Tauranga (crate and garden bin) |
| Onboarding and Settings | iPhone Air: full onboarding with no seed, light, dark, XXXL; Settings sheet |
| Fresh eyes | Codex blind critique (`critique/out.md`): dated 2021; three faults fixed (dark fringes, button lettering, Today gap), two declined with reasons |

### Not verified
- Reduce Motion: the fade-only paths exist but `simctl` cannot switch it on; not seen running.
- VoiceOver walked end to end; labels, values, hints and custom actions are set in code only.
- A physical device, and the widget beyond compiling (it now draws lid spheres from the shared code).
- Hindi, Korean and te reo Māori on screen (the strings exist and pass the checker; two te reo renderings are flagged for a speaker in `strings/translations.json` notes).

### Known compromises
- The trio render and the composed clusters sit at slightly different camera distances.
- The props are flat renders: wheels do not turn during the roll.
- The minimum iOS rose from 17 to 26 (see the plan). Nothing is committed.
