#!/usr/bin/env python3
"""Generate 700px-wide WebP thumbnails for the photo grid."""
from pathlib import Path
from PIL import Image

SRC_DIR = Path(__file__).resolve().parent.parent / "photos" / "img"
DST_DIR = Path(__file__).resolve().parent.parent / "photos" / "thumbs"
TARGET_WIDTH = 700
WEBP_QUALITY = 78


def main():
    DST_DIR.mkdir(parents=True, exist_ok=True)
    sources = sorted(SRC_DIR.glob("*.jpg"))
    for src in sources:
        dst = DST_DIR / (src.stem + ".webp")
        if dst.exists() and dst.stat().st_mtime >= src.stat().st_mtime:
            continue
        with Image.open(src) as img:
            w, h = img.size
            if w > TARGET_WIDTH:
                new_h = int(h * TARGET_WIDTH / w)
                img = img.resize((TARGET_WIDTH, new_h), Image.LANCZOS)
            img.save(dst, "WEBP", quality=WEBP_QUALITY, method=6)
    print(f"Done: {len(sources)} thumbs in {DST_DIR}")


if __name__ == "__main__":
    main()
