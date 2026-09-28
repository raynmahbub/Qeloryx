// QELORYX — App
// QeloryxApp.swift
// @main entry per spec

import SwiftUI

@main
struct QeloryxApp: App {
    
    // MARK: - Dependencies (Composition Root)
    private let eventBus: any EventBusProtocol = AstryxEventBus.shared
    private let capabilityRegistry = AstryxCapabilityRegistry.shared
    private let providerRegistry = AstryxProviderRegistry.shared
    private let libraryEngine: any LibraryEngineProtocol
    private let audioEngine: any AstryxAudioEngineProtocol
    private let searchEngine: any SearchEngineProtocol
    private let downloadEngine: any DownloadEngineProtocol
    
    init() {
        // Initialize core engines
        let library = AstryxLibraryEngine(eventBus: eventBus)
        let queueController = AstryxQueueController(eventBus: eventBus)
        let audio = AstryxAudioEngine(queueController: queueController, eventBus: eventBus, libraryEngine: library)
        let search = AstryxSearchEngine(libraryEngine: library, eventBus: eventBus)
        let download = AstryxDownloadEngine(eventBus: eventBus)
        
        self.libraryEngine = library
        self.audioEngine = audio
        self.searchEngine = search
        self.downloadEngine = download
        
        // Configure platform
        AstryxNowPlayingManager.shared.configure()
        AstryxBackgroundTaskManager.shared.registerBackgroundTasks()
        
        // Register providers
        providerRegistry.register(AstryxLyricsProvider() as any Provider)
        providerRegistry.register(AstryxArtworkProvider() as any Provider)
        
        // Performance budget instrumentation placeholder
        #if DEBUG
        debugPrint("[QELORYX] App initialized — \(AppConfiguration.current.version) — Midnight Aurora")
        debugPrint("[QELORYX] Capabilities: \(capabilityRegistry.enabledCapabilities().map { $0.name })")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.audioEngine, audioEngine)
                .environment(\.libraryEngine, libraryEngine)
                .environment(\.searchEngine, searchEngine)
                .environment(\.eventBus, eventBus)
        }
    }
}
