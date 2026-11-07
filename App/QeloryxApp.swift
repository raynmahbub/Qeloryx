// QELORYX — App
// QeloryxApp.swift
//
// The app entry point now owns nothing but lifecycle. Every engine, adapter and
// store is built once by `AppDependencies.live()` and injected downward, so:
//   • the library is backed by the persistent SwiftData store (BUG-01)
//   • one DSP instance serves both the engine and the Audio Lab (BUG-07)
//   • the crossfade setting reaches the dual-deck adapter (BUG-06)
//   • the queue and position are persisted and restored paused
//
// The previous version built ~15 concrete objects inline, kept them as `let`
// properties and still left views default-constructing their own engines.

import SwiftUI

@main
struct QeloryxApp: App {

    @Environment(\.scenePhase) private var scenePhase

    private let dependencies: AppDependencies
    @StateObject private var playerViewModel: AstryxPlayerViewModel

    init() {
        AstryxLaunchOptimizer.shared.optimizeColdLaunch()

        let dependencies = AppDependencies.live()
        self.dependencies = dependencies

        // The player view model receives the composition root's engines. It no
        // longer default-constructs an audio engine or a library (BUG-19).
        let viewModel = AstryxPlayerViewModel(
            audioEngine: dependencies.audioEngine,
            libraryEngine: dependencies.libraryEngine,
            eventBus: dependencies.eventBus,
            dspEngine: dependencies.dspEngine,
            settings: dependencies.settingsRepository,
            playbackRestorer: dependencies.playbackRestorer
        )
        _playerViewModel = StateObject(wrappedValue: viewModel)

        AstryxBackgroundTaskManager.shared.registerBackgroundTasks()

        // Apply persisted audio preferences before any playback can start.
        let settings = dependencies.settingsRepository
        Task { [audioEngine = dependencies.audioEngine] in
            await settings.applyAudioSettings(to: audioEngine)
            if let downloadSession = dependencies.downloadSession as? AstryxDownloadSessionManager {
                downloadSession.setAllowsCellularAccess(settings.downloads.allowsCellular)
            }
        }

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
                .astrixTheme()
                .task {
                    await restorePlaybackIfNeeded()
                }
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background, .inactive:
                // Persist the resume point whenever we leave the foreground.
                dependencies.playbackRestorer.capture(from: dependencies.audioEngine)
            default:
                break
            }
        }
    }

    /// Restores the last queue **paused**. Never auto-plays: an app that starts
    /// making noise on launch is worse than one that forgot where it was.
    private func restorePlaybackIfNeeded() async {
        defer {
            // Always close the launch measurement, even on the early-exit paths.
            AstryxLaunchOptimizer.shared.optimizeWarmLaunch()
            AstryxLaunchOptimizer.shared.endLaunchTracking()
        }

        guard dependencies.settingsRepository.playback.restoreQueueOnLaunch else { return }
        // No `as?` cast: restoration is part of `AstryxAudioEngineProtocol`, so
        // substituting the engine implementation cannot silently disable it.
        await dependencies.playbackRestorer.restore(into: dependencies.audioEngine, paused: true)
    }
}
