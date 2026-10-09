#!/usr/bin/env python3
"""Build a side-by-side iOS-sheet vs Android-golden comparison image."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def load(path: Path) -> Image.Image:
    return Image.open(path).convert("RGB")


def fit(img: Image.Image, width: int, height: int) -> Image.Image:
    img = img.copy()
    img.thumbnail((width, height), Image.Resampling.LANCZOS)
    canvas = Image.new("RGB", (width, height), (16, 16, 16))
    x = (width - img.width) // 2
    y = (height - img.height) // 2
    canvas.paste(img, (x, y))
    return canvas


def label(draw: ImageDraw.ImageDraw, text: str, x: int, y: int) -> None:
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 22)
    except OSError:
        font = ImageFont.load_default()
    draw.text((x, y), text, fill=(230, 228, 224), font=font)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--ios-dir", default="open-blocker/redesign/compare")
    parser.add_argument(
        "--android-dir",
        default="android/app/src/test/snapshots/images",
    )
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    root = Path("/workspace")
    ios = root / args.ios_dir
    android = root / args.android_dir
    prefix = "app.openblocker.android.ui_ScreenshotTest_"

    pairs = [
        ("iOS key (idle / hold / blocked / burst)", ios / "key-gray-sheet.png", None),
        ("iOS modes", ios / "modes-sheet.png", None),
        ("iOS settings / privacy / camera", ios / "settings-perms-sheet.png", None),
        ("iOS round 4 (settings, activity, privacy, home, camera)", ios / "round4-sheet.png", None),
        ("Android home idle dark", None, android / f"{prefix}home_idle_dark.png"),
        ("Android home hold dark", None, android / f"{prefix}home_hold_dark.png"),
        ("Android home blocked dark", None, android / f"{prefix}home_blocked_dark.png"),
        ("Android home idle light", None, android / f"{prefix}home_idle_light.png"),
        ("Android templates dark", None, android / f"{prefix}templates_dark.png"),
        ("Android modes dark", None, android / f"{prefix}modes_dark.png"),
        ("Android mode edit dark", None, android / f"{prefix}mode_edit_dark.png"),
        ("Android settings dark", None, android / f"{prefix}settings_dark.png"),
        ("Android settings light", None, android / f"{prefix}settings_light.png"),
        ("Android emergency dark", None, android / f"{prefix}emergency_dark.png"),
        ("Android privacy dark", None, android / f"{prefix}privacy_dark.png"),
        ("Android permission dark", None, android / f"{prefix}permission_dark.png"),
    ]

    cell_w, cell_h = 720, 720
    pad = 24
    label_h = 40
    cols = 2
    rows = (len(pairs) + 1) // 2
    width = pad + cols * (cell_w + pad)
    height = pad + rows * (cell_h + label_h + pad)
    out = Image.new("RGB", (width, height), (10, 10, 10))
    draw = ImageDraw.Draw(out)

    for i, (title, ios_path, and_path) in enumerate(pairs):
        r, c = divmod(i, cols)
        x = pad + c * (cell_w + pad)
        y = pad + r * (cell_h + label_h + pad)
        src = ios_path if ios_path and ios_path.exists() else and_path
        if src is None or not src.exists():
            label(draw, f"{title} (missing)", x, y)
            continue
        tile = fit(load(src), cell_w, cell_h)
        out.paste(tile, (x, y + label_h))
        label(draw, title, x, y)

    dest = Path(args.out)
    dest.parent.mkdir(parents=True, exist_ok=True)
    out.save(dest, "PNG")
    print(dest)


if __name__ == "__main__":
    main()
