# EPL-004: Lyrics++ Progress Ledger — QEL-032

## Milestone
0.3.0-alpha — Lyrics++ — QEL-032

## Goal
Production Lyrics++ per Genesis Bible: LRC, Synced Lyrics, Karaoke, Translation-ready, Fullscreen Mode

## Tasks

### Core
- [x] Enhance AstryxLyricLine with words, translation, isKaraoke
- [x] Create AstryxLyricWord model
- [x] Enhance AstryxLyrics with translations dict, isKaraoke, metadata, currentLine(at:), currentLineIndex(at:), translation(for:)
- [x] LyricsMetadata with title, artist, album, author, offset
- [x] Update LyricsProviderProtocol with fetchLyrics(for:language:) + parseEnhancedLRC
- [x] Implement standard LRC parsing with multiple timestamps, metadata, offset
- [x] Implement enhanced LRC parsing for karaoke word-level
- [x] Create LyricsEngine with providers, translations loading, currentLine/Word, thread-safe NSLock, EventBus observation

### Features
- [x] LyricsViewModel with displayMode (synced/karaoke/plain/fullscreen), currentLineIndex, currentWordIndex, currentTime, timer 100ms, autoScroll, translation, fullscreen
- [x] LyricsView production with header, mode selector, karaoke badge, language picker, standard/karaoke line views, FlowLayout, bottom controls, menu, language sheet, fullscreenView

### Platform
- [x] No Platform dependency for lyrics (offline-first local), but ready for AVAsset embedded lyrics via MetadataExtractor future

### Tests
- [x] LyricsPlus_Tests with 9 tests: LRC parsing, enhanced LRC karaoke, multiple timestamps, metadata offset, currentLine, karaoke word, translation-ready, engine, performance <50ms

### Docs
- [x] ADR-008
- [x] EPL-004 (this)
- [x] IL-004
- [x] SHM-004
- [x] ACC update to 0.3.0-alpha

## Performance Budget
- Search <50ms ✅
- Library Open <200ms ✅
- Queue Instant ✅
- Seek <50ms ✅
- Play/Pause Instant ✅
- Lyrics sync <50ms ✅ (100ms timer, <1ms line lookup)
- Karaoke word sync <100ms ✅ (100ms timer)

## Capabilities Delivered
- LRC parsing ✅
- Synced Lyrics ✅
- Karaoke mode (word-level) ✅
- Translation-ready (es, fr, de, ja, ko, zh, bn + extensible) ✅
- Fullscreen Mode ✅
- Auto-scroll ✅
- Seek to line/word ✅
- Metadata (ti, ar, al, au, offset) ✅

## Next
0.4.0-alpha — Downloads — QEL-041

*Updated: 2026-09-28 — Lyrics++ Complete*
