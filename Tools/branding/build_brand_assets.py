#!/usr/bin/env python3
"""QELORYX — brand asset generator.

Builds every icon and lockup from the app's own Midnight Aurora tokens so the
artwork can never drift from the design system. Run from the repository root:

    python3 Tools/branding/build_brand_assets.py

Requires Pillow (`python3 -m pip install Pillow`).

Coordinates are authored in a 1024x1024 design space and scaled, so the mark is
identical at 40px and at 1024px. Everything is drawn 4x supersampled and
downsampled with LANCZOS for clean antialiased edges.
"""

from __future__ import annotations

import math
import pathlib

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

# MARK: - Brand tokens (mirrors Qeloryx/DesignSystem/Colors/AstryxColors.swift)

MIDNIGHT_900 = (5, 8, 22)      # #050816  Semantic.background
MIDNIGHT_800 = (15, 23, 42)    # #0F172A
AURORA_500 = (59, 130, 246)    # #3B82F6  Semantic.primary
VIOLET = (139, 92, 246)        # #8B5CF6  Gradients.aurora[1]
CYAN = (6, 182, 212)           # #06B6D4  Gradients.aurora[2]
ICE_WHITE = (248, 250, 252)    # #F8FAFC  iceWhite

GRADIENT_STOPS = (AURORA_500, VIOLET, CYAN)

# Geometry in the 1024 design space.
CANVAS = 1024
RING_CENTER = (512.0, 500.0)
RING_OUTER = 300.0
RING_INNER = 176.0             # stroke weight 124 — heavy, reads at 40px
TAIL_ANGLE = math.radians(45)  # down-right
TAIL_START = 0.50              # fraction along radius where the tail leaves the ring
TAIL_END = 1.46                # fraction where the tail ends
TAIL_WIDTH = 158.0             # width at the ring, before taper
TAIL_TIP_WIDTH = 30.0          # rounded-tip width, not a sharp point

SUPERSAMPLE = 4

FONT_DIR = pathlib.Path("Qeloryx/Resources/Fonts")
FONT_BOLD = FONT_DIR / "SpaceGrotesk-Bold.ttf"
FONT_MEDIUM = FONT_DIR / "SpaceGrotesk-Medium.ttf"

OUT_DOCS = pathlib.Path("Docs/Branding")
OUT_ICONSET = pathlib.Path("Qeloryx/Resources/Assets.xcassets/AppIcon.appiconset")
OUT_LOGO = pathlib.Path("Qeloryx/Resources/Assets.xcassets/BrandLogo.imageset")


# MARK: - Primitives


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def lerp_rgb(c0, c1, t):
    return tuple(int(round(lerp(c0[i], c1[i], t))) for i in range(3))


def gradient_rgb(t: float):
    """Sample the 3-stop aurora gradient at 0...1."""
    t = max(0.0, min(1.0, t))
    if t <= 0.5:
        return lerp_rgb(GRADIENT_STOPS[0], GRADIENT_STOPS[1], t / 0.5)
    return lerp_rgb(GRADIENT_STOPS[1], GRADIENT_STOPS[2], (t - 0.5) / 0.5)


def gradient_over_mask(mask: Image.Image) -> Image.Image:
    """Aurora gradient mapped across the *mark's* bounding box.

    Mapping across the whole square (the obvious choice) leaves the bottom-right
    corner — where the tail ends — stuck in the blue range, so cyan never
    appears. Mapping across the bbox guarantees the full 3-stop ramp lands on the
    mark itself.
    """
    size = mask.size[0]
    x0, y0, x1, y1 = mask.getbbox()
    small = 320
    img = Image.new("RGB", (small, small))
    px = img.load()
    d0 = x0 + y0
    d1 = x1 + y1
    span = max(1.0, float(d1 - d0))
    for y in range(small):
        fy = y0 + (y / (small - 1)) * (y1 - y0)
        for x in range(small):
            fx = x0 + (x / (small - 1)) * (x1 - x0)
            t = ((fx + fy) - d0) / span
            px[x, y] = gradient_rgb(t)
    return img.resize((size, size), Image.LANCZOS)


