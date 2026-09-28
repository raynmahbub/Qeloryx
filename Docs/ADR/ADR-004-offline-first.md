# ADR-004: Offline-First Architecture

**Date:** 2026-09-28
**Status:** Accepted
**Tags:** architecture, offline-first, persistence, SwiftData

## Context
QELORYX target experience is premium offline-first. Users expect:
- Library works without network
- Playback works without network
- Search works without network
- Downloads resumable

We need persistence that supports:
- Complex relationships (Track → Album → Artist)
- Incremental indexing
- Artwork cache
- Fast queries (<50ms search, <200ms library open)

## Decision
Use **SwiftData** as primary persistence (iOS 17+), with abstraction layer.

**Stack:**
- Persistence: SwiftData (Apple's modern persistence over Core Data)
- Abstraction: `SwiftDataStack` protocol in Core, `SwiftDataAdapter` in Platform
- Cache: File system for artwork + in-memory LRU
- Search: Indexed Engine built on top of SwiftData, with in-memory inverted index for instant search

**Principles:**
- Source of truth is local database
- Network is additive (optional providers fetch metadata/artwork/lyrics but don't block)
- All writes go through LibraryEngine → SwiftDataStack
- All reads go through LibraryEngine → SwiftDataStack → Models
- DownloadEngine writes to file system + updates SwiftData
- SearchEngine maintains its own index, rebuilt on LibraryChanged events

**Supported Formats:**
MP3, AAC, M4A, ALAC, FLAC, WAV, AIFF, OGG, OPUS — metadata parsing via MetadataEngine, not SwiftData

## Consequences
**Positive:**
- True offline-first
- Fast local queries
- SwiftData is native, future-proof, SwiftUI-friendly
- Portable logic: abstraction allows future Android Room implementation with same Domain models

**Negative:**
- SwiftData iOS 17+ only (acceptable per Phase 1 target)
- Need to handle migrations

**Mitigation:**
- Keep SwiftData models simple, versioned
- Metadata normalization in separate layer (MetadataNormalizer)

## Implementation
- Core/LibraryEngine/Storage/SwiftDataStack.swift — protocol
- Platform/Persistence/SwiftDataAdapter.swift — concrete implementation
- Core/LibraryEngine/Models — @Model definitions
- Core/LibraryEngine/Indexing — incremental indexer

## Performance Budget Alignment
- Library Open <200ms → SwiftData fetch with predicate + in-memory cache
- Search <50ms → In-memory inverted index, not SwiftData query

## References
- Genesis Bible — Library DNA, Engineering Principles
- Apple SwiftData documentation

---
*QELORYX — Offline-first, always*
