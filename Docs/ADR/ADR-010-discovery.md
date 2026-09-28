# ADR-010: Discovery Architecture — QEL-051

## Status
Accepted — 2026-09-28

## Context
QELORYX Discovery milestone requires production discovery system per Genesis Bible:
- Taste DNA, recommendations, Audio Lab, Spaces, Dashboard, Time Capsule
- 5 pillars: Astryx Player, Library DNA, Taste DNA, Astryx Audio Lab, Astryx Spaces

Constraints:
- Greenfield, offline-first, native performance, modular, testable
- Taste DNA must be evolving listening profile based on local library only (no network)
- Recommendations offline-first from local library analysis
- Audio Lab with DSP, EQ, spectrum, diagnostics
- Spaces with shared queue, DJ handoff future, live reactions
- Dashboard overview

## Decision

### 1. Taste DNA Models — QEL-051 Production
- TasteGenre: id, name, playCount, percentage 0-1, color hex for visualization
- TasteArtist: id, name, playCount, trackCount, percentage
- TasteMood: primary, secondary, energy 0-1, valence 0-1, static moods array [Chill, Energetic, Melancholic, Euphoric, Focused, Nostalgic, Romantic, Dark, Bright, Introspective]
- TasteEra: decade e.g., "2020s", count, percentage
- AstryxTasteProfile: id, topGenres [TasteGenre], topArtists [TasteArtist], mood TasteMood, topEras [TasteEra], totalPlays, totalTracks, totalDuration, favoriteCount, listeningTime, diversityScore 0-1, lastUpdated, evolution [TasteSnapshot], summary (topGenre • topArtist • mood), formattedListeningTime
- TasteSnapshot: id, date, topGenre, topArtist, mood, playCount — for evolution history
- Recommendation: id, title, reason, tracks [AstryxTrack], type RecommendationType, score
- RecommendationType: becauseYouLiked, similarArtist, genreDeepDive, rediscover, moodMatch, newReleases, favoritesMix, timeCapsule with icons

### 2. TasteDNA Engine — Offline-First Analysis
- Protocol TasteDNAEngineProtocol: generateProfile(from:), currentProfile(), recommendations(for:from:limit:), mood(for:), diversityScore(for:)
- AstryxTasteDNAEngine: _currentProfile with NSLock, eventBus
- generateProfile(from:): offline-first local analysis, no network
  - Top genres: Dictionary grouping by genre, playCount sum, sorted, percentage = playCount/totalGenrePlays, top 5, colorForGenre mapping
  - Top artists: grouping by artist, playCount sum, trackCount, sorted, percentage, top 5
  - Mood: heuristic based on top genre mapping genre->mood (Rock->Energetic 0.8/0.6, Pop->Bright 0.7/0.8, Jazz->Chill 0.3/0.5, Classical->Focused 0.2/0.4, Hip-Hop->Energetic, Electronic->Euphoric, Indie->Introspective, Lo-Fi->Chill, Metal->Dark, R&B->Romantic, Folk->Nostalgic), fallback based on avg plays
  - Eras: grouping by year decade (year/10*10), count, percentage, top 3
  - Stats: totalPlays sum playCount, totalDuration sum duration, favoriteCount filter isFavorite, listeningTime sum playCount*duration, diversityScore via diversityScore(for:)
  - Sets _currentProfile with lock
- currentProfile(): returns _currentProfile with lock
- recommendations(for:from:limit:): generates offline recommendations
  - Because you liked: favorites genres, filter library where genre in favoriteGenres and not favorite and playCount<3
  - Genre deep dive: topGenre, filter library genre == topGenre and playCount<5 shuffled
  - Rediscover: playCount>5 and lastPlayed nil or <30 days ago, sorted playCount desc
  - Mood match: genresForMood mapping mood->genres, filter library where genre in moodGenres shuffled
  - Favorites mix: favorites shuffled
  - New releases: dateAdded >14 days ago sorted dateAdded desc
  - Returns [AstryxRecommendation] with title, reason, tracks, type, score
