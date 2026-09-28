# IL-001: Integration Log — Foundation

**Date:** 2026-09-28
**Milestone:** 0.1.0-dev Foundation
**Status:** Completed (scaffold)
**Branch:** arena/01a0e693-qeloryx

## Overview
Foundation milestone establishes greenfield architecture. No external code integrations yet; all modules are QELORYX-owned.

## Integrations

### Core Engines
| Module | Type | Source | License | Integration Notes |
|--------|------|--------|---------|-------------------|
| EventBus | Internal | QELORYX | Proprietary | Actor-based typed bus, no external dep |
| CapabilityRegistry | Internal | QELORYX | Proprietary | Registry pattern for optional features |
| AstryxAudioEngine | Internal | QELORYX | Proprietary | Protocol + coordinator, AVFoundation via Platform adapter |
| LibraryEngine | Internal | QELORYX | Proprietary | SwiftData models, indexing logic |
| SearchEngine | Internal | QELORYX | Proprietary | In-memory inverted index |
| MetadataEngine | Internal | QELORYX | Proprietary | Format support list per spec |
| DownloadEngine | Internal | QELORYX | Proprietary | State machine implementation |
| DSP | Internal | QELORYX | Proprietary | EQ, Spectrum placeholder for future Accelerate |
| ProviderLayer | Internal | QELORYX | Proprietary | Replaceable providers |

### Platform
| Module | Type | Source | License | Notes |
|--------|------|--------|---------|-------|
| AVFoundationAdapter | Apple SDK | Apple | Apple SDK | Isolated in Platform/Audio |
| SwiftDataAdapter | Apple SDK | Apple | Apple SDK | Isolated in Platform/Persistence |
| MediaPlayer (NowPlaying) | Apple SDK | Apple | Apple SDK | Isolated in Platform/System |
| CoreHaptics | Apple SDK | Apple | Apple SDK | Isolated in Platform/Haptics |

### DesignSystem
| Module | Type | Source | License | Notes |
|--------|------|--------|---------|-------|
| Midnight Aurora | Internal | QELORYX | Proprietary | Color tokens, typography, components |
| Space Grotesk | Font | Google Fonts | OFL | Logo font, to be bundled with license file |
| SF Pro | Font | Apple | Apple | System font, no bundling needed |

### Tooling
| Tool | Type | Source | License | Notes |
|------|------|--------|---------|-------|
| SwiftLint | Dev Tool | Realm | MIT | Linting, not shipped |
| XcodeGen | Dev Tool | Yonaskolb | MIT | Project generation |
| GitHub Actions | CI | GitHub | - | macOS runner for iOS builds |

## External Code Reuse
**None** — Foundation is 100% QELORYX-owned greenfield code per Genesis Bible.

Future milestones may study open-source patterns (documented in SHM) but implementation remains QELORYX-owned.

## License Compliance
- All QELORYX code: Proprietary — Qeloryx Labs
- No copyleft code integrated
- Font OFL compliance: Space Grotesk OFL license to be included in App bundle when font file added
- Apple SDKs: Used per Apple Developer Agreement

## Integration Checklist
- [x] No direct Platform API usage in Core/Domain
- [x] All Platform imports isolated
- [x] Public APIs use QELORYX/Astryx naming
- [x] No license violations
- [x] SHM updated with research (if any)

## Next Integrations (Planned)
- QEL-012 Player: AVFoundation concrete playback
- QEL-024 Library: SwiftData concrete implementation
- QEL-0XX Lyrics: LRC parser (may study existing parsers for pattern, but implement own)

---
*IL maintained by Arena Agent*
