// QELORYX — Services/Player
// PlaybackSourceResolver.swift
//
// BUG-02 fix. The engine used to invent `URL(fileURLWithPath: "/tmp/<id>.mp3")`
// whenever a track could not be resolved, swallow the load failure and then
// report `.playing`. That made every downstream failure invisible: the UI
// showed progress over silence and `recordPlay` incremented statistics for a
// track that never played.
//
// A playback source is now an explicit contract: either the engine resolves a
// real URL + track, or it fails the track with a typed error. Tests and
// previews supply `DictionaryPlaybackSourceResolver` instead of relying on
// silent simulation.

import Foundation

/// A playable track resolved to a concrete URL.
public struct PlaybackSource: Sendable, Equatable {
    public let track: AstryxTrack
    public let url: URL

    public init(track: AstryxTrack, url: URL) {
        self.track = track
        self.url = url
    }
}

/// Resolves a track ID to something the audio adapter can load.
public protocol PlaybackSourceResolving: Sendable {
    func resolvePlaybackSource(trackID: String) async -> PlaybackSource?
}

/// Resolves through a `LibraryEngine`. This is the production path.
public struct LibraryPlaybackSourceResolver: PlaybackSourceResolving {
    private let library: any LibraryEngineProtocol

    public init(library: any LibraryEngineProtocol) {
        self.library = library
    }

    public func resolvePlaybackSource(trackID: String) async -> PlaybackSource? {
        guard let track = try? await library.fetchTrack(id: trackID) else { return nil }
        return PlaybackSource(track: track, url: track.fileURL)
    }
}

/// Deterministic resolver for tests, previews and UI wiring before a library
/// exists. Nothing here simulates playback — it only maps IDs to tracks.
public struct DictionaryPlaybackSourceResolver: PlaybackSourceResolving {
    private let sources: [String: PlaybackSource]

    public init(tracks: [AstryxTrack]) {
        var map: [String: PlaybackSource] = [:]
        for track in tracks {
            map[track.id] = PlaybackSource(track: track, url: track.fileURL)
        }
        self.sources = map
    }

    public init(sources: [String: PlaybackSource]) {
        self.sources = sources
    }

    public func resolvePlaybackSource(trackID: String) async -> PlaybackSource? {
        sources[trackID]
    }
}
