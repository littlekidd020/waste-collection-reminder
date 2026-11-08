# Direction C, "Tag"

**Idea:** the council's hang tag, reimagined as one Liquid Glass tag hanging on a cord from the Dynamic Island, carrying tomorrow's date and the bins; it swings when you nudge the phone.

## Elements
- **Today**
  - **Wash**: three large blurred radial gradients in the due bins' lid colours (ochre upper left, terracotta upper right, sage lower), so the glass has light to bend. The lower third stays plain linen.
  - **Cord and eyelet**: a 1.5 pt `Palette.line` cord runs from behind the Dynamic Island to the top of a 10 pt stroked eyelet ring, about 96 pt below the safe area. The tag pivots on the eyelet centre, so the cord never leaves the ring.
  - **Tag**: 296 x 372 pt, radius 40, `.glassEffect(.regular)` with a 1 pt white highlight at 35 percent. It hangs at -3 degrees and casts a long soft shadow down and to the right (light from the upper left).
    - Small caps corners: "TOMORROW · TUE" and "MOUNT EDEN".
    - A 176 pt New York "10" with "November" beneath it.
    - Three `LidSphere`s with centred captions.
  - **Below the tag**:
    - The verdict sentence (20 pt) and "Put them out by 7 am" (17 pt muted).
    - A `.glassProminent` moss "Remind me at 7 pm" button.
    - A small caps line, "NEXT TUESDAY · NO RECYCLING", for the fortnight rhythm.
  - **Settings**: a circular glass gear, top right.
- **Schedule**
  - **Rail**: a 1.5 pt rule starts at the first tag and runs off the right edge. Eight 72 x 104 paper tags hang from it on short cords, each with an eyelet, "TUE", a 30 pt serif day and 9 pt sphere beads. The beads show the fortnight: three beads, then two.
  - **Selected tag**: tomorrow's tag is glass, 84 x 122, hanging lower with the bins' colours blurred behind it. Tap any tag to select it.
  - **Written out below**: the eyebrow date, the bins at 24 pt with 18 pt spheres and frequency labels, hairlines between them, the week after in 15 pt, and the holiday notice with a snowflake.
  - A glass calendar button sits top right.
- **Guide**
  - An eyebrow and one section per bin: a 32 pt serif name with its frequency, a 2-column grid of square `Palette.surface` tiles (an SF Symbol per item, the item name, and an 8 pt sphere in the corner), then "Not in this bin: ..." in 15 pt.
  - A glass safari button sits top right.
- **Extra**: Today with the tag frozen at +9 degrees mid-swing. Its shadow is pushed further out and softened, as if the phone had just been nudged.

## Motion
- **Entrance**: the tag drops 560 pt from above on its cord (spring 0.7 / 0.78) while it swings from 16 degrees to rest (spring response 0.9, damping 0.6), giving two or three visible oscillations. The spheres then settle in with a 40 ms stagger, and the copy fades up 12 pt.
- **Idle**: a 0.6 degree sway over 8 seconds (4 s ease-in-out, autoreversing). The wash drifts about 15 pt over 14 seconds.
- **Gestures**:
  - Drag the tag sideways to swing it; on release an interpolating spring (bounce 0.4) takes the release velocity and rings it back to rest.
  - A CoreMotion user-acceleration spike (|x| > 0.22 g) kicks the tag by up to 14 degrees through the same spring. This does nothing on the simulator.
- **Shadow**: the shadow offset, blur and opacity follow the angle.
- **Schedule**:
  - Tags drop in with a 40 ms stagger.
  - Selecting a tag springs between paper and glass; the date eyebrow uses `.numericText()`.
- **Reduce motion**: the tag fades in at rest; there is no idle sway, no drift and no stagger.

## Compromises
- **Glass under rotation**: Liquid Glass renders inflated (about 30 pt larger on each side) when its view goes through `rotationEffect`. So the glass stays axis-aligned and is given a `RotatedShape`, and only the printed face, highlight and eyelet rotate as views. This works, but if the glass refracts at its true edge, the refraction runs along the axis-aligned bounds.
- **Shadow knockout**: the shadow is a separate blurred shape with the tag knocked out of it (destinationOut), so it never darkens the glass. As a result it only shows outside the tag and reads lightly.
- **Wash strength**: per review, the wash uses lid colours at 55 percent in blurred gradients rather than the pale tints at 35 percent, which were invisible behind the glass.
- **Tag captions**: they are 11 pt centred columns rather than labels left-aligned with the numeral, so the three names don't collide. That breaks the 12 pt label rule and the left edge.
- **Guide**: it has no 120+ pt hero; the 32 pt serif bin names carry it, as the spec asked.

## With another day
- Run the pendulum as a real physics simulation (angle, angular velocity, gravity, damping in a `TimelineView`), with gravity tilt from CoreMotion attitude so the tag hangs truly vertical as you tilt the phone. Add a CoreHaptics tick when it settles.
- Make the cord a slightly curved Bezier during the drop, and move the eyelet's highlight with the swing.
- Give the Guide tiles a little more drama: a rendered prop per item instead of SF Symbols.
