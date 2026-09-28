# ADR-002: Modular Core Engines

**Date:** 2026-09-28
**Status:** Accepted
**Tags:** architecture, modularity, clean-architecture

## Context
Need to define how business logic is organized to achieve:
- Offline-first
- Testable code
- Cross-platform preservation
- Native performance

Monolithic architecture would couple UI to playback to persistence, making testing and portability hard.

## Decision
Adopt **Clean Modular** architecture with layered separation:

```
Presentation (SwiftUI)
   ↓
Application (Use Cases, ViewModels)
   ↓
Domain (Entities, Protocols, pure Swift)
   ↓
Core Engines (AstryxAudioEngine, LibraryEngine, QueueEngine, SearchEngine, MetadataEngine, DownloadEngine, DSP)
   ↓
Platform (AVFoundationAdapter, SwiftDataAdapter, Haptics, System)
```

**Core Layout:**
- Core/AstryxAudioEngine — Playback coordinator, queue controller, audio session
- Core/LibraryEngine — Track/Album/Artist models, indexing, storage
- Core/QueueEngine — Queue manipulation logic (may merge with AudioEngine initially, but keep separate protocol)
- Core/SearchEngine — Indexed universal search
- Core/MetadataEngine — Format support, normalization
- Core/DownloadEngine — State machine for offline
- Core/DSP — EQ, ReplayGain, Spectrum
- Core/EventBus — Decoupled communication
- Core/CapabilityRegistry — Optional features registry
- Core/ProviderLayer — Replaceable services (LyricsProvider, ArtworkProvider, etc.)

**Rules:**
- SwiftUI stays inside Presentation
- Business logic never enters Views
- Platform APIs stay isolated in Platform/
- Communication happens through EventBus
- Each engine exposes protocol, implementation is internal
- Shared business logic must remain portable (no iOS-only types in Domain)

## Consequences
**Positive:**
- Each engine testable in isolation
- Easy to replace Platform adapters for Android/macOS
- Clear ownership

**Negative:**
- More protocols and indirection initially
- Need EventBus discipline

## Implementation
- Define protocols in Core/Shared/Protocols
- Entities in Core/Shared/Domain/Entities (or LibraryEngine/Models for specific)
- Engines depend only on protocols, not concrete Platform types
- Use dependency injection via ProviderRegistry and CapabilityRegistry

## References
- Genesis Bible — Architectural Layers
- ADR-003 for EventBus details

---
*QELORYX — Modular by default*
