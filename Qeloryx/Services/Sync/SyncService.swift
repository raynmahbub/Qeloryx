// QELORYX — Services/Sync
// SyncService.swift
//
// Offline-first sync seam. QELORYX is local-first: everything works with no
// account and no network. Sync is an opt-in overlay on top of the local
// library, and no provider is configured in this build — so the default
// implementation refuses honestly instead of pretending to sync.

import Foundation

public protocol SyncServiceProtocol: Sendable {
    var isConfigured: Bool { get }
    func syncNow() async throws -> AstryxSyncResult
}

public struct AstryxSyncResult: Sendable, Equatable {
    public let syncedTracks: Int
    public let startedAt: Date
    public let finishedAt: Date
    public let errors: [String]

    public init(syncedTracks: Int, startedAt: Date, finishedAt: Date, errors: [String] = []) {
        self.syncedTracks = syncedTracks
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.errors = errors
    }
}

public enum SyncError: Error, LocalizedError, Sendable, Equatable {
    case noProviderConfigured

    public var errorDescription: String? {
        switch self {
        case .noProviderConfigured:
            return "Sync is not configured. QELORYX works fully offline; connect a provider in Settings to enable it."
        }
    }
}

/// The default, honest no-provider sync. Reports itself unconfigured and
/// throws rather than silently "succeeding".
public final class AstryxNoOpSyncService: SyncServiceProtocol {
    public init() {}
    public var isConfigured: Bool { false }

    public func syncNow() async throws -> AstryxSyncResult {
        throw SyncError.noProviderConfigured
    }
}
