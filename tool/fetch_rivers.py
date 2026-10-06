"""Fetch Thailand's main rivers from OpenStreetMap into assets/rivers.geojson.

Run once from the repo root: python3 tool/fetch_rivers.py
Data © OpenStreetMap contributors (ODbL); the app already shows OSM credit.
"""

import json
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

RIVERS = [
    "เจ้าพระยา", "ปิง", "วัง", "ยม", "น่าน", "ป่าสัก", "ท่าจีน", "แม่กลอง",
    "บางปะกง", "ปราจีนบุรี", "มูล", "ชี", "โขง", "ตาปี", "สะแกกรัง",
]
# Douglas-Peucker tolerance in degrees (~300 m) and output precision.
TOLERANCE = 0.003
DECIMALS = 4
# south, west, north, east — a bbox is far cheaper for Overpass than an area.
THAILAND_BBOX = "5.6,97.3,20.5,105.7"
SERVERS = [
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
]
OUT = Path(__file__).resolve().parent.parent / "assets" / "rivers.geojson"

QUERY = """
[out:json][timeout:180];
way["waterway"="river"][~"^name(:th)?$"~"^แม่น้ำ({names})$"]({bbox});
out geom;
""".format(names="|".join(RIVERS), bbox=THAILAND_BBOX)


def fetch():
    for url in SERVERS:
        req = urllib.request.Request(
            url,
            data=urllib.parse.urlencode({"data": QUERY}).encode(),
            headers={"User-Agent": "worning_foold-tool/0.1"},
        )
        try:
            with urllib.request.urlopen(req, timeout=240) as res:
                return json.load(res)["elements"]
        except urllib.error.HTTPError as e:
            print(f"{url}: HTTP {e.code}, trying next server", file=sys.stderr)
    sys.exit("all Overpass servers failed")


def simplify(points, tol):
    if len(points) < 3:
        return points
    (x1, y1), (x2, y2) = points[0], points[-1]
    dx, dy = x2 - x1, y2 - y1
    norm = (dx * dx + dy * dy) ** 0.5 or 1e-12
    idx, dmax = 0, 0.0
    for i in range(1, len(points) - 1):
        x, y = points[i]
        d = abs(dy * x - dx * y + x2 * y1 - y2 * x1) / norm
        if d > dmax:
            idx, dmax = i, d
    if dmax <= tol:
        return [points[0], points[-1]]
    return simplify(points[: idx + 1], tol)[:-1] + simplify(points[idx:], tol)


def main():
    ways = fetch()
    lines = {}
    for way in ways:
        tags = way["tags"]
        # Some ways carry the Thai name only in `name`, not `name:th`.
        thai = next(
            t for t in (tags.get("name:th"), tags.get("name"))
            if t and t.removeprefix("แม่น้ำ") in RIVERS
        )
        name = thai.removeprefix("แม่น้ำ")
        coords = [(p["lon"], p["lat"]) for p in way.get("geometry", [])]
        coords = simplify(coords, TOLERANCE)
        if len(coords) >= 2:
            lines.setdefault(name, []).append(
                [[round(x, DECIMALS), round(y, DECIMALS)] for x, y in coords]
            )
    missing = sorted(set(RIVERS) - set(lines))
    if missing:
        print("warning: no ways for", ", ".join(missing), file=sys.stderr)
    features = [
        {
            "type": "Feature",
            "properties": {"name": f"แม่น้ำ{name}"},
            "geometry": {"type": "MultiLineString", "coordinates": parts},
        }
        for name, parts in sorted(lines.items())
    ]
    OUT.write_text(
        json.dumps(
            {"type": "FeatureCollection", "features": features},
            ensure_ascii=False,
            separators=(",", ":"),
        ),
        encoding="utf-8",
    )
    print(f"{len(features)} rivers, {len(ways)} ways -> {OUT} "
          f"({OUT.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
