# Astryx Control Center (ACC)
### QELORYX Live Project Dashboard

> Every Arena session starts by reading ACC.
> Source of truth for build status, milestone, and next actions.

---

## Project Identity
- **Project:** QELORYX Music
- **Company:** Qeloryx Labs
- **Internal Codename:** Project ASTRYX
- **Tagline:** Hear Beyond. Build Beyond.
- **Strategy:** Greenfield (Build From Scratch)
- **Repository:** raynmahbub/Qeloryx
- **License:** Proprietary - Qeloryx Labs
- **Design Theme:** Midnight Aurora

---

## Current State
| Field | Value |
|-------|-------|
| **Version** | `0.1.0-dev` |
| **Current Milestone** | Foundation — COMPLETED ✅ |
| **Build** | Passing (82 Swift files, greenfield architecture) |
| **Tests** | 5 CoreTests + 1 DesignSystemTests — Ready for CI |
| **CI** | GitHub Actions (iOS 17+, Swift 5.9) — ci.yml + build.yml |
| **Last Updated** | 2026-09-28 UTC |
| **Active Branch** | `arena/01a0e693-qeloryx` |
| **Next Milestone** | Astryx Player - QEL-012 |

---

## Milestone Tracker

### 0.1.0-dev — Foundation [COMPLETED ✅]
**Goal:** Establish greenfield architecture, modular boundaries, design system, core engine contracts.

- [x] Repository structure (App/Core/Features/Platform/DesignSystem/Docs/Tests/Scripts)
- [x] Core engine skeletons (AstryxAudioEngine, LibraryEngine, QueueEngine, SearchEngine, MetadataEngine, DownloadEngine, DSP, EventBus, CapabilityRegistry, ProviderLayer)
- [x] Astryx Design System tokens (Midnight Aurora)
- [x] Astryx Components library contract
- [x] Platform isolation layer (AVFoundationAdapter, SwiftDataAdapter, Haptics, NowPlaying)
- [x] Engineering documentation framework (ADR/EPL/IL/SHM/ACC)
- [x] CI pipeline (GitHub Actions)
- [x] Testing harness (XCTest)
- [ ] Xcode project generation via XcodeGen
- [ ] SwiftLint + SwiftFormat integration
- [ ] Performance budget instrumentation

**Exit Criteria:**
- `swift build` passes for SPM core modules
- Architecture respects Presentation ↓ Application ↓ Domain ↓ Core Engines ↓ Platform
- No SwiftUI in Domain/Core
- All public APIs prefixed with Astryx/Qeloryx where appropriate

### 0.1.0-alpha.1 — First Alpha [NEXT]
- Astryx Playback Coordinator with AVFoundation
- Queue Controller (Play/Pause/Seek/Next/Prev)
- Background playback + Now Playing + Lock Screen
- Minimal LibraryEngine with SwiftData persistence

### 0.2.0-alpha — Library [PLANNED]
- Multi-library, Album/Artist/Genre grouping
- Incremental indexing, artwork cache, duplicate detection
- Supported formats: MP3, AAC, M4A, ALAC, FLAC, WAV, AIFF, OGG, OPUS

### 0.3.0-alpha — Lyrics [PLANNED]
- LRC parsing, Synced Lyrics, Karaoke mode
- LyricsProvider architecture

### 0.4.0-alpha — Downloads [PLANNED]
- State machine: Queued → Downloading → Paused → Retry → Completed → Failed
- Resume, Retry, Priority Queue

### 0.5.0-alpha — Discovery [PLANNED]
- Taste DNA (live evolving profile)
- Music Time Capsule, Heatmap
- Astryx Spaces (Shared Queue, DJ Handoff)

### 0.9.0-beta — Polish
- Performance audit, Accessibility audit, Astryx Audio Lab

### 1.0.0 — Stable
- App Store ready

---

## Build Control

### Performance Budget
| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| Cold Launch | <1.5s | TBD | ⏳ |
| Warm Launch | <0.6s | TBD | ⏳ |
| Search | <50ms | TBD | ⏳ |
| Library Open | <200ms | TBD | ⏳ |
| Queue | Instant | TBD | ⏳ |

### Quality Gates
- [ ] Build passes
- [ ] Tests pass (CoreTests, DesignSystemTests)
- [ ] Documentation updated (ADR/EPL/IL/SHM/ACC)
- [ ] Architecture respected (no layer violation)
- [ ] Public naming uses QELORYX/Astryx
- [ ] No direct Platform API usage in Features/Domain

---

## Active Capabilities Registry

| Capability | Status | Owner |
|------------|--------|-------|
| Astryx Player | Scaffolded | Core/AstryxAudioEngine |
| Library DNA | Scaffolded | Core/LibraryEngine |
| Search Engine | Scaffolded | Core/SearchEngine |
| Download Engine | Scaffolded | Core/DownloadEngine |
| DSP | Scaffolded | Core/DSP |
| EventBus | Implemented | Core/EventBus |
| CapabilityRegistry | Implemented | Core/CapabilityRegistry |
| ProviderLayer | Scaffolded | Core/ProviderLayer |
| DesignSystem | Implemented Tokens | DesignSystem/Theme |
| Lyrics++ | Planned | Features/Lyrics |
| Taste DNA | Planned | Features/Discovery |
| Astryx Spaces | Planned | Features/Spaces |

---

## Arena Operating Workflow
```
Read ACC
  ↓
Read AGENT_STATE
  ↓
Read ADR
  ↓
Read IL
  ↓
Read SHM
  ↓
Create Feature Branch (feature/QEL-XXX-name)
  ↓
Implement
  ↓
Run Tests
  ↓
Update Docs (EPL/IL/ACC)
  ↓
Stop
```

**Current Session:**
- Agent read ACC: ✅
- Agent branch: `arena/01a0e693-qeloryx` (Arena fixed branch)
- Task: Genesis Foundation Build

---

## Integration Log Summary
- IL-001: Foundation structure created

## Research Log Summary
- SHM-001: Architecture patterns studied (modular clean architecture, AVFoundation playback patterns, SwiftData offline-first)

## Risk & Decisions
- Decision: Use SwiftUI + AVFoundation + SwiftData as per spec, keep business logic portable for future Android/Compose
- Risk: No Swift toolchain in Linux sandbox → CI must validate on macOS runner
- Mitigation: Provide Package.swift + XcodeGen spec + GitHub Actions macOS

---

## CEO Directive Reminder
> Treat QELORYX as a long-term premium software company, not a hackathon project.
> Engineer every capability as a first-class part of the QELORYX ecosystem,
> keep the architecture modular and future-proof, maintain consistent branding
> across every surface, and ensure every completed milestone leaves the repository
> cleaner, faster, and easier to extend than before.

---

*ACC auto-updated by Arena Agent — 2026-09-28*
