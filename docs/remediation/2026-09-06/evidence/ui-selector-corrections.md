# Recovered iPhone UI journey: selector corrections

Device: BinDay Audit 0609, iPhone 17 / iOS 26.2, E7B0A682-1912-4538-B8DC-EA62BEA8D745. All profiles are synthetic; the app was uninstalled before each full journey.

The following recovered runs executed real app interactions. They are failed runs, not a passing end-to-end result. Full xcresult bundles and raw attachments are retained under `/tmp`; named screenshots and compact manifests are in `screenshots/ui-recovered-N/`.

| Run | Reached | Evidence-based test correction |
| --- | --- | --- |
| 1 | Welcome → optional address → manual schedule editor | The labeled confirmation switch is a containing row. Tapping its unlabeled native child UISwitch changes the value and enables Save. Assert both before continuing. |
| 2 | Saved manual schedule → reminders → denied notification permission → Today → edit schedule | Two nested sheets each expose a navigation-bar Save button. Scope Save and Cancel to `Your bin schedule` and `Change schedule`. |
| 3 | Edit cancellation → Schedule → Info | The actual guide button combines title and subtitle. Query the button containing its title StaticText; scope Done to its guide navigation bar. |

## Selector excerpts

Run 1 hierarchy after tapping the containing row:

```text
Switch, {{16.0, 803.7}, {370.0, 72.0}}, label: 'I have checked these dates for my property', value: 0
  Switch, {{309.0, 826.0}, {63.0, 28.0}}, value: 0
```

Run 2 ambiguous query:

```text
NavigationBar, identifier: 'Change schedule'
  Button, label: 'Save', Disabled
NavigationBar, identifier: 'Your bin schedule'
  Button, label: 'Save', Disabled
```

Run 3 guide hierarchy:

```text
Other, label: 'Rubbish'
  Button, label: 'Rubbish, What goes in'
    StaticText, label: 'Rubbish'
    StaticText, label: 'What goes in'
Other, label: 'Recycling'
  Button, label: 'Recycling, What goes in'
```

These failures establish selector mismatch, not a broken app control. The parent/child accessibility structure still merits physical VoiceOver review; simulator automation is not a substitute.

## Visual finding

`14-today-dark-before.png` was captured after reopening the saved synthetic profile in dark appearance and inspected directly. The Council link, notification-settings link, and selected Today tab use a dark green tint on dark surfaces, making these controls difficult to read. The main white-on-green Change schedule button remains readable. This is a real app contrast issue, reported to the root agent for a semantic-color fix. The simulator was returned to light appearance afterward.

At default text size, the inspected welcome, optional-address, schedule editor, Today, and Schedule screenshots show readable native layouts without observed clipping of their main visible controls. Compact layouts, larger text, spoken focus order, and the remaining journey are separate evidence gates.

## Run 4: full interaction path, audit-engine timeout

All functional assertions reached: native confirmation enabled Save; setup completed with notification permission denied; Today exposed the denial; nested edit cancellation returned to the preserved schedule; Schedule and both guide sheets opened; no video webview loaded automatically; Privacy and Help opened; Chinese retained the selected Settings tab; switching back to English and terminating/relaunching restored Today without onboarding. The test then failed because Apple's combined accessibility audit returned `com.apple.xcode.xctest.accessibilityAudit Code=-56: Audit failed to complete in time`. This is not a passing test result and does not establish accessibility conformance. See `ui-recovered-4-summary.json` and its execution log.

The complete current guide, privacy, Settings, and Chinese screenshots were inspected directly. Visible text and main controls remain readable at default text size. This is a visual/layout check, not fluent-language validation or verification of offscreen content. The selected Settings tab and version 1.2 (3) are visible in the Chinese screenshot.

The next test build separates the functional journey from native visual and accessibility checks. Focused audit options come from Apple's installed `XCUIAutomation.framework/Headers/XCUIAccessibilityAuditTypes.h`: contrast, hitRegion, sufficientElementDescription, dynamicType, and textClipped. No audit issues are filtered or suppressed.
