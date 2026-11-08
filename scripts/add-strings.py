#!/usr/bin/env python3
"""Insert new keys into Localizable.xcstrings without disturbing its order.

Usage: add-strings.py <translations.json>
  translations.json: {"English key": {"zh-Hans": "...", "mi": "...", "ko": "...", "hi": "...", "comment": "optional"}}

The catalog keeps Xcode's case-insensitive key order and its language order (en, zh-Hans, mi, ko, hi);
sorting it any other way rewrites every entry. Keys already present only gain missing languages.
"""
import json, sys
from pathlib import Path

CATALOG = Path(__file__).resolve().parent.parent / "BinDayNZ/Resources/Localizable.xcstrings"
LANGS = ["en", "zh-Hans", "mi", "ko", "hi"]


def unit(value):
    return {"stringUnit": {"state": "translated", "value": value}}


def main(path):
    new = json.loads(Path(path).read_text())
    catalog = json.loads(CATALOG.read_text())
    strings = catalog["strings"]
    added, updated = 0, 0
    for key, langs in new.items():
        entry = strings.get(key)
        values = {"en": langs.get("en", key), **{l: langs[l] for l in LANGS if l in langs}}
        if entry is None:
            entry = {}
            if langs.get("comment"):
                entry["comment"] = langs["comment"]
            entry["localizations"] = {l: unit(values[l]) for l in LANGS if l in values}
            # insert in case-insensitive order
            items = list(strings.items())
            index = next((i for i, (k, _) in enumerate(items) if k.casefold() > key.casefold()), len(items))
            items.insert(index, (key, entry))
            strings.clear(); strings.update(items)
            added += 1
        else:
            localizations = entry.setdefault("localizations", {})
            before = len(localizations)
            for l in LANGS:
                if l in values and l not in localizations:
                    localizations[l] = unit(values[l])
            ordered = {l: localizations[l] for l in LANGS if l in localizations}
            ordered.update({l: v for l, v in localizations.items() if l not in ordered})
            entry["localizations"] = ordered
            if len(ordered) != before:
                updated += 1
    text = json.dumps(catalog, indent=2, ensure_ascii=False)
    CATALOG.write_text(text + ("\n" if CATALOG.read_text().endswith("\n") else ""))
    print(f"added {added} keys, completed {updated} existing keys; catalog now {len(strings)} keys")


if __name__ == "__main__":
    main(sys.argv[1])
