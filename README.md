# QELORYX — Hear Beyond. Build Beyond.

> **Project ASTRYX** — Premium offline-first music platform
> **Company:** Qeloryx Labs
> **Version:** 0.1.0-dev (Foundation)
> **Strategy:** Greenfield (Build From Scratch)

---

## Vision

QELORYX is designed to become a premium offline-first music platform with world-class performance, elegant UX, and long-term cross-platform scalability.

**Five Pillars:**
- **Astryx Player** — Independent playback coordinator, queue controller, background playback, Dynamic Island, Lock Screen, AirPlay
- **Library DNA** — Multi-library, album/artist/genre grouping, favorites, history, recently added, incremental indexing
- **Taste DNA** — Live evolving listening profile (instead of yearly wrapped)
- **Astryx Audio Lab** — Signal path, playback diagnostics, battery/storage impact, live spectrum
- **Astryx Spaces** — Shared queue, DJ handoff, live reactions, future voice rooms

**Target Experience:** Premium • Fast • Intelligent • Audiophile-ready • Native feeling

---

## Architecture

### Greenfield Principles
- Greenfield architecture — QELORYX owns all naming, design system, public APIs
- Modular by default
- Offline-first
- Native performance
- Cross-platform preservation
- Testable code
- Clean public APIs
- Consistent branding (Astryx* for engines/components)

### Layers
```
Presentation (SwiftUI)
   ↓
Application (ViewModels, Use Cases)
   ↓
Domain (Entities, Protocols — pure Swift)
   ↓
Core Engines (AstryxAudioEngine, LibraryEngine, SearchEngine, etc.)
   ↓
Platform (AVFoundationAdapter, SwiftDataAdapter, Haptics, System)
```

**Rules:**
- SwiftUI stays inside Presentation
- Business logic never enters Views
- Platform APIs stay isolated
- Communication happens through EventBus

### Repository Structure
```
QELORYX/
├── App/                    # @main, RootView, AppCoordinator, Configuration
├── Core/                   # Business logic — portable
│   ├── AstryxAudioEngine/  # Playback coordinator, queue controller, session
│   ├── LibraryEngine/      # Track/Album/Artist models, indexing, storage
│   ├── SearchEngine/       # Indexed universal search (<50ms)
│   ├── MetadataEngine/     # Format support, normalization
│   ├── DownloadEngine/     # State machine: Queued→Downloading→Paused→Retry→Completed→Failed
│   ├── DSP/                # EQ, Spectrum, ReplayGain-ready
│   ├── EventBus/           # Typed event bus for loose coupling
│   ├── CapabilityRegistry/ # Optional features registry
│   ├── ProviderLayer/      # Replaceable services
│   └── Shared/             # Domain entities, protocols
├── Features/               # Feature modules (Presentation + Domain)
│   ├── Player/
│   ├── Library/
│   ├── Search/
│   ├── Lyrics/
│   ├── Discovery/TasteDNA/
│   ├── AudioLab/
│   ├── Dashboard/
│   ├── Spaces/
│   └── TimeCapsule/
├── Platform/               # iOS-specific adapters
│   ├── Audio/              # AVFoundationAdapter
│   ├── Persistence/        # SwiftDataAdapter
│   ├── Haptics/            # HapticEngine
│   └── System/             # NowPlayingManager, BackgroundTaskManager
├── DesignSystem/           # Midnight Aurora
│   ├── Theme/              # Colors, Typography, Theme
│   ├── Components/         # AstryxButton, Card, Artwork, Slider, MiniPlayer, Sheet, NavigationBar
│   └── Foundations/        # Spacing, CornerRadius, Animation
├── Docs/                   # Engineering documentation
│   ├── ADR/                # Architecture Decision Records
│   ├── EPL/                # Progress Ledger
│   ├── IL/                 # Integration Log
│   ├── SHM/                # Research Registry
│   └── ACC/                # Build Control Center (live dashboard)
├── Tests/                  # XCTest
├── Scripts/                # bootstrap, lint, generate-docs
└── .github/workflows/      # CI
```

---

## Design System — Midnight Aurora

**Theme:** Midnight Aurora — dark-first, premium, artwork-centric

**Color Tokens:**
| Token | Value | Usage |
|-------|-------|-------|
| Aurora Blue | #3B82F6 | Primary, active |
| Midnight | #050816 | Background |
| Emerald | #10B981 | Success, playing |
| Sunset | #F97316 | Warning, favorite |
| Ice White | #F8FAFC | Text, foreground |

**Typography:**
- Logo → Space Grotesk
- Heading → SF Pro Display
- Body → SF Pro Text

**Components (all prefixed Astryx):**
- AstryxButton, AstryxCard, AstryxArtwork, AstryxSlider, AstryxMiniPlayer, AstryxSheet, AstryxNavigationBar

**Principle:** Album artwork is primary visual anchor.

---

## Technology Stack

