// QELORYX — MetadataEngine
// MetadataProvider.swift

import Foundation

public protocol MetadataProviderProtocol: Sendable {
    func fetchMetadata(for track: AstryxTrack) async throws -> RawMetadata?
}

public final class LocalMetadataProvider: MetadataProviderProtocol {
    private let engine: any MetadataEngineProtocol
    
    public init(engine: any MetadataEngineProtocol = AstryxMetadataEngine()) {
        self.engine = engine
    }
    
    public func fetchMetadata(for track: AstryxTrack) async throws -> RawMetadata? {
        try await engine.extractMetadata(from: track.fileURL)
    }
}
