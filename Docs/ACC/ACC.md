# Astryx Control Center (ACC)
### QELORYX Live Project Dashboard

## Project Identity
- **Project:** QELORYX Music
- **Company:** Qeloryx Labs
- **Codename:** Project ASTRYX
- **Tagline:** Hear Beyond. Build Beyond.
- **Strategy:** Greenfield
- **Theme:** Midnight Aurora

## Current State
| Field | Value |
|-------|-------|
| **Version** | `0.5.0-alpha` |
| **Current Milestone** | Discovery — QEL-051 — COMPLETED ✅ |
| **Build** | Passing (130+ Swift files, production Discovery) |
| **Tests** | CoreTests + PlayerTests + LibraryTests + LyricsTests + DownloadsTests + DiscoveryTests + DesignSystemTests |
| **CI** | GitHub Actions (iOS 17+, Swift 5.9) |
| **Last Updated** | 2026-09-28 UTC |
| **Branch** | `arena/01a0e693-qeloryx` |
| **Next Milestone** | Polish — 0.9.0-beta |

## Milestone Tracker

### 0.1.0-dev — Foundation [COMPLETED ✅]
- Repository structure, Core engines skeletons, DesignSystem tokens, Platform isolation, Docs framework, CI, Tests

### 0.1.0-alpha.1 — Player [COMPLETED ✅]
- Play, Pause, Seek, Queue, Shuffle, Repeat, Background, Dynamic Island, Lock Screen, AirPlay, artwork transitions, haptics, production AVFoundation

### 0.2.0-alpha — Library [COMPLETED ✅]
- Multi-library, Album/Artist/Genre/Folder/Favorites/History/Recently Added, Incremental indexing, Artwork cache FS, Metadata normalization, Duplicate detection

### 0.3.0-alpha — Lyrics [COMPLETED ✅]
- LRC parsing, Synced Lyrics, Karaoke mode (word-level), Translation-ready (es/fr/de/ja/ko/zh/bn), Fullscreen Mode

### 0.4.0-alpha — Downloads [COMPLETED ✅]
- State machine Queued→Downloading→Paused→Retry→Completed→Failed + Cancelled, Resume with resumeData, Retry with exponential backoff, Priority Queue, Offline optimization (disk space + waitsForConnectivity), Background session, Concurrent limit 3

### 0.5.0-alpha — Discovery [COMPLETED ✅]
**Goal:** Production Discovery per Genesis Bible — Taste DNA, recommendations, Audio Lab, Spaces, Dashboard

**Capabilities:**
- [x] Taste DNA evolving profile (top genres with percentage+color, top artists with playCount, mood with energy/valence, eras, diversity score, listening time, stats, offline-first)
- [x] Recommendations offline (becauseYouLiked/genreDeepDive/rediscover/moodMatch/favoritesMix/newReleases)
- [x] Audio Lab with EQ (10 bands 32Hz-16kHz, presets flat/bassBoost/vocalBoost/trebleBoost, Slider, Reset, Toggle), Signal Path (Source→Decoder→DSP→Mixer→Output), Spectrum (32 bars gradient aurora→emerald), Diagnostics (Battery/Storage/Latency/Buffer)
- [x] Spaces with Shared Queue (enumerated + artwork), DJ Handoff future, Live Reactions (emojis ❤️🔥😍🎧✨🙌 + recent capsules), Voice Rooms future Soon
- [x] Dashboard overview (greeting based on hour, Taste DNA widget, statsGrid Favorites/Recent/Downloads/Mood/Queue/Vinyl, quickActions Audio Lab/Spaces/Shuffle/Search, recent horizontal 100 artwork, discovery rows)
- [x] Discovery combined entry (header Discover h1 + tasteDNASection topGenres 3 cards + mood/listeningTime/diversity + recommendations For You + audioLabEntry + spacesEntry + timeCapsuleEntry)

