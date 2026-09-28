# SHM-006: Discovery Research — QEL-051

## Purpose
Record engineering research for Discovery milestone, per Genesis Bible research policy. Study but implement within QELORYX identity, no code reuse.

## Research Entries

### R-035: Taste DNA & Listening Profile
- **Source:** Spotify Taste Profile, Apple Music Replay, Last.fm listening stats research
- **What we learned:** Taste DNA is evolving listening profile based on play history, favorites, genres, artists, mood, eras, listening time, diversity. Top genres by playCount sum, percentage = playCount/total, top 5. Top artists by playCount sum, trackCount, percentage, top 5. Mood heuristic based on genre mapping (Rock->Energetic, Jazz->Chill, etc.) + energy/valence 0-1. Eras based on year decade grouping. Diversity score based on unique genres/artists vs total. Listening time = sum playCount*duration. Summary = topGenre • topArtist • mood. Offline-first means all analysis local, no network. Evolution via snapshots over time.
- **How we used:** Implemented AstryxTasteProfile with all fields, TasteDNAEngine generateProfile offline-first grouping by genre/artist/year, mood mapping, diversityScore, recommendations based on profile. Mock profile for preview with Indie/Rock/Lo-Fi/Jazz/Electronic + Tame Impala/Khruangbin etc. + Chill/Introspective.
- **QELORYX identity:** Our Taste DNA is greenfield, Astryx prefix, Midnight Aurora visualization with progress bars, circles, capsules, not copying Spotify/Apple.

### R-036: Recommendations — Offline Local
- **Source:** Spotify recommendations, Apple Music For You research
- **What we learned:** Recommendations types: Because you liked (favorites genres filter not favorite playCount<3), Similar artist (same genre), Genre deep dive (top genre filter playCount<5), Rediscover (playCount>5 lastPlayed nil or <30 days), Mood match (genresForMood mapping), Favorites mix (favorites shuffled), New releases (dateAdded >14 days), Time capsule (old favorites). Offline-first means from local library only, no network. Score 0-1 for ranking. Should be limit 5-10 per type.
- **How we used:** Implemented recommendations(for:from:limit:) with 6 types: becauseYouLiked, genreDeepDive, rediscover, moodMatch, favoritesMix, newReleases, each with title, reason, tracks, type, score. All local, no network. Shuffled for variety.
- **QELORYX identity:** Our recommendations are greenfield, offline-first per QELORYX spec, not copying Spotify.

### R-037: Audio Lab — DSP, EQ, Spectrum, Diagnostics
- **Source:** Plexamp audio diagnostics, Roon signal path, Spotify audio quality research
- **What we learned:** Audio Lab includes: Signal Path (Source->Decoder->DSP->Mixer->Output with icons and active dot), EQ (10 bands 32Hz-16kHz gain -12..+12 dB, presets flat/bassBoost/vocalBoost/trebleBoost, Slider, Reset, Toggle Enable), Spectrum (live visualization 32 bars random height 4..60 gradient aurora->emerald, 44.1kHz/16-bit/Stereo labels), Diagnostics (Battery Optimized, Storage free, Latency <50ms, Buffer Healthy). DSP enable/disable. Performance budget Seek <50ms, Play/Pause Instant.
- **How we used:** Enhanced existing EQ already production, DSPEngine already production, created AudioLabViewModel with isDSPEnabled/isEQEnabled/bands/currentPreset/presets/currentFormat/storageInfo/signalPath mock 5 nodes, AudioLabView production with header DSP status circle emerald/surface + stats LabStat, signalPathSection with nodes circle 32 icon + name/detail + active dot + connecting line, eqSection presets capsules blue selected + bands frequency + Slider + gain dB + Reset + Toggle, spectrumSection mock 32 bars gradient, diagnosticsSection LazyVGrid DiagCard.
- **QELORYX identity:** Our Audio Lab is Midnight Aurora, Astryx components, not copying Plexamp/Roon.

