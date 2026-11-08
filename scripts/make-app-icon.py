#!/usr/bin/env python3
"""Build the Bin Day NZ app icon from its vector master.

The mark is a fortnight: two rows of seven matte spheres. The fourth sphere in the top row
floats raised in recycling yellow, the fifth in the bottom row sits in food-scraps green.
It was chosen on 2026-11-08 from the generated options in docs/brand/icon-options-2026-11-08
(option 17) and rebuilt here as geometry so every appearance is rendered from one source.

Outputs
  docs/brand/icon/bin-day-icon-{light,dark,tinted}.svg      editable masters
  BinDayNZ/Assets.xcassets/AppIcon.appiconset/icon-*.png    1024 px, single-size iOS icon
  docs/brand/icon/preview-sheet.png                         size ladder for review

Appearances follow Apple's asset-catalog guidance: the light icon is opaque, the dark icon
has a transparent background so the system background shows through, and the tinted icon
is a grayscale image on a transparent background.

Requires Python 3 with Pillow, and Google Chrome for headless SVG rendering
(set CHROME to another Chromium binary if needed).
"""
import os
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ICON_DIR = ROOT / "docs" / "brand" / "icon"
ICONSET = ROOT / "BinDayNZ" / "Assets.xcassets" / "AppIcon.appiconset"
CHROME = os.environ.get("CHROME", "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")

S = 1024
D = 110                      # sphere diameter
PITCH = 122                  # column pitch, a 12 px gap
ROW_TOP, ROW_BOT = 460, 612  # row centres
RAISE = 40                   # lift of the yellow sphere
COLS = [512 + (i - 3) * PITCH for i in range(7)]
YELLOW_COL, GREEN_COL = 3, 4
R = D / 2

PALETTES = {
    "light": dict(
        bg=("#DAD5CD", "#D0CBC2"),
        white=[(0, "#FBFAF8"), (0.35, "#F1F0ED"), (0.75, "#D9D7D0"), (1, "#B6B3AB")],
        yellow=[(0, "#FFD75A"), (0.35, "#F9C620"), (0.75, "#E4AB10"), (1, "#C48D08")],
        green=[(0, "#6CBE70"), (0.35, "#4A9E4F"), (0.75, "#357B39"), (1, "#28602C")],
        shadow="#4A4036", contact=0.52, float_=0.34, shade=0.24),
    "dark": dict(
        bg=None,
        white=[(0, "#F6F5F2"), (0.35, "#E4E3DF"), (0.75, "#B4B2AC"), (1, "#75736E")],
        yellow=[(0, "#FFD75A"), (0.35, "#F9C620"), (0.75, "#DDA60F"), (1, "#B07E06")],
        green=[(0, "#6CBE70"), (0.35, "#4A9E4F"), (0.75, "#32763A"), (1, "#22522A")],
        shadow="#000000", contact=0.60, float_=0.45, shade=0.28),
    "tinted": dict(
        bg=None,
        white=[(0, "#ECECEC"), (0.35, "#D6D6D6"), (0.75, "#A6A6A6"), (1, "#6E6E6E")],
        yellow=[(0, "#FFFFFF"), (0.35, "#F6F6F6"), (0.75, "#CFCFCF"), (1, "#9A9A9A")],
        green=[(0, "#FFFFFF"), (0.35, "#F6F6F6"), (0.75, "#CFCFCF"), (1, "#9A9A9A")],
        shadow="#000000", contact=0.55, float_=0.40, shade=0.28),
}
DARK_PREVIEW_BG = ("#1B1E22", "#121417")   # stands in for the system background in previews


def gradient(id_, stops):
    inner = "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in stops)
    return f'<radialGradient id="{id_}" cx="0.5" cy="0.5" r="0.5" fx="0.36" fy="0.30">{inner}</radialGradient>'


def svg(p, bg=None):
    bg = bg or p["bg"]
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" viewBox="0 0 {S} {S}">',
        "<defs>",
        gradient("gw", p["white"]), gradient("gy", p["yellow"]), gradient("gg", p["green"]),
        '<linearGradient id="shade" x1="0" y1="0" x2="0" y2="1">'
        f'<stop offset="0.42" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="{p["shade"]}"/></linearGradient>',
        '<filter id="soft" x="-80%" y="-200%" width="260%" height="500%"><feGaussianBlur stdDeviation="7"/></filter>',
        '<filter id="softer" x="-80%" y="-200%" width="260%" height="500%"><feGaussianBlur stdDeviation="10"/></filter>',
    ]
    if bg:
        parts.append(f'<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{bg[0]}"/><stop offset="1" stop-color="{bg[1]}"/></linearGradient>')
    parts.append("</defs>")
    if bg:
        parts.append(f'<rect width="{S}" height="{S}" fill="url(#bg)"/>')
    spheres = []
    for row, cy in ((0, ROW_TOP), (1, ROW_BOT)):
        for i, cx in enumerate(COLS):
            fill, y = "url(#gw)", cy
            if row == 0 and i == YELLOW_COL:
                fill, y = "url(#gy)", cy - RAISE
                parts.append(f'<ellipse cx="{cx}" cy="{cy + R - 12:.0f}" rx="42" ry="11" fill="{p["shadow"]}" opacity="{p["float_"]}" filter="url(#softer)"/>')
            else:
                if row == 1 and i == GREEN_COL:
                    fill = "url(#gg)"
                parts.append(f'<ellipse cx="{cx}" cy="{y + R - 3:.0f}" rx="46" ry="9" fill="{p["shadow"]}" opacity="{p["contact"]}" filter="url(#soft)"/>')
            spheres.append(f'<circle cx="{cx}" cy="{y}" r="{R:g}" fill="{fill}"/><circle cx="{cx}" cy="{y}" r="{R:g}" fill="url(#shade)"/>')
    parts.extend(spheres)
    parts.append("</svg>")
    return "\n".join(parts) + "\n"


