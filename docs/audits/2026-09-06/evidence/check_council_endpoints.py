"""Read-only public council lookups; no private profile data or account access."""
import concurrent.futures
import datetime
import hashlib
import json
import pathlib
import re
import urllib.error
import urllib.parse
import urllib.request

AUDIT_DIR = pathlib.Path(__file__).resolve().parent
REPO_DIR = AUDIT_DIR.parents[3]
SOURCE = REPO_DIR / "BinDayNZ/Services/AddressSearchService.swift"
PATTERN = re.search(r'let pattern = #"(.*?)"#', SOURCE.read_text()).group(1)
QUERIES = [
    "12 Queen Street, Auckland",
    "4 Figaro Street, Ponsonby",
    "999999 Audit Example Road, Auckland",
    "1/12 Queen Street, Auckland",
]


def fetch(url, *, page=False):
    headers = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" if page else "Mozilla/5.0"}
    if not page:
        headers["Accept"] = "application/json"
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=25) as response:
            data = response.read()
            return {
                "url": url,
                "final_url": response.url,
                "status": response.status,
                "content_type": response.headers.get("Content-Type"),
                "bytes": len(data),
                "sha256": hashlib.sha256(data).hexdigest(),
                "body": data.decode("utf-8", errors="replace"),
            }
    except urllib.error.HTTPError as error:
        return {"url": url, "status": error.code, "error": str(error), "body_excerpt": error.read().decode("utf-8", errors="replace")[:300]}
    except Exception as error:
        return {"url": url, "error": f"{type(error).__name__}: {error}"}


def lookup(query):
    result = {"query": query}
    url = "https://experience.aucklandcouncil.govt.nz/nextapi/property?" + urllib.parse.urlencode({"query": query, "pageSize": 5})
    api = fetch(url)
    result["property_api"] = api
    body = api.pop("body", None)
    if body is None:
        return result
    try:
        decoded = json.loads(body)
    except ValueError as error:
        api["parse_error"] = str(error)
        api["body_excerpt"] = body[:300]
        return result
    items = decoded.get("items") or []
    api["items"] = [{"id": item.get("id"), "address": item.get("address")} for item in items]
    if not items:
        api["production_outcome"] = "nil: response.items.first absent"
        return result
    first = items[0]
    api["production_selected_property"] = {"id": first.get("id"), "address": first.get("address")}
    api["query_equals_first_address_case_insensitive"] = query.casefold().strip() == str(first.get("address", "")).casefold().strip()
    assessment_id = urllib.parse.quote(str(first["id"]), safe="")
    page = fetch("https://www.aucklandcouncil.govt.nz/en/rubbish-recycling/rubbish-recycling-collections/rubbish-recycling-collection-days/" + assessment_id + ".html", page=True)
    result["schedule_page"] = page
    html = page.pop("body", None)
    if html is not None:
        page["production_regex"] = PATTERN
        page["production_regex_matches"] = [list(match) for match in re.findall(PATTERN, html, flags=re.IGNORECASE)]
        page["schedule_label_contexts"] = [html[max(0, match.start() - 100):match.end() + 500] for match in list(re.finditer(r"(?:Rubbish|Recycling)\s*:", html, flags=re.IGNORECASE))[:6]]
        title = re.search(r"<title[^>]*>(.*?)</title>", html, flags=re.IGNORECASE | re.DOTALL)
        page["title"] = title.group(1).strip() if title else None
        page["production_outcome"] = "regex yielded candidate date fields; actual returned zone requires weekday/parity processing" if page["production_regex_matches"] else "nil: no recycling date parsed"
    return result


if __name__ == "__main__":
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
        results = list(executor.map(lookup, QUERIES))
    output = {
        "checked_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "samples": "Two app sample strings, one deliberately nonexistent address, one unit variant; no user profile read.",
        "regex_note": "Python regex uses the exact pattern from current Swift source; no Apple MapKit resolution or Swift async HTTP stack executed.",
        "results": results,
    }
    path = AUDIT_DIR / "council-endpoints.json"
    path.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(output, ensure_ascii=False, indent=2))
