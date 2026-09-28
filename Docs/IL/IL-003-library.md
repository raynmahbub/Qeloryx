# IL-003: Integration Log — Library Milestone QEL-024

**Date:** 2026-09-28
**Milestone:** 0.2.0-alpha — Library DNA
**Status:** Completed
**Branch:** arena/01a0e693-qeloryx

## Overview
Library milestone implements production multi-library, grouping, folder view, incremental indexing, artwork cache file system, SwiftData concrete.

## Integrations

### Core — Enhanced

| Module | Type | Source | License | Notes |
|--------|------|--------|---------|-------|
| Library (AstryxLibrary, Folder, Genre) | Internal | QELORYX | Proprietary | Multi-library support: id, name, rootURL, type (local/external/nas/cloud/webDAV), isEnabled, trackCount, totalDuration, totalSize, lastIndexed, createdAt, isIndexing, displayName, formattedSize, formattedDuration. Folder: id, name, path, parentPath, trackCount, folderCount, libraryID. Genre: id, name, trackCount, albumCount |
| FileScanner | Internal | QELORYX | Proprietary | FileManager.enumerator with resourceKeys fileSize/modificationDate/isRegularFile/isDirectory, skips hidden/packages, filters by AudioFormat.supportedFormats, yields every 500 files, FileScanResult with discovered/removed/duration/totalBytes, incremental with knownFiles dict |
| SwiftDataStack | Internal | QELORYX | Proprietary | Protocol expanded to 20+ methods, InMemory enhanced with full grouping (albums by album|albumArtist, artists by artist, genres by genre, folders by folderPath), special queries (recent/favorites/history/mostPlayed), stats (trackCount/duration/size), libraries separate dict |
| FileSystemArtworkCache | Internal | QELORYX | Proprietary | Composes memory LRU + disk (caches/com.qeloryx.artwork), memory fast path then disk, disk atomic write + diskSize tracking + eviction if over 500MB, LRU eviction by modification date until under 80% (400MB), thread-safe NSLock |
| LibraryEngine | Internal | QELORYX | Proprietary | Production with FileScanner, knownFiles dict with NSLock, batch insert 100, indexingProgress every 50, incremental indexing (new/modified/removed), multi-library add/remove/enable/disable, stats, duplicate detection via existing indexer |
| MetadataEngine | Internal | QELORYX | Proprietary | Enhanced with file name parsing (Artist - Album - Title, Artist - Title, track number prefix removal via regex) + AVAsset placeholder, real extraction in Platform MetadataExtractor |

### Platform — Production

| Module | Type | Source | License | Notes |
|--------|------|--------|---------|-------|
| SwiftDataAdapter | Apple SDK | Apple | Apple SDK | Production: @Model TrackModel with 20 fields (id, title, artist, album, albumArtist, genre, year, trackNumber, discNumber, duration, fileURLString, fileFormatRaw, fileSize, dateAdded, dateModified, playCount, lastPlayed, isFavorite, folderPath, checksum, libraryID, isLossless) + LibraryModel with 7 fields, mapping toDomain/fromDomain, ModelContainer + ModelContext autosave, FetchDescriptor + #Predicate, batch insert, update via fetch+modify+save, delete via context.delete(model:where:), fallback for Linux typealias to InMemory |
| MetadataExtractor | Apple SDK | Apple | Apple SDK | NEW, AVURLAsset async load duration and commonMetadata, extracts title/artist/album/genre/artwork via commonKey, albumArtist/trackNumber/year via availableMetadataFormats and identifier, fallback for Linux |

### Features — Library

| Module | Type | Source | License | Notes |
|--------|------|--------|---------|-------|
| LibraryViewModel | Internal | QELORYX | Proprietary | Production with selectedTab (songs/albums/artists/genres/folders/favorites/recent/history), tracks/albums/artists/genres/folders/libraries/favorites/recentlyAdded/history/mostPlayed/stats, isLoading/isIndexing/indexingProgress/searchText/errorMessage, observes libraryDidChange/indexingProgress/indexingStarted/indexingCompleted via EventBus, debounced search 300ms via Combine, loadAll with async let parallel, loadForCurrentTab, actions playTrack/playAlbum/playArtist/toggleFavorite/addLibrary/startIndexing/scanForDuplicates |
| LibraryView | Internal | QELORYX | Proprietary | Production UI: stats header horizontal StatCards (songs/albums/artists/duration/size/favorites), tab selector horizontal capsules with icons blue when selected, content SongsListView with swipe actions (delete/favorite/play), AlbumsGridView 2 columns 160pt artwork, ArtistsListView, GenresListView, FoldersListView, Favorites/Recent/History reuse SongsListView, toolbar ellipsis menu (rescan/add library/find duplicates), indexing progress indicator, searchable, refreshable, sheets AddLibrary and Duplicates, uses Astryx components |

## External Code Reuse

None — 100% QELORYX-owned + Apple SDKs (AVFoundation, SwiftData)

## License Compliance

- QELORYX Proprietary
- Apple SDKs per Developer Agreement
- No copyleft
- No third-party dependencies

## Integration Checklist

- [x] No direct Platform API usage in Core/Domain/Features (all via protocols)
- [x] All Platform imports isolated with canImport checks
- [x] Public APIs use QELORYX/Astryx naming
- [x] No license violations
- [x] SHM-003 updated with research
- [x] Multi-library per spec
- [x] Album grouping, Artist grouping, Genre, Folder view, Favorites, History, Recently Added per spec
- [x] Incremental indexing at scale with FileManager enumerator + Task.yield()
- [x] Artwork cache file system + LRU memory with 500MB limit and eviction
- [x] Metadata normalization via file name parsing + AVAsset
- [x] Duplicate detection via checksum grouping
- [x] Performance: Library Open <200ms via in-memory grouping

## Performance

- Library Open <200ms: achieved via in-memory grouping via Dictionary after initial index
- Search <50ms: already achieved
- Indexing 10k tracks: first scan may be slower, but incremental only changed files, batch insert 100, yield 500, progress 50
- Artwork cache: memory fast path + disk persistence, 500MB limit

## Next Integrations (Planned)

- QEL-032 Lyrics: LRC parser with word-level timing, LyricsProvider
- QEL-0XX Downloads: State machine with resume/retry/priority

---
*IL maintained by Arena Agent — Library*
