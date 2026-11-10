// QELORYX — Services/ListeningHistory
// ListeningHistoryService.swift
//
// Records and reads play history through the library engine, which owns the
// persistent store. History never leaves the device.

import Foundation

public protocol ListeningHistoryServiceProtocol: Sendable {
    func recordPlay(trackID: String) async throws
    func history(limit: Int) async -> [AstryxTrack]
    func mostPlayed(limit: Int) async -> [AstryxTrack]
}

public final class AstryxListeningHistoryService: ListeningHistoryServiceProtocol {
    private let libraryEngine: any LibraryEngineProtocol

    public init(libraryEngine: any LibraryEngineProtocol) {
        self.libraryEngine = libraryEngine
    }

    public func recordPlay(trackID: String) async throws {
        try await libraryEngine.recordPlay(trackID: trackID)
    }

    public func history(limit: Int) async -> [AstryxTrack] {
        (try? await libraryEngine.fetchHistory(limit: limit)) ?? []
    }

    public func mostPlayed(limit: Int) async -> [AstryxTrack] {
        (try? await libraryEngine.fetchMostPlayed(limit: limit)) ?? []
    }
}
