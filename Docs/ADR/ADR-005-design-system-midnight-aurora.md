# ADR-005: Design System — Midnight Aurora

**Date:** 2026-09-28
**Status:** Accepted
**Tags:** design-system, UI, branding

## Context
Need consistent premium visual identity across all platforms. QELORYX targets:
- Premium
- Fast
- Intelligent
- Audiophile-ready
- Native feeling

Generic iOS look would not differentiate. Need own design language.

## Decision
Create **Astryx Design System** with theme **Midnight Aurora**.

**Color Tokens:**
| Token | Value | Usage |
|-------|-------|-------|
| Aurora Blue | #3B82F6 | Primary, links, active states |
| Midnight | #050816 | Background, dark mode base |
| Emerald | #10B981 | Success, playing indicator |
| Sunset | #F97316 | Warning, favorite, energy |
| Ice White | #F8FAFC | Text, cards, foreground |

**Extended Palette:**
- Midnight variants: 900 #050816, 800 #0F172A, 700 #1E293B
- Aurora Blue variants: 500 #3B82F6, 400 #60A5FA, 300 #93C5FD
- Surface: card, sheet, navigation bar with blur
- Semantic: background, foreground, muted, border

**Typography:**
- Logo → Space Grotesk (custom font, bundled)
- Heading → SF Pro Display (system, but wrapped in AstryxTypography)
- Body → SF Pro Text

**Principles:**
- Album artwork is primary visual anchor
- Dark mode first, light mode secondary but supported
- No generic UI duplication — every reusable component begins with Astryx
- Haptic feedback for premium feeling

**Astryx Components:**
- AstryxButton (primary, secondary, ghost, destructive)
- AstryxCard (album, track, playlist variants)
- AstryxArtwork (with placeholder, shimmer, transition)
- AstryxSlider (for seek, volume, EQ)
- AstryxMiniPlayer (persistent bottom player)
- AstryxSheet (custom detent, blur background)
- AstryxNavigationBar (large title, artwork-aware)

**Foundations:**
- Spacing: 4pt grid (4, 8, 12, 16, 20, 24, 32, 40, 48)
- CornerRadius: xs 8, sm 12, md 16, lg 24, xl 32, full 9999
- Animation: spring-based, 0.3s default, haptic-synced

## Consequences
**Positive:**
- Consistent branding
- Premium feeling
- Easy theming for future platforms

**Negative:**
- Need to build components from scratch vs using system defaults

## Implementation
- DesignSystem/Theme/AstryxColors.swift — color tokens
- DesignSystem/Theme/AstryxTypography.swift — typography
- DesignSystem/Theme/AstryxTheme.swift — theme composition
- DesignSystem/Components/* — reusable components
- DesignSystem/Foundations/* — spacing, radius

## References
- Genesis Bible — Astryx Design System
- Inspiration: Apple Music, Plexamp, Tidal (UX only, not code)

---
*QELORYX — Midnight Aurora*