def q_mark_mask(size: int) -> Image.Image:
    """Anti-aliased L-mode mask of the Q monogram, optically centred in `size`."""
    ss = size * SUPERSAMPLE
    kk = ss / CANVAS

    mask = Image.new("L", (ss, ss), 0)
    d = ImageDraw.Draw(mask)

    cx, cy = RING_CENTER[0] * kk, RING_CENTER[1] * kk
    outer = RING_OUTER * kk
    inner = RING_INNER * kk

    # Outer disc first; the counter is subtracted *after* the tail is unioned in,
    # otherwise the tail paints across the bowl and leaves a notch inside the Q.
    d.ellipse([cx - outer, cy - outer, cx + outer, cy + outer], fill=255)

    # Tail: a tapered wedge leaving the ring at 45 degrees. Drawn as two
    # matching edges sampled along the length so the taper is smooth rather than
    # a single hard triangle — a straight quad reads as a stubby nub, not a Q.
    ang = TAIL_ANGLE
    dx, dy = math.cos(ang), math.sin(ang)
    px_, py_ = -dy, dx

    r0 = outer * TAIL_START
    r1 = outer * TAIL_END
    half_base = (TAIL_WIDTH * kk) / 2.0
    half_tip = (TAIL_TIP_WIDTH * kk) / 2.0

    steps = 64
    left, right = [], []
    for i in range(steps + 1):
        f = i / steps
        r = lerp(r0, r1, f)
        # ease so the tail stays thick near the ring then falls away near the tip
        half = lerp(half_base, half_tip, f ** 1.55)
        bx = cx + dx * r
        by = cy + dy * r
        left.append((bx + px_ * half, by + py_ * half))
        right.append((bx - px_ * half, by - py_ * half))

    tail = Image.new("L", (ss, ss), 0)
    td = ImageDraw.Draw(tail)
    td.polygon(left + right[::-1], fill=255)
    # rounded tip
    tip_r = half_tip
    tx, ty = cx + dx * r1, cy + dy * r1
    td.ellipse([tx - tip_r, ty - tip_r, tx + tip_r, ty + tip_r], fill=255)
    mask = ImageChops.lighter(mask, tail)

    # Subtract the counter last so nothing intrudes into the bowl.
    dd = ImageDraw.Draw(mask)
    dd.ellipse([cx - inner, cy - inner, cx + inner, cy + inner], fill=0)

    # Optical centring: the tail makes the raw bbox bottom-right heavy, so
    # centre the actual ink and nudge up slightly.
    bbox = mask.getbbox()
    ink = mask.crop(bbox)
    out = Image.new("L", (ss, ss), 0)
    ox = (ss - ink.size[0]) // 2
    oy = (ss - ink.size[1]) // 2 - int(ss * 0.012)
    out.paste(ink, (ox, oy))

    return out.resize((size, size), Image.LANCZOS)


def q_mark_rgba(size: int) -> Image.Image:
    """The Q in aurora gradient on transparent background."""
    mask = q_mark_mask(size)
    grad = gradient_over_mask(mask)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(grad, (0, 0), mask)
    return out


def _scaled_blur(img: Image.Image, radius: float) -> Image.Image:
    return img.filter(ImageFilter.GaussianBlur(radius))


def compose_icon(size: int = CANVAS, bg=MIDNIGHT_900) -> Image.Image:
    """Full-bleed square app icon: midnight field + bloom + Q + inner rim light."""
    base = Image.new("RGB", (size, size), bg)

    # Subtle radial lift in the centre so the field is not dead flat.
    vignette = Image.new("L", (size, size), 0)
    vd = ImageDraw.Draw(vignette)
    r = size * 0.72
    vd.ellipse(
        [size / 2 - r, size / 2 - r, size / 2 + r, size / 2 + r],
        fill=46,
    )
    vignette = _scaled_blur(vignette, size * 0.10)
    lift = Image.new("RGB", (size, size), MIDNIGHT_800)
    base = Image.composite(lift, base, vignette)

    mark = q_mark_rgba(size)

    # Aurora bloom: blurred, saturated copy of the mark behind it.
    bloom = mark.copy()
    alpha = bloom.getchannel("A").point(lambda v: int(v * 0.55))
    bloom.putalpha(alpha)
    bloom = _scaled_blur(bloom, size * 0.055)
    base = Image.alpha_composite(base.convert("RGBA"), bloom)

    base = Image.alpha_composite(base, mark)

    # Inner rim highlight along the top-left of the ring.
    # Sheen: light falling from the upper-left, clipped to the mark itself.
    # (An arc drawn separately had to guess the ring centre and read as a seam.)
    alpha = mark.getchannel("A")
    w, h = size, size
    sheen = Image.new("L", (w, h), 0)
    sp = sheen.load()
    for y in range(h):
        for x in range(w):
            t = (x + y) / (2 * (w - 1))          # 0 at top-left -> 1 at bottom-right
            sp[x, y] = int(max(0.0, 0.55 - t) * 255 * 0.30)
    sheen = ImageChops.multiply(sheen, alpha)
    sheen = _scaled_blur(sheen, size * 0.012)
    highlight = Image.new("RGBA", (size, size), ICE_WHITE + (255,))
    highlight.putalpha(sheen)
    base = Image.alpha_composite(base, highlight)

    return base.convert("RGB")


