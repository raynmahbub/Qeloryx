// QELORYX — App
// AppDependencies.swift
//
// The dependency container.
//
// Before this file existed, `QeloryxApp.init` built every engine inline and
// views default-constructed their own (`AstryxLibraryEngine()`,
// `AstryxAudioEngine()`, `AstryxDSPEngine()`), which is why:
//   • the production library ran on an in-memory store  (BUG-01)
//   • the Audio Lab edited a second DSP instance        (BUG-07)
//   • a player view model could own a different engine  (BUG-19)
//
// Everything downstream now receives its dependencies; nothing constructs an
// engine implicitly.

import Foundation

/// Whether the library this launch is backed by data that survives a relaunch.
///
/// A degraded library must be visible to the user: "your imports will vanish on
/// quit" is not something to discover tomorrow.
public enum StorageStatus: Sendable, Equatable {
    case persistent
    case degraded(reason: String)

    public var isPersistent: Bool { self == .persistent }

    public var userFacingMessage: String? {
        switch self {
        case .persistent:
            return nil
        case .degraded(let reason):
            return "Library is not being saved: \(reason)"
        }
    }
}

public struct AppDependencies {

    public let configuration: AppConfiguration
    public let storageStatus: StorageStatus
    public let eventBus: any EventBusProtocol
    public let capabilityRegistry: AstryxCapabilityRegistry
    public let providerRegistry: AstryxProviderRegistry
    public let performanceMonitor: AstryxPerformanceMonitor

    public let storage: any SwiftDataStackProtocol
    public let libraryEngine: any LibraryEngineProtocol
    public let metadataEngine: any MetadataEngineProtocol
    public let audioEngine: any AstryxAudioEngineProtocol
    public let searchEngine: any SearchEngineProtocol
    public let downloadEngine: any DownloadEngineProtocol
    public let queueController: any QueueControllerProtocol
    public let tasteEngine: any TasteDNAEngineProtocol
    public let recommendationProvider: any RecommendationProviderProtocol
    public let lyricsEngine: any LyricsEngineProtocol
    public let dspEngine: any DSPEngineProtocol
    public let settingsRepository: SettingsRepository
    public let playbackRestorer: PlaybackRestorer

    // Platform adapters
    public let avAdapter: any AudioPlayerAdapterProtocol
    public let sessionManager: any AudioSessionManagerProtocol
    public let nowPlayingManager: any NowPlayingManagerProtocol
    public let liveActivityManager: any LiveActivityManagerProtocol
    public let hapticEngine: any HapticEngineProtocol
    public let downloadSession: any DownloadSessionProtocol
}