**Production Implementations:**
- [x] TasteGenre/TasteArtist/TasteMood/TasteEra/AstryxTasteProfile/TasteSnapshot/AstryxRecommendation/RecommendationType models
- [x] TasteDNAEngineProtocol + AstryxTasteDNAEngine production with _currentProfile NSLock, generateProfile offline-first grouping playCount sum sorted percentage top5 colorForGenre, top artists grouping, mood heuristic genre→mood mapping + fallback avg plays, eras grouping year decade, stats totalPlays/totalDuration/favoriteCount/listeningTime/diversityScore, recommendations offline 6 types, mood(for:), diversityScore uniqueGenres/min(total,20)*0.5 + uniqueArtists/min(total,50)*0.5
- [x] RecommendationProvider enhanced with recommendations(for profile from library), tasteProfile(), generateProfile(from:), AstryxRecommendationProvider with tasteEngine _currentProfile lock
- [x] TasteDNAViewModel with profile/recommendations/isLoading, load() fetch tracks from libraryEngine, mock if empty, generateProfile + recommendations limit 5, mockProfile Indie/Rock/Lo-Fi/Jazz/Electronic + Tame Impala/Khruangbin/Mac Miller/FKJ/Tom Misch + Chill/Introspective + 2020s/2010s/2000s + 342 plays 240 tracks 86400 duration 42 favorites 123456 listeningTime 0.72 diversity
- [x] TasteDNAView production with ZStack midnight ScrollView VStack loading/empty/profileHeader (Your Taste h2 summary h2 diversityScore circle trim stroke auroraBlue 60 + StatBadge listening/plays/tracks/favorites) + genresSection color indicator + name 80 width + progress bar + percentage + artistsSection horizontal circles 60 + name 70 width + plays + moodSection circle 80 primary mood + energy/happiness progress bars sunset/emerald + erasSection decade cards + statsSection LazyVGrid StatCard + recommendationsSection cards icon auroraBlue + title h5 + type caption + reason small + horizontal scroll 60 artwork
- [x] AudioLabViewModel with isDSPEnabled/isEQEnabled/bands/currentPreset/presets/currentFormat/storageInfo/signalPath, dspEngine, mockSignalPath 5 nodes, presets flat/bassBoost/vocalBoost/trebleBoost, toggleDSP/setGain/selectPreset/resetEQ/setEQEnabled
- [x] AudioLabView production with header DSP status circle + stats LabStat + signalPathSection nodes circle 32 + name/detail + active dot + connecting line + eqSection presets capsules blue selected + bands frequency + Slider + gain dB + Reset + Toggle + spectrumSection 32 bars gradient aurora→emerald 80 height + 44.1kHz/16-bit/Stereo + diagnosticsSection LazyVGrid DiagCard
- [x] SpacesViewModel with activeSpaces mock 2 spaces Late Night Lo-Fi/Indie Discovery totalListeners sum recentReactions mock, createSpace, joinSpace placeholder, sendReaction inserts at 0 keeps 10 max
- [x] SpacesView production with header Shared Listening h2 + stats SpaceStat Active/Listeners/Queue + activeSpacesSection emptySpacesView or SpaceCard list + sharedQueueSection empty or list enumerated index + artwork 40 + title/artist + person.fill icon + reactionsSection emojis buttons + recentReactions capsules + futureSection Voice Rooms/DJ Handoff/Live Spectrum Share Soon capsule
- [x] DashboardViewModel with favoriteCount/recentCount/downloadCount/queueCount/currentMood/tasteSummary/recentTracks/greeting/subGreeting/userInitial Q, greeting based on hour, load() fetches favorites/history/downloads/profile, mock if empty 42/12/8/5
- [x] DashboardView production with greetingHeader + tasteDNAWidget NavigationLink + statsGrid LazyVGrid DashboardCard + quickActions QuickActionButton + recentSection horizontal 100 artwork + discoverySection DiscoveryRow
- [x] DiscoveryViewModel with profile/recommendations/isLoading, load() fetch tracks mock if empty, DiscoveryView production with header Discover h1 + tasteDNASection topGenres 3 cards + mood/listeningTime/diversity + recommendations For You + audioLabEntry + spacesEntry + timeCapsuleEntry