# MARK: - Lockups


def wordmark(text: str, px_size: int, weight: str = "bold") -> Image.Image:
    """Render `text` in Space Grotesk with opened tracking, on transparent."""
    font_path = FONT_BOLD if weight == "bold" else FONT_MEDIUM
    font = ImageFont.truetype(str(font_path), px_size)
    tracking = px_size * 0.055

    widths = []
    for ch in text:
        adv = font.getlength(ch)
        widths.append(adv + tracking)
    total = sum(widths) - tracking

    pad = px_size
    img = Image.new("RGBA", (int(total + pad * 2), int(px_size * 2.0)), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    x = pad
    for ch, w in zip(text, widths):
        d.text((x, px_size * 0.5), ch, font=font, fill=ICE_WHITE + (255,))
        x += w

    bbox = img.getbbox()
    return img.crop(bbox) if bbox else img


def _cap_height(font: ImageFont.FreeTypeFont) -> int:
    """Cap height measured from an actual glyph, not guessed from the em size."""
    box = font.getbbox("H")
    return box[3] - box[1]


def q_mark_ink(target_ink_px: int) -> Image.Image:
    """The Q rendered so its *ink* is exactly `target_ink_px` wide.

    `q_mark_mask` centres the mark inside its canvas, and the ink only fills
    ~61.5% of it. Sizing the canvas therefore under-sizes the mark — sizing the
    ink and cropping to the bbox is what makes proportions predictable.
    """
    canvas = max(8, int(round(target_ink_px / 0.615)))
    mark = q_mark_rgba(canvas)
    bbox = mark.getbbox()
    return mark.crop(bbox)


def _build_lockup(height: int, bg=None, dark_text: bool = False) -> Image.Image:
    """Mark + QELORYX, sized and aligned off the wordmark's real cap height.

    Proportions chosen to read correctly in a horizontal lockup: mark ink is
    1.30x the cap height, gap is 0.40x cap, and the mark's ink centre is aligned
    to the middle of the capitals rather than to the text box centre (the Q's
    descender drags the box down and would leave the wordmark sitting high).
    """
    text_px = int(height * 0.62)
    font = ImageFont.truetype(str(FONT_BOLD), text_px)
    cap = _cap_height(font)

    text = wordmark("QELORYX", text_px)
    if dark_text:
        alpha = text.getchannel("A")
        solid = Image.new("RGBA", text.size, MIDNIGHT_900 + (255,))
        solid.putalpha(alpha)
        text = solid

    mark = q_mark_ink(int(round(cap * 1.30)))
    if dark_text:
        # The icon master has the midnight field baked in, so on a light field it
        # would read as a dark tile. Use the mark's ink alone.
        ink_source = q_mark_rgba(mark.width * 2)
        mark = ink_source.crop(ink_source.getbbox()).resize(mark.size, Image.LANCZOS)
    gap = int(round(cap * 0.40))
    pad_x = int(round(cap * 0.45))
    pad_y = int(round(cap * 0.30))

    w = pad_x * 2 + mark.width + gap + text.width
    h = mark.height + pad_y * 2

    fill = (tuple(bg) + (255,)) if bg else (0, 0, 0, 0)
    canvas = Image.new("RGBA", (w, h), fill)

    mark_mid = pad_y + mark.height // 2
    # wordmark() is cropped to ink and every letter in "QELORYX" is a capital,
    # so the cap block starts at y=0 and spans `cap` pixels.
    text_top = mark_mid - cap // 2

    canvas.paste(mark, (pad_x, pad_y), mark)
    canvas.paste(text, (pad_x + mark.width + gap, text_top), text)
    return canvas


def lockup(height: int = 320, bg=MIDNIGHT_900, dark_text: bool = False) -> Image.Image:
    """Horizontal lockup on a solid background."""
    return _build_lockup(height, bg=bg, dark_text=dark_text).convert("RGB")


def transparent_lockup(height: int = 320) -> Image.Image:
    """Same lockup on transparent background, for dark surfaces."""
    return _build_lockup(height, bg=None)


# MARK: - Email / iOS icon sizes

# (idiom, points, scales) — the iOS 17 icon set.
ICON_SPECS = [
    ("iphone", 20, [2, 3]),
    ("iphone", 29, [2, 3]),
    ("iphone", 40, [2, 3]),
    ("iphone", 60, [2, 3]),
    ("ipad", 20, [1, 2]),
    ("ipad", 29, [1, 2]),
    ("ipad", 40, [1, 2]),
    ("ipad", 76, [1, 2]),
    ("ipad", 83, [2]),
    ("ios-marketing", 1024, [1]),
]


def icon_filename(idiom: str, points: int, scale: int) -> str:
    return f"AppIcon-{idiom}-{points}@{scale}x.png"


def write_appiconset(master: Image.Image) -> None:
    import json

    OUT_ICONSET.mkdir(parents=True, exist_ok=True)
    images = []
    for idiom, points, scales in ICON_SPECS:
        for scale in scales:
            px = points * scale
            fn = icon_filename(idiom, points, scale)
            master.resize((px, px), Image.LANCZOS).save(
                OUT_ICONSET / fn, "PNG", optimize=True
            )
            images.append(
                {"filename": fn, "idiom": idiom, "scale": f"{scale}x", "size": f"{points}x{points}"}
            )
    contents = {"images": images, "info": {"author": "xcode", "version": 1}}
    (OUT_ICONSET / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")
    print(f"  AppIcon.appiconset  {len(images)} images")


def write_logo_imageset(master: Image.Image) -> None:
    import json

    OUT_LOGO.mkdir(parents=True, exist_ok=True)
    # A single vector-eta-free dark mark for in-app use.
    master.resize((512, 512), Image.LANCZOS).save(OUT_LOGO / "brand-logo@2x.png", "PNG")
    master.resize((256, 256), Image.LANCZOS).save(OUT_LOGO / "brand-logo.png", "PNG")
    contents = {
        "images": [
            {"filename": "brand-logo.png", "idiom": "universal", "scale": "1x"},
            {"filename": "brand-logo@2x.png", "idiom": "universal", "scale": "2x"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (OUT_LOGO / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")
    print("  BrandLogo.imageset   2 images")


def write_catalog_metadata() -> None:
    """Top-level Contents.json files + the AccentColor the app tints controls with."""
    import json

    root = OUT_ICONSET.parent
    catalog_root = {"info": {"author": "xcode", "version": 1}}
    (root / "Contents.json").write_text(json.dumps(catalog_root, indent=2) + "\n")

    accent = root / "AccentColor.colorset"
    accent.mkdir(parents=True, exist_ok=True)
    payload = {
        "colors": [
            {
                "color": {
                    "color-space": "srgb",
                    "components": {
                        "alpha": "1.000",
                        "blue": "0xF6",
                        "green": "0x82",
                        "red": "0x3B",
                    },
                },
                "idiom": "universal",
            }
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (accent / "Contents.json").write_text(json.dumps(payload, indent=2) + "\n")
    print("  AccentColor         #3B82F6 (Aurora.500)")


def main() -> None:
    for out in (OUT_DOCS, OUT_ICONSET, OUT_LOGO):
        out.mkdir(parents=True, exist_ok=True)

    master = compose_icon(CANVAS)

    master.save(OUT_DOCS / "qeloryx-icon-1024.png", "PNG", optimize=True)
    master.resize((512, 512), Image.LANCZOS).save(OUT_DOCS / "qeloryx-icon-512.png", "PNG")
    master.resize((256, 256), Image.LANCZOS).save(OUT_DOCS / "qeloryx-icon-256.png", "PNG")
    q_mark_rgba(1024).save(OUT_DOCS / "qeloryx-mark-1024.png", "PNG")
    q_mark_rgba(256).save(OUT_DOCS / "qeloryx-mark-256.png", "PNG")

    lockup(360).save(OUT_DOCS / "qeloryx-lockup-dark.png", "PNG")
    transparent_lockup(360).save(OUT_DOCS / "qeloryx-lockup-transparent.png", "PNG")
    lockup(360, bg=(248, 250, 252), dark_text=True).save(
        OUT_DOCS / "qeloryx-lockup-light.png", "PNG"
    )

    write_appiconset(master)
    write_logo_imageset(master)
    write_catalog_metadata()

    # Sanity: the marketing icon must be a raw full-bleed square, no alpha.
    assert master.size == (1024, 1024)
    assert master.mode == "RGB", master.mode
    print("  Docs/Branding       PNGs + alpha-free 1024 master ✔")


if __name__ == "__main__":
    main()
