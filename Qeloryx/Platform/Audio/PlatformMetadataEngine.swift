// QELORYX — Platform
// PlatformMetadataEngine.swift
//
// BUG-25. `MetadataExtractor.swift` in this folder contains a complete AVAsset
// reader (title, artist, album, albumArtist, genre, year, trackNumber,
// discNumber, duration, artwork, embedded lyrics) — and nothing ever
// constructed it. Imports therefore fell back to parsing file names, which is
// why freshly imported tracks showed "Unknown Artist", no artwork and 0:00.
//
// This is the bridge to Core's `MetadataEngineProtocol`. It lives in Platform,
// not Core, because the dependency direction is Core ← Platform: Core must stay
// free of AVFoundation and must never import Platform.

#if canImport(QeloryxCore)
import QeloryxCore
#endif

import Foundation

public final class AstryxPlatformMetadataEngine: MetadataEngineProtocol, @unchecked Sendable {

    private let fallback: any MetadataEngineProtocol

    public init(fallback: any MetadataEngineProtocol = AstryxMetadataEngine()) {
        self.fallback = fallback
    }

    public func supportedFormats() -> [AudioFormat] {
        AudioFormat.supportedFormats
    }

    public func isSupported(url: URL) -> Bool {
        AudioFormat.fromExtension(url.pathExtension).isDecodable
    }

    public func extractMetadata(from url: URL) async throws -> RawMetadata {
        let extractor = AstryxMetadataExtractor()
        if let metadata = try? await extractor.extractMetadata(from: url) {
            // A reader that returns nothing useful is treated as a miss so the
            // filename parser can still supply a title.
            if metadata.title != nil || metadata.duration != nil || metadata.artworkData != nil {
                return metadata
            }
        }
        return try await fallback.extractMetadata(from: url)
    }
}
