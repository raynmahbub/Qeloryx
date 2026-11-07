# QELORYX — Brand Guidelines

Everything here is derived from the interface's own design tokens. If a colour
below ever disagrees with `DesignSystem/Theme/AstryxColors.swift`, the code
wins and the artwork is stale — regenerate it.

## The mark

A geometric **Q**: a heavy uniform ring with a tapered tail leaving the bowl at
45° toward the lower right. The tail is what makes it a Q rather than a percent
sign, so never crop it, and never rotate the mark.

- Ring: outer radius 300, stroke weight 124 (in a 1024 design space)
- Tail: leaves the ring at 0.50× radius, ends at 1.46×, tapering 158→30 wide
- Ink occupies ~61.5% of the canvas; the generator crops and optically centres
  to the ink, so the mark sits true at every size

## Palette

| Role | Hex | Token |
|---|---|---|
| Field | `#050816` | `AstryxColors.Midnight._900` |
| Field, lifted | `#0F172A` | `AstryxColors.Midnight._800` |
| Gradient start | `#3B82F6` | `AstryxColors.Aurora._500` |
| Gradient mid | `#8B5CF6` | `AstryxColors.Gradients.aurora[1]` |
| Gradient end | `#06B6D4` | `AstryxColors.Gradients.aurora[2]` |
| Wordmark | `#F8FAFC` | `AstryxColors.iceWhite` |

The gradient runs top-left → bottom-right **across the mark's bounding box**,
not across the square. Mapping it to the square leaves the tail stuck in the
blue range and the cyan never appears — that is why the generator maps to the
ink box.

## Typeface

**Space Grotesk** (SIL Open Font License 1.1, font version 2.000), Bold for the
wordmark and Medium for secondary uses.

- Wordmark is set in `QELORYX`, all caps, tracking opened by `0.055 × size`
- PostScript name for `Font.custom` is `SpaceGrotesk-Bold`
- Bundled at `App/Resources/Fonts/` and registered through `UIAppFonts`
- Licence text: `App/Resources/Fonts/OFL-SpaceGrotesk.txt`
- Attribution recorded in `THIRD-PARTY-NOTICES.md`

## Lockup proportions

Mark ink is **1.30×** the cap height of the wordmark, the gap is **0.40×** the
cap height, and the mark is centred on the capitals rather than the text box —
the wordmark's Q has a descender that would otherwise push the text up.

## Usage

**Do**

- Give the mark clear space of at least 25% of its width on every side
- Use `AstryxBrandMark` / `AstryxWordmark` / `AstryxBrandLockup` rather than
  referencing asset names directly
- Use the dark lockup on the midnight field, the light lockup on light surfaces

**Don't**

- Don't recolour the gradient, add outlines, bevels, shadows, or glows beyond
  the built-in aurora bloom
- Don't stretch, rotate, or rearrange the lockup
- Don't place the mark on a busy image; the field is part of the mark
- Don't typeset the wordmark in another face, or add lowercase
- Don't hand-edit the PNGs — they are build output
- Don't use the mark to imply endorsement of a fork or derivative work

## App icon

Full-bleed square, **no alpha channel** and no pre-rounded corners — iOS applies
the mask. The 1024 marketing icon is asserted alpha-free by the generator.

Sizes are produced for iPhone (20/29/40/60 pt at 2× and 3×), iPad (20/29/40/76
pt at 1× and 2×, 83 pt at 2×), and the 1024 marketing icon.

## Regenerating

```sh
python3 -m pip install Pillow
python3 Tools/branding/build_brand_assets.py
```

The generator writes:

- `App/Resources/Assets.xcassets/AppIcon.appiconset/` — 18 images + `Contents.json`
- `App/Resources/Assets.xcassets/BrandLogo.imageset/` — 2 images + `Contents.json`
- `App/Resources/Assets.xcassets/AccentColor.colorset/` — `#3B82F6`
- `Docs/Branding/` — 1024/512/256 icons, standalone mark, three lockups

All artwork is first-party, drawn procedurally from the values above.
