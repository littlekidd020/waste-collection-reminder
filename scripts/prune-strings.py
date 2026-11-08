#!/usr/bin/env python3
"""Remove catalog keys no Swift file uses any more (L()/WL() literals), keeping the catalog's order.
Usage: prune-strings.py [--apply]   (without --apply it only lists the keys)"""
import json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "BinDayNZ/Resources/Localizable.xcstrings"
KEEP = {"%@"}  # interpolation helpers marked nontranslatable


def main():
    catalog = json.loads(CATALOG.read_text())
    strings = catalog["strings"]
    source = "\n".join(p.read_text() for root in ("BinDayNZ", "BinDayNZWidget") for p in (ROOT / root).rglob("*.swift"))
    used = set(re.findall(r'\b(?:L|WL)\("((?:[^"\\]|\\.)*)"', source))
    unused = [k for k in strings if k not in used and k not in KEEP and strings[k].get("shouldTranslate", True)]
    for k in unused:
        print(k)
    print(f"{len(unused)} unused keys", file=sys.stderr)
    if "--apply" in sys.argv:
        for k in unused:
            del strings[k]
        CATALOG.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + "\n")
        print(f"removed {len(unused)}; {len(strings)} keys remain", file=sys.stderr)


if __name__ == "__main__":
    main()
