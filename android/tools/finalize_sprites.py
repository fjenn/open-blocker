#!/usr/bin/env python3
"""Pack Blender stills as drawable WebP and sit them next to the iPhone key."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path("/workspace")
RENDERS = ROOT / "android" / "tools" / "renders"
DRAWABLE = ROOT / "android" / "app" / "src" / "main" / "res" / "drawable-nodpi"
IOS_SHEET = ROOT / ".local" / "ios-ref" / "key-gray-sheet.png"


def write_webp(src: Path, name: str) -> Path:
    # Keep the iOS camera framing. Trimming the film would zoom the puck
    # past the 300pt KeyStage box and make Android larger than iPhone.
    im = Image.open(src).convert("RGBA")
    dest = DRAWABLE / f"{name}.webp"
    DRAWABLE.mkdir(parents=True, exist_ok=True)
    im.save(dest, "WEBP", lossless=True, quality=90, method=6)
    png = DRAWABLE / f"{name}.png"
    if png.exists():
        png.unlink()
    print(f"wrote {dest} {im.size} {dest.stat().st_size}b")
    return dest


def ios_key() -> Image.Image:
    sheet = Image.open(IOS_SHEET).convert("RGB")
    w, h = sheet.size
    y0 = int(h * 0.055)
    cell_w = (w - 36) // 4
    cell_h = int(h * 0.89) // 2
    phone = sheet.crop((26, y0 + 6, 18 + cell_w - 8, y0 + cell_h - 28))
    pw, ph = phone.size
    return phone.crop((int(pw * 0.16), int(ph * 0.34), int(pw * 0.84), int(ph * 0.66)))


def compare() -> None:
    ios = ios_key()
    idle = Image.open(RENDERS / "key_idle.png").convert("RGBA")
    filled = Image.open(RENDERS / "key_fill.png").convert("RGBA")
    h = 640

    def fit(im: Image.Image, bg: tuple[int, int, int, int]) -> Image.Image:
        im = im.convert("RGBA")
        nw = max(1, int(im.size[0] * h / im.size[1]))
        im = im.resize((nw, h), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (nw, h), bg)
        canvas.alpha_composite(im)
        return canvas.convert("RGB")

    ios_r = ios.resize((int(ios.size[0] * h / ios.size[1]), h), Image.Resampling.LANCZOS)
    idle_r = fit(idle, (24, 24, 24, 255))
    fill_r = fit(filled, (24, 24, 24, 255))
    gap = 18
    canvas = Image.new(
        "RGB",
        (ios_r.size[0] + idle_r.size[0] + fill_r.size[0] + gap * 4, h + 42),
        (10, 10, 10),
    )
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 16)
    except Exception:
        font = ImageFont.load_default()
    draw = ImageDraw.Draw(canvas)
    draw.text((gap, 10), "iPhone key", fill=(230, 228, 224), font=font)
    draw.text((gap * 2 + ios_r.size[0], 10), "Blender idle", fill=(230, 228, 224), font=font)
    draw.text((gap * 3 + ios_r.size[0] + idle_r.size[0], 10), "Blender fill", fill=(230, 228, 224), font=font)
    canvas.paste(ios_r, (gap, 36))
    canvas.paste(idle_r, (gap * 2 + ios_r.size[0], 36))
    canvas.paste(fill_r, (gap * 3 + ios_r.size[0] + idle_r.size[0], 36))
    dest = RENDERS / "key-vs-iphone.png"
    canvas.save(dest)
    print(f"wrote {dest} {canvas.size}")


def main() -> None:
    write_webp(RENDERS / "key_idle.png", "key_idle")
    write_webp(RENDERS / "key_fill.png", "key_fill")
    compare()


if __name__ == "__main__":
    main()
