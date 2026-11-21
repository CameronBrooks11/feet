"""Render each foot and check its shape.

usage: python3 tests/test_feet.py [OPENSCAD]

- Each model renders with --hardwarnings. OpenSCAD exits 0 on a failed
  assert when exporting, so a WARNING or ERROR line fails the check,
  whatever the exit status.
- Each is one solid: toes, pads, claws and malleoli fused to the body.
- Each stands on z = 0 and is cut off flat at the top of its leg: the
  human ankle at ankle_height, 115 mm; the dog's leg and the chicken's
  shank where their default lengths and angles end.
"""

import math
import os
import struct
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Top of each model from its default parameters.
MODELS = {
    "human_foot.scad": 115,
    "dog_foot.scad": 3 + 30 * 0.7 + 44 * math.sin(math.radians(74)) + 55 * math.sin(math.radians(84)),
    "chicken_foot.scad": 15 + 96 * math.sin(math.radians(82)),
}

results = []


def check(label, ok, got):
    results.append(bool(ok))
    print(f"{'ok  ' if ok else 'FAIL'} {label}: {got}")


def solids(path):
    """Each separate solid in a binary STL as (zmin, zmax), by joining shared corners."""
    data = open(path, "rb").read()
    (n,) = struct.unpack_from("<I", data, 80)
    tris = [struct.unpack_from("<9f", data, 84 + i * 50 + 12) for i in range(n)]
    parent = {}

    def find(v):
        while parent[v] != v:
            parent[v] = parent[parent[v]]
            v = parent[v]
        return v

    for t in tris:
        pts = (t[0:3], t[3:6], t[6:9])
        for p in pts:
            parent.setdefault(p, p)
        root = find(pts[0])
        for p in pts[1:]:
            parent[find(p)] = root
    parts = {}
    for t in tris:
        for p in (t[0:3], t[3:6], t[6:9]):
            lo, hi = parts.get(find(p), (1e9, -1e9))
            parts[find(p)] = (min(lo, p[2]), max(hi, p[2]))
    return list(parts.values())


def main():
    openscad = sys.argv[1] if len(sys.argv) > 1 else "openscad"
    with tempfile.TemporaryDirectory() as tmp:
        stl = os.path.join(tmp, "out.stl")
        for name, top in MODELS.items():
            r = subprocess.run([openscad, "--hardwarnings", "--export-format", "binstl", "-o", stl,
                                os.path.join(ROOT, name)], capture_output=True, text=True)
            bad = [l for l in r.stderr.splitlines() if l.startswith(("WARNING", "ERROR"))]
            if r.returncode or bad:
                check(f"{name} renders", False, (bad or [f"exit {r.returncode}"])[0])
                continue
            parts = solids(stl)
            z = parts[0] if len(parts) == 1 else None
            ok = z and abs(z[0]) < 1e-3 and abs(z[1] - top) < 1e-2
            check(f"{name} is one solid from z = 0 to {top:.2f}", ok,
                  f"z {z[0]:.2f} to {z[1]:.2f}" if z else f"{len(parts)} solids")

    print(f"{sum(results)} of {len(results)} checks passed")
    sys.exit(0 if all(results) else 1)


main()
