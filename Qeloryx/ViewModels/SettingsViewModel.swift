// QELORYX — ViewModels
// SettingsViewModel.swift
// Observed by `Views/Settings/SettingsView`. Mirrors the settings repository
// into bindable state and writes validated values back through it — the
// repository remains the single source of truth and persists every change.

import Foundation
import Combine

@MainActor
public final class SettingsViewModel: ObservableObject {

    private let repository: SettingsRepository

    // Playback
    @Published public var restoreQueueOnLaunch: Bool
    @Published public var gaplessEnabled: Bool
    @Published public var replayGainEnabled: Bool
    /// 0 = disabled, up to 12 s (clamped by the repository).
    @Published public var crossfadeSeconds: Double

    // Downloads
    @Published public var allowsCellular: Bool
    @Published public var maxConcurrentDownloads: Int

    // Privacy
    @Published public var analyticsEnabled: Bool
    @Published public var syncHistoryEnabled: Bool

    public init(repository: SettingsRepository) {
        self.repository = repository
        restoreQueueOnLaunch = repository.playback.restoreQueueOnLaunch
        gaplessEnabled = repository.audio.gaplessEnabled
        replayGainEnabled = repository.audio.replayGainEnabled
        crossfadeSeconds = repository.audio.crossfadeSeconds
        allowsCellular = repository.downloads.allowsCellular
        maxConcurrentDownloads = repository.downloads.maxConcurrent
        analyticsEnabled = repository.privacy.analyticsEnabled
        syncHistoryEnabled = repository.privacy.syncHistoryEnabled
    }

    public func setRestoreQueueOnLaunch(_ value: Bool) {
        restoreQueueOnLaunch = value
        repository.setRestoreQueueOnLaunch(value)
    }

    public func setGaplessEnabled(_ value: Bool) {
        gaplessEnabled = value
        repository.setGaplessEnabled(value)
    }

    public func setReplayGainEnabled(_ value: Bool) {
        replayGainEnabled = value
        repository.setReplayGainEnabled(value)
    }

    public func setCrossfadeSeconds(_ value: Double) {
        // The repository clamps to 0…12; reflect back the validated value.
        repository.setCrossfadeSeconds(value)
        crossfadeSeconds = repository.audio.crossfadeSeconds
    }

    public func setAllowsCellular(_ value: Bool) {
        allowsCellular = value
        repository.setAllowsCellular(value)
    }

    public func setMaxConcurrentDownloads(_ value: Int) {
        // The repository clamps to 1…maximumConcurrentDownloads; reflect back the validated value.
        repository.setMaxConcurrentDownloads(value)
        maxConcurrentDownloads = repository.downloads.maxConcurrent
    }

    public func setAnalyticsEnabled(_ value: Bool) {
        analyticsEnabled = value
        repository.setAnalyticsEnabled(value)
    }

    public func setSyncHistoryEnabled(_ value: Bool) {
        syncHistoryEnabled = value
        repository.setSyncHistoryEnabled(value)
    }
}
