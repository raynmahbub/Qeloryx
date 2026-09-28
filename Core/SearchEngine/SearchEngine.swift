// QELORYX — SearchEngine
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
    
    public init(
        indexedSearch: any IndexedSearchProtocol = AstryxIndexedSearch(),
        libraryEngine: any LibraryEngineProtocol = AstryxLibraryEngine(),
        eventBus: any EventBusProtocol = AstryxEventBus.shared
    ) {
        self.indexedSearch = indexedSearch
        self.libraryEngine = libraryEngine
        self.eventBus = eventBus
        
        observeLibraryChanges()
    }
    
    private func observeLibraryChanges() {
        let sub = eventBus.subscribe(to: QeloryxEvent.libraryDidChange(changeType: .incremental).name) { [weak self] event in
            Task {
                await self?.rebuildIndex()
            }
        }
        subscriptionStore.store(sub)
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
            let playlists: [AstryxPlaylist] = [] // TODO
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
