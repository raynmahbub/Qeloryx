# ADR-001: Greenfield Architecture

**Date:** 2026-09-28
**Status:** Accepted
**Deciders:** Qeloryx Labs CTO, Arena Agent
**Tags:** architecture, greenfield, ownership

## Context
QELORYX is defined as a brand-new premium music platform. We must decide whether to fork existing open-source player (e.g., Amperfy, Swiftfin, or similar) or build from scratch.

Requirements:
- Premium, fast, intelligent, audiophile-ready, native feeling
- Offline-first
- Cross-platform scalability (iOS → Android, macOS, Windows, Linux, Web, Watch)
- Own branding, design system, public APIs

## Decision
Build QELORYX as **greenfield** project.

- Repository, architecture, naming, design system, public APIs, documentation, product identity belong entirely to QELORYX.
- Existing products (Spotify, Apple Music, Plexamp, Tidal, SoundCloud) treated as UX inspiration, not code sources.
- Open-source projects may be studied for architectural patterns (playback workflows, indexing strategies, modular design) but implementation stays within QELORYX architecture.
- If any upstream code is reused, respect its license and record in SHM and IL.

## Consequences
**Positive:**
- Full ownership of identity and architecture
- No legacy constraints
- Clean modular boundaries from day one
- Portable business logic for future platforms

**Negative:**
- More initial effort vs forking
- Need to re-implement proven patterns

**Mitigation:**
- Use engineering research registry (SHM) to capture patterns
- Use CapabilityRegistry and ProviderLayer for extensibility

## Implementation
- Structure: App/Core/Features/Platform/DesignSystem/Docs/Tests/Scripts
- Each Core folder has single responsibility
- Public naming: Astryx* for engines/components, Qeloryx* for app-level

## References
- Genesis Bible v3.0 — Executive Directive
- SHM-001

---
*QELORYX — Hear Beyond. Build Beyond.*
