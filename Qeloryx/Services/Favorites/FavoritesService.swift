// QELORYX — Services/Favorites
// FavoritesService.swift
//
// Thin, testable façade over the library's favourite handling. Screens that
// only need "fav/unfav + is this a favourite" depend on this instead of the
// whole library engine protocol.

import Foundation

public protocol FavoritesServiceProtocol: Sendable {
    func toggleFavorite(trackID: String) async throws
    func isFavorite(trackID: String) async -> Bool
    func favorites() async -> [AstryxTrack]
}

public final class AstryxFavoritesService: FavoritesServiceProtocol {
    private let libraryEngine: any LibraryEngineProtocol

    public init(libraryEngine: any LibraryEngineProtocol) {
        self.libraryEngine = libraryEngine
    }

    public func toggleFavorite(trackID: String) async throws {
        try await libraryEngine.toggleFavorite(trackID: trackID)
    }

    public func isFavorite(trackID: String) async -> Bool {
        let favorites = (try? await libraryEngine.fetchFavorites()) ?? []
        return favorites.contains { $0.id == trackID }
    }

    public func favorites() async -> [AstryxTrack] {
        (try? await libraryEngine.fetchFavorites()) ?? []
    }
}