### R-038: Spaces — Shared Queue, DJ Handoff, Live Reactions
- **Source:** Spotify Jam, Discord voice channels, Apple SharePlay research
- **What we learned:** Spaces is shared listening: Active Spaces (name, host, listeners, isActive), Shared Queue (enumerated index + artwork + title/artist + person.fill icon), Live Reactions (emojis ❤️🔥😍🎧✨🙌 buttons sendReaction, recentReactions horizontal scroll capsules), Future Voice Rooms, DJ Handoff, Live Spectrum Share with Soon capsule. Create Space adds My Space, Join placeholder, totalListeners sum. Offline-first for QEL-051 mock, future can add real backend via WebSocket.
- **How we used:** Created AstryxSpace model, SpacesViewModel with activeSpaces mock 2 spaces Late Night Lo-Fi/Indie Discovery, sharedQueue empty, recentReactions mock, totalListeners sum, createSpace, joinSpace placeholder, sendReaction inserts at 0 keeps 10 max, SpacesView production with header Shared Listening + stats SpaceStat Active/Listeners/Queue, activeSpacesSection emptySpacesView or SpaceCard list, sharedQueueSection, reactionsSection with emojis buttons + recentReactions capsules, futureSection with FutureFeatureRow Voice Rooms/DJ Handoff/Live Spectrum Share Soon capsule.
- **QELORYX identity:** Our Spaces is greenfield, Astryx prefix, Midnight Aurora, not copying Spotify Jam/Discord.

### R-039: Dashboard — Overview Widgets
- **Source:** Apple Music Listen Now, Spotify Home, Plexamp dashboard research
- **What we learned:** Dashboard overview widgets: Favorites, Recent, Downloads, Mood, Queue, Vinyl, each with value and icon and destination, LazyVGrid 2 columns, greeting based on time Good morning/afternoon/evening/night, subGreeting, userInitial circle gradient aurora, Taste DNA widget with icon waveform.path.ecg circle auroraBlue 0.15 + Your Taste DNA h4 + tasteSummary + chevron + stroke auroraBlue 0.2, Quick Actions Audio Lab/Spaces/Shuffle/Search icon circle color 0.15 bg, Recently Played horizontal scroll 100 artwork, Discovery rows Audio Lab/Spaces/Taste DNA.
- **How we used:** Created DashboardViewModel with favoriteCount/recentCount/downloadCount/queueCount/currentMood/tasteSummary/recentTracks/greeting/subGreeting/userInitial Q, init greeting based on hour, load() fetches favorites history downloads profile, mock if empty 42/12/8/5, DashboardView production with greetingHeader, tasteDNAWidget NavigationLink, statsGrid DashboardCard, quickActions, recentSection, discoverySection.
- **QELORYX identity:** Our Dashboard is Midnight Aurora, Astryx components, not copying Apple/Spotify.

### R-040: Discovery Combined Entry
- **Source:** QELORYX Genesis Bible 5 pillars + Discovery milestone spec
- **What we learned:** Discovery is combined entry for Taste DNA, Recommendations, Audio Lab, Spaces, Time Capsule. Header Discover h1 + subtitle Taste DNA•Recommendations•Audio Lab•Spaces•Time Capsule, tasteDNASection with topGenres 3 cards + mood/listeningTime/diversity labels, recommendationsSection For You with cards icon + title + track count + reason + horizontal scroll artwork, audioLabEntry NavigationLink with icon circle auroraBlue + title + subtitle + chevron, spacesEntry emerald, timeCapsuleEntry sunset. All using DesignSystem.
- **How we used:** Created DiscoveryViewModel with profile/recommendations/isLoading, load() fetch tracks, mock if empty, DiscoveryView production with header, tasteDNASection, recommendationsSection, audioLabEntry, spacesEntry, timeCapsuleEntry.
- **QELORYX identity:** Our Discovery is greenfield, QELORYX owned, 5 pillars per Genesis Bible.

## Summary
- Taste DNA evolving profile offline-first ✅
- Recommendations offline local ✅
- Audio Lab EQ + signal path + spectrum + diagnostics ✅
- Spaces shared queue + reactions + future ✅
- Dashboard overview ✅
- Discovery combined ✅
- No external code reuse, all greenfield QELORYX owned ✅

*Research completed: 2026-09-28 — QEL-051 Discovery*
