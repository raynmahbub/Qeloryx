// QELORYX — Models/Providers
// ProviderCapability.swift
//
// Distinct from `AstryxCapability` (Services/Providers/CapabilityRegistry):
// that protocol models an enable/disable *feature flag* with dependencies.
// This enum models what a *provider* can actually do — the contract surface
// the app queries before offering provider-backed UI.

import Foundation

public enum AstryxProviderCapability: String, Sendable, CaseIterable, Codable, Equatable, Hashable {
    case streamingPlayback
    case offlineDownloads
    case lyrics
    case artwork
    case metadataLookup
    case recommendations
    case scrobbling
    case sync

    public var displayName: String {
        switch self {
        case .streamingPlayback: return "Streaming playback"
        case .offlineDownloads: return "Offline downloads"
        case .lyrics: return "Lyrics"
        case .artwork: return "Artwork"
        case .metadataLookup: return "Metadata lookup"
        case .recommendations: return "Recommendations"
        case .scrobbling: return "Scrobbling"
        case .sync: return "Sync"
        }
    }
}
