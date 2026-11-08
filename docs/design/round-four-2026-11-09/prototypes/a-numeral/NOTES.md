# Direction A: Numeral

**Idea:** the day is a number. Today is carried by one enormous light "10" on linen; the bins are three matte clay spheres beneath it, and colour exists only inside those spheres.

## Elements
- **Location capsule + gear (Today):** one `GlassEffectContainer`; the capsule "Mount Eden ⌄" is the title, the circular glass gear is settings. No navigation title.
- **Eyebrow "TOMORROW · TUESDAY":** 13 pt tracked label; it answers "how soon" before the numeral answers "when".
- **Rhythm:** capsule to eyebrow 32 pt; eyebrow, numeral, sentence, spheres and button step down in even 24–32 pt intervals; fortnight sits 32 pt above the tab bar.
- **Hero "10":** SF 180 pt Light, tracking -8, `monospacedDigit`, `numericText` transition, `minimumScaleFactor(0.5)`. Pulled 21 pt left so the flag of the "1" sits on the 24 pt margin, and the empty line box above the cap height is trimmed so the cap top sits 12 pt under the eyebrow. "November" 20 pt muted hangs off the baseline.
- **Sentence:** 24 pt ink verdict, then "Put them out by 7 am" 17 pt muted.
- **Bins:** three `LidSphere(size: 36)` as a left-anchored cluster, 28 pt gaps, sphere and small-caps name leading-aligned so the first sphere sits on the margin (art direction: 48 pt full-width read as a traffic light).
- **Primary action:** "Remind me at 7 pm", content-width `.glass` capsule, `.controlSize(.large)`, label in moss, left-aligned under the spheres (the full-width opaque prominent capsule was too heavy).
- **Fortnight strip:** two rows of seven 12 pt spheres echoing the app icon; this Tuesday raised ochre, next Tuesday raised sage, the rest greige. Labels "THIS WEEK / NEXT WEEK" to the left. Texture first, calendar second.
- **Schedule:** eyebrow "NOVEMBER 2026" + glass `calendar.badge.clock`; boxless 7-column grid with hairline week rules, 17 pt tabular numerals, past days muted, collection Tuesdays carry a tight cluster of 9 pt spheres, today (9) is a 32 pt moss disc. Below: next four collections as type (34 pt light numeral, small-caps weekday or "TOMORROW", bin names 17 pt with 14 pt spheres), rows top-aligned so "TOMORROW" and "TUE" share the same position, bin lines on a 24 pt pitch, hairlines between, then the snowflake holiday line in 15 pt muted. Scrolls under the glass tab bar.
- **Guide:** paged `TabView` per bin; frequency eyebrow, 44 pt name, 184 pt hero sphere, 17 pt blurb, YES / NO columns in 15 pt (ink / muted) split by a hairline. Page indicator is three 8 pt spheres, current one raised; glass `safari` button trailing.
- **Extra:** the reminder sheet (`.fraction(0.42)`, `.thinMaterial` warmed with 55% linen), three 28 pt light options with small-caps captions; the selected one carries a moss matte sphere.

## Motion
- **Entrance (Today):** eyebrow rises 12 pt, numeral settles from 24 pt below (spring response 0.6, damping 0.85), sentence follows 60 ms later, the three spheres drop from 28 pt above with 40 ms stagger and squash on landing (scale 1.07 x 0.9 anchored at the bottom, released on a bouncier spring), labels follow each sphere, the button last (content-width glass), the fortnight fades in at 400 ms.
- **Idle:** only the raised ochre sphere in this week's row breathes (scale 1.06 and 0.8 pt lift, 3 s each way, a 6 s cycle). Nothing else moves.
- **Schedule / Guide:** grid and rows settle in with the same spring, 40 ms stagger; the guide hero sphere drops and squashes; indicator sphere rises with the page spring.
- **Numbers:** `.contentTransition(.numericText())` on the hero and the schedule numerals.
- **Reduce Motion:** offsets and drops are skipped, everything cross-fades in 250 ms, the breathing is off.
- **Gestures:** horizontal paging in Guide; option rows in the sheet animate the sphere across on tap.

## Compromises
- Hero numeral is 180 pt, not the 196 pt in the direction note, to stay inside the brief's 120–180 pt rule. Guide sphere is 184 pt, not 168 pt, to meet the 45 % width rule.
- The sheet hides the bin names in the extra shot (the spheres stay visible above it).
- Today's capsule and Guide's indicator are static; no address picker or settings screen behind them.
- Optical alignment offsets (-21 pt leading, -34/-36 pt line box trim) are tuned for "10" at this size; other numerals (e.g. "24") would need per-glyph metrics.
- Schedule has no single oversized hero; the grid is the object, which reads quieter than Today.

## With another day
- Compute side bearings from CoreText glyph bounds instead of hard offsets, so any day number sits on the margin.
- Let the fortnight strip scrub: drag across it to preview any day, with the numeral rolling via `numericText`.
- A month-to-month swipe in Schedule with the eyebrow and numerals rolling.
- Tune the sheet material warmer still, and fill its lower third (e.g. "Also remind me next week" as a quiet line).
