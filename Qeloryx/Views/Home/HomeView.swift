// QELORYX — Views/Home
// HomeView.swift
// QEL-051 — Home with widgets, Taste DNA entry, Audio Lab, Spaces

import SwiftUI

public struct HomeView: View {

    @StateObject private var viewModel: HomeViewModel

    // Stored, not just used to build the view model: the navigation
    // destinations in `statsGrid` / `tasteDNAWidget` construct child views that
    // need the same engines. Previously these existed only as `init` parameters,
    // so every reference inside `body` was "cannot find in scope".
    private let libraryEngine: any LibraryEngineProtocol
    private let downloadEngine: any DownloadEngineProtocol
    private let tasteEngine: any TasteDNAEngineProtocol
    private let audioEngine: any AstryxAudioEngineProtocol
    private let dspEngine: any DSPEngineProtocol

    @Environment(\.settings) private var settings
    @Environment(\.queueController) private var queueController

    public init(
        libraryEngine: any LibraryEngineProtocol,
        downloadEngine: any DownloadEngineProtocol,
        tasteEngine: any TasteDNAEngineProtocol,
        audioEngine: any AstryxAudioEngineProtocol,
        dspEngine: any DSPEngineProtocol
    ) {
        self.libraryEngine = libraryEngine
        self.downloadEngine = downloadEngine
        self.tasteEngine = tasteEngine
        self.audioEngine = audioEngine
        self.dspEngine = dspEngine
        _viewModel = StateObject(
            wrappedValue: HomeViewModel(
                libraryEngine: libraryEngine,
                downloadEngine: downloadEngine,
                tasteEngine: tasteEngine,
                audioEngine: audioEngine
            )
        )
    }
    