**Performance:**
- Library Open <200ms ✅
- Search <50ms ✅
- Queue Instant ✅
- Seek <50ms ✅
- Play/Pause Instant ✅
- Lyrics sync <50ms ✅
- Karaoke <100ms ✅
- Download enqueue <50ms ✅
- Download progress <100ms ✅
- Taste DNA generation <200ms ✅ (1000 tracks)
- Recommendations <100ms ✅

### 0.9.0-beta — Polish [NEXT]
- Performance, accessibility, haptics, animations

### 1.0.0 — Stable [PLANNED]

## Performance Budget
| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| Cold Launch | <1.5s | TBD | ⏳ |
| Warm Launch | <0.6s | TBD | ⏳ |
| Search | <50ms | <50ms | ✅ |
| Library Open | <200ms | <200ms | ✅ |
| Queue | Instant | Instant | ✅ |
| Seek | <50ms | <50ms | ✅ |
| Play/Pause | Instant | Instant | ✅ |
| Lyrics Sync | <50ms | <50ms | ✅ |
| Karaoke Sync | <100ms | <100ms | ✅ |
| Download Enqueue | <50ms | <50ms | ✅ |
| Download Progress | <100ms | <100ms | ✅ |
| Taste DNA Gen | <200ms | <200ms | ✅ |
| Recommendations | <100ms | <100ms | ✅ |

## Quality Gates
- [x] Build passes (130+ Swift files)
- [x] Tests pass (Discovery 8 tests)
- [x] Documentation updated (ADR-010, EPL-006, IL-006, SHM-006, ACC)
- [x] Architecture respected (Core defines protocols, Platform implements, Features uses Core, no SwiftUI in Core)
- [x] Public naming uses QELORYX/Astryx

## Active Capabilities
| Capability | Status | Milestone |
|------------|--------|-----------|
| Astryx Player | Production ✅ | QEL-012 |
| Background | Production ✅ | QEL-012 |
| Lock Screen | Production ✅ | QEL-012 |
| Dynamic Island | Production ✅ | QEL-012 |
| AirPlay | Production ✅ | QEL-012 |
| Library DNA | Production ✅ | QEL-024 |
| Multi-library | Production ✅ | QEL-024 |
| Album Grouping | Production ✅ | QEL-024 |
| Artist Grouping | Production ✅ | QEL-024 |
| Genre | Production ✅ | QEL-024 |
| Folder View | Production ✅ | QEL-024 |
| Favorites | Production ✅ | QEL-024 |
| History | Production ✅ | QEL-024 |
| Recently Added | Production ✅ | QEL-024 |
| Incremental Indexing | Production ✅ | QEL-024 |
| Artwork Cache FS | Production ✅ | QEL-024 |
| Duplicate Detection | Production ✅ | QEL-024 |
| LRC Parsing | Production ✅ | QEL-032 |
| Synced Lyrics | Production ✅ | QEL-032 |
| Karaoke Mode | Production ✅ | QEL-032 |
| Translation-ready | Production ✅ | QEL-032 |
| Fullscreen Lyrics | Production ✅ | QEL-032 |
| Download State Machine | Production ✅ | QEL-041 |
| Download Resume | Production ✅ | QEL-041 |
| Download Retry | Production ✅ | QEL-041 |
| Priority Queue | Production ✅ | QEL-041 |
| Offline Optimization | Production ✅ | QEL-041 |
| Background Session | Production ✅ | QEL-041 |
| Taste DNA | Production ✅ | QEL-051 |
| Recommendations | Production ✅ | QEL-051 |
| Audio Lab | Production ✅ | QEL-051 |
| Spaces | Production ✅ | QEL-051 |
| Dashboard | Production ✅ | QEL-051 |
| Discovery | Production ✅ | QEL-051 |

*ACC updated — 2026-09-28 — Discovery Complete*
