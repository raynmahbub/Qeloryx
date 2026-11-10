// QELORYX — App
// QeloryxApp.swift
//
// The app entry point owns nothing but the scene graph. Every engine, adapter
// and store is built once by `AppDependencies.live()` (see AppCompositionRoot)
// and injected downward, so:
//   • the library is backed by the persistent SwiftData store (BUG-01)
//   • one DSP instance serves both the engine and the Audio Lab (BUG-07)
//   • the crossfade setting reaches the dual-deck adapter (BUG-06)
//   • the queue and position are persisted and restored paused
//
// Launch bookkeeping lives in `AppLifecycle`; the UIKit delegate bridge is
// `AppDelegate`.

import SwiftUI

@main
struct QeloryxApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    private let dependencies: AppDependencies
    @StateObject private var playerViewModel: PlayerViewModel

    init() {
        AppLifecycle.didLaunch()

        let dependencies = AppDependencies.live()
        self.dependencies = dependencies

        // The player view model receives the composition root's engines. It no
        // longer default-constructs an audio engine or a library (BUG-19).
        let viewModel = PlayerViewModel(
            audioEngine: dependencies.audioEngine,
            libraryEngine: dependencies.libraryEngine,
            eventBus: dependencies.eventBus,
            dspEngine: dependencies.dspEngine,
            settings: dependencies.settingsRepository,
            playbackRestorer: dependencies.playbackRestorer
        )
        _playerViewModel = StateObject(wrappedValue: viewModel)

        // Apply persisted audio preferences before any playback can start.
        AppLifecycle.applyPersistedAudioPreferences(dependencies: dependencies)

        #if DEBUG
        debugPrint("[QELORYX] \(dependencies.configuration.version) — composition root ready")
        #endif
        // Launch tracking is ended in `restorePlaybackIfNeeded`, after the first
        // frame is on screen — not here, where nothing has been rendered yet.
    }

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: playerViewModel)
                .environment(\.audioEngine, dependencies.audioEngine)
                .environment(\.libraryEngine, dependencies.libraryEngine)
                .environment(\.searchEngine, dependencies.searchEngine)
                .environment(\.eventBus, dependencies.eventBus)
                .environment(\.downloadEngine, dependencies.downloadEngine)
                .environment(\.dspEngine, dependencies.dspEngine)
                .environment(\.settings, dependencies.settingsRepository)
                .environment(\.lyricsEngine, dependencies.lyricsEngine)
                .environment(\.tasteEngine, dependencies.tasteEngine)
                .environment(\.queueController, dependencies.queueController)
                .astrixTheme()
                .task {
                    await AppLifecycle.restorePlaybackIfNeeded(dependencies: dependencies)
                }
        }
        .onChange(of: scenePhase) { phase in
            AppLifecycle.handleScenePhaseChange(phase, dependencies: dependencies)
        }
    }
}
