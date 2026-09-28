# SHM-003: Engineering Research Registry — Library Milestone

**Date:** 2026-09-28
**Milestone:** 0.2.0-alpha — Library DNA (QEL-024)

## Research Entries

### SHM-R-017: FileManager Enumeration at Scale (10k+ Tracks)
**Date:** 2026-09-28
**Projects Studied:** Apple FileManager documentation, large directory enumeration best practices
**Patterns Observed:**
- FileManager.enumerator(at:includingPropertiesForKeys:options:) with resourceKeys fileSize, contentModificationDate, isRegularFile, isDirectory is efficient for large directories
- Options: skipsHiddenFiles, skipsPackageDescendants to avoid unnecessary files
- Check isDirectory and isRegularFile to skip directories
- Filter by pathExtension against supported set
- Task.yield() every 500 files to avoid blocking main thread for 10k+ tracks
- Incremental indexing: keep knownFiles dict path->modificationDate, compare modification dates, only re-index new or modified (modDate > knownDate), detect removed via seenPaths Set
- Progress publishing every 50 files to avoid flooding EventBus

**QELORYX Application:**
- FileScanner implements all above
- supportedExtensions built from AudioFormat.supportedFormats
- scan and scanIncremental methods
- FileScanResult with discovered, removed, duration, totalBytes
- DiscoveredFile with url, fileSize, modificationDate, format, libraryID

**Code Reuse:** None
**License Impact:** Foundation framework (Apple)

---