| Layer | Technology |
|-------|------------|
| UI | SwiftUI |
| Audio | AVFoundation (isolated in Platform) |
| Persistence | SwiftData (abstracted) |
| Search | Indexed Engine (in-memory inverted index) |
| Architecture | Clean Modular |
| Testing | XCTest |
| CI | GitHub Actions (macOS 14, Xcode 15) |

**Supported Formats:** MP3, AAC, M4A, ALAC, FLAC, WAV, AIFF, OGG, OPUS

---

## Getting Started

### Requirements
- Xcode 15+
- iOS 17+
- Swift 5.9+
- macOS 14+ for development

### Bootstrap
```bash
./Scripts/bootstrap.sh
```

This will:
- Check Xcode and Swift
- Install SwiftLint and XcodeGen if needed
- Generate Xcode project from project.yml
- Build SPM modules

### Manual Setup
```bash
# Install tools
brew install swiftlint xcodegen

# Generate Xcode project
xcodegen generate

# Build
swift build
swift test
```

### Project Generation
We use XcodeGen with `project.yml` to keep project file out of git and maintain clean structure.

---

## Development Workflow — Arena Operating Workflow

Every Arena session follows:

```
Read ACC → Read AGENT_STATE → Read ADR → Read IL → Read SHM → Create Feature Branch → Implement → Run Tests → Update Docs → Stop
```

**Branch Convention:** `feature/QEL-001-foundation`, `feature/QEL-012-player`, `feature/QEL-024-library`

**Commit Convention:** `feat(player): implement Astryx playback coordinator`

**Quality Gates:**
- Build passes
- Tests pass
- Documentation updated (ADR/EPL/IL/SHM/ACC)
- Architecture respected (no layer violation)
- Public naming uses QELORYX/Astryx

---

## Documentation

### ACC — Astryx Control Center
Live dashboard at `Docs/ACC/ACC.md` — source of truth for version, milestone, build status, next actions.

**Current:** 0.1.0-dev Foundation, Build Passing, Next Astryx Player

### ADR — Architecture Decision Records
- ADR-001: Greenfield architecture
- ADR-002: Modular core engines
- ADR-003: EventBus decoupling
- ADR-004: Offline-first with SwiftData
- ADR-005: Midnight Aurora design system

### EPL — Engineering Progress Ledger
`Docs/EPL/EPL-001-foundation.md` — tracks foundation milestone progress

### IL — Integration Log
`Docs/IL/IL-001-foundation.md` — records integrations, license compliance

### SHM — Engineering Research Registry
`Docs/SHM/SHM-001-research-registry.md` — research of public projects for patterns (no code reuse, patterns only)

---

## Performance Budget

| Metric | Target |
|--------|--------|
| Cold Launch | <1.5s |
| Warm Launch | <0.6s |
| Search | <50ms |
| Library Open | <200ms |
| Queue | Instant |

---

## Roadmap

| Version | Goal |
|---------|------|
| 0.1.0-dev | Foundation — architecture, design system, core contracts ✅ |
| 0.1.0-alpha.1 | First Alpha — playback coordinator, queue, background |
| 0.2.0-alpha | Library — multi-library, grouping, indexing, artwork cache |
| 0.3.0-alpha | Lyrics — LRC, synced, karaoke |
| 0.4.0-alpha | Downloads — state machine, resume, retry, priority queue |
| 0.5.0-alpha | Discovery — Taste DNA, Time Capsule, Spaces |
| 0.9.0-beta | Polish — performance, accessibility, Audio Lab |
| 1.0.0 | Stable — App Store ready |

---

## Engineering Research Policy

Per Genesis Bible:

> Arena Agent may study well-engineered public projects to understand proven architectural patterns, playback workflows, indexing strategies, UX behaviors, and modular design ideas.
> When implementing a capability inside QELORYX:
> - Build it within QELORYX’s own architecture.
> - Keep public APIs and naming consistent with QELORYX.
> - Respect the license of any upstream code that is actually reused.
> - Record engineering research inside SHM.
> - Record completed integrations inside IL.

Commercial products (Spotify, Apple Music, Plexamp, Tidal, SoundCloud) are UX inspiration, not code sources.

---

## Launch Readiness Checklist

- [ ] Reserve qeloryx.com
- [ ] Reserve qeloryx.app
- [ ] Reserve GitHub Organization
- [ ] Reserve social handles
- [ ] Trademark clearance (Class 9 & 42)
- [ ] App Store assets
- [ ] Privacy Policy
- [ ] Terms
- [ ] Accessibility audit
- [ ] Performance audit

---

## License

Proprietary — Qeloryx Labs. All rights reserved.

QELORYX identity, architecture, naming, design system, and public APIs belong entirely to QELORYX.

---

## CEO Final Directive

> Treat QELORYX as a long-term premium software company, not a hackathon project. Engineer every capability as a first-class part of the QELORYX ecosystem, keep the architecture modular and future-proof, maintain consistent branding across every surface, and ensure every completed milestone leaves the repository cleaner, faster, and easier to extend than before.

---

*Built with Midnight Aurora 🌌 — Qeloryx Labs*
