# AGENT_STATE
### Arena Agent Working Memory — QELORYX

> This file is read at the start of every Arena session.
> It preserves context across sessions.

---

## Session: 2026-09-28 — Genesis Foundation

### Who am I?
Arena Agent assigned to build QELORYX as greenfield premium music platform.
Repository: raynmahbub/Qeloryx
Branch: arena/01a0e693-qeloryx (fixed by Arena, must not switch)
Base: 93af092 Initial commit (empty except README)

### What was requested?
User provided QELORYX Genesis Bible v3.0 — full CTO spec for greenfield build.
Requirements:
- Greenfield architecture, modular by default, offline-first, native performance
- Tech: SwiftUI, AVFoundation, SwiftData, Clean Modular
- Structure: App/Core/Features/Platform/DesignSystem/Docs/Tests/Scripts
- Core: AstryxAudioEngine, LibraryEngine, QueueEngine, SearchEngine, MetadataEngine, DownloadEngine, DSP, EventBus, CapabilityRegistry, ProviderLayer
- DesignSystem: Midnight Aurora (Aurora Blue #3B82F6, Midnight #050816, Emerald #10B981, Sunset #F97316, Ice White #F8FAFC)
- Components: AstryxButton, AstryxCard, AstryxArtwork, AstryxSlider, AstryxMiniPlayer, AstryxSheet, AstryxNavigationBar
- Documentation: ADR/EPL/IL/SHM/ACC
- Engineering research policy: study public projects for patterns, but implement within QELORYX identity

### What have I done?
**Foundation Milestone 0.1.0-dev — IN PROGRESS**

1. Created full directory structure per spec
2. Created ACC.md with live dashboard
3. Next: Create AGENT_STATE (this file), ADR, EPL, IL, SHM
4. Then: Implement Core engines with proper protocols
5. Then: Implement DesignSystem tokens and components
6. Then: Implement App entry, Platform adapters, Features scaffolding
7. Then: Implement Tests, Scripts, CI, Package.swift, README, .gitignore

### Current Architecture Decisions
- ADR-001: Greenfield architecture — QELORYX owns all naming, public APIs, design system. No copy-paste from open-source; research only for patterns.
- ADR-002: Modular Core Engines — Each engine is independent Swift module with single responsibility, communicates via EventBus
- ADR-003: EventBus decoupling — All cross-engine communication via typed events, no direct dependencies
- ADR-004: Offline-first — SwiftData as source of truth, all features work without network, sync is additive

### File Ownership
- Public APIs: Must use QELORYX/Astryx prefix
- SwiftUI: Only in Presentation layers (Features/*/Presentation, App/Root, DesignSystem/Components)
- Domain/Core: No UIKit, no SwiftUI, no AVFoundation direct import (via Platform adapters)
- Platform: Only place where AVFoundation, MediaPlayer, SwiftData, CoreHaptics imported

### Next Steps for this Session
1. Complete Docs (ADR-001 to ADR-004, EPL-001, IL-001, SHM-001)
2. Implement Core layer with clean protocols
3. Implement DesignSystem
4. Implement Platform adapters
5. Implement App and Features scaffolding
6. Create Package.swift, project.yml, .gitignore, CI workflows
7. Create Tests
8. Update README
9. Verify structure and run lint

### Blockers
- No Swift toolchain in sandbox — cannot compile locally. Must rely on CI on macOS runner. Create scripts that would work in CI.

### Notes for Next Agent
- If you resume, read ACC.md first, then this file, then ADR/*.md, IL/*.md, SHM/*.md
- Foundation is almost complete — check if Core engines are implemented
- After Foundation, next is QEL-012 Player: implement AstryxPlaybackCoordinator with real AVFoundation
- Keep branding consistent: Astryx for components/engines, Qeloryx for app/company
- Commit convention: feat(scope): message — e.g., feat(player): implement Astryx playback coordinator

### Performance Budget (from Bible)
- Cold Launch <1.5s
- Warm Launch <0.6s
- Search <50ms
- Library Open <200ms
- Queue Instant

---

*Last updated: 2026-09-28 by Arena Agent — Foundation session*
