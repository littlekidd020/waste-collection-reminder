# Direction B: Dial

**The idea:** the fortnight is an instrument. You read the coming two weeks off a matte clay ring the way you read a watch.

## Elements
- **Today, the fortnight dial** (`FortnightDial`, `TorusRing`). A 312 pt torus, centred 38 percent down the screen. Twelve o'clock is now (Monday 5:30 pm), and the ring runs clockwise through fourteen days. The shading is layered strokes: a radial tube gradient with ambient occlusion at both edges, a global light from the upper left and shade to the lower right, specular bands on the outer shoulder (upper left) and the inner wall (lower right), and 1 pt rim highlights. Shadow is `Palette.shadow` at 12 percent, radius 18, y 10, plus a 2 pt contact shadow. Fourteen engraved ticks (a dark cut with a lit edge) sit on the exact midnight angles. The weekday initials (10 pt, muted) sit on each day's centre angle, and the collection day's initial is set bold in ink.
- **Bins as spheres on the ring.** The first sphere of each Tuesday sits exactly at 7 am on that day's arc and the rest fan forward along the day, so where a sphere sits means something: "out by 7 am". Tomorrow has three spheres and next Tuesday two, so the fortnight rhythm shows with no text.
- **Sweep.** A 28 pt arc in accent at 28 percent runs from now to 7 am on the collection day ("until collection"). It sits under the clay lighting, so it looks dyed into the clay rather than painted on top.
- **Needle.** A 2 pt accent hand from the hub to 5 pt past the ring. Where it would cross the centre type it passes under it: it starts at the edge of the type block, with the 6 pt hub bead there. This keeps "Tue 10" legible at every angle.
- **Centre:** the eyebrow ("TOMORROW" or "IN 8 DAYS"), "Tue 10" at 60 pt light with tabular digits, then "3 bins".
- **Verdict:** one 22 pt sentence, "Put them out by 7 am", and one glass-prominent reminder button in moss that hugs its text.
- **Chrome:** a glass "Mount Eden" capsule and a glass gear in one `GlassEffectContainer`, plus the system glass tab bar (three tabs, minimises on scroll).
- **Schedule, the thread.** A 1.5 pt hairline at x = 88 with each collection as a bead cluster on it (the first sphere 20 pt, the rest 16 pt, stacked tightly). The day sits left of the rule (12 pt weekday over a 34 pt light tabular numeral, fixed width) and the names right of it. The month label appears only when the month changes, and "Tomorrow" sits with it on the first row. Recycling weeks get a faint 2 pt ochre dash on the rule under the cluster. The holiday notice with a snowflake ends the thread. Rows are 96 pt.
- **Guide, three gauges.** Each is a 96 pt mini torus (10 pt tube) in clay, with the completed arc dyed in the lid colour at 70 percent: weekly is full, fortnightly is half. A 28 pt sphere sits in the centre. The selected gauge is scaled 1.08 with a deeper shadow and a raised sphere, and the others dim to 70 percent. Below are the name (40 pt), the frequency line, the blurb, and YES/NO columns with a hairline between them. Switching gauges cross-fades the detail (`.id` + `.transition(.opacity)`) with a selection haptic.

## Motion
- **Entrance (Today):** the ring draws itself clockwise from twelve over 0.7 s (every lighting layer is trimmed together, so it draws as an object). Ticks and labels fade in at 0.45 s. Spheres drop 26 pt onto the ring one after another (70 ms stagger, spring response 0.42 and damping 0.52 for a small bounce). The needle swings in from 48 degrees before twelve and settles on now (spring response 0.7, damping 0.8). Now is at twelve by definition, so a literal "twelve to now" swing would be zero, which is why the swing starts before twelve.
- **Idle:** a `TimelineView(.everyMinute)` advances the needle by 1/20 160 of a turn per real minute. That is honest, and imperceptible. The centre numerals, eyebrow and button label use `.contentTransition(.numericText())`.
- **Scrub (the Extra state):** a `DragGesture` on the dial converts the touch angle to one of the fourteen days and snaps the needle to that day's centre, with a light impact haptic per day. The centre and the sentence follow the next collection on or after that day. The sweep extends to it, its spheres rise (raised, scaled 1.14), the other Tuesday's spheres dim to 45 percent, and the day initial goes bold. On release, everything springs back to now. VoiceOver gets an adjustable action that steps through the days. `-screen extra` freezes the dial on Saturday 14, about a third of the way round, where the next collection is Tue 17.
- **Schedule** rows rise in with a 40 ms stagger. **Guide** gauges draw their arcs in with a 60 ms stagger.
- **Reduce motion:** draws become a 0.4 s fade, spheres fade in place, and the needle starts at rest.

## Compromises
- The weekday initials on the ring are 10 pt, per art direction. That is below the brief's 12 pt label floor.
- The thread moved from x = 72 to x = 88 so two-digit 34 pt numerals and a bead fit inside the 24 pt margin.
- The needle doesn't start at the true centre (see above). The 6 pt hub bead sits at the needle's inner end instead.
- The weekly gauges are necessarily full lid-colour rings, so the gauge row still carries more colour than the rest of the screen.
- The sweep is short on Today (5:30 pm Monday to 7 am Tuesday is 14 degrees) and is partly covered by the first sphere. It only reads strongly in the scrub state.
- The status bar shows 9:41 (the capture override), while the content is set at 5:30 pm.

## With another day
- Render the ring as a real normal-mapped Metal or `layerEffect` shader, with grain on the clay and a true contact shadow under each sphere on the tube surface.
- Add a detent "click" sound and rubber-banding at the ring ends.
- Add a holiday marker on the dial when a shift falls inside the fortnight.
- Animate the Schedule beads threading down the rule on entrance.
- Give the gear and capsule real sheets.
