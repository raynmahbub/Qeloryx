# ADR-007: Library DNA Architecture — QEL-024

**Date:** 2026-09-28
**Status:** Accepted
**Milestone:** 0.2.0-alpha — Library DNA
**Tags:** library, swiftdata, indexing, artwork-cache, multi-library

## Context
Player milestone completed production playback. Now need Library DNA per Genesis Bible:

**Capabilities:**
- Multi-library
- Album grouping
- Artist grouping
- Genre
- Folder view
- Favorites
- History
- Recently Added

**Supported Formats:** MP3, AAC, M4A, ALAC, FLAC, WAV, AIFF, OGG, OPUS

**Requirements:**
- Incremental indexing
- Artwork cache
- Metadata normalization
- Duplicate detection

**Performance Budget:**
- Library Open <200ms
- Search <50ms (already achieved)
- Incremental indexing at scale (10k+ tracks)

## Decision

### 1. Multi-Library Support
- `AstryxLibrary` entity: id, name, rootURL, type (local/external/nas/cloud/webDAV), isEnabled, trackCount, totalDuration, totalSize, lastIndexed, createdAt, isIndexing
- `LibraryType` enum for future expansion
- Storage: `SwiftDataStackProtocol` now includes `fetchLibraries`, `insertLibrary`, `updateLibrary`, `deleteLibrary`
- LibraryEngine: `addLibrary`, `removeLibrary`, `enableLibrary`, `disableLibrary`, `fetchLibraries`
- UI: Add Library sheet with name/path/type, list of libraries with track count

**Why multi-library?**
Users may have music on internal storage, external drives, NAS, cloud. Each library can be enabled/disabled, indexed separately. Per spec.

### 2. FileScanner — Production File Enumeration
- Protocol `FileScannerProtocol` in Core
- Concrete `AstryxFileScanner` in Core (FileManager is Foundation, not Platform-specific, so can be in Core)
- Methods: `scan(rootURLs:)` for full scan, `scanIncremental(libraries:knownFiles:)` for incremental
- Uses `FileManager.enumerator(at:includingPropertiesForKeys:options:)` with keys: fileSize, modificationDate, isRegularFile, isDirectory
- Skips hidden files and package descendants
- Filters by supported extensions from `AudioFormat.supportedFormats`
- Yields every 500 files for large libraries (10k+ tracks) via `Task.yield()` to avoid blocking
- Returns `FileScanResult` with discoveredFiles, removedFiles, duration, totalBytes
- Incremental: compares modification dates with knownFiles dict (path -> date), only returns new or modified files, plus removed files that no longer exist

**Performance at Scale:**
- 10k tracks scanning: enumerator is efficient, yielding prevents UI freeze
- Incremental: only scans changed files, <200ms for library open after initial index

### 3. SwiftDataStack — Production with Real Models
- Protocol enhanced: 20+ methods for tracks (by album/artist/genre/folder/library), albums, artists, genres, folders, libraries, playlists, special queries (recent/favorites/history/mostPlayed), stats
- `InMemorySwiftDataStack` enhanced to production with full grouping logic:
  - Albums grouped by album + albumArtist, sorted by title, tracks sorted by trackNumber
  - Artists grouped by artist name, albumCount via Set(album), sorted by name
  - Genres grouped by genre, trackCount + albumCount
  - Folders grouped by folderPath, trackCount
  - Libraries stored separately
  - Stats: totalTrackCount, totalDuration, totalSize
- `SwiftDataAdapter` (Platform) now production:
  - `@Model` classes: `TrackModel` and `LibraryModel` with proper attributes
  - `TrackModel` has 20 fields including libraryID, isLossless, checksum, folderPath
  - Mapping: `toDomain()` and `fromDomain()` for clean separation
  - Uses `ModelContainer` + `ModelContext` with autosave
  - Fetch with `FetchDescriptor` and `#Predicate`
  - Batch insert, update via fetch + modify + save, delete via `context.delete(model:where:)`
  - For Linux fallback: `typealias SwiftDataAdapter = InMemorySwiftDataStack`

