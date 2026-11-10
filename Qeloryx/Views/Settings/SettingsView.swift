// QELORYX — Views/Settings
// SettingsView.swift
// First real settings screen. Bound to `SettingsViewModel`; the repository
// persists every change and is the only write path.

import SwiftUI

public struct SettingsView: View {

    @StateObject private var viewModel: SettingsViewModel

    public init(settings: SettingsRepository) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(repository: settings))
    }

    public var body: some View {
        Form {
            playbackSection
            downloadsSection
            privacySection
            aboutSection
        }
        .navigationTitle("Settings")
        .background(AstryxColors.Semantic.background.ignoresSafeArea())
    }

    private var playbackSection: some View {
        Section("Playback") {
            Toggle("Restore queue on launch", isOn: Binding(
                get: { viewModel.restoreQueueOnLaunch },
                set: { viewModel.setRestoreQueueOnLaunch($0) }
            ))
            Toggle("Gapless playback", isOn: Binding(
                get: { viewModel.gaplessEnabled },
                set: { viewModel.setGaplessEnabled($0) }
            ))
            Toggle("ReplayGain volume normalisation", isOn: Binding(
                get: { viewModel.replayGainEnabled },
                set: { viewModel.setReplayGainEnabled($0) }
            ))
            VStack(alignment: .leading) {
                Text("Crossfade")
                Slider(value: Binding(
                    get: { viewModel.crossfadeSeconds },
                    set: { viewModel.setCrossfadeSeconds($0) }
                ), in: 0...12, step: 1)
                Text(viewModel.crossfadeSeconds == 0 ? "Off" : "\(Int(viewModel.crossfadeSeconds))s")
                    .font(AstryxTypography.Body.small)
                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
            }
        }
    }

    private var downloadsSection: some View {
        Section("Downloads") {
            Toggle("Download over cellular", isOn: Binding(
                get: { viewModel.allowsCellular },
                set: { viewModel.setAllowsCellular($0) }
            ))
            Stepper("Max concurrent: \(viewModel.maxConcurrentDownloads)", value: Binding(
                get: { viewModel.maxConcurrentDownloads },
                set: { viewModel.setMaxConcurrentDownloads($0) }
            ), in: 1...SettingsRepository.maximumConcurrentDownloads)
        }
    }

    private var privacySection: some View {
        Section("Privacy") {
            Toggle("Share analytics (opt-in)", isOn: Binding(
                get: { viewModel.analyticsEnabled },
                set: { viewModel.setAnalyticsEnabled($0) }
            ))
            Toggle("Sync listening history", isOn: Binding(
                get: { viewModel.syncHistoryEnabled },
                set: { viewModel.setSyncHistoryEnabled($0) }
            ))
            Text("Nothing leaves this device unless you turn it on.")
                .font(AstryxTypography.Body.small)
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: AppConfiguration.current.version)
            Text("Hear Beyond. Build Beyond.")
                .font(AstryxTypography.Body.small)
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
        }
    }
}

