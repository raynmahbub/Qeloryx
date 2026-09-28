# IL-004: Lyrics++ Integration Log — QEL-032

## Date
2026-09-28

## Scope
Lyrics++ production implementation, integration across Core/ProviderLayer/Features/DesignSystem

## Changes

### Core/ProviderLayer/LyricsProvider/LyricsProvider.swift — Rewritten to Production
- Enhanced models: AstryxLyricWord (id, text, startTime, endTime), AstryxLyricLine (id, text, startTime, endTime, words, isTranslation, translation, isKaraoke computed), AstryxLyrics (trackID, lines, isSynced, language, translations dict, source, isKaraoke, metadata, currentLine(at:), currentLineIndex(at:), translation(for:)), LyricsMetadata (title, artist, album, author, offset)
- Protocol enhanced: fetchLyrics(for:language:) + parseEnhancedLRC
- AstryxLyricsProvider production: fetchLyrics tries embedded lyrics (detect < > for enhanced), fileURL.deletingPathExtension().lrc, explicit lrcURL, fetchLyrics for language tries song.{lang}.lrc, parseLRC with multiple timestamps, metadata, offset, parseEnhancedLRC with word regex <mm:ss.xx>word, plainText rebuild, word end times
- No external reuse, greenfield implementation

### Core/ProviderLayer/LyricsProvider/LyricsEngine.swift — NEW
- Protocol LyricsEngineProtocol: loadLyrics(for:), loadLyrics(for:language:), currentLyrics(), currentLine(at:), currentLineIndex(at:), currentWord(at:), setLyrics(_:), clear(), isKaraokeAvailable(), availableLanguages()
- AstryxLyricsEngine: _currentLyrics with NSLock, providers array, eventBus, subscriptionStore, observePlayback via trackStarted, loadLyrics tries each provider then loads translations for ["es","fr","de","ja","ko","zh","bn"], currentLine/Word via lyrics methods, thread-safe, setLyrics, clear, isKaraokeAvailable, availableLanguages
- Architecture: Core owns engine, Platform not needed for offline-first, but ready for embedded lyrics via MetadataExtractor future

### Features/Lyrics/Presentation/ViewModels/LyricsViewModel.swift — NEW
- LyricsDisplayMode: synced, karaoke, plain, fullscreen with icons
- @MainActor, @Published lyrics, currentLineIndex, currentWordIndex, currentTime, isLoading, errorMessage, displayMode, selectedLanguage, availableLanguages, showTranslation, translationLanguage, isFullscreen, autoScroll
- Dependencies: lyricsEngine, playerEngine, eventBus
- Timer every 0.1s for karaoke smoothness
- Observes trackStarted, playbackStateChanged
- updateCurrentPosition uses playerEngine.currentTime, finds line index, and word index if karaoke
- Actions: loadLyrics, loadTranslation, toggleTranslation, setDisplayMode, seekToLine, seekToWord, toggleAutoScroll, clear, formattedTime
- No business logic in View, all in VM

### Features/Lyrics/Presentation/LyricsView.swift — Rewritten to Production
- Uses DesignSystem AstryxColors + AstryxTypography
- States: loading, content, empty, error
- contentView: headerView + ScrollViewReader + bottomControls
- headerView: metadata title/artist, modeSelector capsules, karaoke badge, language picker, auto-scroll toggle
- modeSelector: synced/karaoke/plain with blue selected
- lyricLineView: delegates to standard or karaoke based on displayMode
- standardLineView: text bold+scale when current, translation secondary
- karaokeLineView: FlowLayout for words, word highlighting current blue bold scale 1.1, past iceWhite, future opacity 0.6, tap to seek word
- FlowLayout custom Layout for wrapping
- bottomControls: currentTime mono, lines count, fullscreen
- menuButton: Menu with mode, fullscreen, auto-scroll, translation submenu
- languagePickerSheet: List of availableLanguages
- fullscreenView: fullScreenCover with larger fonts 32/24 centered, word-level, xmark dismiss
- Integration: onAppear load, onDisappear clear, onChange currentLineIndex scrollTo center

### Platform/Audio/MetadataExtractor.swift — Existing, compatible
- Already extracts lyrics? Could be enhanced future to extract embedded lyrics via AVAsset, but QEL-032 offline-first local LRC sufficient

### Tests/CoreTests/LyricsPlus_Tests.swift — NEW
- 9 tests covering LRC parsing, enhanced karaoke, multiple timestamps, metadata offset, currentLine, karaoke word, translation-ready, engine, performance <50ms

### Docs
- ADR-008: Lyrics++ architecture decision
- EPL-004: Progress ledger
- IL-004: This file
- SHM-004: Research
- ACC: Updated to 0.3.0-alpha

## Integration Points
- Core -> Features: LyricsEngine provides lyrics to ViewModel, ViewModel uses PlayerEngine currentTime for sync
- Features -> DesignSystem: LyricsView uses AstryxColors + AstryxTypography
- EventBus: trackStarted triggers auto-load placeholder, playbackStateChanged triggers position update
- Translation-ready: song.{lang}.lrc files, no code change for new language, includes bn (Bengali) for BD user

## No External Code Reuse
All implementation greenfield, QELORYX owned. No copy from Spotify/Apple Music/Plexamp/Tidal/SoundCloud. Research only from LRC spec.

## Verification
- Build: 115+ Swift files
- Tests: LyricsPlus_Tests 9 tests
- Architecture: No layer violation (Core not importing SwiftUI, Platform isolated)
- Performance: Lyrics sync <50ms, karaoke <100ms via 100ms timer

*QELORYX — Hear Beyond. Build Beyond.*
