// QELORYX — Features/Library
// LibraryViewModel.swift
// QEL-024 Library DNA — Production ViewModel with multi-library, grouping, folder view

import Foundation
import Combine

public enum LibraryTab: String, CaseIterable, Identifiable {
    case songs = "Songs"
    case albums = "Albums"
    case artists = "Artists"
    case genres = "Genres"
    case folders = "Folders"
    case favorites = "Favorites"
    case recent = "Recent"
    case history = "History"
    
    public var id: String { rawValue }
    public var icon: String {
        switch self {
        case .songs: return "music.note"
        case .albums: return "rectangle.stack"
        case .artists: return "person.2"
        case .genres: return "guitars"
        case .folders: return "folder"
        case .favorites: return "heart.fill"
        case .recent: return "clock"
        case .history: return "clock.arrow.circlepath"
        }
    }
}

@MainActor
public final class LibraryViewModel: ObservableObject {
    
    // MARK: - Published
    @Published public var selectedTab: LibraryTab = .songs
    @Published public var tracks: [AstryxTrack] = []
    @Published public var albums: [AstryxAlbum] = []
    @Published public var artists: [AstryxArtist] = []
    @Published public var genres: [AstryxGenre] = []
    @Published public var folders: [AstryxFolder] = []
    @Published public var libraries: [AstryxLibrary] = []
    @Published public var favorites: [AstryxTrack] = []
    @Published public var recentlyAdded: [AstryxTrack] = []
    @Published public var history: [AstryxTrack] = []
    @Published public var mostPlayed: [AstryxTrack] = []
    @Published public var stats: LibraryStats?
    
    @Published public var isLoading = false
    @Published public var isIndexing = false
    @Published public var indexingProgress: (completed: Int, total: Int) = (0, 0)
    @Published public var searchText = ""
    @Published public var errorMessage: String?
    
    // MARK: - Dependencies
    private let libraryEngine: any LibraryEngineProtocol
    private let audioEngine: any AstryxAudioEngineProtocol
    private let eventBus: any EventBusProtocol
    private var subscriptionStore = EventSubscriptionStore()
    private var searchTask: Task<Void, Never>?
    
    public init(
        libraryEngine: any LibraryEngineProtocol = AstryxLibraryEngine(),
        audioEngine: any AstryxAudioEngineProtocol = AstryxAudioEngine(),
        eventBus: any EventBusProtocol = AstryxEventBus.shared
    ) {
        self.libraryEngine = libraryEngine
        self.audioEngine = audioEngine
        self.eventBus = eventBus
        
        observeEvents()
        observeSearch()
    }
    
    private func observeEvents() {
        let sub1 = eventBus.subscribe(to: QeloryxEvent.libraryDidChange(changeType: .incremental).name) { [weak self] _ in
            Task { @MainActor in await self?.loadAll() }
        }
        subscriptionStore.store(sub1)
        
        let sub2 = eventBus.subscribe(to: QeloryxEvent.indexingProgress(completed: 0, total: 0).name) { [weak self] event in
            Task { @MainActor in
                if case .indexingProgress(let completed, let total) = event {
                    self?.indexingProgress = (completed, total)
                }
            }
        }
        subscriptionStore.store(sub2)
        
        let sub3 = eventBus.subscribe(to: QeloryxEvent.indexingStarted.name) { [weak self] _ in
            Task { @MainActor in self?.isIndexing = true }
        }
        subscriptionStore.store(sub3)
        
        let sub4 = eventBus.subscribe(to: QeloryxEvent.indexingCompleted(newTracks: 0).name) { [weak self] _ in
            Task { @MainActor in
                self?.isIndexing = false
                await self?.loadAll()
            }
        }
        subscriptionStore.store(sub4)
    }
    
