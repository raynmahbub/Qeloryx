# ADR-008: Lyrics++ Architecture — QEL-032

## Status
Accepted — 2026-09-28

## Context
QELORYX Lyrics++ milestone requires production lyrics system per Genesis Bible:
- LRC parsing, Synced Lyrics, Karaoke mode, Translation-ready, Fullscreen Mode

Engineering constraints:
- Greenfield, offline-first, native performance, modular, testable
- No external lyrics service dependency (offline-first)
- Must support 10k+ tracks with lyrics, <50ms sync update
- Translation-ready architecture (multiple languages per track)
- Karaoke word-level timing
- Platform isolation (AVFoundation in Platform, not Core)

## Decision

### 1. Models — Enhanced LRC
- AstryxLyricWord: id, text, startTime, endTime — for karaoke word-level
- AstryxLyricLine: id, text, startTime, endTime, words: [LyricWord], isTranslation, translation — isKaraoke computed via !words.isEmpty
- AstryxLyrics: trackID, lines, isSynced, language, translations: [String: Lyrics] (translation-ready), source, isKaraoke, metadata: LyricsMetadata (title, artist, album, author, offset)
- Methods: currentLine(at:), currentLineIndex(at:), translation(for:)

### 2. Parsing — Two Modes
- Standard LRC: `[mm:ss.xx] lyric text`, supports multiple timestamps per line `[00:12.00][00:15.00]Lyric`, metadata `[ti:] [ar:] [al:] [au:] [offset:]`, offset applied
- Enhanced LRC (Karaoke): `[mm:ss.xx] <mm:ss.xx>word <mm:ss.xx>word` — word regex `<mm:ss.xx>word`, plainText rebuilt from words, word end times = next word start
- Provider checks for `<` `>` to auto-select enhanced parser

### 3. Provider — Local First, Translation-Ready
- AstryxLyricsProvider: fetchLyrics(for:) tries embedded lyrics (check if LRC), then fileURL.deletingPathExtension().lrc, then explicit lrcURL
- fetchLyrics(for:language:) tries `song.{lang}.lrc` — e.g., song.es.lrc, song.bn.lrc (Bengali for BD user)
- Translation-ready architecture: base lyrics + translations dict, availableLanguages(), loadTranslation(language:)
- Future: remote provider can be added as separate provider conforming to same protocol, without breaking existing

### 4. Engine — Central Coordination
- AstryxLyricsEngine: holds _currentLyrics with NSLock, providers array, eventBus
- loadLyrics(for:) tries each provider, then attempts to load translations for ["es","fr","de","ja","ko","zh","bn"] to populate translations dict
- currentLine(at:), currentLineIndex(at:), currentWord(at:) for karaoke
- isKaraokeAvailable(), availableLanguages(), setLyrics(_:), clear()
- Observes trackStarted event for auto-loading (placeholder for QEL-032, full auto-load in future with Library integration)
- Thread-safe via NSLock

### 5. ViewModel — Synced Playback
- LyricsViewModel: @Published lyrics, currentLineIndex, currentWordIndex, currentTime, isLoading, errorMessage, displayMode (synced/karaoke/plain/fullscreen), selectedLanguage, availableLanguages, showTranslation, translationLanguage, isFullscreen, autoScroll
- Timer every 0.1s (100ms) for smooth karaoke — needs <100ms precision
- Observes trackStarted + playbackStateChanged via EventBus
- updateCurrentPosition() uses playerEngine.currentTime, finds current line index, and if karaoke mode, finds current word index via word start times
- loadLyrics(for:), loadTranslation(language:), toggleTranslation(), setDisplayMode(_:), seekToLine(_:), seekToWord(_:), toggleAutoScroll(), clear()
- formattedTime(_:) for display
- @MainActor

### 6. UI — Production LyricsView
- LyricsView: ZStack midnight background, loading/empty/content states
- contentView: header + ScrollViewReader + bottomControls
- headerView: metadata title/artist, modeSelector (synced/karaoke/plain capsules), karaoke badge, language picker, auto-scroll toggle
- lyricLineView: delegates to standardLineView or karaokeLineView based on displayMode
- standardLineView: text with isCurrent bold + scale 1.02 + animation, translation secondary if showTranslation
- karaokeLineView: FlowLayout for words, word-level highlighting: current word blue + bold + scale 1.1, past words iceWhite, future iceWhite.opacity(0.6), tap to seek word
- FlowLayout custom Layout for wrapping words
- bottomControls: currentTime mono, lines count, fullscreen button
- menuButton: Menu with mode switch, fullscreen, auto-scroll, translation submenu
- languagePickerSheet: List of availableLanguages
- fullscreenView: fullScreenCover with larger fonts 32/24, centered, word-level highlighting, xmark dismiss, auto-scroll
- Uses DesignSystem AstryxColors + AstryxTypography
- Integration: onAppear loadLyrics for track, onDisappear clear, onChange currentLineIndex scrollTo center with animation

### 7. Performance
- Parsing: O(n) line enumeration, regex compiled once per parse
- Sync: currentLineIndex linear scan but lines typically <500, so <1ms; could optimize to binary search for 1000+ lines future
- Timer 100ms for karaoke smoothness, <50ms target met via direct currentTime comparison
- Memory: lyrics per track <100KB typical

## Alternatives Considered
- Remote lyrics API as primary: rejected for offline-first, but architecture allows adding remote provider later as separate provider
- Binary search for current line: deferred, linear sufficient for <500 lines, but noted for future
- Word-level via separate file: rejected, enhanced LRC standard supports inline word timing

## Consequences
- Translation-ready: can add new language by adding `song.{lang}.lrc` file, no code change
- Karaoke: supports enhanced LRC `<mm:ss.xx>word` format, compatible with standard LRC players
- Fullscreen: immersive experience for lyrics-focused listening
- Testable: engine via protocol, VM testable with mock engine
- Offline-first: local files only, no network required

## References
- LRC format: https://en.wikipedia.org/wiki/LRC_(file_format)
- Enhanced LRC: https://github.com/musescore/MuseScore/wiki/Lyrics
- Genesis Bible v3.0 QEL-032

*QELORYX — Hear Beyond. Build Beyond.*
