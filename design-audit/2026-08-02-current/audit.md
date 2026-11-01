# Bin Day NZ — current-state product design audit

Captured 2 August 2026 from the current iOS build on a clean iPhone 17 simulator. This is a review artifact only; no production UI was changed.

## Overall verdict

The app is functionally understandable and the native iOS foundations are sound, but the experience feels assembled from repeated white cards and explanatory copy rather than shaped around the one answer people need: **what bin goes out next, and when?** The redesign should retain the restrained native structure, reduce copy by roughly one third, and use a consistent visual language of outlined SF Symbols, bin-specific patterns, and a small number of purposeful illustrations or thumbnails.

The most urgent UX issue is not aesthetic: the Rubbish detail currently shows a recycling-cleaning YouTube video, which weakens trust in the guide.

## Screen-by-screen review

### 1. Welcome — needs refinement

![Welcome screen](</Users/kexinli/My Drive/AI Projects/waste collection reminder/design-audit/2026-08-02-current/01-welcome.png>)

- **Strength:** clear product name, language control, and primary action.
- **Issue:** the three benefit rows repeat familiar concepts while the centre of the screen remains visually empty; the three bin icons are decorative rather than explanatory.
- **Direction:** replace the feature list with one compact illustrated collection-day scene, one short promise, and the CTA. Keep text to title, one sentence, and one action.
- **Accessibility:** icon-only decoration is correctly hidden from assistive technology in source, but the language control and hero should be verified at accessibility Dynamic Type sizes.

### 2. Council selection — high friction

![Council selection screen](</Users/kexinli/My Drive/AI Projects/waste collection reminder/design-audit/2026-08-02-current/02-council-selection.png>)

- **Strength:** supported and unsupported councils are distinguishable.
- **Issue:** unavailable “Coming Soon” rows dominate the decision and make the product feel less capable; the user must scan a long inactive inventory before moving on.
- **Direction:** lead with a small NZ/Auckland coverage graphic and one selected council row. Collapse unavailable councils into a secondary “Other councils coming soon” disclosure.
- **Accessibility:** very light disabled labels may be difficult to read; do not rely on fading alone to communicate availability.

### 3. Address search — incomplete empty state

![Address search screen](</Users/kexinli/My Drive/AI Projects/waste collection reminder/design-audit/2026-08-02-current/03-address-search.png>)

- **Strength:** one-field task and a visible manual fallback.
- **Issue:** the screen offers little guidance before typing, and the manual path is visually detached. In this captured state, the bottom page indicator visibly collides with the disabled Continue surface.
- **Direction:** place a lightweight map/route illustration behind a compact search panel, explain accepted address detail with one example, and keep manual setup adjacent to search as an equal fallback.
- **Accessibility:** disabled-action contrast is very low; keyboard, focus order, error messaging, and bottom safe-area behaviour require device testing.

### 4. Manual schedule — healthy, visually generic

![Manual schedule screen](</Users/kexinli/My Drive/AI Projects/waste collection reminder/design-audit/2026-08-02-current/04-manual-schedule.png>)

- **Strength:** compact form, native controls, clear Save/Cancel model.
- **Issue:** users configure abstract fields without seeing the schedule they are creating.
- **Direction:** add a small two-week visual preview using outlined bin symbols and pattern-coded collection days; keep the controls but remove explanatory repetition.
- **Accessibility:** native controls are a good base; verify picker labels, larger text wrapping, and whether colour-coded bin types also have names/patterns.

### 5. Reminders — understandable but repetitive

![Reminder setup screen](</Users/kexinli/My Drive/AI Projects/waste collection reminder/design-audit/2026-08-02-current/05-reminders.png>)

- **Strength:** reminder types and final CTA are easy to find.
- **Issue:** three similarly weighted cards repeat labels, descriptions, toggles, and time controls, slowing the scan.
- **Direction:** use one vertical notification timeline: evening, morning, calendar. Each row gets an outlined time-of-day symbol, a short label, and its control; reveal time only when enabled.
- **Accessibility:** light secondary copy and compact time chips need contrast and touch-target checks. State must be announced beyond colour.

### 6. Today — strong purpose, weak hierarchy

![Today screen](</Users/kexinli/My Drive/AI Projects/waste collection reminder/design-audit/2026-08-02-current/06-today.png>)

- **Strength:** the user can quickly see that there is no collection today and what happens tomorrow.
- **Issue:** “Manual schedule” is duplicated in the address row; Tomorrow and Upcoming repeat the same information; glossy coloured balls conflict with the app’s outlined symbol direction.
- **Direction:** make the next collection the hero: large outlined bin pictogram, day/date, and a countdown chip. Follow it with one compact upcoming timeline. Use solid symbols only for selected/current states.
- **Accessibility:** the address truncates; bin identity should use label + symbol + pattern, not colour alone.

### 7. Schedule — useful overview, difficult scan

![Schedule screen](</Users/kexinli/My Drive/AI Projects/waste collection reminder/design-audit/2026-08-02-current/07-schedule.png>)

- **Strength:** familiar calendar navigation and a compact month overview.
- **Issue:** collection marks and legend labels are too small to decode quickly. The last visible week also appears compressed/misaligned in this capture and needs layout verification.
- **Direction:** use a single pattern-coded collection ring or stacked symbol group per day, strengthen the selected-day treatment, and surface the selected date’s bins directly below the calendar.
- **Accessibility:** tiny marks are risky at standard size. Source includes a list alternative at accessibility Dynamic Type, but VoiceOver order and contrast still need testing.

