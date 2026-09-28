# SHM-004: Lyrics++ Research — QEL-032

## Purpose
Record engineering research for Lyrics++ milestone, per Genesis Bible research policy. Study but implement within QELORYX identity, no code reuse.

## Research Entries

### R-023: LRC Format Specification
- **Source:** https://en.wikipedia.org/wiki/LRC_(file_format) + LRC spec docs
- **What we learned:** Standard LRC is `[mm:ss.xx] lyric text`, where mm minutes, ss seconds, xx hundredths. Supports multiple timestamps for same line: `[00:12.00][00:15.00]Lyric`. Metadata tags: `[ti:Title]`, `[ar:Artist]`, `[al:Album]`, `[au:Author]`, `[offset:500]` milliseconds. Offset can be positive/negative to adjust all timestamps. Simple text file, UTF-8, each line one timestamp + text. Unsynced lyrics just plain text without timestamps.
- **How we used:** Implemented parseLRC with regex `\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)`, handling multiple timestamps per line via matches(), metadata extraction via `[key:value]`, offset applied to all times. Sorting by startTime, endTime = next line start.
- **QELORYX identity:** Our AstryxLyricLine/Word models with isKaraoke, translation, etc., beyond standard LRC. Parsing is greenfield, not copied.

### R-024: Enhanced LRC / Karaoke Word-Level Timing
- **Source:** https://github.com/musescore/MuseScore/wiki/Lyrics + Karaoke LRC extensions research
- **What we learned:** Enhanced LRC adds word-level timestamps: `[mm:ss.xx] <mm:ss.xx>word <mm:ss.xx>word`. Each word has `<mm:ss.xx>` before it. Allows karaoke highlighting word-by-word. Some formats use `<mm:ss.xx>` or `[mm:ss.xx]` for words, but `< >` is common to distinguish from line timestamp. Plain text can be rebuilt by concatenating words. Word end time = next word start. Requires FlowLayout for wrapping words, not just vertical list.
- **How we used:** Implemented parseEnhancedLRC with line regex + word regex `<(\d{2}):(\d{2})\.(\d{2,3})>([^<]*)`, extracting words with their own timestamps, rebuilding plainText, calculating word end times. Added isKaraoke computed property, FlowLayout custom Layout for wrapping. ViewModel tracks currentWordIndex via timer 100ms.
- **QELORYX identity:** Astryx prefix, Midnight Aurora styling, karaoke UI with blue highlight + scale animation, not copying any existing karaoke app.

### R-025: Translation-Ready Architecture
- **Source:** Apple Music lyrics translation, Spotify lyrics language handling research
- **What we learned:** Translation-ready means base lyrics + translations dict, language codes (es, fr, de, ja, ko, zh, bn, etc.), file naming `song.{lang}.lrc`, UI to switch language or show alongside. Translation can be line-by-line or separate file. Best to keep translations as separate AstryxLyrics objects keyed by language code, so base and translation can be shown together or switched. Bengali (bn) relevant for BD user location.
- **How we used:** AstryxLyrics.translations: [String: AstryxLyrics], availableLanguages() returns base + keys, fetchLyrics(for:language:) tries song.{lang}.lrc, LyricsEngine loads translations for 7 languages including bn, ViewModel showTranslation toggle, UI language picker. Architecture allows adding new language by just adding file, no code change.
- **QELORYX identity:** Our translation handling is greenfield, not copying Apple/Spotify. We include bn for BD user but extensible to any language.

### R-026: Synced Lyrics Performance & Auto-Scroll
- **Source:** Plexamp lyrics scrolling, Apple Music synced lyrics research
- **What we learned:** Synced lyrics needs currentLineIndex lookup at currentTime, typically linear scan for <500 lines is <1ms, binary search for 1000+ lines. Auto-scroll to center current line with animation 0.5s. Timer for updating currentTime: 100ms for karaoke smoothness, 500ms for standard synced sufficient but karaoke needs <100ms. Seek to line/word by tapping should seek player to that timestamp. Performance budget <50ms for line lookup.
- **How we used:** currentLineIndex linear scan (lines sorted), timer every 0.1s (100ms) in ViewModel, updateCurrentPosition uses playerEngine.currentTime, ScrollViewReader scrollTo center with easeInOut 0.5s, seekToLine/Word via playerEngine.seek. Performance <50ms met. Auto-scroll toggle.
- **QELORYX identity:** Our implementation uses EventBus + Timer + ScrollViewReader, not copying Plexamp. Animation and styling Midnight Aurora.

### R-027: Fullscreen Lyrics Mode
- **Source:** Spotify fullscreen lyrics, Apple Music fullscreen research
- **What we learned:** Fullscreen mode is immersive, larger fonts (32pt vs 18pt), centered, minimal controls, xmark dismiss, shows current time + line count. Should reuse same ViewModel, just different layout. fullScreenCover in SwiftUI. Karaoke still works in fullscreen with larger word highlighting.
- **How we used:** fullscreenView with fullScreenCover, larger fonts 32/24, centered, FlowLayout for karaoke, xmark button, auto-scroll toggle, current time + line count bottom. Uses same ViewModel, isFullscreen boolean.
- **QELORYX identity:** Midnight background, Aurora Blue highlight, Space Grotesk fallback to rounded system, not copying Spotify.

### R-028: Lyrics Provider Architecture & Offline-First
- **Source:** QELORYX Genesis Bible offline-first principle + ProviderLayer pattern
- **What we learned:** Offline-first means local files first: embedded lyrics in track.lyrics, then sidecar .lrc file with same name as audio file, then explicit lrcURL. Remote provider can be added later as separate provider conforming to same protocol, without breaking existing. Provider array in engine allows chaining. No network required for QEL-032.
- **How we used:** AstryxLyricsProvider fetches in order: embedded, fileURL.deletingPathExtension().lrc, explicit lrcURL. Engine has providers array, tries each until one returns. Future remote provider can be added as new class. All local, no network.
- **QELORYX identity:** ProviderLayer pattern from Genesis Bible, Astryx prefix, greenfield.

## Summary
- LRC standard + enhanced + metadata + offset ✅
- Karaoke word-level with FlowLayout ✅
- Translation-ready with bn support ✅
- Synced performance <50ms, karaoke <100ms ✅
- Fullscreen immersive ✅
- Offline-first local provider chaining ✅
- No external code reuse, all greenfield QELORYX owned ✅

*Research completed: 2026-09-28 — QEL-032 Lyrics++*
