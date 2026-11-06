# SHM-010: OSS Music App Master List — Second Benchmark Pass

**Date:** 2026-11-07
**Milestone:** Post-1.0.0 OSS Feature Integration, batch 2
**Purpose:** Expanded master list of open-source GitHub music apps grouped by purpose/platform. Maps each app family to features, and records what QELORYX integrated (batch 2) vs. roadmap. Per SHM-001 policy: original implementations only, licenses respected.

---

## 🌐 Android Streaming Clients (YouTube Music backends)
| App | Notable features | QELORYX action |
|---|---|---|
| ArchiveTune | Unified local + streaming library | Roadmap: ProviderLayer server sync |
| BitChord | Word-synced lyrics, gapless crossfade | ✅ Lyrics karaoke + crossfade done (batch 1) |
| Blazify | Offline downloads, 10-band EQ | ✅ DownloadEngine + 10-band EQ exist |
| Convx | "Listen Together" rooms | ✅ Spaces shared queue exists; roadmap: live sync |
| Echo Music | USB DAC, AI queue, FLAC fetch | ✅ Bit-perfect DAC mode + smart queue (batch 2) |
| InnerTune | Gapless, live lyric translations | ✅ Gapless done; translations exist in Lyrics |
| InterTune | Local + streaming hybrid | Roadmap |
| Last Wave | Last.fm scrobbling, 15-band EQ | ✅ Scrobbling (batch 2); EQ exists (10-band) |
| Metrolist | Offline caching | ✅ DownloadEngine exists |
| Musify | No-account streaming | N/A (offline-first app) |
| PixelMusic | Telegram channel streaming | Roadmap: ProviderLayer source |
| Prism | Word-by-word lyrics, karaoke, DJ mode | ✅ Karaoke lyrics exist |
| SimpMusic | Android Auto | Roadmap: CarPlay scene for iOS |
| ViMusic | Community forks, data migration | Roadmap: import from other apps' playlists (M3U done) |

## 💻 Desktop-First Clients
| App | Notable features | QELORYX action |
|---|---|---|
| Levyra | Synced lyrics, local+streaming | Covered |
| Limusic | Lightweight native (Rust/Tauri) | N/A (iOS app) |
| Nuclear | Multi-source aggregation | ✅ ProviderLayer pattern; batch 1 research |
| Spotube | ~50k stars, metadata+stream split | ✅ ProviderLayer metadata/stream separation |
| ytmdesktop | Media keys, mini-player, Discord Rich Presence | ✅ NowPlaying/LiveActivity exist; Rich Presence N/A on iOS |

## 📂 Android Local File Players (offline only)
| App | Notable features | QELORYX action |
|---|---|---|
| Auxio | Precise metadata tag management | ✅ Tag editor (batch 2) |
| Symphony | Hi-fi offline, Material You | ✅ Lossless support + Midnight Aurora theme |

## ☁️ Web Alternatives
| App | Notable features | QELORYX action |
|---|---|---|
| Monochrome | Browser streaming aesthetic | N/A |

## Integrated in batch 2 (original implementations)

| Feature | Location | Inspired by |
|---|---|---|
| Last.fm-compatible scrobbling (50% / 4-min rule, now-playing, offline pending queue) | `Core/ProviderLayer/ScrobbleProvider/ScrobbleProvider.swift` | Last Wave, Petrichor, Feishin |
| Smart/AI queue auto-fill (TasteDNA-ranked suggestions) | `Core/AstryxAudioEngine/Queue/SmartQueueFiller.swift` | Echo Music |
| Metadata tag editing with validation | `Core/MetadataEngine/TagEditor.swift` | Auxio |
| Bit-perfect / USB DAC output settings | `Core/AstryxAudioEngine/Session/BitPerfectOutput.swift` | Echo Music, HiFidelity, Petrichor |
| Tests | `Tests/CoreTests/OSSIntegrationTests.swift` (11 tests) | — |

## Roadmap (not yet integrated)
- Self-hosted server sync (Subsonic/Navidrome/Jellyfin) via ProviderLayer — Amperfy, Cassette, Feishin
- CarPlay scene — SimpMusic's Android Auto equivalent
- Live "Listen Together" room sync — Convx
- Import of streaming-service data (Spotify playlists etc.) — ViMusic forks