def render(svg_path: Path, png_path: Path):
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                    "--default-background-color=00000000", f"--window-size={S},{S}", f"--screenshot={png_path}",
                    svg_path.resolve().as_uri()], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)


def rounded(img, px):
    im = img.convert("RGBA").resize((px, px), Image.LANCZOS)
    mask = Image.new("L", (px * 4, px * 4), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, px * 4 - 1, px * 4 - 1), radius=int(px * 4 * 0.2237), fill=255)
    mask = mask.resize((px, px), Image.LANCZOS)
    im.putalpha(Image.composite(im.getchannel("A"), Image.new("L", (px, px), 0), mask))
    return im


def over(fg, bg):
    out = Image.new("RGBA", fg.size); out.paste(bg.convert("RGBA").resize(fg.size)); out.alpha_composite(fg.convert("RGBA")); return out


def tint_preview(gray, tint=(96, 150, 255)):
    g = gray.convert("RGBA"); out = Image.new("RGBA", g.size); px = g.load(); op = out.load()
    for y in range(g.size[1]):
        for x in range(g.size[0]):
            r, gg, b, a = px[x, y]; lum = (r * 299 + gg * 587 + b * 114) / 255000; k = a / 255
            op[x, y] = tuple(int(26 * (1 - k) + tint[c] * lum * k) for c in range(3)) + (255,)
    return out


def main():
    ICON_DIR.mkdir(parents=True, exist_ok=True); ICONSET.mkdir(parents=True, exist_ok=True)
    pngs = {}
    for name, p in PALETTES.items():
        svg_path = ICON_DIR / f"bin-day-icon-{name}.svg"
        svg_path.write_text(svg(p))
        png_path = ICONSET / f"icon-{name}-1024.png"
        render(svg_path, png_path)
        im = Image.open(png_path)
        if name == "light":
            im.convert("RGB").save(png_path)      # the App Store icon must not carry alpha
        pngs[name] = Image.open(png_path)
        print(f"wrote {svg_path.relative_to(ROOT)} and {png_path.relative_to(ROOT)} ({pngs[name].mode})")
    # Preview sheet: the icon at Home Screen, Spotlight and Settings sizes in each appearance.
    dark_bg = Image.open(ICON_DIR / "_dark-bg.png") if (ICON_DIR / "_dark-bg.png").exists() else None
    if dark_bg is None:
        tmp = ICON_DIR / "_dark-bg.svg"; tmp.write_text(svg(PALETTES["dark"], DARK_PREVIEW_BG).replace("url(#gw)", "none").replace("url(#gy)", "none").replace("url(#gg)", "none").replace("url(#shade)", "none"))
        render(tmp, ICON_DIR / "_dark-bg.png"); tmp.unlink(); dark_bg = Image.open(ICON_DIR / "_dark-bg.png")
    rows = [("light", pngs["light"], (185, 182, 176)),
            ("dark, over a stand-in system background", over(pngs["dark"], dark_bg), (52, 54, 58)),
            ("tinted, simulated", tint_preview(pngs["tinted"].resize((256, 256), Image.LANCZOS)), (52, 54, 58))]
    sizes = [256, 180, 120, 87, 58, 40]
    W = 40 + sum(s + 28 for s in sizes); H = 256 + 56
    sheet = Image.new("RGB", (W, H * len(rows)), (240, 239, 236)); d = ImageDraw.Draw(sheet)
    for ri, (label, img, wall) in enumerate(rows):
        y0 = ri * H; d.rectangle((0, y0, W, y0 + H), fill=wall)
        d.text((16, y0 + 8), label, fill=(255, 255, 255) if wall[0] < 100 else (40, 40, 40)); x = 20
        for s in sizes:
            ic = rounded(img, s); sheet.paste(ic, (x, y0 + 32 + (256 - s) // 2), ic); x += s + 28
    sheet.save(ICON_DIR / "preview-sheet.png"); (ICON_DIR / "_dark-bg.png").unlink(missing_ok=True)
    print("wrote", (ICON_DIR / "preview-sheet.png").relative_to(ROOT))


if __name__ == "__main__":
    main()
