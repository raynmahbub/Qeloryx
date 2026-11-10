// QELORYX — App
// AppCompositionRoot.swift
// The composition root: builds the full dependency graph once, at launch.
// Kept separate from AppDependencies.swift so the container stays a plain
// value and the wiring lives in exactly one place.

import Foundation

extension AppDependencies {

    // MARK: - Composition

    /// Builds the full graph.
    ///
    /// - Parameters:
    ///   - configuration: environment info.
    ///   - storage: the persistent store. `nil` builds a real SwiftData store;
    ///     a value is used by tests/previews.
    ///   - avAdapter / sessionManager / nowPlaying / liveActivity / haptics /
    ///     downloadSession: platform adapters, defaulted to the real
    ///     implementations so the app gets them and tests can substitute.
    public static func live(
        configuration: AppConfiguration = .current,
        storage: (any SwiftDataStackProtocol)? = nil,
        metadataEngine: (any MetadataEngineProtocol)? = nil,
        avAdapter: (any AudioPlayerAdapterProtocol)? = nil,
        sessionManager: (any AudioSessionManagerProtocol)? = nil,
        nowPlayingManager: (any NowPlayingManagerProtocol)? = nil,
        liveActivityManager: (any LiveActivityManagerProtocol)? = nil,
        hapticEngine: (any HapticEngineProtocol)? = nil,
        downloadSession: (any DownloadSessionProtocol)? = nil,
        downloadTaskStore: (any DownloadTaskStoring)? = nil
    ) -> AppDependencies {

        let eventBus = AstryxEventBus.shared
        var storageStatus = StorageStatus.persistent
        // Assigned whenever the resolved store is not durable; keeps the banner
        // honest for the caller-supplied case too.

        // Persistence: a real store on platforms that have SwiftData. There is
        // deliberately no silent in-memory fallback — losing the whole library
        // on relaunch is worse than refusing to start (BUG-01).
        let resolvedStorage: any SwiftDataStackProtocol
        if let storage {
            resolvedStorage = storage
        } else {
            #if canImport(SwiftData)
            do {
                resolvedStorage = try SwiftDataAdapter()
            } catch {
                // A corrupt store must be recoverable, not fatal. Degrade to an
                // in-memory library and *say so* in the UI (see
                // `storageStatus`); the previous code silently used an empty
                // in-memory store and looked like data loss (BUG-01).
                storageStatus = .degraded(reason: error.localizedDescription)
                resolvedStorage = InMemorySwiftDataStack()
            }
            #else
            storageStatus = .degraded(reason: "SwiftData is unavailable in this build")
            resolvedStorage = InMemorySwiftDataStack()
            #endif
        }

        // The AVAsset extractor lives in Qeloryx/Platform/Audio/MetadataExtractor.swift.
        // It used to be dead code: nothing constructed it, so imports fell back
        // to guessing titles from file names (BUG-25).
        if !resolvedStorage.isPersistent, storageStatus == .persistent {
            storageStatus = .degraded(reason: "the library is held in memory")
        }

        let resolvedMetadata: any MetadataEngineProtocol = metadataEngine ?? AstryxPlatformMetadataEngine()

        // Core engines
        let library = AstryxLibraryEngine(storage: resolvedStorage, metadataEngine: resolvedMetadata)
        let queueController = AstryxQueueController(eventBus: eventBus)
        let tasteEngine = AstryxTasteDNAEngine(eventBus: eventBus)
        // One DSP instance for the whole app. The Audio Lab observes exactly
        // this object; nothing else constructs another (BUG-07).
        let dspEngine = AstryxDSPEngine()
        let lyricsEngine = AstryxLyricsEngine(eventBus: eventBus)

        // Platform adapters
        let resolvedAdapter = avAdapter ?? GaplessAudioPlayerAdapter()
        let resolvedSession = sessionManager ?? AstryxAudioSessionManager(eventBus: eventBus)
        let resolvedNowPlaying = nowPlayingManager ?? AstryxNowPlayingManager.shared
        let resolvedLiveActivity = liveActivityManager ?? AstryxLiveActivityManager.shared
        let resolvedHaptics = hapticEngine ?? AstryxHapticEngine.shared
        let resolvedDownloadSession = downloadSession ?? AstryxDownloadSessionManager()

        let settingsRepository = SettingsRepository()
        let playbackRestorer = PlaybackRestorer(store: UserDefaultsPlaybackResumeStore())

        // Downloads index their results into the library (BUG-10) using the
        // same metadata engine as imports.
        let download = AstryxDownloadEngine(
            eventBus: eventBus,
            downloadSession: resolvedDownloadSession,
            taskStore: downloadTaskStore ?? FileDownloadTaskStore(),
            library: library,
            metadataEngine: resolvedMetadata
        )

        let audio = AstryxAudioEngine(
            queueController: queueController,
            sessionManager: resolvedSession,
            eventBus: eventBus,
            libraryEngine: library,
            nowPlayingManager: resolvedNowPlaying,
            liveActivityManager: resolvedLiveActivity,
            hapticEngine: resolvedHaptics,
            avAdapter: resolvedAdapter
        )

        let search = AstryxSearchEngine(libraryEngine: library, eventBus: eventBus)
        let recommendationProvider = AstryxRecommendationProvider(tasteEngine: tasteEngine)

        // The registry stores `Provider` conformers. The lyrics and artwork
        // *services* conform to their own protocols, not to `Provider`, so they
        // were never registrable — those lines were removed rather than faked.
        let providerRegistry = AstryxProviderRegistry.shared
        providerRegistry.register(recommendationProvider)

        return AppDependencies(
            configuration: configuration,
            storageStatus: storageStatus,
            eventBus: eventBus,
            capabilityRegistry: .shared,
            providerRegistry: providerRegistry,
            performanceMonitor: .shared,
            storage: resolvedStorage,
            libraryEngine: library,
            metadataEngine: resolvedMetadata,
            audioEngine: audio,
            searchEngine: search,
            downloadEngine: download,
            queueController: queueController,
            tasteEngine: tasteEngine,
            recommendationProvider: recommendationProvider,
            lyricsEngine: lyricsEngine,
            dspEngine: dspEngine,
            settingsRepository: settingsRepository,
            playbackRestorer: playbackRestorer,
            avAdapter: resolvedAdapter,
            sessionManager: resolvedSession,
            nowPlayingManager: resolvedNowPlaying,
            liveActivityManager: resolvedLiveActivity,
            hapticEngine: resolvedHaptics,
            downloadSession: resolvedDownloadSession
        )
    }

    // MARK: - Platform selection
    //
    // The XcodeGen app target compiles Qeloryx/ into one module (App, Views,
    // ViewModels, Services, Platform, DesignSystem, Utilities, Models), so Platform types are referenced directly.
    // The SPM build (`swift build`) does not include App/, Views/ or ViewModels/, so it is unaffected.
    // There is therefore no `canImport` branching here: the real adapters are
    // always used, never a silent downgrade.
}
