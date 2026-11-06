# SHM-009: Open-Source Music Player Feature Benchmark

**Date:** 2026-11-07
**Milestone:** Post-1.0.0 OSS Feature Integration
**Purpose:** Survey the most-starred open-source music players on GitHub, identify their best features, and integrate the highest-value ones into QELORYX's own architecture (per the SHM-001 Engineering Research Policy: original code, QELORYX naming, licenses respected, no upstream code copied).

---

## Projects Surveyed (GitHub search API, sorted by stars)

| Project | Stars | License | Relevance |
|---|---|---|---|
| [pear-devs/pear-desktop](https://github.com/pear-devs/pear-desktop) | ~34k | MIT | Extension-based desktop player |
| [nukeop/nuclear](https://github.com/nukeop/nuclear) | ~19k | AGPL-3.0 | Plugin sources, playlist import/export, synced lyrics w/ translations |
| [jeffvli/feishin](https://github.com/jeffvli/feishin) | ~10k | GPL-3.0 | Self-hosted (Navidrome/Jellyfin/Subsonic) client: scrobbling, smart playlist editor, lyrics |
| [SPlayer-Dev/SPlayer](https://github.com/SPlayer-Dev/SPlayer) | ~7.4k | AGPL-3.0 | Jellyfin/Navidrome/Emby playback |
| [Moriafly/SaltPlayerSource](https://github.com/Moriafly/SaltPlayerSource) | ~7.6k | MIT | Local multi-platform player |
| [zhongyang219/MusicPlayer2](https://github.com/zhongyang219/MusicPlayer2) | ~6.8k | GPL-3.0 | Local library player: lyrics, karaoke, extensive format support |
| [cmus/cmus](https://github.com/cmus/cmus) | ~6.3k | GPL-2.0 | Fast console player: smart playlists, library views |
| [kushalpandya/Petrichor](https://github.com/kushalpandya/Petrichor) | ~1.8k | MIT | Offline macOS player — closest match to QELORYX's offline-first scope |
| [BLeeEZ/amperfy](https://github.com/BLeeEZ/amperfy) | ~1.8k | GPL-3.0 | Native Swift iOS/iPadOS/macOS player for self-hosted servers |
| [CassetteLab/cassette](https://github.com/CassetteLab/cassette) | ~180 | MPL-2.0 | Swift-native iOS Subsonic client |
| [InstaZDLL/WaveFlow](https://github.com/InstaZDLL/WaveFlow) | ~93 | GPL-3.0 | Local-first player with ReplayGain |
| [radiosilence/koan](https://github.com/radiosilence/koan) | ~17 | MIT | Bit-perfect gapless playback |

## Best Features Identified Across the Field

1. **Gapless playback + crossfade** (Petrichor, koan) — seamless track transitions.
2. **ReplayGain / loudness normalization** (Petrichor, WaveFlow) — consistent volume across tracks/albums.
3. **Smart playlists with conditional, negative, and regex rules** (Petrichor, Feishin, cmus).
4. **Playlist import/export (M3U/M3U8)** (Petrichor, Nuclear).
5. **Scrobbling to Last.fm / server** (Petrichor, Feishin).
6. **Synced lyrics with translations** (Nuclear, Feishin) — QELORYX already covers LRC/karaoke.
7. **Broad format support (40+ formats)** (Petrichor, MusicPlayer2).
8. **Self-hosted server support (Subsonic/Navidrome/Jellyfin)** (Amperfy, Cassette, Feishin) — maps to QELORYX's ProviderLayer.
9. **AirPlay 2 / casting** (Petrichor) — QELORYX already has AirPlay via NowPlayingManager.

## Integrated into QELORYX (original implementations)

| Feature | Location | Notes |
|---|---|---|
| ReplayGain normalization | `Core/DSP/ReplayGain/ReplayGainNormalizer.swift` | Track/album modes, 89 dB reference, pre-amp, clipping prevention via peak |
| Gapless + crossfade | `Core/AstryxAudioEngine/Playback/GaplessPlayback.swift` | `AstryxPlaybackSettings`, linear & equal-power fade curves, pure gain math |
| Smart playlists | `Core/LibraryEngine/SmartPlaylists/SmartPlaylist.swift` | 14 fields, 12 operators, negate, AND/OR logic, sort + limit |
| M3U import/export | `Core/LibraryEngine/Playlists/M3UPlaylist.swift` | `#EXTM3U`/`#EXTINF` writer, tolerant parser, library path resolution |
| Tests | `Tests/CoreTests/OSSFeaturesTests.swift` | 13 tests covering all four modules |

Deferred to roadmap (larger scope): Last.fm scrobbling provider, self-hosted server sync via ProviderLayer, expanded format support.
