#!/usr/bin/env python3
"""Key Codex-rendered bin props to transparency and normalise them onto one baseline.

Each render stands on a flat linen background. This script removes the background, splits a
render into its objects, and writes one PNG per object in which a full-size wheelie bin spans
20 % to 80 % of the canvas height with its wheels on the 80 % line. Smaller objects (the food
scraps bin, the glass crate, the inorganic group) are placed at their real size relative to a full
bin, so `BinProp` can bottom-align any set of props and they stand on the same ground.

Usage: key-props.py <out-dir> <spec>...
  spec: <source.png>:<name>[=<relative height>][,<name>[=<relative height>]]...
        names left to right; relative height defaults to 1.0 (a full-size bin); 0 keys and crops only;
        a trailing ~ (e.g. =0.75~) skips the floor clean-up for soft objects such as furniture
Pillow only. Run with -I.
"""
import json, os, sys
from PIL import Image

TOP, FEET = 0.20, 0.80          # a full bin's handle top and wheel line, as fractions of canvas height
D0, D1 = 8.0, 42.0              # colour distance to the background that maps to alpha 0 and 1
NOISE = 12                      # alpha at or below this is cleared
SHADOW = (58, 50, 42)           # warm shadow colour for keyed contact shadows


def smoothstep(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


def key(im):
    im = im.convert("RGB")
    w, h = im.size
    px = im.load()
    border = [px[x, y] for x in range(w) for y in (0, h - 1)] + [px[x, y] for y in range(h) for x in (0, w - 1)]
    bg = tuple(sorted(c[i] for c in border)[len(border) // 2] for i in range(3))
    out = Image.new("RGBA", (w, h))
    op = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            d = ((r - bg[0]) ** 2 + (g - bg[1]) ** 2 + (b - bg[2]) ** 2) ** 0.5
            a = smoothstep((d - D0) / (D1 - D0))
            if a * 255 <= NOISE:
                op[x, y] = (0, 0, 0, 0)
                continue
            # un-premultiply the background out of the edge colour
            rr = max(0, min(255, round((r - bg[0] * (1 - a)) / a)))
            gg = max(0, min(255, round((g - bg[1] * (1 - a)) / a)))
            bb = max(0, min(255, round((b - bg[2] * (1 - a)) / a)))
            mx = max(rr, gg, bb)
            sat = 0 if mx == 0 else (mx - min(rr, gg, bb)) / mx
            ratios = [c / max(1, bgc) for c, bgc in zip((r, g, b), bg)]
            same_hue_as_ground = max(ratios) - min(ratios) < 0.05 and mx > 95
            # Soft edges and contact shadows: anything translucent that is not clearly a lid colour,
            # anything light and grey, and anything that is just the linen darkened (colour bleed
            # under a lid tints the shadow slightly, so saturation alone is not enough).
            if same_hue_as_ground and max(r, g, b) >= 0.985 * max(bg):
                # floor caught by bounce light: linen as bright as the background, so nothing to keep
                op[x, y] = (0, 0, 0, 0)
                continue
            if (a < 0.97 and sat < 0.35) or (sat < 0.15 and mx > 165) or same_hue_as_ground:
                # a soft contact shadow is the linen darkened, not grey paint: keep it as a dark
                # translucent layer so it also reads as shadow on a dark ground
                darkening = 1 - (max(r, g, b) / max(bg))
                op[x, y] = (SHADOW[0], SHADOW[1], SHADOW[2], max(0, min(255, round(darkening * 255 * 1.15))))
                continue
            op[x, y] = (rr, gg, bb, round(a * 255))
    return out, bg


def is_object_pixel(p):
    """Body, lid or wheel rather than contact shadow: dark, or clearly coloured."""
    r, g, b, a = p
    if a < 230:
        return False
    mx, mn = max(r, g, b), min(r, g, b)
    sat = 0 if mx == 0 else (mx - mn) / mx
    return mx < 110 or sat > 0.30


def split_columns(im, count):
    """Split at the widest fully transparent column gaps into `count` ranges."""
    w, h = im.size
    px = im.load()
    occupied = [any(px[x, y][3] > 5 for y in range(h)) for x in range(w)]
    runs, start = [], None
    for x, occ in enumerate(occupied + [False]):
        if occ and start is None:
            start = x
        elif not occ and start is not None:
            runs.append((start, x - 1)); start = None
    runs.sort(key=lambda r: r[1] - r[0], reverse=True)
    runs = sorted(runs[:count])
    assert len(runs) == count, f"found {len(runs)} objects, expected {count}: {runs}"
    return runs


def measure(im, x0, x1):
    w, h = im.size
    px = im.load()
    top = feet = low = None
    for y in range(h):
        row = [px[x, y] for x in range(x0, x1 + 1)]
        if top is None and any(p[3] > 128 for p in row):
            top = y
        if any(is_object_pixel(p) for p in row):
            feet = y
        if any(p[3] > 5 for p in row):
            low = y
    return top, feet, low


def fix_floor(im, raw, x0, x1, top, feet):
    """Around and below the wheels there is only floor: anything linen-hued in the bottom tenth of
    the object becomes shadow, however dark, so no lit floor fragment survives on a dark ground.
    Bodies and wheels are far darker and keep their colour."""
    rp = raw.convert("RGB").load()
    px = im.load()
    w, h = im.size
    bg = tuple(sorted(rp[x, y][i] for x in range(w) for y in (0, h - 1))[w] for i in range(3))
    for y in range(max(0, feet - round(0.1 * (feet - top))), h):
        for x in range(x0, min(w, x1 + 1)):
            if px[x, y][3] == 0:
                continue
            r, g, b = rp[x, y]
            mx = max(r, g, b)
            if mx <= 95:
                continue
            ratios = [c / max(1, bgc) for c, bgc in zip((r, g, b), bg)]
            if max(ratios) - min(ratios) < 0.12:
                darkening = 1 - (mx / max(bg))
                if darkening <= 0.015:
                    px[x, y] = (0, 0, 0, 0)
                else:
                    px[x, y] = (SHADOW[0], SHADOW[1], SHADOW[2], max(0, min(255, round(darkening * 255 * 1.15))))


def normalise(im, x0, x1, top, feet, relative):
    """Canvas where a full bin spans TOP..FEET of the height and this object stands on FEET."""
    full = (feet - top) / relative
    H = round(full / (FEET - TOP))
    canvas_top = round(feet - FEET * H)
    margin = round(0.03 * H)
    box = (x0 - margin, canvas_top, x1 + 1 + margin, canvas_top + H)
    out = Image.new("RGBA", (box[2] - box[0], H))
    src = im.crop((max(0, box[0]), max(0, box[1]), min(im.size[0], box[2]), min(im.size[1], box[3])))
    out.paste(src, (max(0, -box[0]), max(0, -box[1])))
    return out


def main():
    out_dir, specs = sys.argv[1], sys.argv[2:]
    os.makedirs(out_dir, exist_ok=True)
    report = {}
    for spec in specs:
        source, names = spec.split(":", 1)
        parts = []
        for item in names.split(","):
            name, _, rel = item.partition("=")
            floor = not rel.endswith("~")          # a trailing ~ keeps the floor zone as keyed (soft objects)
            parts.append((name, float(rel.rstrip("~")) if rel.rstrip("~") else 1.0, floor))
        raw = Image.open(source)
        im, bg = key(raw)
        for (name, relative, floor), (x0, x1) in zip(parts, split_columns(im, len(parts))):
            top, feet, low = measure(im, x0, x1)
            if floor:
                fix_floor(im, raw, x0, x1, top, feet)
            if relative == 0:
                margin = round(0.02 * im.size[1])
                prop = im.crop((max(0, x0 - margin), max(0, top - margin), min(im.size[0], x1 + 1 + margin), min(im.size[1], low + margin)))
                print(name, "raw crop: object top", margin, "feet", feet - max(0, top - margin), "of", prop.size)
            else:
                prop = normalise(im, x0, x1, top, feet, relative)
            path = os.path.join(out_dir, f"{name}.png")
            prop.save(path)
            report[name] = dict(source=os.path.basename(source), background=bg, object_top=top, feet=feet,
                                shadow_bottom=low, relative_height=relative, canvas=prop.size)
            print(name, report[name])
    with open(os.path.join(out_dir, "props.json"), "w") as f:
        json.dump(report, f, indent=2)


if __name__ == "__main__":
    main()
