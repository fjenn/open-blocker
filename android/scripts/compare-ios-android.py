#!/usr/bin/env python3
"""Lay out Android Paparazzi goldens in the same groups as the attached iOS sheets."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path("/workspace")
GOLDEN = ROOT / "android/app/src/test/snapshots/images"
PREFIX = "app.openblocker.android.ui_ScreenshotTest_"
OUT = Path("/opt/cursor/artifacts/android-ios-parity-comparison.png")
BG = (12, 12, 12)
INK = (242, 240, 237)
MUTED = (155, 152, 147)


def font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in (
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    ):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def load(name: str) -> Image.Image | None:
    path = GOLDEN / f"{PREFIX}{name}.png"
    if not path.exists():
        return None
    return Image.open(path).convert("RGB")


def phone(img: Image.Image, height: int = 640) -> Image.Image:
    ratio = height / img.height
    width = max(1, int(img.width * ratio))
    return img.resize((width, height), Image.Resampling.LANCZOS)


def section(title: str, names: list[str], caption: str) -> Image.Image:
    tiles = [phone(img) for name in names if (img := load(name))]
    pad = 20
    header = 72
    if not tiles:
        canvas = Image.new("RGB", (800, 120), BG)
        draw = ImageDraw.Draw(canvas)
        draw.text((pad, 24), f"{title} (missing)", fill=INK, font=font(22))
        return canvas
    width = pad + sum(t.width + pad for t in tiles)
    height = header + tiles[0].height + pad
    canvas = Image.new("RGB", (width, height), BG)
    draw = ImageDraw.Draw(canvas)
    draw.text((pad, 12), title, fill=INK, font=font(26))
    draw.text((pad, 42), caption, fill=MUTED, font=font(16))
    x = pad
    for tile in tiles:
        canvas.paste(tile, (x, header))
        x += tile.width + pad
    return canvas


def main() -> None:
    blocks = [
        section(
            "Home / key  —  Android (Paparazzi Canvas fallback)",
            [
                "homeIdleDark_home_idle_dark",
                "homeHoldDark_home_hold_dark",
                "homeBlockedDark_home_blocked_dark",
                "homeIdleLight_home_idle_light",
                "homeHoldLight_home_hold_light",
                "homeBlockedLight_home_blocked_light",
            ],
            "Matches iOS key-gray-sheet: idle, mid-hold, blocked. Real app uses KeyModel.glb via Filament; tests keep this puck.",
        ),
        section(
            "Modes  —  Android",
            [
                "templatesDark_templates_dark",
                "modesDark_modes_dark",
                "modeEditDark_mode_edit_dark",
            ],
            "Matches iOS modes-sheet: New mode templates, Select mode, Edit mode (Websites section).",
        ),
        section(
            "Settings / emergency / privacy / camera  —  Android",
            [
                "settingsDark_settings_dark",
                "settingsLight_settings_light",
                "emergencyDark_emergency_dark",
                "privacyDark_privacy_dark",
                "permissionDark_permission_dark",
            ],
            "Matches iOS settings-perms-sheet and round4 settings/privacy/permission frames.",
        ),
    ]
    pad = 28
    title_h = 96
    width = max(b.width for b in blocks) + pad * 2
    height = title_h + pad + sum(b.height + pad for b in blocks)
    out = Image.new("RGB", (width, height), BG)
    draw = ImageDraw.Draw(out)
    draw.text(
        (pad, 20),
        "Open Blocker  —  iOS sheets vs Android goldens",
        fill=INK,
        font=font(32),
    )
    draw.text(
        (pad, 58),
        "iOS source: attached round4 / settings-perms / modes / key-gray sheets. "
        "Android: Paparazzi PIXEL_5 goldens on this branch. Not device-tested.",
        fill=MUTED,
        font=font(16),
    )
    y = title_h
    for block in blocks:
        out.paste(block, (pad, y))
        y += block.height + pad
    OUT.parent.mkdir(parents=True, exist_ok=True)
    out.save(OUT, "PNG")
    repo_copy = ROOT / "artifacts/android-ios-parity-comparison.png"
    repo_copy.parent.mkdir(parents=True, exist_ok=True)
    out.save(repo_copy, "PNG")
    print(OUT, out.size, OUT.stat().st_size)


if __name__ == "__main__":
    main()
