// QELORYX — App
// QeloryxApp.swift
// QEL-012 Player Milestone — Production composition root with AVFoundation, Live Activity, Haptics

import SwiftUI

@main
struct QeloryxApp: App {
    
    private let eventBus: any EventBusProtocol = AstryxEventBus.shared
    private let capabilityRegistry = AstryxCapabilityRegistry.shared
    private let providerRegistry = AstryxProviderRegistry.shared
    
    private let libraryEngine: any LibraryEngineProtocol
    private let audioEngine: any AstryxAudioEngineProtocol
    private let searchEngine: any SearchEngineProtocol
    private let downloadEngine: any DownloadEngineProtocol
    private let queueController: any QueueControllerProtocol
    private let avAdapter: any AudioPlayerAdapterProtocol
    private let sessionManager: any AudioSessionManagerProtocol
    private let nowPlayingManager: any NowPlayingManagerProtocol
    private let liveActivityManager: any LiveActivityManagerProtocol
    private let hapticEngine: any HapticEngineProtocol
    
    @StateObject private var playerViewModel: AstryxPlayerViewModel
    
    init() {
        let eventBus = AstryxEventBus.shared
        let avAdapter: any AudioPlayerAdapterProtocol = AVFoundationAdapter()
        let sessionManager: any AudioSessionManagerProtocol = AstryxAudioSessionManager(eventBus: eventBus)
        let nowPlaying: any NowPlayingManagerProtocol = AstryxNowPlayingManager.shared
        let liveActivity: any LiveActivityManagerProtocol = AstryxLiveActivityManager.shared
        let haptics: any HapticEngineProtocol = AstryxHapticEngine.shared
        
        let library = AstryxLibraryEngine(eventBus: eventBus)
        let queueController = AstryxQueueController(eventBus: eventBus)
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
        let download = AstryxDownloadEngine(eventBus: eventBus)
        
        self.libraryEngine = library
        self.audioEngine = audio
        self.searchEngine = search
        self.downloadEngine = download
        self.queueController = queueController
        self.avAdapter = avAdapter
        self.sessionManager = sessionManager
        self.nowPlayingManager = nowPlaying
        self.liveActivityManager = liveActivity
        self.hapticEngine = haptics
        
        let vm = AstryxPlayerViewModel(audioEngine: audio, libraryEngine: library, eventBus: eventBus)
        _playerViewModel = StateObject(wrappedValue: vm)
        
        AstryxBackgroundTaskManager.shared.registerBackgroundTasks()
        providerRegistry.register(AstryxLyricsProvider() as any Provider)
        providerRegistry.register(AstryxArtworkProvider() as any Provider)
        
        #if DEBUG
        debugPrint("[QELORYX] App initialized — \(AppConfiguration.current.version) — Midnight Aurora — QEL-012 Player")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            RootView(viewModel: playerViewModel)
                .environment(\.audioEngine, audioEngine)
                .environment(\.libraryEngine, libraryEngine)
                .environment(\.searchEngine, searchEngine)
                .environment(\.eventBus, eventBus)
        }
    }
}