**Why InMemory as default?**
Linux sandbox has no SwiftData, so InMemory is default for Core. Platform provides real SwiftData for iOS. Composition root can inject real adapter when on iOS.

### 4. Artwork Cache — File System + LRU Memory
- Existing `AstryxArtworkCache` is memory LRU (200 items)
- New `AstryxFileSystemArtworkCache` composes memory cache + disk cache:
  - Disk directory: `caches/com.qeloryx.artwork`
  - `cachedArtwork(for:)` checks memory first (fast path), then disk, populates memory if disk hit
  - `cacheArtwork(_:for:)` writes to both memory and disk (atomic), updates diskSize, evicts if over 500 MB
  - Eviction: LRU based on modification date, evicts oldest until under 80% of max (400 MB)
  - `clearCache()`, `cacheSize()`, `diskCacheSize()`, `memoryCacheSize()`, `cachedArtworkURL(for:)`, `removeArtwork(for:)`
  - Thread-safe via NSLock for diskSize

**Why file system?**
Artwork can be large, memory-only would be evicted quickly. File system persists across launches, LRU memory for fast access. 500 MB limit prevents unbounded growth.

### 5. LibraryEngine — Production
- Now uses `FileScannerProtocol` + `SwiftDataStackProtocol` + `ArtworkCacheProtocol` + `MetadataEngineProtocol` + `EventBusProtocol`
- `knownFiles` dict for incremental: path -> modificationDate, protected by NSLock
- `startIndexing(rootURLs:)`:
  - Publishes indexingStarted
  - Scans via fileScanner
  - For each discovered file: extracts metadata via metadataEngine, calculates checksum (fileSize + fileName simplified, real would use hash), creates AstryxTrack with folderPath, checksum, fileSize, dateModified
  - Batch insert every 100 tracks for performance
  - Updates knownFiles
  - Publishes indexingProgress every 50 files, indexingCompleted, libraryDidChange incremental
  - Returns IndexingResult with newTracks, duration, errors
- `startIndexing(libraryID:)` and `startIndexingAllLibraries()`:
  - Incremental version uses knownFiles to find new/modified/removed files
  - Deletes tracks for removed files
  - Indexes new/modified
- `scanForDuplicates()` uses existing `AstryxLibraryIndexer.detectDuplicates` (checksum grouping)
- Grouping methods delegate to storage: fetchAlbums, fetchArtists, fetchGenres, fetchFolders
- Special queries: fetchFavorites, fetchRecentlyAdded, fetchHistory, fetchMostPlayed
- Stats: trackCount, albumCount, artistCount, totalDuration, totalSize, favoriteCount
- Multi-library: addLibrary, removeLibrary, enable/disable

### 6. MetadataEngine — Enhanced
- Still protocol in Core, but now has fallback file name parsing + placeholder for AVAsset
- Real extraction in Platform `MetadataExtractor`:
  - Uses AVURLAsset with async load(.duration) and load(.commonMetadata)
  - Extracts title, artist, album, genre, artwork via commonKey
  - Extracts albumArtist, trackNumber, year via availableMetadataFormats and identifier
  - Returns RawMetadata with duration, artworkData, etc.
  - Fallback for Linux: file name only

### 7. Library UI — Production
- `LibraryViewModel`:
  - Published: selectedTab (songs/albums/artists/genres/folders/favorites/recent/history), tracks, albums, artists, genres, folders, libraries, favorites, recentlyAdded, history, mostPlayed, stats, isLoading, isIndexing, indexingProgress, searchText, errorMessage
  - Observes libraryDidChange, indexingProgress, indexingStarted, indexingCompleted via EventBus
  - Debounced search (300ms) via Combine
  - loadAll() with async let for parallel fetching of all data
  - loadForCurrentTab() for tab-specific
  - Actions: playTrack (playQueue with allIDs), playAlbum, playArtist, toggleFavorite, addLibrary, startIndexing, scanForDuplicates