### SHM-R-018: SwiftData Batch Operations and Model Design
**Date:** 2026-09-28
**Projects Studied:** Apple SwiftData documentation, WWDC 2023 SwiftData sessions, batch insert/update/delete patterns
**Patterns Observed:**
- @Model macro with @Attribute(.unique) for id
- ModelContainer with Schema and ModelConfiguration, isStoredInMemoryOnly false for persistence
- ModelContext with autosaveEnabled true, but explicit save() for batch operations
- FetchDescriptor with SortDescriptor and #Predicate for type-safe queries
- Batch insert: loop insert then save once for performance (vs save per insert)
- Update: fetch via predicate, modify properties, save
- Delete: context.delete(model:where:) with predicate
- Relationships: for Library DNA, TrackModel could have library relationship, but for QEL-024 we use libraryID string for simplicity and portability (InMemory fallback doesn't have relationships)
- Mapping: toDomain/fromDomain methods for clean separation between persistence model and domain entity (AstryxTrack struct)

**QELORYX Application:**
- TrackModel with 20 fields including libraryID, isLossless, checksum, folderPath
- LibraryModel with 7 fields
- SwiftDataAdapter production with ModelContainer, ModelContext, mapping, predicates, batch operations
- InMemorySwiftDataStack enhanced with same logic for Linux fallback and testing
- Protocol expanded to 20+ methods for full Library DNA

**Code Reuse:** None
**License Impact:** Apple SwiftData (Apple SDK)

---

### SHM-R-019: Artwork Cache File System with LRU
**Date:** 2026-09-28
**Projects Studied:** Common caching patterns (NSCache, file system cache, LRU eviction), SDWebImage and Kingfisher patterns (for inspiration, not code)
**Patterns Observed:**
- Two-level cache: memory (fast, limited) + disk (slower, larger, persistent)
- Memory: NSCache or custom LRU with max items (200 typical)
- Disk: caches directory (Library/Caches) for artwork, not Documents (so system can purge if needed, but we manage size)
- Key: trackID sanitized as filename (replace / and : with _)
- Write: atomic write to avoid corruption
- Size tracking: keep diskSize variable, update on write/delete, calculate on init via contentsOfDirectory
- Eviction: when over max (500 MB typical), sort files by modification date (oldest first), evict until under 80% of max (400 MB) — LRU
- Thread safety: NSLock for diskSize
- Check memory first (fast path), then disk, populate memory if disk hit

**QELORYX Application:**
- AstryxFileSystemArtworkCache composes existing AstryxArtworkCache (memory LRU) + disk
- Disk directory caches/com.qeloryx.artwork
- Methods: cachedArtwork (memory then disk), cacheArtwork (both), clearCache, cacheSize, diskCacheSize, memoryCacheSize, cachedArtworkURL, removeArtwork
- Eviction: LRU by modification date, target 80%
- Thread-safe via NSLock

**Code Reuse:** None — patterns only
**License Impact:** None (Foundation only)

---

### SHM-R-020: Metadata Normalization and File Name Parsing
**Date:** 2026-09-28
**Projects Studied:** Common music file naming conventions, ID3 tag handling
**Patterns Observed:**
- File names often contain track info: "Artist - Title", "Artist - Album - Title", "TrackNumber Title", "01 - Title"
- Track number prefix removal via regex: ^\d+\s*[-.]\s*
- Dash separator " - " is common, split by it
- If first component is Int, it's track number, rest is title
- If 2 components: first is artist, second is title
- If 3+ components: first artist, second album, rest title
- Fallback: file name as title if no pattern matches
- Trim whitespace and newlines
- Normalize genre capitalization, artist/album whitespace
- For real metadata: AVAsset commonMetadata for title/artist/album/genre/artwork, plus availableMetadataFormats for albumArtist/trackNumber/year

**QELORYX Application:**
- MetadataEngine file name parsing with dashComponents, track number check, album detection, regex cleanup
- MetadataNormalizer already existed from Foundation, now used in indexing
- Platform MetadataExtractor with AVURLAsset async load for real metadata

**Code Reuse:** None
**License Impact:** Foundation + AVFoundation (Apple SDK)

---

### SHM-R-021: Library Grouping and Folder View UX
**Date:** 2026-09-28
**Projects Studied (UX only):** Apple Music library tabs, Plexamp library, Spotify library
**Patterns Observed:**
- Tabs: Songs, Albums, Artists, Genres, Folders, Favorites, Recent, History — common pattern
- Songs: list with artwork 48pt, title/artist/album, duration, play count, swipe actions (play, favorite, delete)
- Albums: grid 2 columns, 160pt artwork, title/artist/track count + duration
- Artists: list with artwork, name, albumCount + trackCount, chevron
- Genres: list with name, trackCount + albumCount
- Folders: list with folder icon, name, path, trackCount
- Stats header: horizontal scroll of cards with trackCount/albumCount/artistCount/duration/size/favoriteCount
- Search: debounced 300ms, searchable modifier
- Add Library: sheet with name/path/type
- Duplicates: sheet with groups

**QELORYX Application:**
- LibraryViewModel with selectedTab enum with icons
- LibraryView with stats header (StatCards), tab selector (capsules), content based on tab, toolbar menu, searchable, refreshable, sheets
- SongsListView with swipe actions, SongRow with artwork and lossless/favorite indicators
- AlbumsGridView 2 columns, AlbumCard
- ArtistsListView, GenresListView, FoldersListView
- AddLibraryView, DuplicatesView

**Code Reuse:** None — UX inspiration only

---

### SHM-R-022: Duplicate Detection at Scale
**Date:** 2026-09-28
**Projects Studied:** Duplicate detection heuristics
**Patterns Observed:**
- Checksum grouping: same file size + same file name, or actual hash (MD5/SHA) of file content (expensive for large files, so simplified to size+name for QEL-024, real hash future)
- Title+artist+duration bucket: normalized title + artist + duration bucket (2 second buckets) for near-duplicates
- Group by checksum or by title|artist|durationBucket, filter groups where count > 1

**QELORYX Application:**
- Existing AstryxLibraryIndexer.detectDuplicates with checksum grouping + fallback title|artist|durationBucket
- LibraryEngine.scanForDuplicates delegates to indexer
- LibraryView has Find Duplicates button that shows DuplicatesView sheet

**Code Reuse:** None

---

## Summary

- Total research entries this milestone: 6 (R-017 to R-022)
- Total overall: 22 (Foundation 8 + Player 8 + Library 6)
- Code reused: 0 (patterns only, all QELORYX-owned)
- License violations: 0
- All implementations are QELORYX-owned greenfield with Apple SDKs isolated

## Next Research

- QEL-032 Lyrics: LRC format with word-level timing, karaoke rendering, translation tracks
- QEL-0XX Downloads: URLSession background downloads with resume data
- Taste DNA: On-device ML for recommendations

---
*SHM maintained by Arena Agent — Library Research*