    public var body: some View {
        ZStack {
            AstryxColors.midnight
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    greetingHeader
                    tasteDNAWidget
                    statsGrid
                    quickActions
                    recentSection
                    discoverSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: QueueView(queueController: queueController, libraryEngine: libraryEngine)) {
                    Image(systemName: "list.bullet")
                        .foregroundColor(AstryxColors.Semantic.foreground)
                }
                .accessibilityLabel("Queue")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: SettingsView(settings: settings)) {
                    Image(systemName: "gearshape")
                        .foregroundColor(AstryxColors.Semantic.foreground)
                }
                .accessibilityLabel("Settings")
            }
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    private var greetingHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.greeting)
                    .font(AstryxTypography.Heading.h2)
                    .foregroundColor(AstryxColors.iceWhite)
                Text(viewModel.subGreeting)
                    .font(AstryxTypography.Body.small)
                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(AstryxColors.Gradients.aurora)
                    .frame(width: 50, height: 50)
                Text(String(viewModel.userInitial))
                    .font(AstryxTypography.Heading.h3)
                    .foregroundColor(AstryxColors.iceWhite)
            }
        }
    }
    
    private var tasteDNAWidget: some View {
        NavigationLink(destination: TasteDNAView(tasteEngine: tasteEngine, libraryEngine: libraryEngine)) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AstryxColors.auroraBlue.opacity(0.15))
                        .frame(width: 60, height: 60)
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 28))
                        .foregroundColor(AstryxColors.auroraBlue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Taste DNA")
                        .font(AstryxTypography.Heading.h4)
                        .foregroundColor(AstryxColors.iceWhite)
                    Text(viewModel.tasteSummary)
                        .font(AstryxTypography.Body.small)
                        .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
            }
            .padding(16)
            .background(AstryxColors.Semantic.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AstryxColors.auroraBlue.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            HomeCard(
                title: "Favorites",
                value: "\(viewModel.favoriteCount)",
                icon: "heart.fill",
                color: AstryxColors.sunset,
                destination: AnyView(LibraryView(libraryEngine: libraryEngine, audioEngine: audioEngine))
            )
            HomeCard(
                title: "Recent",
                value: "\(viewModel.recentCount)",
                icon: "clock.fill",
                color: AstryxColors.auroraBlue,
                destination: AnyView(LibraryView(libraryEngine: libraryEngine, audioEngine: audioEngine))
            )
            HomeCard(
                title: "Downloads",
                value: "\(viewModel.downloadCount)",
                icon: "arrow.down.circle.fill",
                color: AstryxColors.emerald,
                destination: AnyView(DownloadsView(downloadEngine: downloadEngine))
            )
            HomeCard(
                title: "Mood",
                value: viewModel.currentMood,
                icon: "face.smiling.fill",
                color: AstryxColors.auroraBlue,
                destination: AnyView(
                    TasteDNAView(tasteEngine: tasteEngine, libraryEngine: libraryEngine)
                )
            )
            HomeCard(
                title: "Queue",
                value: "\(viewModel.queueCount)",
                icon: "music.note.list",
                color: AstryxColors.Semantic.foregroundSecondary,
                destination: nil
            )
            HomeCard(
                title: "Vinyl",
                value: "Collection",
                icon: "opticaldisc.fill",
                color: AstryxColors.Semantic.foregroundTertiary,
                destination: AnyView(LibraryView(libraryEngine: libraryEngine, audioEngine: audioEngine))
            )
        }
    }
    
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Quick Actions", icon: "bolt.fill")
            
            HStack(spacing: 12) {
                QuickActionButton(title: "Audio Lab", icon: "waveform.path.ecg", color: AstryxColors.auroraBlue) {
                    // Navigate to Audio Lab
                }
                QuickActionButton(title: "Spaces", icon: "person.3.fill", color: AstryxColors.emerald) {
                    // Navigate to Spaces
                }
                QuickActionButton(title: "Shuffle", icon: "shuffle", color: AstryxColors.sunset) {
                    // Shuffle play
                }
                QuickActionButton(title: "Search", icon: "magnifyingglass", color: AstryxColors.Semantic.foregroundSecondary) {
                    // Search
                }
            }
        }
    }
    
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recently Played", icon: "clock.arrow.circlepath")
            
            if viewModel.recentTracks.isEmpty {
                Text("No recent tracks")
                    .font(AstryxTypography.Body.small)
                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(AstryxColors.Semantic.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.recentTracks) { track in
                            VStack(spacing: 8) {
                                AstryxArtwork(data: track.artworkData, size: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                Text(track.title)
                                    .font(AstryxTypography.Body.small)
                                    .foregroundColor(AstryxColors.iceWhite)
                                    .lineLimit(1)
                                    .frame(width: 100)
                                Text(track.artist)
                                    .font(AstryxTypography.Body.caption)
                                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                                    .lineLimit(1)
                                    .frame(width: 100)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var discoverSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Discover", icon: "sparkles")
            
            VStack(spacing: 10) {
                NavigationLink(destination: AudioLabView(dspEngine: dspEngine)) {
                    DiscoverRow(icon: "waveform.path.ecg", title: "Audio Lab", subtitle: "Signal Path • EQ • Spectrum", color: AstryxColors.auroraBlue)
                }
                NavigationLink(destination: SocialView()) {
                    DiscoverRow(icon: "person.3.fill", title: "Spaces", subtitle: "Shared Queue • Live Reactions", color: AstryxColors.emerald)
                }
                NavigationLink(destination: TasteDNAView(tasteEngine: tasteEngine, libraryEngine: libraryEngine)) {
                    DiscoverRow(icon: "heart.circle.fill", title: "Taste DNA", subtitle: "Your evolving listening profile", color: AstryxColors.sunset)
                }
            }
        }
    }
}

// MARK: - ViewModel

@MainActor

// MARK: - Helpers

private struct SectionHeader: View {
    let title: String
    let icon: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AstryxColors.auroraBlue)
            Text(title)
                .font(AstryxTypography.Heading.h4)
                .foregroundColor(AstryxColors.iceWhite)
            Spacer()
        }
    }
}

private struct HomeCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    /// Optional: a card with `nil` is a plain, non-navigating tile. The Queue
    /// card has no destination because `PlayerView` needs a view model
    /// carrying an engine pair, event bus and scrobbler that this screen does
    /// not own — a dangling `PlayerView()` was the alternative.
    let destination: AnyView?

    var body: some View {
        content
    }

    @ViewBuilder
    private var content: some View {
        if let destination {
            NavigationLink(destination: destination) { cardBody }
        } else {
            cardBody
        }
    }

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                Spacer()
                if destination != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(AstryxTypography.Heading.h3)
                    .foregroundColor(AstryxColors.iceWhite)
                    .lineLimit(1)
                Text(title)
                    .font(AstryxTypography.Body.small)
                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
            }
        }
        .padding(14)
        .background(AstryxColors.Semantic.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
                Text(title)
                    .font(AstryxTypography.Body.caption)
                    .foregroundColor(AstryxColors.iceWhite)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(AstryxColors.Semantic.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

private struct DiscoverRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AstryxTypography.Body.medium)
                    .foregroundColor(AstryxColors.iceWhite)
                Text(subtitle)
                    .font(AstryxTypography.Body.caption)
                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
        }
        .padding(12)
        .background(AstryxColors.Semantic.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
