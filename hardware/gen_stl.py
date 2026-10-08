#!/usr/bin/env python3
"""Write a no-support 25 mm NTAG213 case STL (optional 10x2 mm magnet well)."""

from __future__ import annotations

import math
from pathlib import Path

# mm
OUTER_R = 14.9
HEIGHT = 5.3
TAG_R = 12.7
TAG_H = 1.2
MAG_R = 5.1
MAG_H = 2.1
SEGS = 48


def ring(z0: float, z1: float, r: float, inward: bool) -> list[tuple]:
    tris = []
    for i in range(SEGS):
        a0 = 2 * math.pi * i / SEGS
        a1 = 2 * math.pi * (i + 1) / SEGS
        x0, y0 = r * math.cos(a0), r * math.sin(a0)
        x1, y1 = r * math.cos(a1), r * math.sin(a1)
        if inward:
            tris.append(((x0, y0, z0), (x0, y0, z1), (x1, y1, z1)))
            tris.append(((x0, y0, z0), (x1, y1, z1), (x1, y1, z0)))
        else:
            tris.append(((x0, y0, z0), (x1, y1, z1), (x0, y0, z1)))
            tris.append(((x0, y0, z0), (x1, y1, z0), (x1, y1, z1)))
    return tris


def disc(z: float, r_inner: float, r_outer: float, up: bool) -> list[tuple]:
    tris = []
    for i in range(SEGS):
        a0 = 2 * math.pi * i / SEGS
        a1 = 2 * math.pi * (i + 1) / SEGS
        o0 = (r_outer * math.cos(a0), r_outer * math.sin(a0), z)
        o1 = (r_outer * math.cos(a1), r_outer * math.sin(a1), z)
        if r_inner <= 0:
            c = (0.0, 0.0, z)
            tris.append((c, o1, o0) if up else (c, o0, o1))
        else:
            i0 = (r_inner * math.cos(a0), r_inner * math.sin(a0), z)
            i1 = (r_inner * math.cos(a1), r_inner * math.sin(a1), z)
            if up:
                tris.append((i0, o1, o0))
                tris.append((i0, i1, o1))
            else:
                tris.append((i0, o0, o1))
                tris.append((i0, o1, i1))
    return tris


def normal(a, b, c):
    ux, uy, uz = b[0] - a[0], b[1] - a[1], b[2] - a[2]
    vx, vy, vz = c[0] - a[0], c[1] - a[1], c[2] - a[2]
    nx = uy * vz - uz * vy
    ny = uz * vx - ux * vz
    nz = ux * vy - uy * vx
    mag = math.sqrt(nx * nx + ny * ny + nz * nz) or 1.0
    return nx / mag, ny / mag, nz / mag


def main() -> None:
    tag_z = HEIGHT - TAG_H
    tris = []
    tris += ring(0, HEIGHT, OUTER_R, inward=False)
    tris += ring(0, MAG_H, MAG_R, inward=True)
    tris += ring(tag_z, HEIGHT, TAG_R, inward=True)
    tris += disc(0, MAG_R, OUTER_R, up=False)
    tris += disc(MAG_H, 0, MAG_R, up=True)
    tris += disc(tag_z, 0, TAG_R, up=False)
    tris += disc(HEIGHT, TAG_R, OUTER_R, up=True)

    out = Path(__file__).resolve().parent / "openblocker-key-25mm.stl"
    lines = ["solid openblocker_key_25mm"]
    for a, b, c in tris:
        nx, ny, nz = normal(a, b, c)
        lines.append(f"  facet normal {nx:.6f} {ny:.6f} {nz:.6f}")
        lines.append("    outer loop")
        for p in (a, b, c):
            lines.append(f"      vertex {p[0]:.6f} {p[1]:.6f} {p[2]:.6f}")
        lines.append("    endloop")
        lines.append("  endfacet")
    lines.append("endsolid openblocker_key_25mm")
    out.write_text("\n".join(lines) + "\n")
    print(out, out.stat().st_size)


if __name__ == "__main__":
    main()
