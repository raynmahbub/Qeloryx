// QELORYX — Services/Search
// SearchEngine.swift

import Foundation

public protocol SearchEngineProtocol: Sendable {
    func search(query: SearchQuery) async -> [AstryxSearchResult]
    func rebuildIndex() async
    func updateIndex(track: AstryxTrack) async
}

public final class AstryxSearchEngine: SearchEngineProtocol {
    
    private let indexedSearch: any IndexedSearchProtocol
    private let libraryEngine: any LibraryEngineProtocol
    private let eventBus: any EventBusProtocol
    private var subscriptionStore = EventSubscriptionStore()

    /// A rebuild reads the whole library, so bursts of change events (a 10k
    /// file import publishes one per batch) are coalesced instead of racing.
    private var pendingRebuild: Task<Void, Never>?

    public init(
        indexedSearch: any IndexedSearchProtocol = AstryxIndexedSearch(),
        libraryEngine: any LibraryEngineProtocol,
        eventBus: any EventBusProtocol = AstryxEventBus.shared
    ) {
        self.indexedSearch = indexedSearch
        self.libraryEngine = libraryEngine
        self.eventBus = eventBus

        observeLibraryChanges()
    }

    private func observeLibraryChanges() {
        // BUG-15: only `.incremental` was observed, so adding a library
        // (`.fullReload`) or favouriting a track (`.favorites`) left the index
        // stale. Subscribe by event name and rebuild for any change type.
        let sub = eventBus.subscribe(to: QeloryxEvent.libraryDidChange(changeType: .incremental).name) { [weak self] _ in
            self?.scheduleRebuild()
        }
        subscriptionStore.store(sub)

        // Any track mutation should also refresh results (favourite state in
        // rows, title edits after a metadata fix).
        let updated = eventBus.subscribe(to: QeloryxEvent.trackUpdated(id: "").name) { [weak self] _ in
            self?.scheduleRebuild()
        }
        subscriptionStore.store(updated)
    }

    /// Coalesces rebuild requests: at most one rebuild in flight, and one
    /// queued follow-up regardless of how many events arrive meanwhile.
    private func scheduleRebuild() {
        if pendingRebuild != nil { return }
        pendingRebuild = Task { [weak self] in
            guard let self else { return }
            await self.rebuildIndex()
            self.pendingRebuild = nil
        }
    }
    
    public func search(query: SearchQuery) async -> [AstryxSearchResult] {
        eventBus.publish(.searchQueryChanged(query: query.text))
        return await indexedSearch.search(query: query)
    }
    
    public func rebuildIndex() async {
        do {
            let tracks = try await libraryEngine.fetchAllTracks()
            let albums = try await libraryEngine.fetchAlbums()
            let artists = try await libraryEngine.fetchArtists()
            let playlists = (try? await libraryEngine.fetchPlaylists()) ?? []
            await indexedSearch.buildIndex(tracks: tracks, albums: albums, artists: artists, playlists: playlists)
        } catch {
            #if DEBUG
            debugPrint("[SearchEngine] Failed to rebuild index: \(error)")
            #endif
        }
    }
    
    public func updateIndex(track: AstryxTrack) async {
        await indexedSearch.incrementalUpdate(track: track)
    }
}