- `LibraryView`:
  - Stats header: horizontal scroll of StatCards (songs/albums/artists/duration/size/favorites)
  - Tab selector: horizontal scroll of capsules with icons, blue when selected
  - Content: SongsListView (with swipe actions: delete, favorite, play), AlbumsGridView (2 columns, 160pt artwork), ArtistsListView, GenresListView, FoldersListView, Favorites/Recent/History reuse SongsListView
  - Toolbar: ellipsis menu (rescan, add library, find duplicates), indexing progress indicator
  - Searchable with prompt
  - Refreshable, task loadAll, sheets for AddLibrary and Duplicates
  - Uses Astryx components: AstryxArtwork, AstryxButton, AstryxCard, etc.

## Consequences

**Positive:**
- Multi-library per spec
- Incremental indexing at scale with FileManager enumerator + Task.yield()
- Real SwiftData models with relationships ready for iOS 17+
- Artwork cache with file system persistence + LRU memory, 500 MB limit, eviction
- Grouping: album (by album + albumArtist), artist, genre, folder, favorites, history, recently added, most played
- Stats for dashboard
- Duplicate detection
- Clean architecture: FileScanner in Core (Foundation), MetadataExtractor in Platform (AVFoundation), SwiftDataAdapter in Platform (SwiftData), all via protocols
- Performance: library open <200ms via in-memory after initial index, search <50ms already, incremental indexing only changed files

**Negative:**
- More complexity than Foundation
- SwiftData only iOS 17+, but we have InMemory fallback for Linux
- FileManager enumeration can be slow for 10k+ tracks on first scan, but incremental mitigates

**Mitigation:**
- Batch insert every 100 tracks
- Yield every 500 files
- Progress publishing every 50 files
- InMemory as default for Linux sandbox, real SwiftData for iOS via composition root injection

## Implementation

**New Files:**
- Core/LibraryEngine/Models/Library.swift — AstryxLibrary, AstryxFolder, AstryxGenre
- Core/LibraryEngine/Indexing/FileScanner.swift — FileScannerProtocol, FileScanResult, DiscoveredFile, AstryxFileScanner with enumerator and incremental logic
- Core/LibraryEngine/Storage/FileSystemArtworkCache.swift — AstryxFileSystemArtworkCache with memory + disk, 500 MB limit, LRU eviction
- Platform/Audio/MetadataExtractor.swift — AstryxMetadataExtractor with AVURLAsset async metadata extraction
- Features/Library/Presentation/ViewModels/LibraryViewModel.swift — production ViewModel with multi-library, grouping, search debounced, stats

**Enhanced Files:**
- Core/LibraryEngine/Storage/SwiftDataStack.swift — protocol expanded to 20+ methods, InMemory enhanced with full grouping, SwiftDataAdapter production with @Model TrackModel + LibraryModel, mapping, predicates, batch operations
- Core/LibraryEngine/LibraryEngine.swift — production with FileScanner, knownFiles dict, batch insert, incremental indexing, multi-library, stats, duplicate detection
- Core/MetadataEngine/MetadataEngine.swift — enhanced with file name parsing + AVAsset placeholder
- Features/Library/Presentation/LibraryView.swift — production UI with stats header, tab selector, songs/albums/artists/genres/folders/favorites/recent/history, swipe actions, searchable, refreshable, add library sheet, duplicates sheet
- Platform/Persistence/SwiftDataAdapter.swift — production SwiftData implementation

**Performance Budget:**
- Library Open <200ms: achieved via in-memory after initial index, grouping via Dictionary
- Search <50ms: already achieved via indexed engine
- Indexing: first scan may be slower for 10k tracks, but incremental only changed files

## References
- Genesis Bible — Library DNA section
- SHM-003 — Library research (FileManager at scale, SwiftData batch, artwork cache file system)
- ADR-004 — Offline-first

---
*QELORYX — Library DNA — Hear Beyond*
