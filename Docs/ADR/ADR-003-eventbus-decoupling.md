# ADR-003: EventBus Decoupling

**Date:** 2026-09-28
**Status:** Accepted
**Tags:** architecture, eventbus, decoupling

## Context
Multiple engines need to react to same domain events:
- TrackStarted → History, Lyrics, Visualizer, Discovery, Audio Lab
- LibraryChanged → Search index rebuild, UI refresh
- DownloadCompleted → Library insertion

Direct coupling would create spaghetti dependencies.

## Decision
Implement **typed EventBus** as central nervous system.

**Design:**
- EventBus is singleton (or injected) publisher
- Events are value types: `QeloryxEvent` enum with associated values
- Subscribers use `EventSubscription` token for cancellation
- Thread safety via actor or serial queue
- No event should carry UIKit/SwiftUI types

**Event Flow Example:**
```
TrackStarted
  ↓
History (record)
  ↓
Lyrics (fetch)
  ↓
Visualizer (start)
  ↓
Discovery (update Taste DNA)
```

**Event Categories:**
- PlaybackEvents: trackStarted, trackPaused, trackEnded, queueChanged, seeked
- LibraryEvents: libraryDidChange, trackAdded, trackRemoved, artworkUpdated
- SearchEvents: indexUpdated
- DownloadEvents: downloadStateChanged
- SystemEvents: audioSessionInterrupted, appDidEnterBackground

## Consequences
**Positive:**
- Loose coupling everywhere
- Easy to add new listeners without changing emitter
- Testable via mock EventBus

**Negative:**
- Debugging event flow can be harder (need logging)
- Risk of event explosion if not curated

**Mitigation:**
- All events documented in QeloryxEvent.swift
- EventBus has debug logging in DEBUG builds
- Use structured events, not stringly-typed

## Implementation
- Core/EventBus/EventBus.swift — actor-based implementation
- Core/EventBus/QeloryxEvent.swift — all events
- Core/EventBus/EventSubscription.swift — cancellable token

## References
- Genesis Bible — Event Bus section
- Similar patterns: NotificationCenter but typed, Combine, AsyncStream

---
*QELORYX — Loose coupling everywhere*
