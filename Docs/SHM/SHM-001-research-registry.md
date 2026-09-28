# SHM-001: Engineering Research Registry

**Date:** 2026-09-28
**Milestone:** 0.1.0-dev Foundation
**Purpose:** Record engineering research of well-engineered public projects to understand proven patterns. Per Genesis Bible Engineering Research Policy.

> Arena Agent may study well-engineered public projects to understand proven architectural patterns, playback workflows, indexing strategies, UX behaviors, and modular design ideas.
> When implementing a capability inside QELORYX:
> - Build it within QELORYX’s own architecture.
> - Keep public APIs and naming consistent with QELORYX.
> - Respect the license of any upstream code that is actually reused.
> - Record engineering research inside SHM.
> - Record completed integrations inside IL.

---

## Research Entries

### SHM-R-001: Modular Clean Architecture in Music Apps
**Date:** 2026-09-28
**Projects Studied:** General iOS clean architecture references, TCA (The Composable Architecture) concepts, VIPER, Clean Swift
**Patterns Observed:**
- Presentation → Application → Domain → Data layering
- Use of protocols for dependency inversion
- Coordinator pattern for navigation
- Event-driven communication vs direct coupling

**QELORYX Application:**
- Adopted Presentation ↓ Application ↓ Domain ↓ Core Engines ↓ Platform
- AppCoordinator for root navigation
- EventBus for cross-engine communication instead of direct dependencies
- ProviderLayer for replaceable services

**Code Reuse:** None — patterns only, implementation is QELORYX-owned
**License Impact:** None

---

### SHM-R-002: AVFoundation Playback Workflows
**Date:** 2026-09-28
**Projects Studied:** Apple AVFoundation documentation, public AVPlayer examples, background playback handling
**Patterns Observed:**
- AVPlayer + AVPlayerItem for playback
- AVAudioSession for session management
- MPNowPlayingInfoCenter for lock screen
- MPRemoteCommandCenter for remote controls
- Background modes: audio, background fetch
- Queue management via custom controller, not AVQueuePlayer alone (more control)

**QELORYX Application:**
- AstryxAudioEngine/Playback/AstryxPlaybackCoordinator — independent coordinator, not tied to view
- Queue/QueueController — isolated queue logic with shuffle/repeat
- Session/AudioSessionManager — audio session handling
- Platform/Audio/AVFoundationAdapter — isolates AVFoundation
- Platform/System/NowPlayingManager — isolates MediaPlayer

**Code Reuse:** None — implemented from Apple docs understanding
**License Impact:** Apple SDK, per developer agreement

---

### SHM-R-003: SwiftData Offline-First Patterns
**Date:** 2026-09-28
**Projects Studied:** Apple SwiftData documentation, WWDC 2023 SwiftData sessions
**Patterns Observed:**
- @Model macro for persistence models
- ModelContainer + ModelContext
- Predicate-based queries
- Relationship handling
- Incremental updates via history

**QELORYX Application:**
- LibraryEngine/Storage/SwiftDataStack protocol abstracts SwiftData
- Models: Track, Album, Artist, Playlist as @Model (or struct with mapping)
- LibraryIndexer for incremental indexing
- ArtworkCache with file system + LRU

**Code Reuse:** None
**License Impact:** Apple SDK

---

### SHM-R-004: Indexed Search for Music Libraries
**Date:** 2026-09-28
**Projects Studied:** General search engine patterns, inverted index, prefix search, fuzzy search
**Patterns Observed:**
- In-memory inverted index for instant search (<50ms)
- Tokenization + normalization (lowercase, diacritic folding)
- Ranking by recency, play count, favorites
- Universal search across Song, Artist, Album, Playlist, Folder, Lyrics

**QELORYX Application:**
- SearchEngine/IndexedSearch — in-memory index
- SearchResult with type and score
- EventBus listens to libraryDidChange to rebuild index incrementally
- Command palette + keyboard shortcuts (future)

**Code Reuse:** None — custom implementation

---

### SHM-R-005: Download State Machine
**Date:** 2026-09-28
**Projects Studied:** URLSession background download patterns, download managers
**Patterns Observed:**
- State machine: Queued → Downloading → Paused → Retry → Completed → Failed
- Resume data for paused downloads
- Priority queue
- Retry with exponential backoff

**QELORYX Application:**
- DownloadEngine/DownloadState enum with all states
- DownloadTask with resume data, priority, retry count
- DownloadEngine actor managing queue

**Code Reuse:** None

---

### SHM-R-006: DSP and Audio Processing
**Date:** 2026-09-28
**Projects Studied:** Apple Accelerate, Audio Unit, EQ patterns
**Patterns Observed:**
- EQ as array of bands with frequency, gain, Q
- ReplayGain as metadata, not processing
- Spectrum analyzer via FFT
- Signal path visualization

**QELORYX Application:**
- DSP/DSPEngine protocol
- DSP/EQ/Equalizer with bands
- DSP/Spectrum/SpectrumAnalyzer placeholder for future Accelerate integration
- Architecture ready for ReplayGain, Crossfade

**Code Reuse:** None — placeholder architecture, future implementation with Accelerate

---

### SHM-R-007: Design System — Premium Music Apps UX Inspiration
**Date:** 2026-09-28
**Projects Studied (UX only, not code):** Spotify, Apple Music, Plexamp, Tidal, SoundCloud (per Bible: treat as UX inspiration, not code sources)
**UX Patterns Observed:**
- Album artwork as primary visual anchor
- Dark mode first (Midnight theme)
- Mini player persistent at bottom
- Gesture-driven (swipe to queue, long press for actions)
- Haptic feedback for premium feeling
- Blurred backgrounds from artwork

**QELORYX Application:**
- Astryx Design System — Midnight Aurora theme
- AstryxArtwork component with dominant color extraction (future)
- AstryxMiniPlayer, AstryxCard with artwork focus
- HapticEngine for feedback

**Code Reuse:** None — UX inspiration only

---

### SHM-R-008: Lyrics++ and LRC Format
**Date:** 2026-09-28
**Projects Studied:** LRC format spec, synced lyrics display patterns
**Patterns Observed:**
- LRC: [mm:ss.xx] lyrics line
- Word-level timing for karaoke
- Translation support via separate tracks

**QELORYX Application:**
- Future Features/Lyrics — LRC parser planned
- LyricsProvider protocol in ProviderLayer
- Translation-ready architecture (multiple language tracks)

**Code Reuse:** None yet — future implementation

---

## Summary
- Total research entries: 8
- Code reused: 0 (patterns only)
- License violations: 0
- All implementations are QELORYX-owned greenfield

## Next Research
- QEL-012 Player: Deep dive into Dynamic Island, Live Activities, AirPlay 2
- QEL-024 Library: Study incremental indexing at scale (10k+ tracks)
- Taste DNA: Research music recommendation without server (on-device ML)

---
*SHM maintained by Arena Agent — Engineering Research Registry*
