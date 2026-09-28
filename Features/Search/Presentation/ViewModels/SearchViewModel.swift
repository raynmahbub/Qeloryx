// QELORYX — Features — Search
// SearchViewModel.swift
// 1.0.0 Stable — Production universal search with <50ms target, debounced, grouped results

import Foundation
import Combine

#if canImport(SwiftUI)
import SwiftUI
#endif

public enum SearchScope: String, CaseIterable, Sendable {
    case all = "All"
    case tracks = "Songs"
    case albums = "Albums"
    case artists = "Artists"
    case playlists = "Playlists"
    
    public var icon: String {
        switch self {
        case .all: return "magnifyingglass"
        case .tracks: return "music.note"
        case .albums: return "opticaldisc"
        case .artists: return "person.fill"
        case .playlists: return "music.note.list"
        }
    }
    
    public var resultType: SearchResultType? {
        switch self {
        case .all: return nil
        case .tracks: return .track
        case .albums: return .album
        case .artists: return .artist
        case .playlists: return .playlist
        }
    }
}

@MainActor
public final class SearchViewModel: ObservableObject {
    
    @Published public var query: String = ""
    @Published public var results: [AstryxSearchResult] = []
    @Published public var groupedResults: [SearchResultType: [AstryxSearchResult]] = [:]
    @Published public var isSearching: Bool = false
    @Published public var selectedScope: SearchScope = .all
    @Published public var recentQueries: [String] = []
    @Published public var isEmpty: Bool = true
    
    private let searchEngine: any SearchEngineProtocol
    private let eventBus: any EventBusProtocol
    private var cancellables = Set<AnyCancellable>()
    private let performanceMonitor = AstryxPerformanceMonitor.shared
    
    public init(
        searchEngine: any SearchEngineProtocol = AstryxSearchEngine(),
        eventBus: any EventBusProtocol = AstryxEventBus.shared
    ) {
        self.searchEngine = searchEngine
        self.eventBus = eventBus
        
        observeQuery()
        loadRecentQueries()
    }
    
    private func observeQuery() {
        $query
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main) // Debounce 150ms for instant feel <50ms target
            .removeDuplicates()
            .sink { [weak self] newQuery in
                Task { @MainActor in
                    await self?.performSearch(query: newQuery)
                }
            }
            .store(in: &cancellables)
        
        $selectedScope
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.performSearch(query: self?.query ?? "")
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadRecentQueries() {
        // Load from UserDefaults or in-memory for QEL-051
        recentQueries = ["Tame Impala", "Lo-Fi", "Jazz", "Indie Rock"]
    }
    
    public func performSearch(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            results = []
            groupedResults = [:]
            isEmpty = true
            isSearching = false
            return
        }
        
        isSearching = true
        isEmpty = false
        
        // Performance measurement — target <50ms
        let searchQuery: SearchQuery
        if let type = selectedScope.resultType {
            searchQuery = SearchQuery(text: trimmed, filters: SearchFilters(types: [type]), limit: 50)
        } else {
            searchQuery = SearchQuery(text: trimmed, limit: 50)
        }
        
        let start = Date()
        let searchResults = await searchEngine.search(query: searchQuery)
        let duration = Date().timeIntervalSince(start) * 1000
        
        // Record performance
        let metric = PerformanceMetric(name: "Search", duration: duration, target: PerformanceBudget.search)
        performanceMonitor.record(metric)
        
        results = searchResults
        
        // Group by type
        groupedResults = Dictionary(grouping: searchResults) { $0.type }
        
        isSearching = false
        
        // Save to recent if successful
        if !searchResults.isEmpty && !recentQueries.contains(trimmed) {
            recentQueries.insert(trimmed, at: 0)
            if recentQueries.count > 10 {
                recentQueries.removeLast()
            }
        }
    }
    
    public func clearSearch() {
        query = ""
        results = []
        groupedResults = [:]
        isEmpty = true
    }
    
    public func selectRecentQuery(_ recent: String) {
        query = recent
    }
    
    public func clearRecentQueries() {
        recentQueries.removeAll()
    }
    
    public func resultCount(for type: SearchResultType) -> Int {
        groupedResults[type]?.count ?? 0
    }
}
