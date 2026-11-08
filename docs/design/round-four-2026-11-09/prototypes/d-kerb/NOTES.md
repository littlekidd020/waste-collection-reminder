# D, "Kerb"

**The idea:** the household's actual bins, rendered as matte clay objects standing on the linen floor, are the interface; type is quiet and the objects carry the colour.

## Elements

### Today
- **Glass chrome**: a centred "Mount Eden" location capsule and a trailing `gearshape` circle in one `GlassEffectContainer`. No navigation title, no bar.
- **Eyebrow** "TOMORROW · TUESDAY 10 NOVEMBER" (13 pt tracked label), **verdict** "Out tonight" (44 pt semibold), and one human sentence (17 pt muted).
- **Hero**: the `bins-trio` render, 300 pt wide, its feet at 68 % of the screen height. The props carry their own contact shadow; under them sits a 6 % wide ellipse of `Palette.shadow` and a 120 pt `GroundBand` that eases linen into `Palette.surface` and finishes 24 pt below the captions, so the bins stand on a floor rather than float. The band is the surface colour laid over the ground at rising opacity, so the paper grain shows through it.
- **Captions**: lid sphere + name for each bin, 24 pt apart and 24 pt below the feet, so colour is always paired with a word.
- **Fortnight awareness**: "Next Tuesday: rubbish and food scraps only." in 15 pt muted. No holiday note on Today because Christmas is six weeks out; it lives on Schedule.
- **Primary action**: "Remind me at 7 pm", `.glassProminent` tinted moss, content-width and leading at the 24 pt margin, 24 pt above the tab bar.

### Schedule
- Eyebrow "THE NEXT FORTNIGHT" and a glass `calendar.badge.clock` circle.
- **Street strip**: 14 columns of 56 pt, starting today. Numeral (17 pt, monospaced) and weekday initial sit together as one unit, today in a 32 pt moss disc. Collection days hold a mini cluster of the single-bin props at 48 pt (arranged like the trio: recycling front left, rubbish behind and slightly higher, food front right). Every wheel touches one horizon line: the deepest point of a 140 pt band that eases in and back out, marked by one faint kerb hairline the whole street stands on.
- **List**: the next six collections. Weekday label above a 34 pt light numeral ("TOMORROW", and "DECEMBER" on the first row of a new month), bin names in 17 pt, a "Recycling week" / "No recycling" line in 15 pt muted, and the props at 32 pt trailing, standing on the row hairline that doubles as their ground.
- Holiday notice with `snowflake`, 15 pt muted, at the end. The content scrolls under the glass tab bar.

### Guide
- Paged `TabView`, one page per bin. Frequency eyebrow, name at 40 pt regular, the single prop as a 268 pt hero on its own eased band (the food bin comes out shorter on the same baseline because all singles share one camera and one canvas), the blurb, then YES / NO columns with a hairline between them.
- The page indicator is three 8 pt lid spheres, top leading, with the current one raised. A glass `safari` circle sits trailing.

### Extra (the completion moment)
- Swipe the trio right: the bins follow your finger at half speed, leaning up to 4° on their wheels. Past the threshold (measured on the predicted end) they roll about 54 pt towards the right edge, "to the kerb", and settle upright. The verdict becomes "Done for tonight", the sentence "They are at the kerb. Collection is from 7 am.", and the action becomes a content-width glass "Undo". Undo, or a left swipe, rolls them back. A success haptic fires on the change. The `.extra` capture freezes the settled state.

## Motion
- **Entrance**: the trio rolls in from off-screen right, leaning on its wheels (−5°), with spring(response 0.7, damping 0.8). The tilt rights itself with a second, slightly bouncier spring 380 ms in. The verdict block settles up from 12 pt below (spring 0.6 / 0.85, starting 80 ms after the bins), and the captions fade up once the bins land. The Schedule rows stagger in by 40 ms each.
- **Idle**: nothing. The still frame is the point.
- **Gesture**: the drag described under Extra. The rotation anchor is the trio's feet line, so the bins tip on their wheels and do not spin around their centre.
- **Reduce motion**: the bins fade in standing, and rolling to the kerb becomes a 0.3 s cross-fade with no tilt.
- **Scroll parallax (0.85×)**: not built, because Today does not scroll at this size. It would apply if Dynamic Type pushed the content into a scroll view.

## Compromises
- The single-bin renders are 1024 px canvases. At the Guide's 268 pt hero they are drawn at about 2× rather than 3× and are slightly soft up close. The sharper `bin-recycling-hero` exists only for recycling, so I kept every page on the same render for consistency.
- The rolls to and from the kerb are a translation plus a tilt. The wheels do not turn, because the props are flat images.
- The mini clusters in the street strip fake depth with small offsets and scale; at 48 pt that reads fine, but it is not a true render of the set.
- I cleaned faint alpha noise (alpha ≤ 12/255) out of the prop backgrounds in this project's copies so no faint rectangle shows over the band.
- "Remind me" only toggles its label; there is no real notification scheduling.

## With another day
- Render a dedicated kerb scene: a concrete kerb edge and a strip of berm grass on the right, so "Done for tonight" shows the bins standing *on* a kerb rather than nearer the screen edge.
- Re-render the singles at 1536 px for the Guide hero, and render real two- and three-bin cluster props for the street strip.
- Turn the wheels during the roll (a separate wheel layer) and add a soft roll sound.
- Make the ground band follow the time of day (warmer at 5:30 pm, cooler at 7 am).