    private func observeSearch() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] text in
                Task { @MainActor in
                    await self?.performSearch(query: text)
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Load
    
    public func loadAll() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            async let tracksTask = libraryEngine.fetchAllTracks()
            async let albumsTask = libraryEngine.fetchAlbums()
            async let artistsTask = libraryEngine.fetchArtists()
            async let genresTask = libraryEngine.fetchGenres()
            async let librariesTask = libraryEngine.fetchLibraries()
            async let favoritesTask = libraryEngine.fetchFavorites()
            async let recentTask = libraryEngine.fetchRecentlyAdded(limit: 20)
            async let historyTask = libraryEngine.fetchHistory(limit: 20)
            async let mostPlayedTask = libraryEngine.fetchMostPlayed(limit: 20)
            async let statsTask = libraryEngine.stats()
            
            let (t, al, ar, g, lib, fav, rec, hist, most, st) = try await (tracksTask, albumsTask, artistsTask, genresTask, librariesTask, favoritesTask, recentTask, historyTask, mostPlayedTask, statsTask)
            
            self.tracks = t
            self.albums = al
            self.artists = ar
            self.genres = g
            self.libraries = lib
            self.favorites = fav
            self.recentlyAdded = rec
            self.history = hist
            self.mostPlayed = most
            self.stats = st
            
            // Folders from first library if exists
            if let firstLib = lib.first {
                self.folders = try await libraryEngine.fetchFolders(forLibrary: firstLib.id)
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    public func loadForCurrentTab() async {
        switch selectedTab {
        case .songs:
            tracks = (try? await libraryEngine.fetchAllTracks()) ?? []
        case .albums:
            albums = (try? await libraryEngine.fetchAlbums()) ?? []
        case .artists:
            artists = (try? await libraryEngine.fetchArtists()) ?? []
        case .genres:
            genres = (try? await libraryEngine.fetchGenres()) ?? []
        case .folders:
            if let firstLib = libraries.first {
                folders = (try? await libraryEngine.fetchFolders(forLibrary: firstLib.id)) ?? []
            }
        case .favorites:
            favorites = (try? await libraryEngine.fetchFavorites()) ?? []
        case .recent:
            recentlyAdded = (try? await libraryEngine.fetchRecentlyAdded(limit: 50)) ?? []
        case .history:
            history = (try? await libraryEngine.fetchHistory(limit: 50)) ?? []
        }
    }
    
    private func performSearch(query: String) async {
        guard !query.isEmpty else {
            await loadForCurrentTab()
            return
        }
        
        do {
            let results = try await libraryEngine.searchTracks(query: query)
            tracks = results
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Actions
    
    public func playTrack(_ track: AstryxTrack) async {
        let allIDs = tracks.map { $0.id }
        let index = allIDs.firstIndex(of: track.id) ?? 0
        try? await audioEngine.handle(command: .playQueue(queue: allIDs, startIndex: index))
    }
    
    public func playAlbum(_ album: AstryxAlbum) async {
        let ids = album.tracks.map { $0.id }
        try? await audioEngine.handle(command: .playQueue(queue: ids, startIndex: 0))
    }
    
    public func playArtist(_ artistName: String) async {
        do {
            let artistTracks = try await libraryEngine.fetchTracks(forArtist: artistName)
            let ids = artistTracks.map { $0.id }
            try await audioEngine.handle(command: .playQueue(queue: ids, startIndex: 0))
        } catch {}
    }
    
    public func toggleFavorite(_ track: AstryxTrack) async {
        try? await libraryEngine.toggleFavorite(trackID: track.id)
        await loadAll()
    }
    
    public func addLibrary(name: String, url: URL, type: LibraryType) async {
        do {
            _ = try await libraryEngine.addLibrary(name: name, rootURL: url, type: type)
            await loadAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    public func startIndexing() async {
        isIndexing = true
        do {
            _ = try await libraryEngine.startIndexingAllLibraries()
        } catch {
            errorMessage = error.localizedDescription
        }
        isIndexing = false
        await loadAll()
    }
    
    public func scanForDuplicates() async -> [[AstryxTrack]] {
        (try? await libraryEngine.scanForDuplicates()) ?? []
    }
}
