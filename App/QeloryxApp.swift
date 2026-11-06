// QELORYX — App
// QeloryxApp.swift
// QEL-051 Polish — Production composition root with all engines, performance monitoring, launch optimization

import SwiftUI

@main
struct QeloryxApp: App {
    
    private let eventBus: any EventBusProtocol = AstryxEventBus.shared
    private let capabilityRegistry = AstryxCapabilityRegistry.shared
    private let providerRegistry = AstryxProviderRegistry.shared
    private let performanceMonitor = AstryxPerformanceMonitor.shared
    private let launchOptimizer = AstryxLaunchOptimizer.shared
    
    private let libraryEngine: any LibraryEngineProtocol
    private let audioEngine: any AstryxAudioEngineProtocol
    private let searchEngine: any SearchEngineProtocol
    private let downloadEngine: any DownloadEngineProtocol
    private let queueController: any QueueControllerProtocol
    private let tasteEngine: any TasteDNAEngineProtocol
    private let recommendationProvider: any RecommendationProviderProtocol
    private let lyricsEngine: any LyricsEngineProtocol
    private let dspEngine: any DSPEngineProtocol
    private let avAdapter: any AudioPlayerAdapterProtocol
    private let sessionManager: any AudioSessionManagerProtocol
    private let nowPlayingManager: any NowPlayingManagerProtocol
    private let liveActivityManager: any LiveActivityManagerProtocol
    private let hapticEngine: any HapticEngineProtocol
    private let downloadSessionManager: any DownloadSessionProtocol
    
    @StateObject private var playerViewModel: AstryxPlayerViewModel
    
    init() {
        // Performance: start launch tracking immediately — cold launch <1.5s budget
        AstryxLaunchOptimizer.shared.optimizeColdLaunch()
        
        let eventBus = AstryxEventBus.shared
        // Dual-deck gapless adapter: identical to the classic adapter for
        // hard transitions, and honors `.setCrossfade` by pre-staging the
        // next track on the standby deck for seamless fades.
        let avAdapter: any AudioPlayerAdapterProtocol = GaplessAudioPlayerAdapter()
        let sessionManager: any AudioSessionManagerProtocol = AstryxAudioSessionManager(eventBus: eventBus)
        let nowPlaying: any NowPlayingManagerProtocol = AstryxNowPlayingManager.shared
        let liveActivity: any LiveActivityManagerProtocol = AstryxLiveActivityManager.shared
        let haptics: any HapticEngineProtocol = AstryxHapticEngine.shared
        
        // Core engines — lazy initialization for cold launch optimization
        let library = AstryxLibraryEngine(eventBus: eventBus)
        let queueController = AstryxQueueController(eventBus: eventBus)
        let tasteEngine = AstryxTasteDNAEngine(eventBus: eventBus)
        let dspEngine = AstryxDSPEngine()
        let lyricsEngine = AstryxLyricsEngine(eventBus: eventBus)
        
        // Download engine with platform session injection (layer isolation)
        let downloadSessionManager: any DownloadSessionProtocol = AstryxDownloadSessionManager()
        let downloadEngine = AstryxDownloadEngine(eventBus: eventBus, downloadSession: downloadSessionManager)
        
        let audio = AstryxAudioEngine(
            queueController: queueController,
            sessionManager: sessionManager,
            eventBus: eventBus,
            libraryEngine: library,
            nowPlayingManager: nowPlaying,
            liveActivityManager: liveActivity,
            hapticEngine: haptics,
            avAdapter: avAdapter
        )
        let search = AstryxSearchEngine(libraryEngine: library, eventBus: eventBus)
        let recommendationProvider = AstryxRecommendationProvider(tasteEngine: tasteEngine)
        
        self.libraryEngine = library
        self.audioEngine = audio
        self.searchEngine = search
        self.downloadEngine = downloadEngine
        self.queueController = queueController
        self.tasteEngine = tasteEngine
        self.recommendationProvider = recommendationProvider
        self.lyricsEngine = lyricsEngine
        self.dspEngine = dspEngine
        self.avAdapter = avAdapter
        self.sessionManager = sessionManager
        self.nowPlayingManager = nowPlaying
        self.liveActivityManager = liveActivity
        self.hapticEngine = haptics
        self.downloadSessionManager = downloadSessionManager
        
        let vm = AstryxPlayerViewModel(audioEngine: audio, libraryEngine: library, eventBus: eventBus)
        _playerViewModel = StateObject(wrappedValue: vm)
        
        // Background tasks
        AstryxBackgroundTaskManager.shared.registerBackgroundTasks()
        
        // Providers
        providerRegistry.register(AstryxLyricsProvider() as any Provider)
        providerRegistry.register(AstryxArtworkProvider() as any Provider)
        providerRegistry.register(recommendationProvider as any Provider)
        
        #if DEBUG
        debugPrint("[QELORYX] App initialized — \(AppConfiguration.current.version) — Midnight Aurora — QEL-051 Polish — Performance monitoring active")
        #endif
        
        // End launch tracking — should be <1.5s cold
        AstryxLaunchOptimizer.shared.endLaunchTracking()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView(viewModel: playerViewModel)
                .environment(\.audioEngine, audioEngine)
                .environment(\.libraryEngine, libraryEngine)
                .environment(\.searchEngine, searchEngine)
                .environment(\.eventBus, eventBus)
                .astrixTheme() // Midnight Aurora theme — dark-first, auroraBlue tint
                .onAppear {
                    // Warm launch tracking for subsequent launches
                    AstryxLaunchOptimizer.shared.optimizeWarmLaunch()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        AstryxLaunchOptimizer.shared.endLaunchTracking()
                    }
                }
        }
    }
}