- mood(for:): same heuristic as generateProfile
- diversityScore(for:): uniqueGenres count / min(total,20) *0.5 + uniqueArtists count / min(total,50) *0.5, min 1.0, measures how diverse taste is
- Helpers: colorForGenre mapping, genresForMood mapping

### 3. Recommendation Provider — Enhanced
- Protocol RecommendationProviderProtocol: recommendations(for track), recommendations(for profile from library), tasteProfile(), generateProfile(from:)
- AstryxRecommendationProvider: id, name, tasteEngine, _currentProfile with lock
- recommendations(for track): placeholder empty (needs library injection, real via library)
- recommendations(for profile from library): delegates to tasteEngine.recommendations
- tasteProfile(): returns _currentProfile
- generateProfile(from:): calls tasteEngine.generateProfile and sets _currentProfile
- Legacy TasteProfile struct for compatibility

### 4. Audio Lab — Production
- Existing EQ already production: EQBand frequency/gain/q/type, EQPreset flat/bassBoost/vocalBoost with bands, EqualizerProtocol bands()/setGain/setPreset/currentPreset/reset/isEnabled/setEnabled, AstryxEqualizer with _bands/_preset/_enabled NSLock
- DSPEngine already production: equalizer, spectrumAnalyzer, enable/disable/isEnabled
- AudioLabViewModel: isDSPEnabled, isEQEnabled, bands, currentPreset, presets (flat/bassBoost/vocalBoost/trebleBoost), currentFormat, storageInfo, signalPath [SignalNode], dspEngine, init from dspEngine, toggleDSP, setGain, selectPreset, resetEQ, setEQEnabled, mockSignalPath Source->Decoder->DSP->Mixer->Output with icons
- AudioLabView production: ZStack midnight, ScrollView VStack header (title, subtitle, DSP status circle emerald/surface, stats LabStat DSP/EQ/Format), signalPathSection with nodes circle icon + name/detail + active emerald dot + connecting line, eqSection with presets horizontal capsules blue selected, bands with frequency Hz + Slider -12..12 + gain dB, Reset + Toggle Enable EQ, spectrumSection mock visualization HStack 32 bars random height 4..60 with gradient aurora->emerald, 44.1kHz/16-bit/Stereo labels, diagnosticsSection LazyVGrid 2 columns DiagCard Battery Optimized emerald, Storage free, Latency <50ms, Buffer Healthy
- Uses DesignSystem AstryxColors + AstryxTypography

### 5. Spaces — Production
- AstryxSpace: id, name, host, listeners, isActive
- SpacesViewModel: activeSpaces [AstryxSpace], sharedQueue [AstryxTrack], recentReactions [String], totalListeners, init mock 2 spaces Late Night Lo-Fi and Indie Discovery, totalListeners sum, recentReactions mock, createSpace adds My Space, joinSpace placeholder, sendReaction inserts at 0 and keeps 10 max
- SpacesView production: ZStack midnight, ScrollView VStack header (Shared Listening title, subtitle Shared Queue•DJ Handoff•Live Reactions•Future Voice Rooms, icon person.3.fill, stats SpaceStat Active/Listeners/Queue), activeSpacesSection with SectionHeader, emptySpacesView if empty with icon and Create Space button, else SpaceCard list, sharedQueueSection with SectionHeader, empty text or list enumerated index + artwork + title/artist + person.fill icon, reactionsSection with SectionHeader, HStack 6 emojis ❤️🔥😍🎧✨🙌 buttons sendReaction, recentReactions horizontal scroll capsules auroraBlue 0.15 bg, futureSection with SectionHeader Coming Soon and FutureFeatureRow for Voice Rooms, DJ Handoff, Live Spectrum Share with icon + title + description + Soon capsule
- SpaceCard: circle emerald 0.15 bg + antenna icon emerald, name + host/listeners labels, Join button borderedProminent auroraBlue
- Uses DesignSystem

