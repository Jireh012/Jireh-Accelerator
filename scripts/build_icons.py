#!/usr/bin/env python3

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
ICON_DIR = ROOT / "assets" / "icons"
ANDROID_DRAWABLE = ROOT / "android" / "app" / "src" / "main" / "res" / "drawable"
SOURCE_PATH = ICON_DIR / "icon-source.png"
ICO_PATH = ICON_DIR / "linuxdo.ico"
PNG_SIZES = [32, 48, 64, 72, 80, 96, 112, 120, 128, 144, 160, 192, 224, 256, 512]
ICO_SIZES = [
    (16, 16),
    (20, 20),
    (24, 24),
    (32, 32),
    (40, 40),
    (48, 48),
    (64, 64),
    (72, 72),
    (80, 80),
    (96, 96),
    (112, 112),
    (120, 120),
    (128, 128),
    (144, 144),
    (160, 160),
    (192, 192),
    (224, 224),
    (256, 256),
]
CORNER_RADIUS_RATIO = 0.22


def load_master() -> Image.Image:
    if not SOURCE_PATH.exists():
        raise SystemExit(f"missing icon source: {SOURCE_PATH}")
    return Image.open(SOURCE_PATH).convert("RGBA")


def round_corners(image: Image.Image) -> Image.Image:
    size = image.size[0]
    radius = max(1, round(size * CORNER_RADIUS_RATIO))
    mask = Image.new("L", image.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    rounded = Image.new("RGBA", image.size, (0, 0, 0, 0))
    rounded.paste(image, mask=mask)
    return rounded


def render_icon(image: Image.Image, size: int) -> Image.Image:
    return round_corners(image.resize((size, size), Image.Resampling.LANCZOS))


def main() -> None:
    master = load_master()
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    ANDROID_DRAWABLE.mkdir(parents=True, exist_ok=True)

    for size in PNG_SIZES:
        render_icon(master, size).save(ICON_DIR / f"{size}x{size}.png")

    rounded_master = round_corners(master)
    rounded_master.save(ICO_PATH, format="ICO", sizes=ICO_SIZES)
    render_icon(master, 512).save(ANDROID_DRAWABLE / "ic_linuxdo_logo.png")


if __name__ == "__main__":
    main()
