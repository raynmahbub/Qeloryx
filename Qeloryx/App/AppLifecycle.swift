// QELORYX — App
// AppLifecycle.swift
//
// Everything launch- and scene-phase-related, extracted from `QeloryxApp` so
// the App type only declares the scene graph. Side effects are one-directional:
// App → AppLifecycle → engines; engines never call back into here.

import SwiftUI

@MainActor
enum AppLifecycle {

    /// Called once at app init, before any engine work. Owns launch-time
    /// measurements and background-task registration.
    static func didLaunch() {
        AstryxLaunchOptimizer.shared.optimizeColdLaunch()
        AstryxBackgroundTaskManager.shared.registerBackgroundTasks()
    }

    /// Applies persisted audio preferences (and the cellular download flag)
    /// before any playback can start.
    static func applyPersistedAudioPreferences(dependencies: AppDependencies) {
        let settings = dependencies.settingsRepository
        Task { [audioEngine = dependencies.audioEngine] in
            await settings.applyAudioSettings(to: audioEngine)
            if let downloadSession = dependencies.downloadSession as? AstryxDownloadSessionManager {
                downloadSession.setAllowsCellularAccess(settings.downloads.allowsCellular)
            }
        }
    }

    /// Persists the resume point whenever the app leaves the foreground.
    static func handleScenePhaseChange(_ phase: ScenePhase, dependencies: AppDependencies) {
        switch phase {
        case .background, .inactive:
            dependencies.playbackRestorer.capture(from: dependencies.audioEngine)
        default:
            break
        }
    }

    /// Restores the last queue **paused**. Never auto-plays: an app that starts
    /// making noise on launch is worse than one that forgot where it was.
    static func restorePlaybackIfNeeded(dependencies: AppDependencies) async {
        defer {
            // Always close the launch measurement, even on the early-exit paths.
            AstryxLaunchOptimizer.shared.optimizeWarmLaunch()
            AstryxLaunchOptimizer.shared.endLaunchTracking()
        }

        guard dependencies.settingsRepository.playback.restoreQueueOnLaunch else { return }
        // No `as?` cast: restoration is part of the engine protocol, so
        // substituting the engine implementation cannot silently disable it.
        await dependencies.playbackRestorer.restore(into: dependencies.audioEngine, paused: true)
    }
}