### 6. Dashboard — Production
- DashboardViewModel: favoriteCount, recentCount, downloadCount, queueCount, currentMood, tasteSummary, recentTracks, greeting Good morning/afternoon/evening/night based on hour, subGreeting, userInitial Q, libraryEngine, downloadEngine, tasteEngine, init greeting based on hour, load() fetches favorites, history 10, downloads all, profile current, sets counts, currentMood summary, recentTracks history, mock if empty 42/12/8/5, refresh()
- DashboardView production: ZStack midnight, ScrollView VStack greetingHeader (greeting h2 + subGreeting small + userInitial circle gradient aurora), tasteDNAWidget NavigationLink to TasteDNAView with icon waveform.path.ecg circle auroraBlue 0.15 + Your Taste DNA h4 + tasteSummary small + chevron, statsGrid LazyVGrid 2 columns DashboardCard Favorites Recent Downloads Mood Queue Vinyl with icons colors sunset/auroraBlue/emerald etc and destination AnyView LibraryView/DownloadsView/TasteDNAView/PlayerView, quickActionsSection with SectionHeader Quick Actions and HStack 4 QuickActionButton Audio Lab/Spaces/Shuffle/Search with icon circle color 0.15 bg, recentSection SectionHeader Recently Played with empty or horizontal scroll 100 size artwork + title/artist, discoverySection SectionHeader Discovery with DiscoveryRow Audio Lab/Spaces/Taste DNA with icon circle color 0.15 bg + title/subtitle + chevron
- DashboardCard: NavigationLink with icon + chevron + value h3 + title small, backgroundSecondary rounded 12
- QuickActionButton: icon circle + title caption, backgroundSecondary rounded 12
- DiscoveryRow: icon circle + title medium + subtitle caption + chevron, backgroundSecondary rounded 10

### 7. Discovery — Combined Entry
- DiscoveryViewModel: profile, recommendations, isLoading, tasteEngine, libraryEngine, load() fetches tracks, if empty mock profile, else generateProfile + recommendations limit 5, refresh()
- DiscoveryView production: ZStack midnight, ScrollView VStack header Discover h1 + subtitle Taste DNA•Recommendations•Audio Lab•Spaces•Time Capsule, tasteDNASection SectionHeader Your Taste DNA + View All NavigationLink to TasteDNAView + topGenres 3 HStack cards + mood/listeningTime/diversity HStack labels, recommendationsSection SectionHeader For You + empty or list of recommendation cards with icon auroraBlue + title h5 + track count caption + reason small + horizontal scroll 80 size artwork + title caption, audioLabEntry NavigationLink to AudioLabView with icon circle auroraBlue 0.15 + title h4 + subtitle small + chevron, spacesEntry similar emerald, timeCapsuleEntry sunset
- Uses DesignSystem

## Alternatives Considered
- Remote recommendation API: rejected for offline-first, but architecture allows adding remote provider later as separate provider
- ML model for taste: deferred, heuristic sufficient for QEL-051, future can add ML with same protocol
- Real-time collaborative Spaces via WebSocket: deferred, mock for QEL-051, future can add real backend

## Consequences
- Taste DNA evolving profile offline-first ✅
- Recommendations from local library ✅
- Audio Lab with EQ + signal path + spectrum + diagnostics ✅
- Spaces with shared queue + reactions + future voice rooms ✅
- Dashboard overview ✅
- Discovery combined entry ✅
- Testable with mock data ✅

## References
- Taste DNA concept: Spotify Taste Profile, Apple Music Replay research
- Audio Lab: Plexamp audio diagnostics research
- Spaces: Discord voice channels, Spotify Jam research
- Genesis Bible v3.0 QEL-051

*QELORYX — Hear Beyond. Build Beyond.*
