# Native UI verification

Scope: local 1.2 (3) candidate on dedicated synthetic iOS 26.2 simulators, exercised across 6–7 September 2026. No publication, personal profile, external support message or physical-device test was performed. The final source snapshot is maintained by the root audit record.

## Results

| Scenario | Result | Evidence |
| --- | --- | --- |
| Large iPhone 17, light, default text: clean manual setup → deny reminders → edit/cancel → Schedule → guides → Privacy and Help → Chinese/English → relaunch | **Passed**, 1 case, 0 failures, 0 skips | `ui-recovered-5-summary.json`, `ui-recovered-5.log`; named screenshots in `screenshots/ui-recovered-5/` |
| Same full journey plus Apple's combined accessibility audit | Functional assertions reached; **run failed** at audit engine timeout, code -56 | `ui-recovered-4-summary.json`, `ui-recovered-4.log` |
| Compact iPhone SE, dark, default text: same complete functional journey | **Passed**, 1 case, 0 failures/skips | `compact-dark-ui-2-summary.json`, `compact-dark-ui-2.log`; `screenshots/compact-dark/` |
| Compact dark saved Today → Schedule → List → named-bin day detail | **Passed**, 1 visual case | `compact-dark-audits-summary.json`; `screenshots/compact-dark-audits/` |
| Actual frequency and one-off change, save/relaunch/reopen | **Passed**, 1 persistence case | `compact-edit-contrast-summary.json`, `compact-edit-contrast.log`; `screenshots/compact-edit-contrast/` |
| Compact dark, largest text: saved Today → automatic Schedule list → moved Rubbish day detail | **Passed** before and after the final layout fixes, 1 visual case per run | `compact-largest-text-summary.json`, final `compact-largest-text-after-summary.json`; named before/after screenshot directories; requested `accessibility-extra-extra-extra-large` independently confirmed via simctl |
| Native hit-region audit, compact dark default text | **Passed** on Today and Schedule | `compact-dark-audits-summary.json`, `compact-dark-audits.log` |
| Native description, Dynamic Type and clipping audits, compact dark largest text | **Passed** before and after the final layout fixes, 3 focused cases on Today and Schedule per run | `compact-largest-text-summary.json`; final `compact-largest-text-after-summary.json`, `compact-largest-text-after.log` |
| Native contrast audit, compact dark | **Failed** at the initial Today position and after revealing reminder status; both findings sample content behind the floating tab bar. Schedule contrast was not reached. | Original/diagnostic summaries and cropped/full screenshots retained in `compact-dark-audits` and `compact-edit-contrast` |

The passing large-phone test checked the native confirmation value and Save enablement, actual permission denial and visible denied status, both nested editor cancellations, no automatically created guide webviews, retention of the selected Settings tab during Chinese switching, and persisted setup after terminating/relaunching. The additional persistence test changed Rubbish from weekly to fortnightly, moved its next collection from 7 to 8 September, saved both editor and parent, terminated/relaunched, and reopened to verify fortnightly cadence and one saved change. Recycling stayed fortnightly and Food Scraps weekly. Screenshots also show the next regular Rubbish collection on 21 September. These UI cases did **not** enter a real address, enable Calendar, open a source link, play a video, or establish notification delivery. The root agent owns separate notification-allow and native service integration results.

## Visual inspection

Current large-phone Today, editor, Schedule, Info, Rubbish/Recycling guide, Settings, Privacy and Help, Chinese Settings and relaunch images were inspected directly. At default text size, main visible text and controls are readable with no observed clipping. Below-screen content requires scrolling and is not certified by one screenshot. Chinese layout was checked, not fluent translation quality.

The dark pre-fix image `screenshots/14-today-dark-before.png` exposed hard-to-read dark green Council/notification-settings links and selected tab tint. Root replaced the link/tab tint with a semantic light mint in dark mode while keeping a dark green fill behind white primary-button text. The compact dark Today screenshot confirms the Council link and selected Today tab are now clearly visible. The full compact dark journey and saved Schedule/list/detail screens were subsequently inspected and passed their interaction assertions.

At the largest text setting, Today content expands vertically, Schedule switches from the grid to a list, and the moved Rubbish date opens in a full-height detail sheet. The first pass exposed “Sep-tember” hyphenation within the narrow arrow row and symbol/text crowding from a fixed reserved symbol width. The root agent applied two small native layout fixes: give the accessibility-size month title full width above the arrow row, and let the symbol frame grow to its glyph's natural width.

The final candidate was rebuilt (`ui-build-8.log`) and the same four cases rerun: saved-schedule visual navigation plus sufficient-element-description, Dynamic Type and clipped-text audits. **All four passed, 0 failures, 0 skips.** The three audit cases each covered Today and Schedule; the visual case additionally opened the moved collection's named-bin detail. This rerun did not include contrast or hit-region audits.

The final Today, Schedule and detail screenshots were inspected directly. “September” now stays intact above “2026”; month arrows occupy their own row. The Food Scraps and Rubbish glyphs have clear space before their labels, including the full-height Rubbish detail. Both reported layout observations are resolved in this scoped largest-text view. Before images remain in `screenshots/compact-largest-text/`; final images and manifest are in `screenshots/compact-largest-text-after/`. The larger-font vertical scrolling remains intentional, and offscreen content is not certified by a single screenshot.

## Contrast diagnosis

The original contrast failure identified the reminder-status label almost entirely behind the floating tab bar; its element crop is a thin 484×40-pixel strip. A separate diagnostic test scrolled that label fully into view. The status and its Settings link were then visibly readable, but the audit flagged a different Rubbish label behind the tab bar; its crop is only 126×40 pixels and includes the overlying Today icon. This supports an occluded-edge sampling limitation, rather than the same status text remaining low contrast. Both native failures remain failures, no issue handler filters them, and neither run provides a passing full-screen contrast result. Production layout was not changed solely to satisfy the edge sampling.

## Evidence limits

The combined accessibility timeout and the two contrast failures remain open evidence limits. The focused passes above do not imply full accessibility conformance. Physical VoiceOver focus order, spoken labels, minimum-OS behavior, real notification delivery, widget family/layout/refresh behavior, Reduce Motion and fluent-language review remain separate checks. iPad coverage is owned by the root agent. Simulator OS startup stalls and failed selector attempts remain documented without being counted as passes.

Raw xcresult bundles, full AX trees, event recordings and videos remain under `/tmp`. The repository retains named stage screenshots, compact manifests, result summaries and concise selector excerpts in `ui-selector-corrections.md`.