### 8. Info — visually engaging but inconsistent

![Info screen](</Users/kexinli/My Drive/AI Projects/waste collection reminder/design-audit/2026-08-02-current/08-info.png>)

- **Strength:** the map and category grid provide useful visual entry points.
- **Issue:** saturated card headers, glossy dots, outlined symbols, and an emoji illustration compete as four different visual languages. The map summary also repeats manual-schedule text.
- **Direction:** use one pictogram family, quieter surfaces, and category-specific line patterns. Reserve strong bin colours for the icon ring and key state, not entire card headers.
- **Accessibility:** several labels are small/light, and colour-coded categories need text and pattern redundancy.

### 9. Rubbish detail / YouTube — critical content mismatch

![Rubbish detail and YouTube screen](</Users/kexinli/My Drive/AI Projects/waste collection reminder/design-audit/2026-08-02-current/09-youtube-player.png>)

- **Strength:** video can explain a physical sorting task faster than prose.
- **Issue:** the Rubbish detail shows “Clean the Recycled Items,” so the media does not match the selected category. The long Yes/No lists below remain text-heavy.
- **Direction:** fix video/category mapping first. Then use a matched thumbnail with a clear play treatment and convert the lists into labelled pictogram tiles: “Put in” and “Keep out.”
- **Accessibility:** provide captions/transcript availability, an explicit external-video label, and accessible names for every pictogram.

### 10. Settings — familiar but dense

![Settings screen](</Users/kexinli/My Drive/AI Projects/waste collection reminder/design-audit/2026-08-02-current/10-settings.png>)

- **Strength:** grouped settings match iOS expectations and the important controls are present.
- **Issue:** repeated white groups and similarly weighted rows make status hard to parse; several values read like editable content even when they are summaries.
- **Direction:** lead with three compact status rows—Location, Reminders, Calendar—using outlined icons, a one-line value, and disclosure. Move detailed timing controls into a dedicated reminder screen.
- **Accessibility:** verify large-text reflow, toggle/value announcements, and that lower rows are not obscured by the tab bar.

### 11. Change Address — functional, redundant state

![Change Address screen](</Users/kexinli/My Drive/AI Projects/waste collection reminder/design-audit/2026-08-02-current/11-change-address.png>)

- **Strength:** the map restores spatial confidence, the title is correctly placed in the modal header, and Save/Cancel are obvious.
- **Issue:** “Manual schedule” appears as the address, selected schedule, and fallback action. The map pin is centred on Auckland rather than explaining the current manual setup, so the visual can imply false precision.
- **Direction:** when the setup is manual, replace the map with a friendly service-area illustration and a clear “No saved address” state. Show a real map only after an address resolves.
- **Accessibility:** the map can remain decorative, but every status and action needs a text equivalent; verify focus order across header, address field, selected schedule, and manual action.

## Recommended aesthetic direction

**Civic calm with playful collection cues**

- Keep SF Pro, native navigation, generous whitespace, and system materials.
- Use outlined SF Symbols by default; use filled variants only for selected/current states.
- Reduce card count. Prefer open sections, dividers, and icon-led rows; reserve elevated cards for one primary answer or action.
- Use one green product accent. Reserve red/yellow/green/orange for bin semantics, applied to icon rings, small markers, and subtle pattern fills.
- Introduce four accessible category patterns—solid, diagonal stripe, dot, and grid—so bin types remain distinguishable without colour.
- Use imagery purposefully: one hero illustration in onboarding, real map only for resolved locations, and category-matched YouTube thumbnails in guides.
- Replace paragraphs and long lists with pictogram tiles, timelines, and compact status summaries. Target roughly 30–40% less visible copy.

## Motion direction

- Keep system sheet/tab/navigation motion.
- Use 160–200 ms ease transitions for selection and disclosure; use a filled-symbol replacement and light haptic rather than repeated bounce effects.
- Keep the calendar’s directional month transition, but reduce travel and avoid spring overshoot.
- Use a single 250 ms opacity + 8 pt rise for first-load content, disabled when Reduce Motion is enabled.
- Source review shows Reduce Motion is considered in most major views, but the Info entrance still runs a short animation in its reduced-motion branch; standardise this before release.

## Highest-impact changes

1. Fix the Rubbish/recycling YouTube content mismatch.
2. Redesign Today around one next-collection hero and one upcoming timeline.
3. Replace onboarding feature/availability lists with a coverage graphic, one illustration, and shorter copy.
4. Establish one icon/pattern system and remove glossy balls/emoji from the core UI.
5. Simplify Info and Settings by reducing repeated cards and moving detail behind focused drill-ins.
6. Verify address bottom controls, calendar grid alignment, tab-bar insets, and Dynamic Type before visual implementation.

## Evidence limits

This audit covers the complete reachable light-mode app journey in a clean iPhone 17 simulator plus a current-source review of motion and accessibility hooks. Screenshots cannot establish VoiceOver order, actual contrast ratios, touch-target size, keyboard behaviour, live API errors, notification permission recovery, dark mode, Reduce Motion behaviour, or real-device rendering. Those require a separate validation pass after the visual direction is approved.

