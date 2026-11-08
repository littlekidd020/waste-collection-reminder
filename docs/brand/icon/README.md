# Bin Day NZ app icon

Chosen on 8 November 2026 from the twenty-four generated options in
`../icon-options-2026-11-08` (option 17, "Week dots"), then rebuilt as geometry so the
three iOS appearances come from one source.

**The mark.** A fortnight: two rows of seven matte spheres. The fourth sphere in the top
row floats raised in recycling yellow, the fifth in the bottom row sits in food-scraps green.
Nothing literal, no bins, no text. It reads as "fourteen days, two of them matter".

## Files

| File | What it is |
| --- | --- |
| `bin-day-icon-light.svg` | Light master, opaque warm-grey ground (`#DAD5CD` to `#D0CBC2`) |
| `bin-day-icon-dark.svg` | Dark master, transparent ground: iOS supplies the dark background |
| `bin-day-icon-tinted.svg` | Grayscale master, transparent ground: iOS applies the tint |
| `preview-sheet.png` | The three appearances at 256, 180, 120, 87, 58 and 40 px |
| `../../../scripts/make-app-icon.py` | Regenerates the SVGs, the PNGs in the asset catalog and this sheet |

The asset catalog (`BinDayNZ/Assets.xcassets/AppIcon.appiconset`) uses the single-size
iOS format: one 1024 px PNG per appearance (`icon-light-1024.png`, `icon-dark-1024.png`,
`icon-tinted-1024.png`). The light PNG carries no alpha channel, as the App Store requires.

## Regenerating

```bash
python3 scripts/make-app-icon.py
```

Needs Python 3 with Pillow and Google Chrome (headless SVG rendering). Edit the geometry
or palettes in the script, not the PNGs.

## Geometry

Sphere diameter 110 px on a 122 px pitch (a 12 px gap), rows centred at y 460 and 612,
the yellow sphere lifted 40 px. The grid spans 842 px, 82 percent of the square, so the
spheres stay clear of the corner mask and still read at the 58 px Settings size.

## Open items

- A professional trademark search before the icon ships. Two web searches on 8 November
  2026 found no existing mark built on a two-by-seven sphere grid, but that is not a
  clearance.
- Icon Composer (`.icon`) layers for Liquid Glass on iOS 26 are optional; the bitmap set
  is segmented by the system. Worth doing once the redesign direction is settled.
- Alternate icons with the live lid colour (red, blue) need their own dark and tinted
  variants if added.
