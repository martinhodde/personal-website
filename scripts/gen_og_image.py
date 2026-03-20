#!/usr/bin/env python3
"""Render a static frame of the home page icosphere as a 1200x630 OG preview."""
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

IMG_W, IMG_H = 1200, 630
FONT_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"
FONT_SIZE = 14

BG_COLOR = (14, 14, 16)
FG_COLOR = (122, 162, 247)

SCALE = 80
DEPTH = 5
CHARS = " .,:;=~+*#%@"
SC = 0.9
PHI = (1 + math.sqrt(5)) / 2

ANGLE_A = 0.55
ANGLE_B = 0.78


def normalize(v):
    l = math.sqrt(v[0]**2 + v[1]**2 + v[2]**2)
    return [c / l * SC * 2 for c in v]


def build_icosphere():
    verts = [
        [-1, PHI, 0], [1, PHI, 0], [-1, -PHI, 0], [1, -PHI, 0],
        [0, -1, PHI], [0, 1, PHI], [0, -1, -PHI], [0, 1, -PHI],
        [PHI, 0, -1], [PHI, 0, 1], [-PHI, 0, -1], [-PHI, 0, 1],
    ]
    verts = [normalize(v) for v in verts]
    faces = [
        [0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
        [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
        [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
        [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1],
    ]
    mid_cache = {}
    def midpoint(a, b):
        key = (min(a, b), max(a, b))
        if key in mid_cache:
            return mid_cache[key]
        m = normalize([(verts[a][i] + verts[b][i]) / 2 for i in range(3)])
        verts.append(m)
        mid_cache[key] = len(verts) - 1
        return mid_cache[key]
    new_faces = []
    for a, b, c in faces:
        ab, bc, ca = midpoint(a, b), midpoint(b, c), midpoint(c, a)
        new_faces.extend([[a, ab, ca], [b, bc, ab], [c, ca, bc], [ab, bc, ca]])

    edge_set, edges = set(), []
    for a, b, c in new_faces:
        for i, j in [(a, b), (b, c), (c, a)]:
            k = (min(i, j), max(i, j))
            if k not in edge_set:
                edge_set.add(k)
                edges.append((verts[i], verts[j]))
    return edges


def rot_xy(v, a, b):
    ca, sa, cb, sb = math.cos(a), math.sin(a), math.cos(b), math.sin(b)
    x, y, z = v
    y2, z2 = y * ca - z * sa, y * sa + z * ca
    return (x * cb - z2 * sb, y2, x * sb + z2 * cb)


def proj(v, w, h, y_scale):
    s = SCALE / (v[2] + DEPTH)
    return (v[0] * s + w / 2, v[1] * s * y_scale + h / 2, v[2])


def render_grid(W, H, y_scale):
    edges = build_icosphere()
    buf = [[' '] * W for _ in range(H)]
    zbuf = [[1e9] * W for _ in range(H)]
    for v0, v1 in edges:
        p0 = proj(rot_xy(v0, ANGLE_A, ANGLE_B), W, H, y_scale)
        p1 = proj(rot_xy(v1, ANGLE_A, ANGLE_B), W, H, y_scale)
        steps = int(max(abs(p1[0] - p0[0]), abs(p1[1] - p0[1])) * 1.5)
        if steps == 0:
            continue
        for s in range(steps + 1):
            t = s / steps
            x = round(p0[0] + (p1[0] - p0[0]) * t)
            y = round(p0[1] + (p1[1] - p0[1]) * t)
            z = p0[2] + (p1[2] - p0[2]) * t
            if 0 <= x < W and 0 <= y < H and z < zbuf[y][x]:
                zbuf[y][x] = z
                bright = max(0, min(len(CHARS) - 1,
                    int((1 - (z + 2) / 4) * (len(CHARS) - 1))))
                buf[y][x] = CHARS[bright]
    return buf


def main():
    font = ImageFont.truetype(FONT_PATH, FONT_SIZE)
    char_w = round(font.getlength("M"))
    ascent, descent = font.getmetrics()
    line_h = ascent + descent
    y_scale = char_w / line_h

    W = IMG_W // char_w
    H = IMG_H // line_h

    img = Image.new('RGB', (IMG_W, IMG_H), BG_COLOR)
    draw = ImageDraw.Draw(img)
    grid = render_grid(W, H, y_scale)
    for y, row in enumerate(grid):
        line = ''.join(row).rstrip()
        if line:
            draw.text((0, y * line_h), line, fill=FG_COLOR, font=font)

    out_path = Path(__file__).resolve().parent.parent / "og-image.png"
    img.save(out_path)
    print(f"Saved {out_path} ({IMG_W}x{IMG_H}, grid {W}x{H})")


if __name__ == '__main__':
    main()
