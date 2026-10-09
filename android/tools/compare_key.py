#!/usr/bin/env python3
"""Crop the iPhone idle key and sit it next to the Blender sprite."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

REF = Path("/workspace/.local/ios-ref/key-gray-sheet.png")
IDLE = Path("/workspace/android/tools/renders/key_idle.png")
FILL = Path("/workspace/android/tools/renders/key_fill.png")
OUT = Path("/workspace/android/tools/renders/key-vs-iphone.png")


def crop_ios_idle() -> Image.Image:
    sheet = Image.open(REF).convert("RGBA")
    w, h = sheet.size
    # Top-left phone in the 2x4 key-gray sheet.
    cell_w, cell_h = w // 4, int(h * 0.45)
    phone = sheet.crop((18, int(h * 0.055), cell_w - 8, cell_h - 20))
    return phone


def sprite_on(bg: tuple[int, int, int], sprite: Image.Image, height: int) -> Image.Image:
    sprite = sprite.convert("RGBA")
    scale = height / sprite.size[1]
    nw, nh = max(1, int(sprite.size[0] * scale)), height
    sprite = sprite.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (nw, nh), bg + (255,))
    canvas.alpha_composite(sprite)
    return canvas


def main() -> None:
    ios = crop_ios_idle()
    target_h = 820
    ios = ios.resize((int(ios.size[0] * target_h / ios.size[1]), target_h), Image.Resampling.LANCZOS)
    idle = sprite_on((24, 24, 24), Image.open(IDLE), target_h)
    filled = sprite_on((24, 24, 24), Image.open(FILL), target_h)
    gap = 16
    width = ios.size[0] + idle.size[0] + filled.size[0] + gap * 4
    canvas = Image.new("RGB", (width, target_h + 40), (12, 12, 12))
    draw = ImageDraw.Draw(canvas)
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 16)
    except Exception:
        font = ImageFont.load_default()
    draw.text((gap, 10), "iPhone idle", fill=(230, 228, 224), font=font)
    draw.text((gap * 2 + ios.size[0], 10), "Blender idle", fill=(230, 228, 224), font=font)
    draw.text((gap * 3 + ios.size[0] + idle.size[0], 10), "Blender fill", fill=(230, 228, 224), font=font)
    canvas.paste(ios.convert("RGB"), (gap, 36))
    canvas.paste(idle.convert("RGB"), (gap * 2 + ios.size[0], 36))
    canvas.paste(filled.convert("RGB"), (gap * 3 + ios.size[0] + idle.size[0], 36))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(OUT)
    print(f"wrote {OUT} {canvas.size}")


if __name__ == "__main__":
    main()
